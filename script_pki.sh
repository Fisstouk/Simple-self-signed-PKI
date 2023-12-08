#!/bin/bash
#
set -e
set -x
#
signing_ca_client_conf="pki_conf_files/signing-ca-client.conf"
signing_ca_server_conf="pki_conf_files/signing-ca-server.conf"
openssl_cmd="/usr/bin/openssl"
root_ca_conf="pki_conf_files/root-ca.conf"
server_conf="pki_conf_files/server.conf"

if [[ ! -f "${openssl_cmd}" ]]; then
	echo '"${openssl_cmd}" does not exist, install in progress...'
	apt install openssl -y
	sleep 2
fi

# Create Root CA

echo "Create ca, crl and certs directories in your /home/ directory"
sleep 2
mkdir -p ca/root-ca/private ca/root-ca/db crl certs-client certs-server

echo "Secure root-ca directory permissions"
sleep 2
chmod 700 ca/root-ca/private

echo "Create database for maintaining CA"
sleep 2
cp /dev/null ca/root-ca/db/root-ca.db
cp /dev/null ca/root-ca/db/root-ca.db.attr
echo 01 >ca/root-ca/db/root-ca.crt.srl
echo 01 >ca/root-ca/db/root-ca.crl.srl

echo "Create a CA request"
sleep 2
openssl req -new \
	-out ca/root-ca.csr \
	-config "${root_ca_conf}" \
	-keyout ca/root-ca/private/root-ca.key

echo "Create selfsign CA certificate"
sleep 2
openssl ca -selfsign \
	-config "${root_ca_conf}" \
	-in ca/root-ca.csr \
	-out ca/root-ca.crt \
	-extensions root_ca_ext

# Create Signing CA or Intermediate CA Client

echo "Create private, signing-ca-client directories"
sleep 2
mkdir -p ca/signing-ca-client/private ca/signing-ca-client/db

echo "Secure signing-ca-client directory permissions"
sleep 2
chmod 700 ca/signing-ca-client/private

echo "Create database for maintaining CA"
sleep 2
cp /dev/null ca/signing-ca-client/db/signing-ca-client.db
cp /dev/null ca/signing-ca-client/db/signing-ca-client.db.attr
echo 01 >ca/signing-ca-client/db/signing-ca-client.crt.srl
echo 01 >ca/signing-ca-client/db/signing-ca-client.crl.srl

echo "Create CA request"
sleep 2
openssl req -new \
	-config "${signing_ca_client_conf}" \
	-out ca/signing-ca-client.csr \
	-keyout ca/signing-ca-client/private/signing-ca-client.key

echo "Create CA certificate"
sleep 2
openssl ca \
	-config "${root_ca_conf}" \
	-in ca/signing-ca-client.csr \
	-out ca/signing-ca-client.crt \
	-extensions signing_ca_ext

# Signing CA

# Revoke Certificate
#
#openssl ca \
#    -config "${signing_ca_client_conf}" \
#    -revoke ~/ca/signing-ca-client/01.pem \
#    -crl_reason superseded

echo "Create Certificate revocation list (CRL)"
sleep 2
openssl ca -gencrl \
	-config "${signing_ca_client_conf}" \
	-out crl/signing-ca-client.crl

# Output

echo "Create PKCS#12 bundle for Prof"
sleep 2
openssl pkcs12 -export \
	-name "Esgi" \
	-inkey certs-client/esgi.local.key \
	-in certs-client/esgi.local.crt \
	-out certs-client/prof.esgi.local.p12

echo "Create PKCS#12 bundle for Eleve"
sleep 2
openssl pkcs12 -export \
	-name "Esgi" \
	-inkey certs-client/esgi.local.key \
	-in certs-client/esgi.local.crt \
	-out certs-client/eleve.esgi.local.pkcs12

# Create Signing CA or Intermediate CA Server

echo "Create private, signing-ca-server directories"
sleep 2
mkdir -p ca/signing-ca-server/private ca/signing-ca-server/db

echo "Secure signing-ca-client directory permissions"
sleep 2
chmod 700 ca/signing-ca-server/private

echo "Create database for maintaining CA"
sleep 2
cp /dev/null ca/signing-ca-server/db/signing-ca-server.db
cp /dev/null ca/signing-ca-server/db/signing-ca-server.db.attr
echo 01 >ca/signing-ca-server/db/signing-ca-server.crt.srl
echo 01 >ca/signing-ca-server/db/signing-ca-server.crl.srl

echo "Create CA request"
sleep 2
openssl req -new \
	-config "${signing_ca_server_conf}" \
	-out ca/signing-ca-server.csr \
	-keyout ca/signing-ca-server/private/signing-ca-server.key

echo "Create CA certificate"
sleep 2
openssl ca \
	-config "${root_ca_conf}" \
	-in ca/signing-ca-server.csr \
	-out ca/signing-ca-server.crt \
	-extensions signing_ca_ext

# Signing CA

echo "Create TLS server request"
sleep 2
SAN=DNS:www.esgi.local \
	openssl req -new \
	-config "${server_conf}" \
	-out certs-server/esgi.local.csr \
	-keyout certs-server/esgi.local.key

echo "Create TLS server certificate"
sleep 2
openssl ca \
	-config "${signing_ca_server_conf}" \
	-in certs-server/esgi.local.csr \
	-out certs-server/esgi.local.crt \
	-extensions server_ext

# Revoke Certificate
#
#openssl ca \
#    -config "${signing_ca_server_conf}" \
#    -revoke ~/ca/signing-ca-server/01.pem \
#    -crl_reason superseded

echo "Create Certificate revocation list (CRL)"
sleep 2
openssl ca -gencrl \
	-config "${signing_ca_server_conf}" \
	-out crl/signing-ca-server.crl
