#!/bin/bash -e

# Script to install OpenTAKServer on Raspberry Pi OS
# This is adapted from https://github.com/brian7704/OpenTAKServer-Installer/blob/master/raspberry_pi_installer.sh

OTS_USER="${FIRST_USER_NAME}"

echo "Installing OpenTAKServer..."

# Create directories and install OpenTAKServer via on_chroot
on_chroot <<- EOF
	# Configure dpkg to continue on Python bytecode errors in chroot
	echo 'DPkg::Pre-Install-Pkgs {"/bin/true";};' >> /etc/apt/apt.conf.d/99no-pre-install-pkgs-check

	# Create OTS directories
	mkdir -p /home/${OTS_USER}/ots
	mkdir -p /home/${OTS_USER}/ots/ca
	mkdir -p /home/${OTS_USER}/ots/mediamtx/recordings
	mkdir -p /home/${OTS_USER}/.opentakserver_venv
	mkdir -p /home/${OTS_USER}/ots/logs

	# Set proper permissions
	chown -R ${OTS_USER}:${OTS_USER} /home/${OTS_USER}/ots
	chown -R ${OTS_USER}:${OTS_USER} /home/${OTS_USER}/.opentakserver_venv
	chown -R ${OTS_USER}:${OTS_USER} /home/${OTS_USER}/ots/logs

	# Create Python virtual environment and install OpenTAKServer
	echo "Creating Python virtual environment for OpenTAKServer..."
	if ! su - ${OTS_USER} -c "python3 -m venv --system-site-packages ~/.opentakserver_venv" 2>&1; then
		echo "Error: Failed to create Python virtual environment"
		exit 1
	fi

	echo "Virtual environment created successfully"

	# Upgrade pip, setuptools, wheel with timeout
	echo "Upgrading pip, setuptools, and wheel..."
	timeout 300 su - ${OTS_USER} -c "source ~/.opentakserver_venv/bin/activate && pip3 install --no-cache-dir --upgrade pip setuptools wheel" 2>&1 || echo "Warning: pip upgrade had issues, continuing anyway"

	# Install OpenTAKServer with retries and timeout
	# Note: We install with --no-deps to avoid triggering database initialization in chroot
	echo "Installing OpenTAKServer from PyPI..."
	INSTALL_ATTEMPTS=0
	MAX_ATTEMPTS=3
	INSTALL_SUCCESS=0

	while [ $INSTALL_ATTEMPTS -lt $MAX_ATTEMPTS ]; do
		INSTALL_ATTEMPTS=$((INSTALL_ATTEMPTS + 1))
		echo "Installation attempt $INSTALL_ATTEMPTS/$MAX_ATTEMPTS"

		if timeout 600 su - ${OTS_USER} -c "source ~/.opentakserver_venv/bin/activate && pip3 install --no-cache-dir --no-deps opentakserver" 2>&1; then
			echo "OpenTAKServer package files installed successfully"
			INSTALL_SUCCESS=1
			break
		else
			INSTALL_STATUS=$?
			if [ "$INSTALL_STATUS" = "124" ]; then
				echo "Installation timed out"
			else
				echo "Installation failed with status $INSTALL_STATUS"
			fi
			if [ $INSTALL_ATTEMPTS -lt $MAX_ATTEMPTS ]; then
				echo "Retrying... ($INSTALL_ATTEMPTS/$MAX_ATTEMPTS)"
				sleep 5
			fi
		fi
	done

	if [ $INSTALL_SUCCESS -eq 0 ]; then
		echo "Error: Failed to install OpenTAKServer after $MAX_ATTEMPTS attempts."
		exit 1
	fi

	# Install dependencies in a second step to avoid conflicts
	echo "Installing OpenTAKServer dependencies..."
	timeout 600 su - ${OTS_USER} -c "source ~/.opentakserver_venv/bin/activate && pip3 install --no-cache-dir opentakserver" 2>&1 || echo "Warning: Dependency installation had issues, will be retried on first boot"

	# Generate random password for OTS database user (alphanumeric only, no special chars)
	# Store it in a file for first-boot configuration
	OTS_PASS=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 20)
	echo "${OTS_PASS}" > /tmp/ots_password.txt
	chmod 600 /tmp/ots_password.txt

	echo "PostgreSQL and RabbitMQ initialization will be completed on first boot"
