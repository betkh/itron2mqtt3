#!/bin/bash

echo "Setting up Xcel Itron Smart Meter to MQTT Bridge"
echo "================================================"

# Create .env from .env.sample if it doesn't exist
if [ ! -f ".env" ]; then
    if [ -f ".env.sample" ]; then
        cp .env.sample .env
        echo ".env file created from .env.sample."
    else
        echo "Error: .env.sample not found. Please provide a sample environment file."
        exit 1
    fi
else
    echo ".env file already exists."
fi

echo ""
echo "Please edit the .env file and enter the required fields (e.g., METER_IP, MQTT credentials, etc.)."
echo ""
echo "Setup complete!"