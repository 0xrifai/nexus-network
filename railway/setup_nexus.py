import subprocess
import os
import shutil
import time
import sys

# Konfigurasi
NEXUS_HOME = os.path.expanduser("~/.nexus")
os.makedirs(NEXUS_HOME, exist_ok=True)

def log(message):
    """Print dengan timestamp"""
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] {message}")

def run(cmd, ignore_error=False):
    """Jalankan perintah shell dengan logging"""
    log(f"Menjalankan: {cmd}")
    try:
        result = subprocess.run(cmd, shell=True, check=True, text=True, capture_output=True)
        if result.stdout:
            print(result.stdout)
        if result.stderr:
            print(result.stderr)
        return True
    except subprocess.CalledProcessError as e:
        log(f"⚠️ Warning: Perintah gagal dengan exit code {e.returncode}")
        if e.stderr:
            print(e.stderr)
        if not ignore_error:
            return False
        return False

def get_wallet_from_env():
    """Ambil wallet address dari environment variable"""
    wallet = os.environ.get('WALLET_ADDRESS', '').strip()
    if wallet:
        log(f"✅ Wallet dari ENV: {wallet[:10]}...{wallet[-6:]}")
        return wallet
    return None

def get_wallet_interactive():
    """Minta input wallet address dari user (untuk testing lokal)"""
    log("🔑 WALLET ADDRESS REQUIRED")
    print("="*50)
    print("Masukkan wallet address Ethereum Anda")
    print("Format: 0x... (42 karakter)")
    print("Contoh: 0x123456789...ABC")
    print()
    
    while True:
        try:
            wallet = input("Wallet address: ").strip()
            
            if wallet.startswith('0x') and len(wallet) == 42:
                try:
                    int(wallet[2:], 16)
                    return wallet
                except ValueError:
                    print("❌ Format hex tidak valid")
            else:
                print("❌ Format salah! Harus 0x... dengan 42 karakter total")
        except (EOFError, KeyboardInterrupt):
            log("❌ Input dibatalkan")
            sys.exit(1)

def check_environment():
    """Cek environment dan sistem"""
    log("🔍 Checking environment...")
    
    # Cek apakah Railway
    railway_vars = ['RAILWAY_PROJECT_ID', 'RAILWAY_SERVICE_ID', 'RAILWAY_ENVIRONMENT']
    is_railway = any(var in os.environ for var in railway_vars)
    
    if is_railway:
        log("🚂 Railway environment detected!")
        return "railway"
    elif os.path.exists('/.dockerenv'):
        log("🐳 Docker environment detected!")
        return "docker"
    else:
        log("💻 Local environment detected!")
        return "local"

def install_system_deps():
    """Install system dependencies"""
    log("📦 Installing system dependencies...")
    
    deps = [
        "apt-get update",
        "DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential pkg-config libssl-dev git curl protobuf-compiler wget"
    ]
    
    for cmd in deps:
        if not run(cmd, ignore_error=True):
            log(f"⚠️ Failed to run: {cmd}")

def install_rust():
    """Install Rust"""
    if shutil.which("rustc"):
        log("✅ Rust sudah terinstall")
        return True
        
    log("🦀 Installing Rust...")
    
    # Install rustup
    if not run("curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"):
        log("❌ Gagal install Rust")
        return False
    
    # Update PATH
    home_dir = os.path.expanduser("~")
    cargo_bin = f"{home_dir}/.cargo/bin"
    current_path = os.environ.get('PATH', '')
    os.environ["PATH"] = f"{cargo_bin}:{current_path}"
    
    # Source cargo env
    run("source ~/.cargo/env", ignore_error=True)
    
    log("✅ Rust installed successfully")
    return True

