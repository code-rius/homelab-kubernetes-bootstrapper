#!/bin/bash
set -e

OAUTH_FILE="ansible/resources/tailscale-oauth.env"

if [ ! -f "$OAUTH_FILE" ]; then
    echo "❌ OAuth credentials not found at $OAUTH_FILE"
    exit 1
fi

# Source OAuth credentials
source "$OAUTH_FILE"

if [ -z "$OAUTH_CLIENT_ID" ] || [ -z "$OAUTH_CLIENT_SECRET" ]; then
    echo "❌ OAUTH_CLIENT_ID or OAUTH_CLIENT_SECRET not set"
    exit 1
fi

# Get OAuth token
TOKEN_RESPONSE=$(curl -s -d "client_id=$OAUTH_CLIENT_ID" \
    -d "client_secret=$OAUTH_CLIENT_SECRET" \
    "https://api.tailscale.com/api/v2/oauth/token")

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$ACCESS_TOKEN" ]; then
    echo "❌ Failed to get OAuth token"
    exit 1
fi

TAILNET="tail060ef.ts.net"

# Function to delete a device by name
delete_device() {
    local DEVICE_NAME=$1
    echo "🔍 Looking for Tailscale device: $DEVICE_NAME"
    
    # List all devices
    DEVICES=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
        "https://api.tailscale.com/api/v2/tailnet/$TAILNET/devices")
    
    # Parse JSON properly - look for hostname that starts with our device name
    DEVICE_ID=$(echo "$DEVICES" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for device in data.get('devices', []):
    hostname = device.get('hostname', '')
    if hostname.startswith('$DEVICE_NAME'):
        print(device.get('id', ''))
        break
" 2>/dev/null || echo "")
    
    if [ -z "$DEVICE_ID" ]; then
        echo "✅ Device '$DEVICE_NAME' not found (already clean)"
        return 0
    fi
    
    echo "🗑️  Deleting device: $DEVICE_NAME (ID: $DEVICE_ID)"
    
    # Delete the device
    curl -s -X DELETE \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        "https://api.tailscale.com/api/v2/device/$DEVICE_ID" > /dev/null
    
    echo "✅ Device '$DEVICE_NAME' deleted successfully"
}

# Clean up operator device (usually named "tailscale-operator")
delete_device "tailscale-operator"

# Clean up app devices
delete_device "firefly"
delete_device "radicale"

echo ""
echo "🎉 Cleanup complete!"
