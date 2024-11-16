# certbot
## Requirement
- root permission
- Cloudflare API token

## Usage

### Generate for a single domain
```sh
#sudo ./generate.sh YOUR_DOMAIN EMAIL@EXAMPLE.COM CERTS_DIR
sudo ./generate.sh example.com email@example.com /etc/nginx/certs
```

### Generate for multiple domains
```sh
sudo ./generate-certs.sh
```

### Automate Renew
```
# Check certs and renew them at 7:00am every Sunday
0 7 * * 0 /bin/bash /app/certbot/generate-certs.sh
```
