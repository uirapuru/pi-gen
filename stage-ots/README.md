# OpenTAKServer Installation Stage

This stage installs and configures OpenTAKServer on Raspberry Pi OS.

## What is OpenTAKServer?

OpenTAKServer is an open-source implementation of a TAK (Tactical Assault Kit) server that enables real-time communication and data sharing for tactical operations.

## Components Installed

This stage installs the following components:

- **OpenTAKServer** - The main server application
- **Python Virtual Environment** - Isolated Python environment for OpenTAKServer
- **PostgreSQL** - Database backend for OpenTAKServer
- **RabbitMQ** - Message broker for OTS components
- **nginx** - Reverse proxy and load balancer
- **FFmpeg** - Media processing library
- **PostGIS** - Geographic Information System extension for PostgreSQL

## Services Created

The following systemd services are created and enabled:

- `opentakserver` - Main OpenTAKServer service
- `cot_parser` - CoT (Cursor on Target) message parser
- `eud_handler` - EUD (End User Device) handler
- `eud_handler_ssl` - EUD handler with SSL support
- `rabbitmq-server` - RabbitMQ message broker
- `nginx` - Web server and reverse proxy
- `postgresql` - Database server

## Installation Source

This stage is based on the official OpenTAKServer Raspberry Pi installer:
https://github.com/brian7704/OpenTAKServer-Installer

## Configuration

After the system boots, you may need to:

1. Complete the OpenTAKServer configuration by editing `/home/[username]/ots/config.yml`
2. Generate certificates using the OTS CLI
3. Configure nginx with proper SSL certificates
4. Set up database credentials

## Post-Installation

The services are set to start automatically on boot. Check their status with:

```bash
systemctl status opentakserver
systemctl status cot_parser
systemctl status eud_handler
systemctl status eud_handler_ssl
systemctl status rabbitmq-server
systemctl status nginx
systemctl status postgresql
```

View logs with:

```bash
journalctl -u opentakserver -f
journalctl -u rabbitmq-server -f
```

## Usage

To use this stage in your pi-gen build, ensure you're building from a stage that includes all required dependencies (like stage4), then run your build script with this stage-ots included in the build order.

Example build command:
```bash
./build.sh
```

The build system will automatically process stage0 through stage-ots in order.

