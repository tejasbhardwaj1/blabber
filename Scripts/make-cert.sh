#!/bin/bash
# Creates a stable self-signed code-signing certificate so TCC permission
# grants (Microphone, Input Monitoring, Accessibility) survive rebuilds.
# Without this, every ad-hoc-signed build gets a new code directory hash
# and macOS treats it as a brand-new app, silently revoking all grants.
set -euo pipefail

CERT_NAME="Blabber Dev Signing"
KEYCHAIN="login.keychain-db"

if security find-identity -v -p codesigning | grep -q "$CERT_NAME"; then
  echo "Certificate '$CERT_NAME' already exists."
  echo "Delete it first with: security delete-identity -c \"$CERT_NAME\""
  exit 0
fi

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cat > "$TMPDIR/cert.conf" << CFG
[ req ]
default_bits       = 2048
prompt             = no
distinguished_name = dn
x509_extensions    = ext

[ dn ]
CN = $CERT_NAME

[ ext ]
basicConstraints = critical, CA:false
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
CFG

openssl req -new -newkey rsa:2048 -x509 -days 3650 -nodes \
  -keyout "$TMPDIR/cert.key" -out "$TMPDIR/cert.crt" \
  -config "$TMPDIR/cert.conf" -extensions ext

openssl pkcs12 -export -legacy -out "$TMPDIR/cert.p12" \
  -inkey "$TMPDIR/cert.key" -in "$TMPDIR/cert.crt" \
  -passout pass:blabber

# -A grants every application unrestricted access to the imported private key,
# which avoids the keychain ACL prompt that `codesign` otherwise hits when run
# non-interactively (surfaces as errSecInternalComponent / errSecAuthFailed).
security import "$TMPDIR/cert.p12" -k "$KEYCHAIN" -P blabber -A

# Mark as trusted specifically for the codeSign policy. A plain
# add-trusted-cert without -p codeSign leaves 0 policy-specific trust
# settings, and codesign then fails the chain check with
# errSecInternalComponent since the root is self-signed and otherwise
# unknown.
security add-trusted-cert -r trustRoot -p codeSign -k "$KEYCHAIN" "$TMPDIR/cert.crt"

echo "Created and trusted '$CERT_NAME'. Verifying..."
security find-identity -v -p codesigning | grep "$CERT_NAME" || {
  echo "WARNING: identity not showing as valid yet — may need a login/keychain unlock."
}
