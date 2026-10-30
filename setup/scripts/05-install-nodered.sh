#!/bin/bash
# Install Node-RED and related nodes
#
# Uses the official Node-RED script which installs Node.js (20 LTS) and Node-RED.
# Settings are applied non-interactively via a default settings.js template.
# See: https://nodered.org/docs/getting-started/raspberrypi
#
# After installation, run show-token.sh to get the InfluxDB token,
# then manually configure it in Node-RED.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODERED_SETUP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)/nodered"
NODERED_USERDIR="${NODERED_USERDIR:-$HOME/.node-red}"

echo "=========================================="
echo "Install Node-RED"
echo "=========================================="

# Install dependencies required by Node-RED installer (curl for download script)
echo "Installing dependencies..."
sudo apt-get update
sudo apt-get install -y curl

# Create user directory and copy settings.js BEFORE running installer
# This prevents the installer from launching interactive configuration
mkdir -p "$NODERED_USERDIR"
if [ -f "$NODERED_SETUP_DIR/settings.js" ]; then
    echo "Pre-configuring settings.js..."
    cp "$NODERED_SETUP_DIR/settings.js" "$NODERED_USERDIR/settings.js"
    echo "✓ Custom settings.js installed"
fi

# Official script installs Node.js (20 LTS) and Node-RED; no need to install Node separately.
# This can take 20-30 minutes on slower Pi models.
# --no-init: Skip interactive settings.js initialization (we use our own)
echo ""
echo "Installing Node-RED using official script (installs Node.js + Node-RED)..."
bash <(curl -sL https://github.com/node-red/linux-installers/releases/latest/download/install-update-nodered-deb) --confirm-install --confirm-pi --no-init

# Ensure our settings.js is in place (in case installer overwrote it)
echo ""
echo "Verifying settings.js..."
if [ -f "$NODERED_SETUP_DIR/settings.js" ]; then
    cp "$NODERED_SETUP_DIR/settings.js" "$NODERED_USERDIR/settings.js"
    echo "✓ Custom settings.js configured"
else
    echo "⚠ Custom settings.js not found at $NODERED_SETUP_DIR/settings.js"
fi

# Enable Node-RED service
echo ""
echo "Enabling Node-RED service..."
sudo systemctl enable nodered.service
sudo systemctl start nodered.service

# Wait for service to start
echo "Waiting for Node-RED to start..."
sleep 10

# Install additional Node-RED nodes
echo ""
echo "Installing InfluxDB node..."
cd ~/.node-red
npm install node-red-contrib-influxdb

# Optional: Install Dashboard node (for debugging)
echo "Installing Dashboard node..."
npm install node-red-dashboard

echo ""
echo "=========================================="
echo "Configure Meshtastic Flow"
echo "=========================================="

# Copy flows.json
echo "Copying Meshtastic flow configuration..."
if [ -f "$NODERED_SETUP_DIR/flows.json" ]; then
    cp "$NODERED_SETUP_DIR/flows.json" "$NODERED_USERDIR/flows.json"
    echo "✓ flows.json copied"
else
    echo "✗ flows.json not found at $NODERED_SETUP_DIR/flows.json"
fi

# Restart Node-RED to load new nodes and flows
echo ""
echo "Restarting Node-RED..."
sudo systemctl restart nodered.service
sleep 5

# Verify installation
echo ""
echo "Verifying Node-RED installation..."
if systemctl is-active --quiet nodered; then
    echo "✓ Node-RED service is running"
else
    echo "✗ Node-RED service failed to start"
    sudo systemctl status nodered
    exit 1
fi

echo ""
echo "=========================================="
echo "Node-RED installation complete!"
echo "=========================================="
echo ""
echo "Node-RED URL: http://localhost:1880"
echo ""
echo "Installed nodes:"
echo "  - node-red-contrib-influxdb (InfluxDB connection)"
echo "  - node-red-dashboard (visual debugging)"
echo ""
echo "=========================================="
echo "Configure InfluxDB Token (Manual Step)"
echo "=========================================="
echo ""
echo "1. Get the token by running: ./show-token.sh"
echo ""
echo "2. Configure Node-RED:"
echo "   - Open http://<Pi-IP>:1880"
echo "   - Double-click 'Write to InfluxDB' node"
echo "   - Click pencil icon next to 'Local InfluxDB'"
echo "   - Paste the token into 'Token' field"
echo "   - Click 'Update', then 'Done'"
echo "   - Click 'Deploy'"
echo ""
echo "=========================================="
echo "Next Step"
echo "=========================================="
echo ""
echo "  Run: ./06-install-grafana.sh"
echo ""
