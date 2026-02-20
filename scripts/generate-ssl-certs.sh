#!/bin/bash
# SSL Certificate Generation Script
# Run this script to generate self-signed certificates for development
# For production, use Let's Encrypt or purchased SSL certificates

# Create ssl directory if it doesn't exist
mkdir -p nginx/ssl

# Generate private key and self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout nginx/ssl/key.pem \
    -out nginx/ssl/cert.pem \
    -subj "/C=US/ST=State/L=City/O=MediMinder/CN=localhost"

echo "SSL certificates generated successfully!"
echo "Certificate: nginx/ssl/cert.pem"
echo "Private key: nginx/ssl/key.pem"
echo ""
echo "NOTE: For production, use Let's Encrypt or purchase SSL certificates"
echo "      Self-signed certificates will show security warnings in browsers"
