FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
ENV PATH="/usr/local/cargo/bin:${PATH}"

# Install system dependencies
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    pkg-config \
    libssl-dev \
    git \
    curl \
    protobuf-compiler \
    ca-certificates \
    python3 \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --no-modify-path && \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME

# Create nexus user
RUN useradd -m -s /bin/bash nexus && \
    mkdir -p /home/nexus/.nexus && \
    chown -R nexus:nexus /home/nexus

# Switch to nexus user
USER nexus
WORKDIR /home/nexus

# Copy files
COPY --chown=nexus:nexus main.py ./
COPY --chown=nexus:nexus entrypoint.sh ./
RUN chmod +x entrypoint.sh

# Install Nexus CLI
RUN curl https://cli.nexus.xyz/ | sh || echo "Nexus CLI install attempted"

# Update PATH
ENV PATH="/home/nexus/.nexus/bin:${PATH}"

EXPOSE 8080

ENTRYPOINT ["./entrypoint.sh"]