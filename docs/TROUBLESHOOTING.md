# Troubleshooting Guide - Xcel Itron Smart Meter to MQTT

This guide provides step-by-step solutions for common issues you might encounter when setting up and running the Xcel Itron smart meter to MQTT bridge.

## Table of Contents
- [Setup Issues](#setup-issues)
- [Connection Problems](#connection-problems)
- [MQTT Issues](#mqtt-issues)
- [Certificate Problems](#certificate-problems)
- [Performance Issues](#performance-issues)
- [Debugging Commands](#debugging-commands)

## Setup Issues

### Issue: "Certificate files not found"

**Symptoms:**
```
FileNotFoundError: Could not find cert and key credentials
```

**Solution:**
```bash
# Generate new certificates
./scripts/generate_keys.sh

# Verify files exist
ls -la certs/
# Should show: .cert.pem and .key.pem
```

**Example:**
```bash
$ ./setup.sh
Setting up Xcel Itron Smart Meter to MQTT Bridge
================================================
Creating certs directory...
Generating SSL certificates and keys...
Generating new keys!
The following string of numbers should be used as your LFDI value on the Xcel website:
8FA6803F07F4AABB88B9543013B1A55306AE933C
```

### Issue: "LFDI not registered with Xcel"

**Symptoms:**
```
TimeoutError: Waiting too long to get response from meter
```

**Solution:**
1. Copy the LFDI string from certificate generation
2. Visit: https://my.xcelenergy.com/MyAccount/s/meters-and-devices/
3. Click "Add a Device"
4. Paste the LFDI string
5. Fill in device details (any values work)

**Example LFDI:**
```
8FA6803F07F4AABB88B9543013B1A55306AE933C
```



## Connection Problems

### Issue: "Meter not found on network"

**Symptoms:**
```
TimeoutError: Waiting too long to get response from meter
```

**Diagnostic Commands:**
```bash
# Check if meter responds to ping
ping 192.168.1.50

# Test HTTPS connection to meter
curl -k https://192.168.1.50:8081/sdev/sdi

# Check mDNS discovery
docker exec -it xcel_itron2mqtt python3 -c "
from zeroconf import Zeroconf, ServiceBrowser, ServiceListener
import time

class MeterListener(ServiceListener):
    def add_service(self, zc, type, name):
        info = zc.get_service_info(type, name)
        print(f'Found meter: {info.parsed_addresses()[0]}:{info.port}')

zeroconf = Zeroconf()
listener = MeterListener()
browser = ServiceBrowser(zeroconf, '_smartenergy._tcp.local.', listener)
time.sleep(10)
zeroconf.close()
"
```

**Solutions:**
1. **Verify meter IP in .env file:**
   ```bash
   # Check current .env
   cat .env | grep METER_IP
   
   # Update if needed
   sed -i 's/METER_IP=/METER_IP=192.168.1.50/' .env
   ```

2. **Check network connectivity:**
   ```bash
   # Test from host
   curl -k https://YOUR_METER_IP:8081/sdev/sdi
   
   # Test from container
   docker exec -it xcel_itron2mqtt curl -k https://YOUR_METER_IP:8081/sdev/sdi
   ```

3. **Enable mDNS discovery (if IP unknown):**
   ```bash
   # Remove METER_IP from .env to enable auto-discovery
   sed -i '/METER_IP=/d' .env
   ```

### Issue: "Connection refused"

**Symptoms:**
```
ConnectionError: HTTPSConnectionPool(host='192.168.1.50', port=8081): Max retries exceeded
```

**Diagnostic Commands:**
```bash
# Check if port is open
nmap -p 8081 192.168.1.50

# Test with telnet
telnet 192.168.1.50 8081

# Check firewall
sudo ufw status
```

**Solutions:**
1. **Verify meter port:**
   ```bash
   # Update port in .env if different
   sed -i 's/METER_PORT=8081/METER_PORT=8081/' .env
   ```

2. **Check firewall settings:**
   ```bash
   # Allow port 8081
   sudo ufw allow 8081/tcp
   ```

3. **Test with different port:**
   ```bash
   # Try common ports
   for port in 8081 8080 8443 443; do
     echo "Testing port $port..."
     curl -k --connect-timeout 5 https://192.168.1.50:$port/sdev/sdi
   done
   ```

## MQTT Issues

### Issue: "No MQTT messages received"

**Symptoms:**
- Container running but no data in MQTT topics
- Empty output from `./monitor_mqtt.sh`

**Diagnostic Commands:**
```bash
# Check MQTT broker status
docker-compose ps mosquitto

# Test MQTT connectivity
docker exec -it mosquitto mosquitto_sub -h localhost -p 1883 -t "test" -v

# Check MQTT logs
docker-compose logs mosquitto

# Verify MQTT configuration
docker exec -it xcel_itron2mqtt env | grep MQTT
```

**Solutions:**
1. **Check MQTT server configuration:**
   ```bash
   # Verify MQTT_SERVER in .env
   cat .env | grep MQTT_SERVER
   
   # Test MQTT connection
   docker exec -it xcel_itron2mqtt mosquitto_sub -h mqtt -p 1883 -t "homeassistant/#" -v
   ```

2. **Restart MQTT broker:**
   ```bash
   docker-compose restart mosquitto
   ```

3. **Check MQTT authentication:**
   ```bash
   # If using authentication, verify credentials
   cat .env | grep MQTT_USER
   cat .env | grep MQTT_PASSWORD
   ```

### Issue: "MQTT authentication failed"

**Symptoms:**
```
Connection refused, bad username or password
```

**Solution:**
```bash
# Add MQTT credentials to .env
echo "MQTT_USER=myuser" >> .env
echo "MQTT_PASSWORD=mypass123" >> .env

# Restart services
docker-compose restart xcel_itron2mqtt
```

### Issue: "Wrong MQTT topic prefix"

**Symptoms:**
- Data published to wrong topics
- Home Assistant not receiving data

**Solution:**
```bash
# Check current topic prefix
docker exec -it xcel_itron2mqtt env | grep MQTT_TOPIC_PREFIX

# Update topic prefix
sed -i 's/MQTT_TOPIC_PREFIX=.*/MQTT_TOPIC_PREFIX=homeassistant\//' .env

# Restart service
docker-compose restart xcel_itron2mqtt
```

## Certificate Problems

### Issue: "SSL certificate verification failed"

**Symptoms:**
```
SSLError: [SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed
```

**Diagnostic Commands:**
```bash
# Check certificate files
ls -la certs/

# Verify certificate content
openssl x509 -in certs/.cert.pem -text -noout

# Check private key
openssl rsa -in certs/.key.pem -check
```

**Solutions:**
1. **Regenerate certificates:**
   ```bash
   # Remove old certificates
   rm -rf certs/
   
   # Generate new ones
   ./scripts/generate_keys.sh
   ```

2. **Verify LFDI registration:**
   ```bash
   # Get LFDI from certificates
   ./scripts/generate_keys.sh -p
   
   # Register with Xcel Energy Launchpad
   # Visit: https://my.xcelenergy.com/MyAccount/s/meters-and-devices/
   ```

3. **Check certificate permissions:**
   ```bash
   # Fix permissions if needed
   chmod 600 certs/.key.pem
   chmod 644 certs/.cert.pem
   ```

### Issue: "Certificate path not found"

**Symptoms:**
```
FileNotFoundError: [Errno 2] No such file or directory: '/opt/xcel_itron2mqtt/certs/.cert.pem'
```

**Solution:**
```bash
# Check volume mount
docker exec -it xcel_itron2mqtt ls -la /opt/xcel_itron2mqtt/certs/

# Verify host path
ls -la $(pwd)/certs/

# Recreate volume mount
docker-compose down
docker-compose up -d
```

## Performance Issues

### Issue: "High CPU usage"

**Symptoms:**
- Container using excessive CPU
- System becomes slow

**Diagnostic Commands:**
```bash
# Check resource usage
docker stats xcel_itron2mqtt

# Check Python process
docker exec -it xcel_itron2mqtt ps aux | grep python

# Monitor network connections
docker exec -it xcel_itron2mqtt netstat -tulpn
```

**Solutions:**
1. **Reduce polling rate (requires code modification):**
   ```bash
   # Edit polling rate in source
   docker exec -it xcel_itron2mqtt sed -i 's/POLLING_RATE = 5.0/POLLING_RATE = 10.0/' /opt/xcel_itron2mqtt/xcelMeter.py
   ```

2. **Increase log level for debugging:**
   ```bash
   # Set to DEBUG temporarily
   sed -i 's/LOGLEVEL=INFO/LOGLEVEL=DEBUG/' .env
   docker-compose restart xcel_itron2mqtt
   ```

### Issue: "Memory leaks"

**Symptoms:**
- Container memory usage increasing over time
- System becomes unresponsive

**Solution:**
```bash
# Restart container periodically
docker-compose restart xcel_itron2mqtt

# Or add restart policy to docker-compose.yaml
restart: unless-stopped
```

## Debugging Commands

### Container Debugging

```bash
# Get shell in container
docker exec -it xcel_itron2mqtt /bin/bash

# Check environment variables
docker exec -it xcel_itron2mqtt env

# Check Python process
docker exec -it xcel_itron2mqtt ps aux

# Check network connections
docker exec -it xcel_itron2mqtt netstat -tulpn
```

### Log Analysis

```bash
# Search for errors
docker logs xcel_itron2mqtt 2>&1 | grep -i error

# Search for connection issues
docker logs xcel_itron2mqtt 2>&1 | grep -i "connection\|timeout"

# Search for MQTT messages
docker logs xcel_itron2mqtt 2>&1 | grep -i "mqtt"

# Get recent logs with timestamps
docker logs --tail=100 -t xcel_itron2mqtt
```

### Network Debugging

```bash
# Test meter connectivity from container
docker exec -it xcel_itron2mqtt curl -k https://YOUR_METER_IP:8081/sdev/sdi

# Test MQTT connectivity from container
docker exec -it xcel_itron2mqtt mosquitto_sub -h mqtt -p 1883 -t "test" -v

# Check DNS resolution
docker exec -it xcel_itron2mqtt nslookup mqtt
```

### Certificate Debugging

```bash
# Verify certificate chain
openssl verify certs/.cert.pem

# Check certificate dates
openssl x509 -in certs/.cert.pem -noout -dates

# Verify private key matches certificate
openssl x509 -noout -modulus -in certs/.cert.pem | openssl md5
openssl rsa -noout -modulus -in certs/.key.pem | openssl md5
```

## Common Error Messages and Solutions

| Error Message | Solution |
|---------------|----------|
| `FileNotFoundError: Could not find cert and key credentials` | Run `./scripts/generate_keys.sh` |
| `TimeoutError: Waiting too long to get response from meter` | Check METER_IP and LFDI registration |
| `ConnectionError: HTTPSConnectionPool` | Verify meter IP and port accessibility |
| `SSLError: certificate verify failed` | Regenerate certificates and re-register LFDI |
| `Connection refused, bad username or password` | Check MQTT credentials in .env |
| `No such file or directory: '/opt/xcel_itron2mqtt/certs/.cert.pem'` | Check volume mount and certificate files |

## Getting Help

If you're still experiencing issues:

1. **Run the test script:**
   ```bash
   ./scripts/test_setup.sh

   ./scripts/monitor_mqtt.sh
   ```

2. **Check the comprehensive logs:**
   ```bash
   docker compose logs --tail=200 xcel_itron2mqtt
   ```



3. **Create a debug report:**
   ```bash
   # Save debug info to file
   {
     echo "=== Debug Report ==="
     echo "Date: $(date)"
     echo "=== Certificate Files ==="
     ls -la certs/ 2>/dev/null || echo "No certs directory"
     echo "=== Environment Variables ==="
     cat .env 2>/dev/null || echo "No .env file"
     echo "=== Container Status ==="
     docker-compose ps 2>/dev/null || echo "Docker compose not available"
     echo "=== Recent Logs ==="
     docker-compose logs --tail=50 xcel_itron2mqtt 2>/dev/null || echo "No logs available"
   } > debug_report.txt
   ``` 