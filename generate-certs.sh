#!/bin/bash

#BASE_DIR=$(cd "$(dirname "$0")"; pwd)
BASE_DIR=$( dirname -- "$( readlink -f -- "$0"; )"; )

DATA_ROOT=/app/data
CERTBOT_SCRIPT=$BASE_DIR/generate.sh
CERTS_DIR=$DATA_ROOT/certs

# Set default config file
CONFIG_FILE="$BASE_DIR/certs.conf"

# Function to check if the script is running as root
check_root() {
  if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
  fi
}

# Function to read the certs.conf file
read_config() {
  echo "Check certbot config file..."
  ./init.sh
  echo ""

  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "certs.conf file not found!"
    exit 1
  fi

  # Parsing the certs.conf file for domain and email values
  while IFS= read -r line; do
    # Skip empty lines and lines starting with comments
    [[ -z "$line" || "$line" =~ ^\# ]] && continue

    # If a new section starts, reset variables
    if [[ "$line" =~ ^\[(.*)\]$ ]]; then
      DOMAIN=""
      EMAIL=""
      continue
    fi

    # Parse domain and email lines
    if [[ "$line" =~ ^domain= ]]; then
      DOMAIN="${line#*=}"
    elif [[ "$line" =~ ^email= ]]; then
      EMAIL="${line#*=}"
      trigger_generate "$DOMAIN" "$EMAIL" # Trigger generate.sh once both values are available
    fi
  done < "certs.conf"
}

# Function to trigger the generate.sh script
trigger_generate() {
  DOMAIN="$1"
  EMAIL="$2"
  if [[ -n "$DOMAIN" && -n "$EMAIL" ]]; then
    echo ">>> Generating certificate for$DOMAIN"
    $CERTBOT_SCRIPT "$DOMAIN" "$EMAIL" "$CERTS_DIR"
  else
    echo "Missing domain or email for a section; skipping."
  fi
}

# Main function
main() {
  check_root
  read_config

  echo ""
}

# Execute the main function
main