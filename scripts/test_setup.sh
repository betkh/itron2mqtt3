#!/bin/bash

echo "Testing Xcel Itron Smart Meter Setup"
echo "===================================="
echo ""

# Check if certificates exist
if [ ! -f "certs/.cert.pem" ] || [ ! -f "certs/.key.pem" ]; then
    echo "❌ Error: Certificates not found. Run ./setup.sh first."
    exit 1
else
    echo "✅ Certificates found"
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found. Run ./setup.sh first."
    exit 1
else
    echo "✅ .env file found"
fi

# Check if docker-compose is available
if ! command -v docker compose &> /dev/null; then
    echo "❌ Error: docker-compose not found. Please install Docker Compose."
    exit 1
else
    echo "✅ docker-compose available"
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Error: Docker is not running. Please start Docker."
    exit 1
else
    echo "✅ Docker is running"
fi

# Check if services are running
if docker compose ps | grep -q "mosquitto"; then
    echo "✅ Mosquitto MQTT broker is running"
else
    echo "⚠️  Mosquitto MQTT broker is not running"
    echo "   Run: docker-compose up -d"
fi

if docker compose ps | grep -q "xcel_itron2mqtt"; then
    echo "✅ Xcel Itron service is running"
    
    # Check the logs for any errors
    echo ""
    echo "Recent logs from xcel_itron2mqtt:"
    docker compose logs --tail=10 xcel_itron2mqtt
else
    echo "⚠️  Xcel Itron service is not running"
    echo "   Run: docker-compose up -d"
fi

echo ""
echo "Setup test complete!"
echo ""
echo "To monitor MQTT messages, run: ./monitor_mqtt.sh"
echo "To view logs, run: docker-compose logs -f xcel_itron2mqtt" 