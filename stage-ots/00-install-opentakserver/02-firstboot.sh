#!/bin/bash -e

# First boot completion script for OpenTAKServer
# This script runs on the first boot to finish OpenTAKServer setup if installation failed during build

OTS_USER="${FIRST_USER_NAME}"
VENV_DIR="/home/${OTS_USER}/.opentakserver_venv"
OTS_DIR="/home/${OTS_USER}/ots"

# Only run once
if [ -f "$VENV_DIR/.firstboot_completed" ]; then
	echo "First boot setup already completed, exiting"
	exit 0
fi

echo "Starting first boot OpenTAKServer completion..."

# Create directories if they don't exist
mkdir -p "$OTS_DIR"
mkdir -p "$OTS_DIR/ca"
mkdir -p "$OTS_DIR/mediamtx/recordings"
mkdir -p "$OTS_DIR/logs"
chown -R ${OTS_USER}:${OTS_USER} "$OTS_DIR"

# Check if venv exists
if [ ! -d "$VENV_DIR" ]; then
	echo "Creating Python virtual environment..."
	if ! su - ${OTS_USER} -c "python3 -m venv --system-site-packages ~/.opentakserver_venv"; then
		echo "Error: Failed to create Python virtual environment"
		exit 1
	fi
	chown -R ${OTS_USER}:${OTS_USER} "$VENV_DIR"
fi

# Upgrade pip and essential packages
echo "Upgrading pip and essential dependencies..."
timeout 300 su - ${OTS_USER} -c "source ${VENV_DIR}/bin/activate && pip3 install --no-cache-dir --upgrade pip setuptools wheel" 2>&1 || echo "Warning: pip upgrade had issues"

# Check if OpenTAKServer is installed
if ! su - ${OTS_USER} -c "source ${VENV_DIR}/bin/activate && python3 -c 'import opentakserver' 2>/dev/null"; then
	echo "OpenTAKServer not found, installing from PyPI..."
	echo "This may take a very long time on Raspberry Pi (10-30 minutes)..."

	# Install OpenTAKServer with retry logic
	INSTALL_ATTEMPTS=0
	MAX_ATTEMPTS=3
	INSTALL_SUCCESS=0

	while [ $INSTALL_ATTEMPTS -lt $MAX_ATTEMPTS ]; do
		INSTALL_ATTEMPTS=$((INSTALL_ATTEMPTS + 1))
		echo "Installation attempt $INSTALL_ATTEMPTS/$MAX_ATTEMPTS..."

		if timeout 1800 su - ${OTS_USER} -c "source ${VENV_DIR}/bin/activate && pip3 install --no-cache-dir opentakserver" 2>&1; then
			echo "OpenTAKServer installed successfully!"
			INSTALL_SUCCESS=1
			break
		else
			INSTALL_STATUS=$?
			if [ "$INSTALL_STATUS" = "124" ]; then
				echo "Installation timed out after 30 minutes"
			else
				echo "Installation failed with status $INSTALL_STATUS"
			fi

			if [ $INSTALL_ATTEMPTS -lt $MAX_ATTEMPTS ]; then
				echo "Will retry... sleeping 10 seconds"
				sleep 10
			fi
		fi
	done

	if [ $INSTALL_SUCCESS -eq 0 ]; then
		echo "ERROR: Failed to install OpenTAKServer after $MAX_ATTEMPTS attempts"
		echo "You may need to install it manually:"
		echo "  su - ${OTS_USER}"
		echo "  source ${VENV_DIR}/bin/activate"
		echo "  pip3 install opentakserver"
		exit 1
	fi
else
	echo "OpenTAKServer is already installed"
fi

# Ensure PostgreSQL is running and initialized
echo "Checking PostgreSQL..."
if ! systemctl is-active --quiet postgresql; then
	echo "Starting PostgreSQL..."
	systemctl start postgresql
	sleep 3
fi

# Create database and user if they don't exist
echo "Setting up PostgreSQL database..."
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

# Check if ots database already exists
if ! su - postgres -c "psql -lqt | cut -d'|' -f1 | grep -qw ots" 2>/dev/null; then
	echo "Creating PostgreSQL user and database..."

	# Generate random password
	OTS_PASS=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 20)

	# Create user and database
	su - postgres -c "psql -c \"CREATE ROLE ots WITH LOGIN PASSWORD '${OTS_PASS}' CREATEDB;\"" 2>&1 || true
	su - postgres -c "psql -c 'CREATE DATABASE ots OWNER ots;'" 2>&1 || true
	su - postgres -c "psql -c 'GRANT ALL PRIVILEGES ON DATABASE ots TO ots;'" 2>&1 || true
	su - postgres -c "psql -d ots -c 'GRANT ALL ON SCHEMA public TO ots;'" 2>&1 || true

	# Save credentials for reference
	echo "Database password: $OTS_PASS" > "${OTS_DIR}/.db_credentials"
	chmod 600 "${OTS_DIR}/.db_credentials"
	chown ${OTS_USER}:${OTS_USER} "${OTS_DIR}/.db_credentials"

	echo "Database created with user 'ots'"
fi

# Generate OpenTAKServer configuration if it doesn't exist
if [ ! -f "$OTS_DIR/config.yml" ]; then
	echo "Generating OpenTAKServer configuration..."
	su - ${OTS_USER} -c "source ${VENV_DIR}/bin/activate && cd ${VENV_DIR}/lib/python*/site-packages/opentakserver && flask ots generate-config" 2>&1 || true

	# Create/update config file
	su - ${OTS_USER} -c "cat > ~/ots/config.yml <<- 'CFGEOF'
# OpenTAKServer Configuration
# Generated on first boot

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

	echo "Configuration file created"
fi

# Initialize database if needed
echo "Initializing OpenTAKServer database..."
if su - ${OTS_USER} -c "source ${VENV_DIR}/bin/activate && python3 -c 'import opentakserver' 2>/dev/null"; then
	su - ${OTS_USER} -c "source ${VENV_DIR}/bin/activate && cd ${VENV_DIR}/lib/python*/site-packages/opentakserver && timeout 300 flask db upgrade" 2>&1 || echo "Warning: Database upgrade had issues"
fi

# Generate certificates if not present
if [ ! -f "$OTS_DIR/ca/ca-key.pem" ]; then
	echo "Generating OpenTAKServer CA certificates..."
	mkdir -p "$OTS_DIR/ca"
	chown ${OTS_USER}:${OTS_USER} "$OTS_DIR/ca"

	if su - ${OTS_USER} -c "source ${VENV_DIR}/bin/activate && python3 -c 'import opentakserver' 2>/dev/null"; then
		su - ${OTS_USER} -c "source ${VENV_DIR}/bin/activate && cd ${VENV_DIR}/lib/python*/site-packages/opentakserver && timeout 300 flask ots create-ca" 2>&1 || echo "Warning: Certificate generation had issues"
	fi
fi

# Mark as completed
mkdir -p "$VENV_DIR"
touch "$VENV_DIR/.firstboot_completed"
echo "First boot setup completed successfully!"
echo "OpenTAKServer should now start automatically on next boot"

