#!/bin/sh
# Nginx entrypoint script to substitute environment variables

set -e

NGINX_CONFIG_TEMPLATE="/etc/nginx/nginx.conf"
NGINX_CONFIG_RENDERED="/tmp/nginx.conf"

cp "$NGINX_CONFIG_TEMPLATE" "$NGINX_CONFIG_RENDERED"

echo "Substituting environment variables in nginx.conf..."

# Replace SERVER_NAME placeholder with actual value
if [ -n "$SERVER_NAME" ]; then
    sed -i "s/__SERVER_NAME__/$SERVER_NAME/g" "$NGINX_CONFIG_RENDERED"
fi

# Replace API_URL if specified
if [ -n "$API_URL" ]; then
    sed -i "s/__API_URL__/$API_URL/g" "$NGINX_CONFIG_RENDERED"
fi

# Determine SSL certificate paths
# Use Let's Encrypt certs if available, otherwise fall back to self-signed
if [ -f "/etc/letsencrypt/live/$SERVER_NAME/fullchain.pem" ]; then
    echo "Using Let's Encrypt certificates for $SERVER_NAME"
    SSL_CERT="/etc/letsencrypt/live/$SERVER_NAME/fullchain.pem"
    SSL_KEY="/etc/letsencrypt/live/$SERVER_NAME/privkey.pem"
elif [ -f "/etc/nginx/ssl/cert.pem" ]; then
    echo "Using self-signed certificates (Let's Encrypt certs not found)"
    SSL_CERT="/etc/nginx/ssl/cert.pem"
    SSL_KEY="/etc/nginx/ssl/key.pem"
else
    echo "ERROR: No SSL certificates found!"
    echo "Run: docker compose -f docker-compose.production.yml run --rm certbot certonly --webroot -w /var/www/certbot -d $SERVER_NAME"
    echo "Or generate self-signed certs: bash scripts/generate-ssl-certs.sh $SERVER_NAME"
    exit 1
fi

sed -i "s|__SSL_CERT__|$SSL_CERT|g" "$NGINX_CONFIG_RENDERED"
sed -i "s|__SSL_KEY__|$SSL_KEY|g" "$NGINX_CONFIG_RENDERED"

echo "Starting nginx..."
exec nginx -c "$NGINX_CONFIG_RENDERED" -g 'daemon off;'
