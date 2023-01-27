#!/bin/bash

set -o nounset \
    -o errexit

printf "Deleting previous (if any)..."
rm -rf secrets
mkdir secrets
mkdir -p tmp
echo " OK!"
# Generate CA key
printf "Creating CA..."
openssl req -new -x509 -keyout tmp/ca.key -out tmp/ca.crt -days 365 -subj '/CN=MY CA' -passin pass:mylovelyca -passout pass:mylovelyca >/dev/null 2>&1

echo " OK!"

for i in 'kafka' 'client'
do
	printf "Creating cert and keystore of $i..."
	# Create keystores
	keytool -genkey -noprompt \
				 -alias $i \
				 -dname "CN=$i" \
				 -keystore secrets/$i.keystore.jks \
				 -keyalg RSA \
				 -storepass mylovelyca \
				 -keypass mylovelyca  >/dev/null 2>&1

	# Create CSR, sign the key and import back into keystore
	keytool -keystore secrets/$i.keystore.jks -alias $i -certreq -file tmp/$i.csr -storepass mylovelyca -keypass mylovelyca >/dev/null 2>&1

	openssl x509 -req -CA tmp/ca.crt -CAkey tmp/ca.key -in tmp/$i.csr -out tmp/$i-ca-signed.crt -days 365 -CAcreateserial -passin pass:mylovelyca  >/dev/null 2>&1

	keytool -keystore secrets/$i.keystore.jks -alias CARoot -import -noprompt -file tmp/ca.crt -storepass mylovelyca -keypass mylovelyca >/dev/null 2>&1

	keytool -keystore secrets/$i.keystore.jks -alias $i -import -file tmp/$i-ca-signed.crt -storepass mylovelyca -keypass mylovelyca >/dev/null 2>&1

	# Create truststore and import the CA cert.
	keytool -keystore secrets/$i.truststore.jks -alias CARoot -import -noprompt -file tmp/ca.crt -storepass mylovelyca -keypass mylovelyca >/dev/null 2>&1
  echo " OK!"
done

echo "Exporting client keystore to PCKS12"
keytool -importkeystore -srckeystore secrets/client.keystore.jks -destkeystore secrets/client.keystore.p12 -srcstoretype JKS -deststoretype PKCS12 -srcstorepass mylovelyca -deststorepass mylovelyca >/dev/null 2>&1

echo "Exporing CA"
keytool -importkeystore -srckeystore secrets/client.truststore.jks -destkeystore secrets/client.truststore.p12 -srcstoretype JKS -deststoretype PKCS12 -srcstorepass mylovelyca -deststorepass mylovelyca >/dev/null 2>&1
openssl pkcs12 -in secrets/client.truststore.p12 -out secrets/ca.crt -nokeys -passin pass:mylovelyca >/dev/null 2>&1

echo "Moving keystore and CA to TestProducer"
cp secrets/client.keystore.p12 TestProducer/
cp secrets/ca.crt TestProducer/

echo "mylovelyca" > secrets/cert_creds
rm -rf tmp

echo "SUCCEEDED"
