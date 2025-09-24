#!/usr/bin/env python3

import subprocess
import os
import sys

def run_command(cmd, ignore_error=False):
    """Run shell command and show output"""
    print(f"\n=== Running: {cmd} ===")
    try:
        result = subprocess.run(cmd, shell=True, check=True, text=True, capture_output=True)
        if result.stdout:
            print(result.stdout)
        if result.stderr:
            print(result.stderr)
        return result
    except subprocess.CalledProcessError as e:
        print(f"⚠️ Command failed with exit code {e.returncode}")
        if e.stderr:
            print(e.stderr)
        if not ignore_error:
            raise
        return None

def get_wallet_address():
    """Get wallet address from user input"""
    print("\n🔑 WALLET ADDRESS")
    print("Format: 0x... (42 characters)")
    print("Example: 0x123456789...ABC")
    print()
    
    while True:
        wallet = input("Enter your wallet address: ").strip()
        
        if wallet.startswith('0x') and len(wallet) == 42:
            try:
                int(wallet[2:], 16)
                return wallet
            except ValueError:
                print("❌ Invalid format. Use valid hex characters.")
        else:
            print("❌ Wrong wallet address format!")
            print("   - Must start with '0x'")
            print("   - Total length must be 42 characters")
        print()

def get_node_id():
    """Get node ID from user input"""
    print("\n🆔 NODE ID")
    print("Enter your existing node ID")
    print()
    
    while True:
        node_id = input("Enter your node ID: ").strip()
        if node_id:
            return node_id
        else:
            print("❌ Node ID cannot be empty!")
        print()

def choose_method():
    """Choose registration method"""
    print("\n" + "="*50)
    print("🚀 NEXUS NETWORK SETUP")
    print("="*50)
    print("Choose setup method:")
    print()
    print("1️⃣  New registration with wallet address")
    print("     - For new users")
    print("     - Will create new node ID")
    print()
    print("2️⃣  Use existing node ID")
    print("     - For users with existing registration")
    print("     - Start with existing node ID")
    print()
    
    while True:
        choice = input("Choose option (1 or 2): ").strip()
        if choice == "1":
            return "wallet"
        elif choice == "2":
            return "node_id"
        else:
            print("❌ Choose 1 or 2 only!")
        print()

def find_nexus_binary():
    """Find nexus-network binary"""
    possible_paths = [
        "/home/nexus/.nexus/bin/nexus-network",
        "/home/nexus/.nexus/nexus-network",
        "/home/nexus/.local/bin/nexus-network"
    ]
    
    for path in possible_paths:
        if os.path.exists(path):
            print(f"✅ Nexus binary found at: {path}")
            return path
    
    # Try with which command
    result = subprocess.run("which nexus-network", shell=True, capture_output=True, text=True)
    if result.returncode == 0:
        path = result.stdout.strip()
        print(f"✅ Nexus binary found with which: {path}")
        return path
    
    print("❌ Nexus binary not found!")
    return None

def save_config(method, value):
    """Save configuration to file"""
    config_dir = "/home/nexus/.nexus"
    os.makedirs(config_dir, exist_ok=True)
    
    config_file = os.path.join(config_dir, "config.txt")
    with open(config_file, "w") as f:
        if method == "wallet":
            f.write(f"METHOD=wallet\nWALLET={value}\n")
        else:
            f.write(f"METHOD=node_id\nNODE_ID={value}\n")
    
    print(f"✅ Configuration saved to {config_file}")

def main():
    print("🐳 Docker Nexus Network Setup")
    
    # Find nexus binary
    nexus_binary = find_nexus_binary()
    if not nexus_binary:
        print("❌ Setup failed: Nexus binary not found")
        sys.exit(1)
    
    # Choose method
    method = choose_method()
    
    if method == "wallet":
        # New registration with wallet
        wallet_address = get_wallet_address()
        
        print("\n⚡ Registering user and node...")
        run_command(f"{nexus_binary} register-user --wallet-address {wallet_address}", ignore_error=True)
        run_command(f"{nexus_binary} register-node", ignore_error=True)
        
        save_config("wallet", wallet_address)
        print(f"\n✅ Setup completed!")
        print(f"🔑 Registered wallet: {wallet_address}")
        
    else:
        # Use existing node ID
        node_id = get_node_id()
        
        save_config("node_id", node_id)
        print(f"\n✅ Setup completed!")
        print(f"🆔 Using node ID: {node_id}")
    
    print("\n🚀 Node will start automatically...")

if __name__ == "__main__":
    main()