# Nexus Network Docker

🚀 **Simple Docker setup for Nexus Network node** - Run your Nexus node in a containerized environment with easy setup and management.

## ✨ Features

- 🐳 **Containerized deployment** - Clean, isolated environment
- 🔄 **Auto-restart** - Container restarts automatically if it crashes
- 💾 **Persistent data** - Your node data survives container restarts
- ⚙️ **Interactive setup** - Choose between wallet address or existing node ID
- 📊 **Easy monitoring** - Built-in logging and status checking
- 🛠️ **Management script** - Simple commands for all operations

## 🏗️ Architecture

```
┌─────────────────────┐
│   Docker Container  │
├─────────────────────┤
│ Ubuntu 22.04        │
│ ├─ Rust & Cargo     │
│ ├─ Nexus CLI        │
│ ├─ Python3          │
│ └─ Setup Scripts    │
└─────────────────────┘
         │
    ┌────▼────┐
    │ Volume  │
    │ Data    │
    └─────────┘
```

## 📋 Prerequisites

- Docker installed and running
- 4GB+ RAM recommended
- Stable internet connection

## 🚀 Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/0xrifai/nexus-docker.git
cd nexus-docker
```

### 2. Make Management Script Executable
```bash
chmod +x manage.sh
```

### 3. Build Docker Image (First Time Only)
```bash
# Option 1: Use manage script
./manage.sh build

# Option 2: Build manually
docker build -t nexus-network .
```

### 4. Nexus Address Workflow
```bash
# Step 1: Start container
./manage.sh start

# Step 2: Interactive setup (choose option 1)
./manage.sh setup
# Enter your Ethereum wallet address when prompted
# Format: 0xYourWalletAddress...

# Step 3: Start the node manually (REQUIRED!)
./manage.sh node-start
# Press 'Y' when prompted to confirm

# Step 4: Monitor logs (in another terminal)
./manage.sh logs
```

### 5. Nexus Node ID Workflow
```bash
# Step 1: Start container
./manage.sh start

# Step 2: Interactive setup (choose option 2)
./manage.sh setup
# Enter your existing node ID when prompted
# Example: 12345678

# Step 3: Start the node manually (REQUIRED!)
./manage.sh node-start
# Press 'Y' when prompted to confirm

# Step 4: Monitor logs (in another terminal)
./manage.sh logs
```

## 🛠️ Management Commands

The `manage.sh` script provides all necessary commands:

### 🚀 Setup & Start
```bash
./manage.sh build      # Build Docker image (first time)
./manage.sh start      # Start container
./manage.sh setup      # Run interactive node setup
./manage.sh node-start # Start Nexus node (MANUAL STEP REQUIRED)
```

### 📊 Monitoring
```bash
./manage.sh logs       # Show real-time container logs
./manage.sh status     # Show detailed system status
./manage.sh config     # Show current configuration
./manage.sh shell      # Open container bash shell
```

### 🔧 Management
```bash
./manage.sh stop       # Stop container
./manage.sh restart    # Restart container
./manage.sh rebuild    # Rebuild Docker image
./manage.sh update     # Update and restart everything
./manage.sh clean      # Remove container and data (⚠️ DATA LOSS)
```

## ⚠️ IMPORTANT: Manual Node Start Required

**The Nexus node does NOT start automatically!** This is the most important step:

### After Setup, You Must Manually Start:

1. **Run the command**: `./manage.sh node-start`
2. **Press 'Y'** when prompted to confirm
3. **Keep terminal open** while node is running

### Example Output:
```bash
$ ./manage.sh node-start
🆔 Starting with Node ID: 12345678
⚠️  You need to manually confirm by pressing 'Y'
Starting Nexus Network node...
Press 'Y' to confirm: Y
Node started successfully!
```

### Why Manual Start?
The Nexus CLI requires interactive confirmation which cannot be automated in containers.

## 📊 Monitoring Your Node

### Check Status
```bash
./manage.sh status
```
**Expected Output:**
```
✅ Container: Running
✅ Nexus Node: Running  # This means your node is mining!
✅ Volume: nexus_data exists
✅ Image: nexus-network built
```

### View Logs
```bash
# Real-time logs (press Ctrl+C to exit)
./manage.sh logs
```

### Check Configuration
```bash
./manage.sh config
```
**Example Output:**
```
METHOD=node_id
NODE_ID=12345678
```

## 🔧 Configuration

The setup creates a configuration file with your settings:

**For wallet address setup:**
```
METHOD=wallet
WALLET=0xYourWalletAddress
```

**For node ID setup:**
```
METHOD=node_id
NODE_ID=YourNodeID
```

## 📁 File Structure

```
nexus-network-docker/
├── Dockerfile              # Container definition
├── docker-compose.yml      # Docker Compose config (optional)
├── main.py               # Interactive main script
├── entrypoint.sh          # Container startup script
├── manage.sh              # Management helper script ⭐
├── .dockerignore          # Docker ignore file
└── README.md             # This file
```

## 🔄 Daily Operations

### First Time Setup
```bash
./manage.sh build       # Build image (first time only)
./manage.sh start        # Start container
./manage.sh setup        # Configure wallet/node ID
./manage.sh node-start   # Start mining (press Y)
./manage.sh logs         # Monitor
```

### Starting Your Node (After Restart)
```bash
# If container stopped or you restarted your computer
./manage.sh start        # Start container
./manage.sh node-start   # Start mining (press Y)
./manage.sh logs         # Monitor
```

### Checking If Everything Is Running
```bash
./manage.sh status
# Look for "✅ Nexus Node: Running"
```

### Stopping Mining
```bash
# In the terminal where node is running, press Ctrl+C
# Or stop the entire container:
./manage.sh stop
```

## 🔍 Troubleshooting

### First Time Issues
```bash
# Image not found error
./manage.sh build        # Build image first
./manage.sh start        # Then start

