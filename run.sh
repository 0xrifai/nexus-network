#!/bin/bash

echo "=== Nexus Network Setup ==="
echo ""

# Configuration di awal
echo "=== Configuration ==="

# Input Node ID
read -p "Masukkan NODE ID Anda: " NODE_ID

# Input max threads
read -p "Masukkan jumlah threads (contoh: 24): " MAX_THREADS

# Difficulty selection
echo ""
echo "Pilih tingkat kesulitan:"
echo "1. extra_large"
echo "2. extra_large_2" 
echo "3. extra_large_3"
echo "4. extra_large_4"
echo "5. extra_large_5"
echo ""
read -p "Pilih nomor (1-5): " DIFFICULTY_CHOICE

case $DIFFICULTY_CHOICE in
    1) DIFFICULTY="extra_large";;
    2) DIFFICULTY="extra_large_2";;
    3) DIFFICULTY="extra_large_3";;
    4) DIFFICULTY="extra_large_4";;
    5) DIFFICULTY="extra_large_5";;
    *) echo "Pilihan tidak valid, menggunakan extra_large_5"; DIFFICULTY="extra_large_5";;
esac

echo ""
echo "=== Konfigurasi yang dipilih ==="
echo "Node ID: $NODE_ID"
echo "Threads: $MAX_THREADS"
echo "Difficulty: $DIFFICULTY"
echo ""
read -p "Lanjutkan instalasi? (y/n): " CONFIRM

if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
    echo "Instalasi dibatalkan."
    exit 1
fi

echo ""
echo "=== Memulai Instalasi ==="

# Install Rust
echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

# Update system and install dependencies
echo "Installing dependencies..."
sudo apt update
sudo apt install -y build-essential pkg-config libssl-dev protobuf-compiler

# Clone and build
echo "Cloning and building Nexus CLI..."
git clone https://github.com/kira1752/nexus-cli.git
cd nexus-cli/clients/cli
cargo build --release
sudo cp target/release/nexus-network /usr/local/bin/nexus-network
sudo chmod +x /usr/local/bin/nexus-network

echo ""
echo "=== Starting Nexus Network ==="
echo "Menggunakan konfigurasi:"
echo "Node ID: $NODE_ID"
echo "Threads: $MAX_THREADS"
echo "Difficulty: $DIFFICULTY"
echo ""

# Function untuk keep alive logging
start_keep_alive() {
    while true; do
        echo "keep alive $(date)" >> keep_alive.log
        sleep 300   # setiap 5 menit
    done
}

# Jalankan keep alive di background
echo "Starting keep alive logging..."
start_keep_alive &
KEEP_ALIVE_PID=$!

# Function untuk cleanup ketika script dihentikan
cleanup() {
    echo ""
    echo "Stopping keep alive logging..."
    kill $KEEP_ALIVE_PID 2>/dev/null
    echo "Keep alive stopped."
    exit 0
}

# Set trap untuk cleanup ketika script dihentikan
trap cleanup SIGINT SIGTERM

echo "Keep alive logging started (PID: $KEEP_ALIVE_PID)"
echo "Log file: keep_alive.log"
echo ""

# Start the network
nexus-network start --node-id $NODE_ID --max-threads $MAX_THREADS --max-difficulty $DIFFICULTY
