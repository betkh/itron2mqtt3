#!/bin/bash

echo "Monitoring MQTT messages from Xcel Itron Smart Meter"
echo "==================================================="
echo ""

# Check if docker-compose is running
if ! sudo docker compose ps | grep -q "mosquitto"; then
    echo "Error: Docker Compose services are not running."
    echo "Please start them first with: docker-compose up -d"
    exit 1
fi

echo "Starting MQTT message monitor..."
echo "Press Ctrl+C to stop monitoring"
echo ""

# Monitor all homeassistant topics
docker compose exec mosquitto mosquitto_sub -t 'homeassistant/#' -v 