EOF

# Create systemd services
on_chroot <<- EOF
	cat > /etc/systemd/system/opentakserver.service <<- 'SVCEOF'
		[Unit]
		Description=OpenTAKServer - TAK Server Implementation
		Wants=network.target rabbitmq-server.service postgresql.service
		After=network.target rabbitmq-server.service postgresql.service

		[Service]
		Type=simple
		User=${OTS_USER}
		WorkingDirectory=/home/${OTS_USER}/ots
		Environment="PATH=/home/${OTS_USER}/.opentakserver_venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
		ExecStart=/home/${OTS_USER}/.opentakserver_venv/bin/opentakserver
		Restart=on-failure
		RestartSec=5s
		StandardOutput=append:/home/${OTS_USER}/ots/logs/opentakserver.log
		StandardError=append:/home/${OTS_USER}/ots/logs/opentakserver.log

		[Install]
		WantedBy=multi-user.target
	SVCEOF

	cat > /etc/systemd/system/cot_parser.service <<- 'SVCEOF'
		[Unit]
		Description=OpenTAKServer COT Parser
		Wants=network.target rabbitmq-server.service
		After=network.target rabbitmq-server.service
		PartOf=opentakserver.service

		[Service]
		Type=simple
		User=${OTS_USER}
		WorkingDirectory=/home/${OTS_USER}/ots
		Environment="PATH=/home/${OTS_USER}/.opentakserver_venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
		ExecStart=/home/${OTS_USER}/.opentakserver_venv/bin/cot_parser
		Restart=on-failure
		RestartSec=5s
		StandardOutput=append:/home/${OTS_USER}/ots/logs/opentakserver.log
		StandardError=append:/home/${OTS_USER}/ots/logs/opentakserver.log

		[Install]
		WantedBy=multi-user.target
	SVCEOF

	cat > /etc/systemd/system/eud_handler.service <<- 'SVCEOF'
		[Unit]
		Description=OpenTAKServer EUD Handler
		Wants=network.target rabbitmq-server.service
		After=network.target rabbitmq-server.service
		PartOf=opentakserver.service

		[Service]
		Type=simple
		User=${OTS_USER}
		WorkingDirectory=/home/${OTS_USER}/ots
		Environment="PATH=/home/${OTS_USER}/.opentakserver_venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
		ExecStart=/home/${OTS_USER}/.opentakserver_venv/bin/eud_handler
		Restart=on-failure
		RestartSec=5s
		StandardOutput=append:/home/${OTS_USER}/ots/logs/opentakserver.log
		StandardError=append:/home/${OTS_USER}/ots/logs/opentakserver.log

		[Install]
		WantedBy=multi-user.target
	SVCEOF

	cat > /etc/systemd/system/eud_handler_ssl.service <<- 'SVCEOF'
		[Unit]
		Description=OpenTAKServer EUD Handler SSL
		Wants=network.target rabbitmq-server.service
		After=network.target rabbitmq-server.service
		PartOf=opentakserver.service

		[Service]
		Type=simple
		User=${OTS_USER}
		WorkingDirectory=/home/${OTS_USER}/ots
		Environment="PATH=/home/${OTS_USER}/.opentakserver_venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
		ExecStart=/home/${OTS_USER}/.opentakserver_venv/bin/eud_handler --ssl
		Restart=on-failure
		RestartSec=5s
		StandardOutput=append:/home/${OTS_USER}/ots/logs/opentakserver.log
		StandardError=append:/home/${OTS_USER}/ots/logs/opentakserver.log

		[Install]
		WantedBy=multi-user.target
	SVCEOF

	systemctl daemon-reload
	systemctl enable opentakserver
	systemctl enable cot_parser
	systemctl enable eud_handler
	systemctl enable eud_handler_ssl

	echo "Systemd services created and enabled"

	echo "OpenTAKServer chroot installation completed. Database initialization will occur on first boot."
