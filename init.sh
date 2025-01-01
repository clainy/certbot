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

# Create cloudflare.ini file if it doesn't exist and prompt for token
create_cloudflare_ini() {
  local INI_FILE="$BASE_DIR/cloudflare.ini"

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
  local CERTS_FILE="$BASE_DIR/certs.conf"

  if [[ ! -f "$CERTS_FILE" ]]; then
    echo "certs.conf file not found. Creating certs.conf..."

    # Open file descriptor for writing
    exec 3> "$CERTS_FILE"

    # Gather multiple domain-email pairs
    local COUNTER=1
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

# Function to add script to cron jobs
add_to_cron() {
  # can add cron job manually as:
  # 1. sudo crontab -e
  # 2. echo "0 7 * * 0 /path/to/your/script.sh" | sudo crontab -
  local CRON_JOB="0 7 * * 0 /path/to/your/script.sh"

  # Check if the cron job already exists
  if ! crontab -l | grep -q "generate-certs.sh"; then
    read -p "Do you want to check certs 7AM every Sunday? (y/n): " ADD_CRON

    if [[ "$ADD_CRON" == "y" || "$ADD_CRON" == "Y" ]]; then
      (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
      echo "Cron job added to run the script every Sunday at 7:00 AM."
    fi
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