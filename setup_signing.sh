#!/bin/bash
# ============================================
# Creates (once) a local certificate to sign Scarlett 8i6 Mixer.
#
# Why: when the app is signed "ad-hoc" (no identity), every rebuild changes its
# signature and macOS stops applying the Accessibility permission to it (the
# volume keys stop working). With a fixed identity, macOS recognizes it as the
# same app and the permission is kept.
#
# The certificate stays in your login keychain only and is only used to sign
# code on this Mac. macOS will ask for your password to trust it.
#   ./setup_signing.sh
# ============================================
set -e
NAME="Scarlett 8i6 Local Signing"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

if security find-identity -v -p codesigning 2>/dev/null | grep -q "$NAME"; then
    echo "The identity \"$NAME\" already exists. Nothing to do."
    exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/cert.cfg" <<EOF
[ req ]
distinguished_name = dn
x509_extensions    = ext
prompt             = no
[ dn ]
CN = $NAME
[ ext ]
keyUsage         = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
basicConstraints = critical, CA:false
EOF

echo "[1/3] Creating the certificate..."
/usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -keyout "$TMP/key.pem" -out "$TMP/cert.pem" -config "$TMP/cert.cfg" >/dev/null 2>&1
/usr/bin/openssl pkcs12 -export -inkey "$TMP/key.pem" -in "$TMP/cert.pem" \
    -out "$TMP/id.p12" -passout pass:scarlett -name "$NAME" >/dev/null 2>&1

echo "[2/3] Saving it to your keychain..."
security import "$TMP/id.p12" -k "$KEYCHAIN" -P scarlett -T /usr/bin/codesign >/dev/null

echo "[3/3] Trusting it for code signing (macOS will ask for your password)..."
security add-trusted-cert -r trustRoot -p codeSign -k "$KEYCHAIN" "$TMP/cert.pem"

if security find-identity -v -p codesigning | grep -q "$NAME"; then
    echo ""
    echo "Done. Now run ./build_8i6.sh: the app will be signed with \"$NAME\"."
else
    echo ""
    echo "The certificate was created but macOS does not list it as a valid signing identity."
    echo "Check the output of: security find-identity -v -p codesigning"
    exit 1
fi