EOF

# Enable services for first boot
on_chroot <<- EOF
	# Enable services to start on first boot
	systemctl enable postgresql 2>&1 || true
	systemctl enable rabbitmq-server 2>&1 || true
	systemctl enable nginx 2>&1 || true
EOF
on_chroot <<- EOF
	cat > /usr/local/bin/generate-ots-certs.sh << 'CERTEOF'
#!/bin/bash

# Generate OpenTAKServer certificates on first boot
OTS_USER="${FIRST_USER_NAME}"
OTS_VENV="/home/\${OTS_USER}/.opentakserver_venv"

if [ ! -f "/home/\${OTS_USER}/ots/ca/ca-key.pem" ]; then
	echo "Generating OpenTAKServer CA certificates..."
	su - \${OTS_USER} -c "source \${OTS_VENV}/bin/activate && cd \${OTS_VENV}/lib/python*/site-packages/opentakserver && flask ots create-ca" 2>&1 || true
	echo "CA certificates generated"
fi
CERTEOF

	chmod +x /usr/local/bin/generate-ots-certs.sh

	# Create a systemd service to generate certs on first boot
	cat > /etc/systemd/system/generate-ots-certs.service << 'SVCEOF'
[Unit]
Description=Generate OpenTAKServer CA Certificates
Before=opentakserver.service
Wants=postgresql.service
After=postgresql.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/generate-ots-certs.sh
RemainAfterExit=yes
User=root

[Install]
WantedBy=multi-user.target
SVCEOF

	systemctl enable generate-ots-certs.service
EOF

# Enable services for first boot and install firstboot script
on_chroot <<- 'EOF'
	# Enable services to start on first boot
	systemctl enable postgresql 2>&1 || true
	systemctl enable rabbitmq-server 2>&1 || true
	systemctl enable nginx 2>&1 || true

	# Create firstboot script
	cat > /usr/local/bin/opentakserver-firstboot.sh << 'FBEOF'
#!/bin/bash -e

# First boot completion script for OpenTAKServer
OTS_USER="${FIRST_USER_NAME}"
VENV_DIR="/home/${OTS_USER}/.opentakserver_venv"
OTS_DIR="/home/${OTS_USER}/ots"

if [ -f "$VENV_DIR/.firstboot_completed" ]; then
	echo "First boot setup already completed, exiting"
	exit 0
fi

echo "Starting first boot OpenTAKServer completion..."

mkdir -p "$OTS_DIR"/{ca,mediamtx/recordings,logs}
chown -R ${OTS_USER}:${OTS_USER} "$OTS_DIR"

if [ ! -d "$VENV_DIR" ]; then
	echo "Creating Python virtual environment..."
	su - ${OTS_USER} -c "python3 -m venv --system-site-packages ~/.opentakserver_venv"
	chown -R ${OTS_USER}:${OTS_USER} "$VENV_DIR"
fi

echo "Upgrading pip and essential dependencies..."
timeout 300 su - ${OTS_USER} -c "source ${VENV_DIR}/bin/activate && pip3 install --no-cache-dir --upgrade pip setuptools wheel" 2>&1 || true

# Ensure PostgreSQL is running
echo "Checking PostgreSQL..."
systemctl start postgresql || true
sleep 3

POSTGRES_READY=0
WAIT_COUNT=0
while [ $WAIT_COUNT -lt 30 ]; do
	if timeout 5 su - postgres -c "psql -c 'SELECT 1' >/dev/null 2>&1"; then
		POSTGRES_READY=1
		break
	fi
	echo "Waiting for PostgreSQL... ($WAIT_COUNT/30)"
	sleep 1
	((WAIT_COUNT+=1))