def install_nexus_cli():
    """Install Nexus CLI"""
    log("⚡ Installing Nexus CLI...")
    
    try:
        proc = subprocess.Popen(
            "curl https://cli.nexus.xyz/ | sh",
            shell=True,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        stdout, stderr = proc.communicate(input="Y\n", timeout=300)  # 5 menit timeout
        
        if proc.returncode == 0:
            log("✅ Nexus CLI installed")
            return True
        else:
            log(f"❌ Nexus CLI install failed: {stderr}")
            return False
            
    except subprocess.TimeoutExpired:
        log("❌ Nexus CLI install timeout")
        proc.kill()
        return False

def find_nexus_binary():
    """Cari binary nexus-network"""
    log("🔍 Looking for nexus-network binary...")
    
    home_dir = os.path.expanduser("~")
    possible_locations = [
        f"{home_dir}/.nexus/bin/nexus-network",
        f"{home_dir}/.nexus/nexus-network",
        f"{home_dir}/.local/bin/nexus-network",
        "/usr/local/bin/nexus-network",
        "/root/.nexus/bin/nexus-network"
    ]
    
    for location in possible_locations:
        if os.path.exists(location) and os.access(location, os.X_OK):
            log(f"✅ Nexus binary found: {location}")
            return location
    
    # Coba dengan which
    result = subprocess.run("which nexus-network", shell=True, capture_output=True, text=True)
    if result.returncode == 0:
        binary_path = result.stdout.strip()
        log(f"✅ Nexus binary found with 'which': {binary_path}")
        return binary_path
    
    log("❌ Nexus binary tidak ditemukan")
    return None

def register_and_start(nexus_binary, wallet_address, env_type):
    """Register user & node, then start"""
    log(f"📝 Registering with wallet: {wallet_address[:10]}...{wallet_address[-6:]}")
    
    # Register user
    register_user_cmd = f"{nexus_binary} register-user --wallet-address {wallet_address}"
    run(register_user_cmd, ignore_error=True)
    
    # Register node
    register_node_cmd = f"{nexus_binary} register-node"
    run(register_node_cmd, ignore_error=True)
    
    # Start node
    log("🚀 Starting Nexus node...")
    
    if env_type in ["railway", "docker"]:
        # Untuk production environment
        log("🔄 Starting in production mode...")
        try:
            proc = subprocess.Popen(
                [nexus_binary, "start"],
                stdin=subprocess.PIPE,
                text=True
            )
            proc.communicate(input="Y\n")
            
            # Keep alive untuk production
            log("💓 Node running... keeping alive")
            while True:
                time.sleep(60)
                log("💓 Still alive...")
                
        except KeyboardInterrupt:
            log("🛑 Shutting down...")
            proc.terminate()
    else:
        # Untuk local development
        log("🔄 Starting in development mode...")
        proc = subprocess.Popen(
            [nexus_binary, "start"],
            stdin=subprocess.PIPE,
            text=True
        )
        proc.communicate(input="Y\n")
        log("✅ Node started!")

def main():
    """Main function"""
    log("🌟 Nexus Network Setup Starting...")
    
    # 1. Check environment
    env_type = check_environment()
    
    # 2. Get wallet address
    wallet_address = get_wallet_from_env()
    if not wallet_address:
        if env_type == "local":
            wallet_address = get_wallet_interactive()
        else:
            log("❌ WALLET_ADDRESS environment variable tidak ditemukan!")
            log("💡 Set WALLET_ADDRESS=0x... di Railway dashboard")
            sys.exit(1)
    
    # Validate wallet format
    if not (wallet_address.startswith('0x') and len(wallet_address) == 42):
        log("❌ Invalid wallet format!")
        sys.exit(1)
    
    # 3. Install dependencies
    install_system_deps()
    
    if not install_rust():
        log("❌ Rust installation failed!")
        sys.exit(1)
    
    if not install_nexus_cli():
        log("❌ Nexus CLI installation failed!")
        sys.exit(1)
    
    # 4. Find binary
    nexus_binary = find_nexus_binary()
    if not nexus_binary:
        log("❌ Nexus binary not found!")
        sys.exit(1)
    
    # 5. Register and start
    register_and_start(nexus_binary, wallet_address, env_type)
    
    log("🎉 Setup completed successfully!")

if __name__ == "__main__":
    main()