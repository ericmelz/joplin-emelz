FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Install system dependencies
RUN apt-get update -y && \
    apt-get install -y \
    tzdata \
    npm \
    python3 \
    python3-pip \
    python3-venv \
    curl \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Create symlink for python (python3 -> python)
RUN ln -s /usr/bin/python3 /usr/bin/python

# Install Joplin CLI
RUN npm install -g joplin

# Install Python dependencies for backup script
RUN pip3 install --no-cache-dir --break-system-packages \
    requests \
    python-dateutil

# Create working directory
WORKDIR /app

# Set default command
CMD ["/bin/bash"]
