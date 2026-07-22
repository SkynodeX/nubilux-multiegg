FROM ubuntu:22.04

# Ignore APT warnings about not having a TTY
ENV DEBIAN_FRONTEND=noninteractive

# Install all required dependencies for our "All-in-One" image
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    git \
    wget \
    tar \
    bash \
    python3 \
    python3-pip \
    openjdk-8-jre-headless \
    openjdk-17-jre-headless \
    openjdk-21-jre-headless \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && useradd -d /home/container -m container \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

# Copy our baked-in scripts
COPY entrypoint.sh /entrypoint.sh
COPY functions/ /functions/

# Set execution permissions (handled by GitHub Actions/Docker build, but good measure)
USER root
RUN chmod +x /entrypoint.sh
USER container

CMD ["/bin/bash", "/entrypoint.sh"]
