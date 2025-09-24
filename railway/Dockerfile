FROM ubuntu:22.04

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    libssl-dev \
    git \
    curl \
    wget \
    protobuf-compiler \
    python3 \
    python3-pip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy application files
COPY setup_nexus.py .
COPY start.sh .

# Make start script executable
RUN chmod +x start.sh

# Create nexus directory
RUN mkdir -p /root/.nexus

# Expose port (jika diperlukan)
EXPOSE 8080

# Start command
CMD ["python3", "setup_nexus.py"]