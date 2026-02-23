#!/bin/bash
# Let's Encrypt certificate initialization script for Docker
# Usage: bash scripts/init-letsencrypt.sh [email]
# Example: bash scripts/init-letsencrypt.sh admin@sotibit.club

set -e

DOMAIN="mediminder.sotibit.club"
EMAIL=${1:-""}
COMPOSE_FILE="docker-compose.production.yml"
STAGING=0  # Set to 1 to test against Let's Encrypt staging (no rate limits)

if [ -z "$EMAIL" ]; then
    echo "Usage: bash scripts/init-letsencrypt.sh <email>"
    echo "Example: bash scripts/init-letsencrypt.sh admin@sotibit.club"
    exit 1
fi

echo "=== Let's Encrypt Certificate Setup for $DOMAIN ==="

# Step 1: Ensure self-signed certs exist for initial nginx startup
if [ ! -f "nginx/ssl/cert.pem" ]; then
    echo "Generating temporary self-signed certificate for initial startup..."
    bash scripts/generate-ssl-certs.sh "$DOMAIN"
fi

# Step 2: Start nginx (needs to be running to serve ACME challenge)
echo "Starting nginx..."
export DOMAIN_NAME="$DOMAIN"
docker compose -f "$COMPOSE_FILE" up -d nginx

# Wait for nginx to be ready
echo "Waiting for nginx to start..."
sleep 5

# Step 3: Request the certificate
echo "Requesting Let's Encrypt certificate for $DOMAIN..."

STAGING_ARG=""
if [ "$STAGING" -eq 1 ]; then
    STAGING_ARG="--staging"
    echo "(Using staging environment - certificate will NOT be trusted)"
fi

docker compose -f "$COMPOSE_FILE" run --rm certbot certonly \
    --webroot \
    -w /var/www/certbot \
    -d "$DOMAIN" \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    $STAGING_ARG

# Step 4: Restart nginx to pick up the new certificate
echo "Restarting nginx with Let's Encrypt certificate..."
docker compose -f "$COMPOSE_FILE" restart nginx

echo ""
echo "=== Done! ==="
echo "Certificate installed for $DOMAIN"
echo ""
echo "To renew (run periodically via cron):"
echo "  docker compose -f $COMPOSE_FILE run --rm certbot renew"
echo "  docker compose -f $COMPOSE_FILE restart nginx"
echo ""
echo "Suggested crontab entry (renew every 12 hours):"
echo "  0 */12 * * * cd $(pwd) && docker compose -f $COMPOSE_FILE run --rm certbot renew --quiet && docker compose -f $COMPOSE_FILE restart nginx"
