# OpenTAKServer Stage Compatibility

## Supported Platforms

- Raspberry Pi 3B+
- Raspberry Pi 4
- Raspberry Pi 5

## Supported OS Versions

- Raspberry Pi OS Bookworm (Debian 12)
- Raspberry Pi OS Bullseye (Debian 11)

## Recommended Hardware Requirements

For optimal performance:

- **RAM**: Minimum 2GB, Recommended 4GB or more
- **Storage**: 8GB SD card minimum, 32GB or more recommended
- **CPU**: Raspberry Pi 4 or newer for better performance
- **Network**: Gigabit Ethernet recommended for better throughput

## Minimum Hardware Requirements

The stage will work with:

- **RAM**: 1GB (may cause swapping, slower performance)
- **Storage**: 4GB SD card minimum (tight fit, may limit features)
- **CPU**: Raspberry Pi 3B+ (adequate but slower)
- **Network**: Standard Ethernet or WiFi

## Known Limitations

1. **32-bit OS**: While the installer is designed for 32-bit systems, 64-bit builds are recommended for better performance
2. **Database**: PostgreSQL requires about 100-300MB of disk space for the OTS database
3. **Virtual Environment**: Python venv adds approximately 200-300MB to storage
4. **Memory**: Running all services simultaneously may consume 500MB-1GB of RAM

## Python Compatibility

- Requires: Python 3.8 or higher
- Tested with: Python 3.9, 3.10, 3.11, 3.12

## Dependencies

This stage assumes you're building from stage4 or later, which includes:

- Essential build tools
- Python 3 development files
- Network tools
- System utilities

## Network Requirements

For proper operation:

- DNS resolution must work
- Connection to PyPI for pip package downloads (during build)
- Optional: Connection to GitHub for additional components (mediamtx, UI)

## Pre-requisites

Before using this stage:

1. Ensure your base system has sufficient disk space (at least 2GB free)
2. Have a working network connection during build
3. Ensure sufficient RAM for compilation of Python packages
4. Budget build time of 30-60 minutes depending on hardware

## Post-Installation Requirements

After flashing the image:

1. Boot the system and allow PostgreSQL to initialize (first boot may take longer)
2. Configure OpenTAKServer via the web UI or config file
3. Generate SSL certificates using OTS CLI tools
4. Set proper permissions on log directories if needed

