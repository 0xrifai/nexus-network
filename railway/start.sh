#!/bin/bash

echo "🚀 Starting Nexus Network on Railway..."

# Set environment variables
export PATH="/root/.cargo/bin:/root/.nexus/bin:$PATH"

# Check if wallet address is set
if [ -z "$WALLET_ADDRESS" ]; then
    echo "❌ Error: WALLET_ADDRESS environment variable is required"
    echo "💡 Set it in Railway dashboard: Variables section"
    exit 1
fi

echo "✅ Wallet address: ${WALLET_ADDRESS:0:10}...${WALLET_ADDRESS: -6}"

# Run the setup
python3 setup_nexus.py