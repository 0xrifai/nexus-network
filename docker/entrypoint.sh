#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}🚀 NEXUS NETWORK CONTAINER${NC}"
echo -e "${BLUE}================================${NC}"

CONFIG_FILE="/home/nexus/.nexus/config.txt"

# Find nexus binary
find_nexus_binary() {
    local paths=(
        "/home/nexus/.nexus/bin/nexus-network"
        "/home/nexus/.nexus/nexus-network"
        "/home/nexus/.local/bin/nexus-network"
    )
    
    for path in "${paths[@]}"; do
        if [ -f "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    
    # Try with which
    which nexus-network 2>/dev/null && return 0
    
    return 1
}

NEXUS_BINARY=$(find_nexus_binary)

if [ -z "$NEXUS_BINARY" ]; then
    echo -e "${RED}❌ Nexus binary not found!${NC}"
    echo -e "${YELLOW}⚡ Trying to reinstall Nexus CLI...${NC}"
    curl https://cli.nexus.xyz/ | sh
    
    NEXUS_BINARY=$(find_nexus_binary)
    if [ -z "$NEXUS_BINARY" ]; then
        echo -e "${RED}❌ Still cannot find nexus binary!${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✅ Nexus binary: $NEXUS_BINARY${NC}"

# Check if config exists
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${GREEN}✅ Using existing configuration${NC}"
    source "$CONFIG_FILE"
    
    if [ "$METHOD" = "wallet" ]; then
        echo -e "${BLUE}🔑 Wallet: $WALLET${NC}"
        echo -e "${YELLOW}⚡ Starting node...${NC}"
        exec "$NEXUS_BINARY" start
    elif [ "$METHOD" = "node_id" ]; then
        echo -e "${BLUE}🆔 Node ID: $NODE_ID${NC}"
        echo -e "${YELLOW}⚡ Starting node with node ID...${NC}"
        exec "$NEXUS_BINARY" start --node-id "$NODE_ID"
    fi
else
    echo -e "${YELLOW}⚙️ First time setup...${NC}"
    python3 main.py
    
    # After setup, start node
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        
        if [ "$METHOD" = "wallet" ]; then
            echo -e "${YELLOW}⚡ Starting node...${NC}"
            exec "$NEXUS_BINARY" start
        elif [ "$METHOD" = "node_id" ]; then
            echo -e "${YELLOW}⚡ Starting node with node ID...${NC}"
            exec "$NEXUS_BINARY" start --node-id "$NODE_ID"
        fi
    else
        echo -e "${RED}❌ Setup failed!${NC}"
        exit 1
    fi
fi