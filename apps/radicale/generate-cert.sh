#!/bin/bash
# Generate self-signed certificate for Radicale

DOMAIN="radicale.tail060ef.ts.net"
CERT_DIR="apps/radicale/certs"

mkdir -p $CERT_DIR

# Check if certificates already exist
if [ -f "$CERT_DIR/tls.crt" ] && [ -f "$CERT_DIR/tls.key" ]; then
    echo "⚠️  Certificates already exist in $CERT_DIR"
    echo "To regenerate, first delete the existing files:"
    echo "  rm $CERT_DIR/tls.crt $CERT_DIR/tls.key"
    exit 1
fi

# Generate private key and certificate
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout $CERT_DIR/tls.key \
  -out $CERT_DIR/tls.crt \
  -subj "/CN=$DOMAIN/O=Homelab/C=US" \
  -addext "subjectAltName=DNS:$DOMAIN"

echo "✅ Certificate generated in $CERT_DIR"
echo "Certificate expires in 10 years"
echo ""
echo "To import on iOS/macOS:"
echo "1. Copy tls.crt to your device"
echo "2. Open the file and install the certificate"
echo "3. Settings → General → About → Certificate Trust Settings"
echo "4. Enable full trust for this certificate"
