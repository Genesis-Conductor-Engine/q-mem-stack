#!/bin/bash
# Deploy Cloudflare Workers

set -e

echo "Deploying Cloudflare Workers..."

# Check for wrangler
if ! command -v npx &> /dev/null; then
    echo "Error: npx is required but not installed."
    exit 1
fi

echo "Deploying q-mem-stack (root)..."
npx wrangler deploy

echo "Deploying q-mcp..."
cd q-mcp
npx wrangler deploy
cd ..

echo "Deployment complete!"
