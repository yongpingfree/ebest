#!/usr/bin/env bash
# Usage: ./build_keystore.sh   (prompts for passwords; outputs to ./out)
set -euo pipefail
cd "$(dirname "$0")"
KEY="1私钥.txt"; CERT="11证书.txt"; CHAIN="111证书链.txt"
ALIAS="ebest"; OUT=out
read -rsp "Private key password (existing): " KEYPW; echo
read -rsp "New keystore/truststore password: " STOREPW; echo
mkdir -p "$OUT" && rm -f "$OUT"/*

if [ 0 -eq 0 ];
then

# 1. verify key matches cert
[ "$(openssl x509 -in "$CERT" -noout -modulus | openssl md5)" = \
  "$(openssl rsa -in "$KEY" -passin pass:"$KEYPW" -noout -modulus | openssl md5)" ] \
  || { echo "Key does not match certificate"; exit 1; }

# 2. PEM bundles for nginx
cat "$CERT" "$CHAIN" > "$OUT/fullchain.pem"
openssl rsa -in "$KEY" -passin pass:"$KEYPW" -out "$OUT/privkey.pem"
chmod 600 "$OUT/privkey.pem"

# 3. keystore (PKCS12): private key + cert + chain
openssl pkcs12 -export -inkey "$OUT/privkey.pem" -in "$CERT" -certfile "$CHAIN" \
  -name "$ALIAS" -out "$OUT/keystore.p12" -passout pass:"$STOREPW"

fi

# 4. truststore (PKCS12): CA certs only
awk -v d="$OUT" '/BEGIN CERT/{n++} {print > sprintf("%s/ca%d.pem", d, n)}' "$CHAIN"
i=0; for f in "$OUT"/ca*.pem; do i=$((i+1))
  keytool -importcert -noprompt -trustcacerts -alias "ca$i" -file "$f" \
    -keystore "$OUT/truststore.p12" -storetype PKCS12 -storepass "$STOREPW"
done
rm -f "$OUT"/ca*.pem

keytool -list -keystore "$OUT/keystore.p12"   -storepass "$STOREPW" | tail -4
keytool -list -keystore "$OUT/truststore.p12" -storepass "$STOREPW" | tail -4
echo "Done -> $(pwd)/$OUT"
