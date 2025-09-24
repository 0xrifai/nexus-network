#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
CONTAINER_NAME="nexus-node"
IMAGE_NAME="nexus-network"
VOLUME_NAME="nexus_data"
PORT="8080:8080"

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}🚀 NEXUS NETWORK DOCKER MANAGER${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_status() {
    echo -e "${CYAN}📊 Current Status:${NC}"
    
    # Check if container exists
    if docker ps -a --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        # Container exists, check if running
        if docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
            echo -e "${GREEN}✅ Container: Running${NC}"
            
            # Check if nexus process is running
            if docker exec ${CONTAINER_NAME} ps aux | grep -q "[n]exus-network"; then
                echo -e "${GREEN}✅ Nexus Node: Running${NC}"
            else
                echo -e "${YELLOW}⚠️  Nexus Node: Not running (needs manual start)${NC}"
            fi
        else
            echo -e "${RED}❌ Container: Stopped${NC}"
        fi
    else
        echo -e "${RED}❌ Container: Not created${NC}"
    fi
    
    # Check if volume exists
    if docker volume ls | grep -q ${VOLUME_NAME}; then
        echo -e "${GREEN}✅ Volume: ${VOLUME_NAME} exists${NC}"
    else
        echo -e "${YELLOW}⚠️  Volume: ${VOLUME_NAME} not found${NC}"
    fi
    
    # Check if image exists
    if docker images | grep -q ${IMAGE_NAME}; then
        echo -e "${GREEN}✅ Image: ${IMAGE_NAME} built${NC}"
    else
        echo -e "${YELLOW}⚠️  Image: ${IMAGE_NAME} not found${NC}"
    fi
    echo ""
}

case "$1" in
    "build")
        print_header
        echo -e "${YELLOW}🔨 Building Docker image...${NC}"
        docker build -t ${IMAGE_NAME} .
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Image built successfully${NC}"
            echo -e "${CYAN}💡 Next: Run ${YELLOW}./manage.sh start${NC} to start container"
        else
            echo -e "${RED}❌ Failed to build image${NC}"
        fi
        ;;
        
    "start")
        print_header
        echo -e "${YELLOW}🚀 Starting Nexus container...${NC}"
        
        # Check if image exists, if not build it
        if ! docker images | grep -q ${IMAGE_NAME}; then
            echo -e "${YELLOW}⚠️  Image not found. Building first...${NC}"
            docker build -t ${IMAGE_NAME} .
            
            if [ $? -ne 0 ]; then
                echo -e "${RED}❌ Failed to build image${NC}"
                exit 1
            fi
            echo -e "${GREEN}✅ Image built successfully${NC}"
        fi
        
        # Stop and remove existing container if any
        docker stop ${CONTAINER_NAME} 2>/dev/null && echo -e "${YELLOW}Stopped existing container${NC}"
        docker rm ${CONTAINER_NAME} 2>/dev/null && echo -e "${YELLOW}Removed existing container${NC}"
        
        # Create volume if not exists
        if ! docker volume ls | grep -q ${VOLUME_NAME}; then
            docker volume create ${VOLUME_NAME}
            echo -e "${GREEN}✅ Created volume: ${VOLUME_NAME}${NC}"
        fi
        
        # Start new container
        docker run -d \
            --name ${CONTAINER_NAME} \
            --restart unless-stopped \
            -it \
            -p ${PORT} \
            -v ${VOLUME_NAME}:/home/nexus/.nexus \
            -e DEBIAN_FRONTEND=noninteractive \
            ${IMAGE_NAME}
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Container started successfully${NC}"
            echo -e "${CYAN}💡 Next steps:${NC}"
            echo -e "   1. Run: ${YELLOW}./manage.sh setup${NC} (if first time)"
            echo -e "   2. Run: ${YELLOW}./manage.sh node-start${NC} (to start mining)"
            echo -e "   3. Run: ${YELLOW}./manage.sh logs${NC} (to monitor)"
        else
            echo -e "${RED}❌ Failed to start container${NC}"
        fi
        ;;
        
    "setup")
        print_header
        echo -e "${YELLOW}⚙️ Running interactive setup...${NC}"
        
        if ! docker ps | grep -q ${CONTAINER_NAME}; then
            echo -e "${RED}❌ Container is not running. Run './manage.sh start' first${NC}"
            exit 1
        fi
        
        docker exec -it ${CONTAINER_NAME} python3 main.py
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Setup completed${NC}"
            echo -e "${CYAN}💡 Now run: ${YELLOW}./manage.sh node-start${NC} to start mining"
        fi
        ;;
        
    "node-start")
        print_header
        echo -e "${YELLOW}⚡ Starting Nexus node manually...${NC}"
        
        if ! docker ps | grep -q ${CONTAINER_NAME}; then
            echo -e "${RED}❌ Container is not running. Run './manage.sh start' first${NC}"
            exit 1
        fi
        
        # Check if config exists
        if docker exec ${CONTAINER_NAME} test -f /home/nexus/.nexus/config.txt; then
            echo -e "${GREEN}✅ Configuration found${NC}"
            
            # Read config and start node accordingly
            CONFIG=$(docker exec ${CONTAINER_NAME} cat /home/nexus/.nexus/config.txt)
            
            if echo "$CONFIG" | grep -q "METHOD=node_id"; then
                NODE_ID=$(echo "$CONFIG" | grep "NODE_ID=" | cut -d'=' -f2)
                echo -e "${BLUE}🆔 Starting with Node ID: ${NODE_ID}${NC}"
                echo -e "${YELLOW}⚠️  You need to manually confirm by pressing 'Y'${NC}"
                docker exec -it ${CONTAINER_NAME} /home/nexus/.nexus/bin/nexus-network start --node-id ${NODE_ID}
            elif echo "$CONFIG" | grep -q "METHOD=wallet"; then
                WALLET=$(echo "$CONFIG" | grep "WALLET=" | cut -d'=' -f2)
                echo -e "${BLUE}🔑 Starting with Wallet: ${WALLET}${NC}"
                echo -e "${YELLOW}⚠️  You need to manually confirm by pressing 'Y'${NC}"
                docker exec -it ${CONTAINER_NAME} /home/nexus/.nexus/bin/nexus-network start
            fi
        else
            echo -e "${RED}❌ No configuration found. Run './manage.sh setup' first${NC}"
        fi
        ;;
        
    "logs")
        print_header
        echo -e "${YELLOW}📋 Showing container logs...${NC}"
        echo -e "${CYAN}Press Ctrl+C to exit${NC}"
        echo ""
        docker logs -f ${CONTAINER_NAME}
        ;;
        
    "shell")
        print_header
        echo -e "${YELLOW}🐚 Opening container shell...${NC}"
        
        if ! docker ps | grep -q ${CONTAINER_NAME}; then
            echo -e "${RED}❌ Container is not running${NC}"
            exit 1
        fi
        
        echo -e "${CYAN}💡 Useful commands inside container:${NC}"
        echo -e "   - Check config: ${YELLOW}cat /home/nexus/.nexus/config.txt${NC}"
        echo -e "   - Start node: ${YELLOW}/home/nexus/.nexus/bin/nexus-network start --node-id YOUR_ID${NC}"
        echo -e "   - Check processes: ${YELLOW}ps aux | grep nexus${NC}"
        echo ""
        docker exec -it ${CONTAINER_NAME} bash
        ;;
        
    "stop")
        print_header
        echo -e "${YELLOW}⏹️ Stopping container...${NC}"
        docker stop ${CONTAINER_NAME}
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Container stopped${NC}"
        else
            echo -e "${RED}❌ Failed to stop container${NC}"
        fi
        ;;
        
    "restart")
        print_header
        echo -e "${YELLOW}🔄 Restarting container...${NC}"
        docker restart ${CONTAINER_NAME}
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Container restarted${NC}"
            echo -e "${CYAN}💡 You may need to run: ${YELLOW}./manage.sh node-start${NC}"
        else
            echo -e "${RED}❌ Failed to restart container${NC}"
        fi
        ;;
        
    "status")
        print_header
        print_status
        
        # Show detailed container info if running
        if docker ps | grep -q ${CONTAINER_NAME}; then
            echo -e "${CYAN}📊 Container Details:${NC}"
            docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep ${CONTAINER_NAME}
            echo ""
            
            echo -e "${CYAN}🔍 Node Processes:${NC}"
            docker exec ${CONTAINER_NAME} ps aux | grep -E "(nexus|PID)" || echo "No nexus processes running"
            echo ""
        fi
        ;;
        
    "config")
        print_header
        echo -e "${YELLOW}⚙️ Current configuration:${NC}"
        
        if docker exec ${CONTAINER_NAME} test -f /home/nexus/.nexus/config.txt 2>/dev/null; then
            echo -e "${GREEN}Configuration file found:${NC}"
            docker exec ${CONTAINER_NAME} cat /home/nexus/.nexus/config.txt
        else
            echo -e "${RED}❌ No configuration found${NC}"
            echo -e "${CYAN}💡 Run: ${YELLOW}./manage.sh setup${NC} to create configuration"
        fi
        ;;
        
    "clean")
        print_header
        echo -e "${YELLOW}🧹 Cleaning up all resources...${NC}"
        echo -e "${RED}⚠️  This will remove all data! Continue? (y/N)${NC}"
        read -r response
        
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            docker stop ${CONTAINER_NAME} 2>/dev/null && echo -e "${YELLOW}Stopped container${NC}"
            docker rm ${CONTAINER_NAME} 2>/dev/null && echo -e "${YELLOW}Removed container${NC}"
            docker volume rm ${VOLUME_NAME} 2>/dev/null && echo -e "${YELLOW}Removed volume${NC}"
            echo -e "${GREEN}✅ Cleanup completed${NC}"
        else
            echo -e "${CYAN}Cleanup cancelled${NC}"
        fi
        ;;
        
    "rebuild")
        print_header
        echo -e "${YELLOW}🔨 Rebuilding Docker image...${NC}"
        docker build -t ${IMAGE_NAME} . --no-cache
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Image rebuilt successfully${NC}"
            echo -e "${CYAN}💡 Run: ${YELLOW}./manage.sh restart${NC} to use new image"
        else
            echo -e "${RED}❌ Failed to rebuild image${NC}"
        fi
        ;;
        
    "update")
        print_header
        echo -e "${YELLOW}📦 Updating Nexus Network...${NC}"
        echo -e "${CYAN}This will rebuild image and restart container${NC}"
        
        # Rebuild image
        docker build -t ${IMAGE_NAME} . --no-cache
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Image updated${NC}"
            
            # Restart container with new image
            docker stop ${CONTAINER_NAME} 2>/dev/null
            docker rm ${CONTAINER_NAME} 2>/dev/null
            
            docker run -d \
                --name ${CONTAINER_NAME} \
                --restart unless-stopped \
                -it \
                -p ${PORT} \
                -v ${VOLUME_NAME}:/home/nexus/.nexus \
                -e DEBIAN_FRONTEND=noninteractive \
                ${IMAGE_NAME}
                
            echo -e "${GREEN}✅ Container updated and restarted${NC}"
            echo -e "${CYAN}💡 Run: ${YELLOW}./manage.sh node-start${NC} to start mining"
        else
            echo -e "${RED}❌ Update failed${NC}"
        fi
        ;;
        
    *)
        print_header
        echo -e "${PURPLE}📋 Available Commands:${NC}"
        echo ""
        echo -e "${GREEN}🚀 Setup & Start:${NC}"
        echo -e "  ${YELLOW}build${NC}      - Build Docker image (first time)"
        echo -e "  ${YELLOW}start${NC}      - Build (if needed) and start container"
        echo -e "  ${YELLOW}setup${NC}      - Run interactive node setup"
        echo -e "  ${YELLOW}node-start${NC} - Start Nexus node (manual step)"
        echo ""
        echo -e "${GREEN}📊 Monitoring:${NC}"
        echo -e "  ${YELLOW}logs${NC}       - Show container logs (real-time)"
        echo -e "  ${YELLOW}status${NC}     - Show detailed status"
        echo -e "  ${YELLOW}config${NC}     - Show current configuration"
        echo -e "  ${YELLOW}shell${NC}      - Open container bash shell"
        echo ""
        echo -e "${GREEN}🔧 Management:${NC}"
        echo -e "  ${YELLOW}stop${NC}       - Stop container"
        echo -e "  ${YELLOW}restart${NC}    - Restart container"
        echo -e "  ${YELLOW}rebuild${NC}    - Rebuild Docker image"
        echo -e "  ${YELLOW}update${NC}     - Update and restart everything"
        echo -e "  ${YELLOW}clean${NC}      - Remove container and data"
        echo ""
        echo -e "${GREEN}🎯 Quick Workflow:${NC}"
        echo -e "  ${CYAN}New User:${NC}"
        echo -e "    1. ${YELLOW}./manage.sh build${NC} (first time only)"
        echo -e "    2. ${YELLOW}./manage.sh start${NC}"
        echo -e "    3. ${YELLOW}./manage.sh setup${NC} (choose option 1, enter wallet)"
        echo -e "    4. ${YELLOW}./manage.sh node-start${NC} (press Y when prompted)"
        echo -e "    5. ${YELLOW}./manage.sh logs${NC} (monitor in another terminal)"
        echo ""
        echo -e "  ${CYAN}Existing User:${NC}"
        echo -e "    1. ${YELLOW}./manage.sh build${NC} (first time only)"
        echo -e "    2. ${YELLOW}./manage.sh start${NC}"
        echo -e "    3. ${YELLOW}./manage.sh setup${NC} (choose option 2, enter node ID)"
        echo -e "    4. ${YELLOW}./manage.sh node-start${NC} (press Y when prompted)"
        echo -e "    5. ${YELLOW}./manage.sh logs${NC} (monitor in another terminal)"
        echo ""
        echo -e "  ${CYAN}Quick Start (Auto-build):${NC}"
        echo -e "    1. ${YELLOW}./manage.sh start${NC} (auto-builds if needed)"
        echo -e "    2. ${YELLOW}./manage.sh setup${NC}"
        echo -e "    3. ${YELLOW}./manage.sh node-start${NC} (press Y)"
        echo -e "    4. ${YELLOW}./manage.sh logs${NC}"
        echo ""
        echo -e "${RED}⚠️  Important:${NC} Node requires manual start with 'node-start' command"
        ;;
esac