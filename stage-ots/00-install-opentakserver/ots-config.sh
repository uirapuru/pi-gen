#!/bin/bash

# OpenTAKServer Post-Installation Configuration Helper
# This script helps configure OpenTAKServer after the system is booted

set -e

OTS_USER="${SUDO_USER:-$USER}"
OTS_HOME="/home/${OTS_USER}"
OTS_DIR="${OTS_HOME}/ots"
VENV_DIR="${OTS_HOME}/.opentakserver_venv"

echo "================================================"
echo "OpenTAKServer Post-Installation Configuration"
echo "================================================"
echo ""

# Check if running as non-root
if [ "$EUID" -eq 0 ]; then
  echo "Please do not run this script as root."
  echo "Instead run it as: sudo -u $OTS_USER $0"
  exit 1
fi

# Check if OTS is installed
if [ ! -d "$VENV_DIR" ]; then
  echo "OpenTAKServer virtual environment not found at $VENV_DIR"
  exit 1
fi

echo "Using OpenTAKServer installation at: $OTS_DIR"
echo "User: $OTS_USER"
echo ""

# Function to generate certificates
generate_certificates() {
  echo "Generating OpenTAKServer certificates..."
  cd "$VENV_DIR/lib/python3.*/site-packages/opentakserver" || exit 1

  source "$VENV_DIR/bin/activate"
  flask ots create-ca
  deactivate

  echo "Certificates generated successfully at $OTS_DIR/ca"
}

# Function to display database status
check_database() {
  echo "Checking PostgreSQL database status..."
  sudo systemctl status postgresql --no-pager | head -5

  if sudo su postgres -c "psql -d ots -c '\dt'" &>/dev/null; then
    echo "✓ OpenTAKServer database is accessible"
  else
    echo "✗ Cannot access OpenTAKServer database"
  fi
}

# Function to display service status
check_services() {
  echo ""
  echo "Checking OpenTAKServer services status..."
  for service in opentakserver cot_parser eud_handler eud_handler_ssl rabbitmq-server nginx postgresql; do
    status=$(sudo systemctl is-active $service 2>/dev/null || echo "inactive")
    if [ "$status" = "active" ]; then
      echo "✓ $service is active"
    else
      echo "✗ $service is $status"
    fi
  done
}

# Function to display logs
show_logs() {
  echo ""
  echo "Last 20 lines of OpenTAKServer log:"
  if [ -f "$OTS_DIR/logs/opentakserver.log" ]; then
    tail -20 "$OTS_DIR/logs/opentakserver.log"
  else
    echo "Log file not found at $OTS_DIR/logs/opentakserver.log"
  fi
}

# Function to start services
start_services() {
  echo ""
  echo "Starting OpenTAKServer services..."
  sudo systemctl start postgresql
  sudo systemctl start rabbitmq-server
  sudo systemctl start opentakserver
  sudo systemctl start cot_parser
  sudo systemctl start eud_handler
  sudo systemctl start eud_handler_ssl
  sudo systemctl start nginx
  echo "Services started"
}

# Function to stop services
stop_services() {
  echo ""
  echo "Stopping OpenTAKServer services..."
  sudo systemctl stop opentakserver
  sudo systemctl stop cot_parser
  sudo systemctl stop eud_handler
  sudo systemctl stop eud_handler_ssl
  sudo systemctl stop nginx
  sudo systemctl stop rabbitmq-server
  echo "Services stopped"
}

# Main menu
show_menu() {
  echo ""
  echo "Select an option:"
  echo "1) Generate certificates"
  echo "2) Check database status"
  echo "3) Check services status"
  echo "4) Show recent logs"
  echo "5) Start services"
  echo "6) Stop services"
  echo "7) View configuration file"
  echo "8) Exit"
  echo ""
  read -p "Enter your choice [1-8]: " choice

  case $choice in
    1) generate_certificates ;;
    2) check_database ;;
    3) check_services ;;
    4) show_logs ;;
    5) start_services ;;
    6) stop_services ;;
    7) nano "$OTS_DIR/config.yml" || vi "$OTS_DIR/config.yml" ;;
    8) exit 0 ;;
    *) echo "Invalid choice" ;;
  esac
}

# Run menu
while true; do
  show_menu
done

