import subprocess
import os
import shutil

# Use user's home directory, not /opt
NEXUS_HOME = os.path.expanduser("~/.nexus")
os.makedirs(NEXUS_HOME, exist_ok=True)

def run(cmd, ignore_error=False):
    """Run shell command and display output"""
    print(f"\n=== Running: {cmd} ===")
    try:
        result = subprocess.run(cmd, shell=True, check=True, text=True, capture_output=True)
        print(result.stdout)
        if result.stderr:
            print(result.stderr)
    except subprocess.CalledProcessError as e:
        print(f"⚠️ Warning: Command failed with exit code {e.returncode}")
        print(e.stderr)
        if not ignore_error:
            raise

def get_wallet_address():
    """Get wallet address input from user"""
    print("\n🔑 WALLET ADDRESS")
    print("Format: 0x... (42 characters)")
    print("Example: 0x123456789...ABC")
    print()
    
    while True:
        wallet = input("Enter your wallet address: ").strip()
        
        # Validate wallet address format
        if wallet.startswith('0x') and len(wallet) == 42:
            try:
                # Check if characters after 0x are valid hex
                int(wallet[2:], 16)
                return wallet
            except ValueError:
                print("❌ Invalid format. Please use valid hex characters.")
        else:
            print("❌ Wrong wallet address format!")
            print("   - Must start with '0x'")
            print("   - Total length must be 42 characters")
            print("   - Example: 0xdb182b44AFa6Bee13f4038cfE27162D6b9414969")
        print()

def get_node_id():
    """Get node ID input from user"""
    print("\n🆔 NODE ID")
    print("Enter a previously registered node ID")
    print()
    
    while True:
        node_id = input("Enter your node ID: ").strip()
        
        if node_id:
            return node_id
        else:
            print("❌ Node ID cannot be empty!")
        print()

def choose_registration_method():
    """Choose registration method: wallet address or node ID"""
    print("\n" + "="*60)
    print("🚀 NEXUS NETWORK SETUP")
    print("="*60)
    print("Choose method to run the node:")
    print()
    print("1️⃣  New registration with wallet address")
    print("     - For new users who haven't registered before")
    print("     - Will create a new node ID")
    print()
    print("2️⃣  Use existing node ID")
    print("     - For users who have registered before")
    print("     - Start directly with existing node ID")
    print()
    
    while True:
        choice = input("Choose option (1 or 2): ").strip()
        
        if choice == "1":
            return "wallet"
        elif choice == "2":
            return "node_id"
        else:
            print("❌ Please choose 1 or 2 only!")
        print()

# 1️⃣ Update & install OS dependencies
run("sudo apt-get update")
run("sudo apt-get install -y build-essential pkg-config libssl-dev git curl protobuf-compiler cargo")
run("sudo apt-get clean")

# 2️⃣ Check if Rust is already installed
rust_installed = shutil.which("rustc") is not None
if rust_installed:
    print("\n✅ Rust is already installed, skipping Rust installation")
else:
    print("\n⚡ Installing Rust via rustup")
    run("curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y")

# 3️⃣ Source bashrc to update PATH
run("source ~/.bashrc", ignore_error=True)

# 4️⃣ Update PATH for current session
home_dir = os.path.expanduser("~")
cargo_bin = f"{home_dir}/.cargo/bin"
nexus_bin = f"{home_dir}/.nexus/bin"
current_path = os.environ.get('PATH', '')
os.environ["PATH"] = f"{cargo_bin}:{nexus_bin}:{current_path}"

print(f"\n📁 Current PATH: {os.environ['PATH']}")

# 5️⃣ Install Nexus CLI using Popen + input Y
print("\n⚡ Installing Nexus CLI")
proc = subprocess.Popen(
    "curl https://cli.nexus.xyz/ | sh",
    shell=True,
    stdin=subprocess.PIPE,
    text=True
)
proc.communicate(input="Y\n")

# 6️⃣ Check if nexus-network binary exists
nexus_binary = f"{nexus_bin}/nexus-network"
if not os.path.exists(nexus_binary):
    # Try looking in alternative locations
    possible_locations = [
        f"{home_dir}/.nexus/nexus-network",
        f"{home_dir}/.local/bin/nexus-network",
        "/usr/local/bin/nexus-network"
    ]
    
    for location in possible_locations:
        if os.path.exists(location):
            nexus_binary = location
            print(f"✅ Nexus binary found at: {location}")
            break
    else:
        print("❌ Nexus binary not found, try reinstalling")
        # Try checking with which
        result = subprocess.run("which nexus-network", shell=True, capture_output=True, text=True)
        if result.returncode == 0:
            nexus_binary = result.stdout.strip()
            print(f"✅ Nexus binary found with 'which': {nexus_binary}")

# 7️⃣ Choose registration method
method = choose_registration_method()

# 8️⃣ Process based on choice
if os.path.exists(nexus_binary):
    if method == "wallet":
        # New registration with wallet address
        wallet_address = get_wallet_address()
        run(f"{nexus_binary} register-user --wallet-address {wallet_address}", ignore_error=True)
        run(f"{nexus_binary} register-node", ignore_error=True)
        
        # Start node normally
        print("\n⚡ Starting Nexus node")
        print("Automatically pressing 'Y' for confirmation...")
        proc_start = subprocess.Popen(
            [nexus_binary, "start"],
            stdin=subprocess.PIPE,
            text=True
        )
        proc_start.communicate(input="Y\n")
        
        print("\n✅ Setup completed!")
        print(f"🔑 Registered wallet: {wallet_address}")
        
    else:  # method == "node_id"
        # Use existing node ID
        node_id = get_node_id()
        
        # Start node with node ID
        print(f"\n⚡ Starting Nexus node with node ID: {node_id}")
        print("Automatically pressing 'Y' for confirmation...")
        proc_start = subprocess.Popen(
            [nexus_binary, "start", "--node-id", node_id],
            stdin=subprocess.PIPE,
            text=True
        )
        proc_start.communicate(input="Y\n")
        
        print("\n✅ Setup completed!")
        print(f"🆔 Node ID used: {node_id}")
else:
    print("❌ Cannot run nexus-network because binary was not found")

print("🚀 Nexus node should be running now!")