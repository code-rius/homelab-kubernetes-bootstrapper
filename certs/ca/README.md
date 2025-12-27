# Homelab Root Certificate Authority

This directory contains your homelab's root CA used by cert-manager to sign service certificates.

## Files

- `ca.crt` - Root CA public certificate (safe to share within your network)
- `ca.key` - Root CA private key (**keep secret!**)

## Installing CA on Devices

### macOS

```bash
# Import certificate
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain certs/ca/ca.crt

# Or via GUI:
# 1. Double-click ca.crt
# 2. Select "System" keychain → Add
# 3. Open Keychain Access → System → Find "Homelab Root CA"
# 4. Double-click → Trust → "Always Trust"
```

### iOS/iPadOS

1. AirDrop `ca.crt` to your device
2. Settings → Profile Downloaded → Install
3. Enter passcode
4. Settings → General → About → Certificate Trust Settings
5. Enable "Homelab Root CA"

### Linux

```bash
# Ubuntu/Debian
sudo cp certs/ca/ca.crt /usr/local/share/ca-certificates/homelab-ca.crt
sudo update-ca-certificates

# Fedora/RHEL
sudo cp certs/ca/ca.crt /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust
```

### Windows

1. Open `ca.crt`
2. Install Certificate → Local Machine
3. Place in "Trusted Root Certification Authorities"

### Firefox

Firefox uses its own certificate store:

1. Preferences → Privacy & Security → Certificates → View Certificates
2. Authorities → Import → Select `ca.crt`
3. Trust for websites

## Backup

**Critical**: Back up both files securely!

- If you lose `ca.key`, you cannot sign new certificates
- If compromised, regenerate and reinstall on all devices
- Store encrypted backup off-site

## Validity

- **Expires**: 20 years from generation date
- **Check expiry**: `openssl x509 -in certs/ca/ca.crt -noout -enddate`

## Regenerating CA

⚠️ **Warning**: Regenerating invalidates all service certificates!

```bash
# Delete existing CA
rm certs/ca/ca.{crt,key}

# Generate new CA
./scripts/generate-ca.sh

# Reinstall on all devices
# Redeploy all services to get new certificates
make deploy-radicale
```
