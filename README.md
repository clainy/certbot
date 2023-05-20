# certbot
## Requirement
- root permission
- Cloudflare API token

## Usage
```sh
#sudo ./generate.sh YOUR_DOMAIN EMAIL@EXAMPLE.COM CERTS_DIR [NGINX_CONTAINER]
sudo ./generate.sh example.com email@example.com /etc/nginx/certs nginx
```