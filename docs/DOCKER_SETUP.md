# Docker Compose Setup for Xcel Itron Smart Meter

This document explains the fixes made to enable docker-compose functionality for the Xcel Itron smart meter to MQTT bridge.

## What Was Fixed

### 1. Updated `docker-compose.yaml`
- **Changed MQTT broker**: Switched from `emqx/nanomq` to `eclipse-mosquitto:latest` for better compatibility
- **Added proper volumes**: Configured persistent volumes for MQTT data and logs
- **Fixed environment variables**: Moved all environment variables directly into the compose file
- **Added network mode**: Set `network_mode: host` for better mDNS discovery
- **Added restart policy**: Set `restart: unless-stopped` for reliability

### 2. Created Helper Scripts

#### `setup.sh`
- Automatically generates SSL certificates and LFDI string
- Creates `.env` file with all required environment variables
- Provides step-by-step instructions for Xcel Energy Launchpad registration

#### `monitor_mqtt.sh`
- Monitors MQTT messages from the smart meter
- Shows real-time data flow to verify connectivity

#### `test_setup.sh`
- Validates the entire setup
- Checks for certificates, .env file, Docker availability
- Shows service status and recent logs

### 3. Updated Documentation
- Enhanced README.md with quick start instructions
- Added troubleshooting section
- Documented all environment variables

## Quick Start Guide

### Step 1: Initial Setup
```bash
# Run the setup script
./setup.sh
```

This will:
- Generate SSL certificates and LFDI string
- Create `.env` file with default values
- Provide instructions for Xcel Energy Launchpad

### Step 2: Register with Xcel Energy
1. Copy the LFDI string from the setup output
2. Visit: https://my.xcelenergy.com/MyAccount/s/meters-and-devices/
3. Click "Add a Device"
4. Paste the LFDI string
5. Fill in device details (any values work)

### Step 3: Configure Your Setup
```bash
# Edit the .env file to add your meter IP address
nano .env
```

Add your smart meter's IP address to the `METER_IP` field.

### Step 4: Start Services
```bash
# Start the services
docker compose up -d

# Check the logs
docker compose logs -f xcel_itron2mqtt

# Monitor MQTT messages
./monitor_mqtt.sh
```

## Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `MQTT_SERVER` | MQTT broker address | Yes | `mqtt` |
| `MQTT_PORT` | MQTT broker port | No | `1883` |
| `MQTT_TOPIC_PREFIX` | MQTT topic prefix | No | `homeassistant/` |
| `MQTT_USER` | MQTT username | No | (empty) |
| `MQTT_PASSWORD` | MQTT password | No | (empty) |
| `METER_IP` | Your smart meter IP address | Yes* | (auto-discovered) |
| `METER_PORT` | Smart meter port | No | `8081` |
| `CERT_PATH` | Path to certificate file | No | `/opt/xcel_itron2mqtt/certs/.cert.pem` |
| `KEY_PATH` | Path to private key file | No | `/opt/xcel_itron2mqtt/certs/.key.pem` |
| `LOGLEVEL` | Logging level | No | `INFO` |

*METER_IP is required unless your meter supports mDNS auto-discovery

## Troubleshooting

### Common Issues

1. **"Meter not found" error**
   - Ensure your meter is on the same network
   - Verify the LFDI is registered with Xcel Energy Launchpad
   - Check that `METER_IP` is correct in `.env`

2. **"Connection refused" error**
   - Verify Docker is running
   - Check that the meter IP is accessible from your network
   - Ensure the meter port (8081) is correct

3. **No MQTT messages**
   - Verify the MQTT broker is running: `docker-compose ps`
   - Check logs: `docker-compose logs xcel_itron2mqtt`
   - Test MQTT connectivity: `./monitor_mqtt.sh`

### Testing Your Setup
```bash
# Run the test script to validate everything
./test_setup.sh
```

## Data Flow

1. **Certificate Generation**: `./scripts/generate_keys.sh` creates SSL certificates
2. **Xcel Registration**: LFDI string is registered with Xcel Energy Launchpad
3. **Meter Discovery**: The application finds your meter via mDNS or IP address
4. **Data Collection**: Smart meter data is queried every 5 seconds
5. **MQTT Publishing**: Data is published to MQTT topics under `homeassistant/`

## MQTT Topics

The application publishes data to topics like:
- `homeassistant/sensor/xcel_meter/instantaneous_demand`
- `homeassistant/sensor/xcel_meter/current_summation`
- `homeassistant/sensor/xcel_meter/frequency`
- And many more depending on your meter's capabilities

## Monitoring

### View Logs
```bash
# Follow logs in real-time
docker compose logs -f xcel_itron2mqtt

# View recent logs
docker compose logs --tail=50 xcel_itron2mqtt
```

### Monitor MQTT Messages
```bash
# Monitor all homeassistant topics
./monitor_mqtt.sh

# Or manually
docker compose exec mosquitto mosquitto_sub -t 'homeassistant/#' -v
```

### Check Service Status
```bash
# View running services
docker compose ps

# Test the setup
./test_setup.sh
```

## Stopping Services
```bash
# Stop all services
docker compose down

# Stop and remove volumes (will delete MQTT data)
docker compose down -v
```

## Development

For development work, you can run the container interactively:
```bash
docker compose run --rm xcel_itron2mqtt /bin/bash
```

This gives you a shell inside the container for debugging and development. 