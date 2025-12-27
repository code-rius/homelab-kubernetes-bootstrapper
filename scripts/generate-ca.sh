#!/bin/bash
# Generate root CA for homelab
# This CA will be used to sign all service certificates

CA_DIR="certs/ca"
CA_NAME="Homelab Root CA"

mkdir -p $CA_DIR

# Check if CA already exists
if [ -f "$CA_DIR/ca.crt" ] && [ -f "$CA_DIR/ca.key" ]; then
    echo "⚠️  CA already exists in $CA_DIR"
    echo "To regenerate, first delete the existing CA:"
    echo "  rm $CA_DIR/ca.{crt,key}"
    echo ""
    echo "⚠️  WARNING: Regenerating CA will invalidate all service certificates!"
    echo "You'll need to reinstall the CA on all devices."
    exit 1
fi

echo "🔐 Generating Root CA..."

# Generate CA private key
openssl genrsa -out $CA_DIR/ca.key 4096

# Generate CA certificate (valid for 20 years)
openssl req -x509 -new -nodes -key $CA_DIR/ca.key \
  -sha256 -days 7300 \
  -out $CA_DIR/ca.crt \
  -subj "/CN=$CA_NAME/O=Homelab/C=US" \
  -addext "basicConstraints=critical,CA:TRUE" \
  -addext "keyUsage=critical,keyCertSign,cRLSign"

echo "✅ Root CA generated in $CA_DIR"
echo "Certificate expires in 20 years"
echo ""
echo "📱 To trust on iOS/macOS:"
echo "1. Copy $CA_DIR/ca.crt to your device"
echo "2. Open the file and install the certificate"
echo "3. Settings → General → About → Certificate Trust Settings"
echo "4. Enable full trust for 'Homelab Root CA'"
echo ""
echo "🔒 IMPORTANT: Back up these files securely!"
echo "   - $CA_DIR/ca.crt (public certificate)"
echo "   - $CA_DIR/ca.key (private key - keep secret!)"
