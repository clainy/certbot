#!/bin/bash

# Check if script is run as root
check_root() {
  if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
  fi
}

#BASE_DIR=$(cd "$(dirname "$0")"; pwd)
BASE_DIR=$( dirname -- "$( readlink -f -- "$0"; )"; )
LETSENCRYPT_DIR=${BASE_DIR}/letsencrypt

# Create cloudflare.ini file if it doesn't exist and prompt for token
create_cloudflare_ini() {
  INI_FILE="$BASE_DIR/letsencrypt/cloudflare.ini"
  
  # Create directory if it doesn't exist
  mkdir -p "$(dirname "$INI_FILE")"
  
  if [[ ! -f "$INI_FILE" ]]; then
    echo "Cloudflare token file not found. Creating cloudflare.ini..."
    read -sp "Enter your Cloudflare API token: " TOKEN
    echo
    echo "dns_cloudflare_api_token=$TOKEN" > "$INI_FILE"
    chmod 600 "$INI_FILE"  # Secure the file
    echo "cloudflare.ini created with the provided token."
  else
    echo "cloudflare.ini already exists."
  fi
}

# Create certs.conf if it doesn't exist and prompt for domain and email
create_certs_conf() {
  CERTS_FILE="certs.conf"
  
  if [[ ! -f "$CERTS_FILE" ]]; then
    echo "certs.conf file not found. Creating certs.conf..."
    
    # Open file descriptor for writing
    exec 3> "$CERTS_FILE"
    
    # Gather multiple domain-email pairs
    COUNTER=1
    while true; do
      read -p "Enter domain for cert$COUNTER (or press Enter to finish): " DOMAIN
      [[ -z "$DOMAIN" ]] && break  # Stop when input is empty
      
      read -p "Enter email for cert$COUNTER: " EMAIL
      echo "[cert$COUNTER]" >&3
      echo "domain=$DOMAIN" >&3
      echo "email=$EMAIL" >&3
      echo "" >&3
      
      ((COUNTER++))
    done
    
    # Close file descriptor
    exec 3>&-
    echo "certs.conf created with the provided domain-email pairs."
  else
    echo "certs.conf already exists."
  fi
}

# Main function to call other functions
main() {
  check_root
  create_cloudflare_ini
  create_certs_conf
}

# Run the main function
main