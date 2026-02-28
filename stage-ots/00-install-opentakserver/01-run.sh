#!/bin/bash -e

# Script to install OpenTAKServer on Raspberry Pi OS
# This is adapted from https://github.com/brian7704/OpenTAKServer-Installer/blob/master/raspberry_pi_installer.sh

OTS_USER="${FIRST_USER_NAME}"

echo "Installing OpenTAKServer..."

# Create directories and install OpenTAKServer via on_chroot
on_chroot <<- EOF
	# Stop any running services that might interfere
	systemctl stop postgresql 2>/dev/null || true
	systemctl stop rabbitmq-server 2>/dev/null || true
	systemctl stop nginx 2>/dev/null || true
	sleep 1
	killall -9 postgres 2>/dev/null || true
	killall -9 epmd 2>/dev/null || true
	killall -9 beam.smp 2>/dev/null || true
	sleep 1

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

	# Initialize PostgreSQL database
	# Start PostgreSQL service
	echo "Starting PostgreSQL service..."
	service postgresql start

	# Wait for PostgreSQL to be ready (with timeout)
	MAX_WAIT=30
	WAIT_COUNT=0
	while ! su - postgres -c "psql -c 'SELECT 1' >/dev/null 2>&1" && [ $WAIT_COUNT -lt $MAX_WAIT ]; do
		echo "Waiting for PostgreSQL to start... ($WAIT_COUNT/$MAX_WAIT)"
		sleep 1
		((WAIT_COUNT++))
	done

	if [ $WAIT_COUNT -eq $MAX_WAIT ]; then
		echo "Warning: PostgreSQL did not start within timeout"
	else
		echo "PostgreSQL is ready"
	fi

	# Create Python virtual environment and install OpenTAKServer
	echo "Creating Python virtual environment for OpenTAKServer..."
	set +e
	su - ${OTS_USER} -c "python3 -m venv --system-site-packages ~/.opentakserver_venv" 2>&1
	VENV_STATUS="$?"
	set -e

	if [ "$VENV_STATUS" = "0" ]; then
		echo "Virtual environment created successfully"

		# Upgrade pip, setuptools, wheel
		echo "Upgrading pip, setuptools, and wheel..."
		su - ${OTS_USER} -c "source ~/.opentakserver_venv/bin/activate && pip3 install --no-cache-dir --upgrade pip setuptools wheel" 2>&1 || true

		# Install OpenTAKServer with retries
		echo "Installing OpenTAKServer from PyPI..."
		INSTALL_ATTEMPTS=0
		MAX_ATTEMPTS=3
		while [ $INSTALL_ATTEMPTS -lt $MAX_ATTEMPTS ]; do
			set +e
			su - ${OTS_USER} -c "source ~/.opentakserver_venv/bin/activate && pip3 install --no-cache-dir opentakserver" 2>&1
			INSTALL_STATUS="$?"
			set -e

			if [ "$INSTALL_STATUS" = "0" ]; then
				echo "OpenTAKServer installed successfully"
				break
			else
				INSTALL_ATTEMPTS=$((INSTALL_ATTEMPTS + 1))
				if [ $INSTALL_ATTEMPTS -lt $MAX_ATTEMPTS ]; then
					echo "Installation failed, retrying... ($INSTALL_ATTEMPTS/$MAX_ATTEMPTS)"
					sleep 2
				else
					echo "Failed to install OpenTAKServer after $MAX_ATTEMPTS attempts"
				fi
			fi
		done
	else
		echo "Error: Failed to create Python virtual environment"
	fi

	# Generate random password for OTS database user (alphanumeric only, no special chars)
	OTS_PASS=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 20)

	# Create OTS user in PostgreSQL using proper escaping
	echo "Creating PostgreSQL user and database..."
	su - postgres -c "psql -c \"CREATE ROLE ots WITH LOGIN PASSWORD '${OTS_PASS}' CREATEDB;\"" 2>&1 || true

	# Create OTS database
	su - postgres -c "psql -c 'CREATE DATABASE ots OWNER ots;'" 2>&1 || true

	# Grant privileges
	su - postgres -c "psql -c 'GRANT ALL PRIVILEGES ON DATABASE ots TO ots;'" 2>&1 || true
	su - postgres -c "psql -d ots -c 'GRANT ALL ON SCHEMA public TO ots;'" 2>&1 || true

	# Generate default config (skip if module not available)
	echo "Generating OpenTAKServer configuration..."
	su - ${OTS_USER} -c "source ~/.opentakserver_venv/bin/activate && python3 -c 'try:
    from opentakserver import create_app
    app = create_app()
    print(\"Config generated\")
except ImportError:
    print(\"Warning: opentakserver module not available, skipping config generation\")
except Exception as e:
    print(f\"Warning: Config generation failed: {e}\")' 2>&1" || true

	# Create config file with database credentials
	echo "Creating OpenTAKServer config file..."
	su - ${OTS_USER} -c "cat > ~/ots/config.yml <<- 'CFGEOF'
database:
  username: ots
  password: ${OTS_PASS}
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

	echo "Database initialized successfully"

	# Configure RabbitMQ (enable but don't start in chroot)
	echo "Enabling RabbitMQ service..."
	systemctl enable rabbitmq-server 2>&1 || true

	# Configure nginx
	echo "Enabling nginx service..."
	systemctl enable nginx 2>&1 || true
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

	# Cleanup: Stop services before exiting chroot
	echo "Cleaning up services..."
	systemctl stop postgresql 2>/dev/null || true
	systemctl stop rabbitmq-server 2>/dev/null || true
	systemctl stop nginx 2>/dev/null || true

	# Kill any remaining processes in the chroot
	killall -9 postgres 2>/dev/null || true
	killall -9 epmd 2>/dev/null || true
	killall -9 beam.smp 2>/dev/null || true

	sleep 2
EOF

echo "OpenTAKServer installation completed!"