# Permission denied
chmod +x manage.sh       # Make script executable
```

### Container Issues
```bash
# Container won't start
./manage.sh rebuild      # Rebuild image
./manage.sh start        # Start again

# Check what's wrong
./manage.sh logs         # View error messages
```

### Node Issues
```bash
# Node won't start
./manage.sh shell        # Enter container
# Then manually: /home/nexus/.nexus/bin/nexus-network start --node-id YOUR_ID

# Node process died
./manage.sh status       # Check if node is running
./manage.sh node-start   # Restart if needed
```

### Configuration Issues
```bash
# Wrong wallet/node ID entered
./manage.sh setup        # Run setup again to reconfigure

# Lost configuration
./manage.sh config       # Check current config
./manage.sh setup        # Reconfigure if needed
```

### Complete Reset
```bash
# Start fresh (⚠️ DELETES ALL DATA)
./manage.sh clean        # Remove everything
./manage.sh build        # Build image
./manage.sh start        # Start fresh
./manage.sh setup        # Setup again
```

### Common Issues & Solutions

| Problem | Solution |
|---------|----------|
| "Image not found" | Run `./manage.sh build` first |
| "Container is not running" | Run `./manage.sh start` |
| "No configuration found" | Run `./manage.sh setup` |
| "Nexus Node: Not running" | Run `./manage.sh node-start` and press Y |
| Node process keeps dying | Check logs with `./manage.sh logs` |
| Port 8080 already in use | Change port in manage.sh: `PORT="8081:8080"` |
| Out of memory | Increase Docker memory limit to 4GB+ |

## 📈 Performance & Requirements

**System Requirements:**
- **CPU**: 2+ cores recommended
- **RAM**: 4GB minimum, 8GB recommended  
- **Storage**: 10GB+ for blockchain data
- **Network**: Stable broadband connection

**Resource Usage:**
- Container uses ~2GB RAM when active
- Mining process is CPU intensive
- Blockchain data grows over time

## 🔐 Security & Best Practices

- Container runs as non-root user `nexus`
- All data stored in Docker volumes (persistent)
- Network isolation through Docker
- Keep your wallet address/node ID secure
- Regular backups recommended for important data

## 🎯 Quick Reference

### Essential Commands
```bash
# Full setup workflow (first time)
./manage.sh build && ./manage.sh start && ./manage.sh setup && ./manage.sh node-start

# Daily check
./manage.sh status

# View mining activity  
./manage.sh logs

# Emergency stop
./manage.sh stop
```

### File Locations Inside Container
```bash
# Configuration
/home/nexus/.nexus/config.txt

# Nexus binary
/home/nexus/.nexus/bin/nexus-network

# Blockchain data
/home/nexus/.nexus/
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/0xrifai/nexus-docker/issues)
- **Discussions**: [GitHub Discussions](https://github.com/0xrifai/nexus-docker/discussions)
- **Nexus Network**: [Official Documentation](https://nexus.xyz)

## 🙏 Acknowledgments

- [Nexus Network](https://nexus.xyz) for the amazing blockchain platform
- Docker community for containerization best practices
- Contributors who helped improve this setup

---

**⭐ If this helped you, please give it a star!**

**🎉 Happy mining with Nexus Network!**

**💡 Remember**: Build image first (`./manage.sh build`), then `./manage.sh node-start` after setup to begin mining!