done

if [ $POSTGRES_READY -eq 0 ]; then
	echo "WARNING: PostgreSQL did not start within timeout"
fi

# Create database and user if they don't exist
if ! su - postgres -c "psql -lqt | cut -d'|' -f1 | grep -qw ots" 2>/dev/null; then
	echo "Creating PostgreSQL user and database..."
	OTS_PASS=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 20)

	su - postgres -c "psql -c \"CREATE ROLE ots WITH LOGIN PASSWORD '${OTS_PASS}' CREATEDB;\"" 2>&1 || true
	su - postgres -c "psql -c 'CREATE DATABASE ots OWNER ots;'" 2>&1 || true
	su - postgres -c "psql -c 'GRANT ALL PRIVILEGES ON DATABASE ots TO ots;'" 2>&1 || true
	su - postgres -c "psql -d ots -c 'GRANT ALL ON SCHEMA public TO ots;'" 2>&1 || true

	echo "Database password: $OTS_PASS" > "${OTS_DIR}/.db_credentials"
	chmod 600 "${OTS_DIR}/.db_credentials"
	chown ${OTS_USER}:${OTS_USER} "${OTS_DIR}/.db_credentials"
fi

# Install OpenTAKServer if not present
if ! su - ${OTS_USER} -c "source ${VENV_DIR}/bin/activate && python3 -c 'import opentakserver' 2>/dev/null"; then
	echo "Installing OpenTAKServer from PyPI..."
	timeout 1800 su - ${OTS_USER} -c "source ${VENV_DIR}/bin/activate && pip3 install --no-cache-dir opentakserver" 2>&1 || echo "Warning: Installation had issues"
else
	echo "OpenTAKServer is already installed"
fi

# Generate configuration
if [ ! -f "$OTS_DIR/config.yml" ]; then
	echo "Generating OpenTAKServer configuration..."
	su - ${OTS_USER} -c "cat > ~/ots/config.yml <<- 'CFGEOF'
database:
  username: ots
  database: ots
  host: localhost
  port: 5432

rabbitmq:
  host: localhost
  port: 5672

api:
  host: 0.0.0.0
  port: 8000

logging:
  level: INFO
  file: /home/${OTS_USER}/ots/logs/opentakserver.log
CFGEOF
" 2>&1 || true
fi

# Initialize database
if su - ${OTS_USER} -c "source ${VENV_DIR}/bin/activate && python3 -c 'import opentakserver' 2>/dev/null"; then
	echo "Initializing OpenTAKServer database..."
	su - ${OTS_USER} -c "source ${VENV_DIR}/bin/activate && cd ${VENV_DIR}/lib/python*/site-packages/opentakserver && timeout 300 flask db upgrade" 2>&1 || true
fi

# Generate certificates
if [ ! -f "$OTS_DIR/ca/ca-key.pem" ]; then
	echo "Generating OpenTAKServer CA certificates..."
	mkdir -p "$OTS_DIR/ca"
	chown ${OTS_USER}:${OTS_USER} "$OTS_DIR/ca"

	su - ${OTS_USER} -c "source ${VENV_DIR}/bin/activate && cd ${VENV_DIR}/lib/python*/site-packages/opentakserver && timeout 300 flask ots create-ca" 2>&1 || true
fi

mkdir -p "$VENV_DIR"
touch "$VENV_DIR/.firstboot_completed"
echo "First boot setup completed!"
FBEOF

	chmod +x /usr/local/bin/opentakserver-firstboot.sh

	# Create systemd service
	cat > /etc/systemd/system/opentakserver-firstboot.service << 'SVCEOF'
[Unit]
Description=OpenTAKServer First Boot Setup
After=network-online.target postgresql.service
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/opentakserver-firstboot.sh
RemainAfterExit=yes
User=root

[Install]
WantedBy=multi-user.target
SVCEOF

	systemctl enable opentakserver-firstboot.service
EOF

echo "OpenTAKServer installation completed!"

