#!/bin/bash
set -e

# Create certs directory if it doesn't exist
mkdir -p certs
cd certs

echo "Generating CA certificate..."
openssl genrsa -out ca.key 2048
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt -subj "/C=US/ST=State/L=City/O=Oli/OU=IT/CN=vpn.oli.local"

echo "Generating server certificate..."
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr -subj "/C=US/ST=State/L=City/O=Oli/OU=IT/CN=server.vpn.oli.local"
openssl x509 -req -days 3650 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt \
  -extfile <(printf "keyUsage=digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth")

echo "Generating client certificate..."
openssl genrsa -out client.key 2048
openssl req -new -key client.key -out client.csr -subj "/C=US/ST=State/L=City/O=Oli/OU=IT/CN=client.vpn.oli.local"
openssl x509 -req -days 3650 -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt \
  -extfile <(printf "keyUsage=digitalSignature\nextendedKeyUsage=clientAuth")

echo "Certificates generated successfully in ./certs/"
