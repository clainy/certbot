#!/bin/bash

# Need
#    - root permission
#    - Cloudflare API token
#
# Usage: sudo ./generate.sh YOUR_DOMAIN EMAIL@EXAMPLE.COM CERTS_DIR [NGINX_CONTAINER]
#    e.g. `sudo ./generate.sh example.com email@example.com /etc/nginx/certs nginx`

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."

    exit
fi

DOMAIN=$1
EMAIL=$2
CERTS_DIR=$3
NGINX_CONTAINER=$4

BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LETSENCRYPT_DIR=${BASE_DIR}/letsencrypt
CLOUDFLARE_PROPAGATION_DURATION=30

###############################################################
# Verify settings
###############################################################

CLOUDFLARE_CONFIG=${LETSENCRYPT_DIR}/cloudflare.ini

if [ ! -f "${CLOUDFLARE_CONFIG}" ]; then
    echo "Cloudflare configuration not found."

    read -e -p "Please enter your Cloudflare TOKEN: " CLOUDFLARE_TOKEN
    echo "dns_cloudflare_api_token=${CLOUDFLARE_TOKEN}" > ${CLOUDFLARE_CONFIG}

#    exit
fi

###############################################################
# Certbot generating SSL certificates
###############################################################

if [ -z "${DOMAIN}" ] || [ -z "${EMAIL}" ] || [ ! -d "${CERTS_DIR}" ]; then
  if [ -z "${DOMAIN}" ]; then
    echo "Domain is missing"
  elif [ -z "${EMAIL}" ]; then
    echo "Contact email is missing"
  else
    echo "Certificates directory is not accessible or not exist"
  fi

  echo "Usage  : sudo ./generate.sh YOUR_DOMAIN YOUR_EMAIL NGINX_CERTS_DIRECTORY [CONTAINER_NAME]"
  echo "Example: sudo ./generate.sh example.com email@example.com /etc/nginx/certs nginx"

  exit
fi

echo "Generate/renew SSL certificates for *.${DOMAIN} ..."

docker run -it --rm \
  --name certbot \
  -v "${LETSENCRYPT_DIR}:/etc/letsencrypt" \
  certbot/dns-cloudflare \
  certonly --dns-cloudflare \
    --non-interactive \
    --agree-tos \
    --no-eff-email \
    --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
    --dns-cloudflare-propagation-seconds ${CLOUDFLARE_PROPAGATION_DURATION} \
    --cert-name ${DOMAIN} \
    -m "${EMAIL}" \
    -d "${DOMAIN}" \
    -d "*.${DOMAIN}"

GENERATED_CERTS_DIR=${LETSENCRYPT_DIR}/archive/${DOMAIN}
CERT_CHAIN_FILE=${GENERATED_CERTS_DIR}/fullchain1.pem
CERT_KEY_FILE=${GENERATED_CERTS_DIR}/privkey1.pem

if [ ! -f "${CERT_CHAIN_FILE}" ] || [ ! -f "${CERT_KEY_FILE}" ]; then
    echo "Failed to generate SSL certificates."

    exit
fi

echo "SSL certificates have been successfully renewed."

###############################################################
# Replacing SSL certificates
###############################################################

echo "Updating NGNIX cert and key:"

echo "    ${CERTS_DIR}/${DOMAIN}.crt"
cp -pf "${CERT_CHAIN_FILE}" "${CERTS_DIR}/${DOMAIN}".crt

echo "    ${CERTS_DIR}/${DOMAIN}.key"
cp -pf "${CERT_KEY_FILE}" "${CERTS_DIR}/${DOMAIN}".key

###############################################################
# Restart NGINX services
###############################################################

if [ "${NGINX_CONTAINER}" ] && [ "$(docker ps -a -q -f name=${NGINX_CONTAINER})" ]; then
    # Reload Nginx in another container
    # Send a signal to the Nginx container to reload its configuration
    docker exec -it "$NGINX_CONTAINER" nginx -s reload
    echo "Nginx configuration reloaded."
fi
