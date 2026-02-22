#!/bin/sh
# Nginx entrypoint script to substitute environment variables

echo "Substituting environment variables in nginx.conf..."

# Replace SERVER_NAME placeholder with actual value
if [ -n "$SERVER_NAME" ]; then
    sed -i "s/__SERVER_NAME__/$SERVER_NAME/g" /etc/nginx/nginx.conf
fi

# Replace API_URL if specified
if [ -n "$API_URL" ]; then
    sed -i "s/__API_URL__/$API_URL/g" /etc/nginx/nginx.conf
fi

echo "Starting nginx..."
exec nginx -g 'daemon off;'
