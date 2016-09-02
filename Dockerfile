# ------------------------------------------------------------------------------
# Based on a work at https://github.com/docker/docker
# Based on a work at https://github.com/kdelfour/cloud9-docker
# Based on a work at https://github.com/kdelfour/supervisor-docker
# ------------------------------------------------------------------------------
# Pull base image.
FROM ubuntu:14.04
MAINTAINER Rohit Hazra <rohithzr@live.com>

# Replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Set debconf to run non-interactively
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# ------------------------------------------------------------------------------
# Install base
# Install base dependencies
RUN apt-get update && apt-get install -y -q --no-install-recommends \
        apt-transport-https \
        build-essential \
        ca-certificates \
        libssl-dev \
        supervisor \
        apache2-utils \
        git \
        libxml2-dev \
        sshfs \
        g++ \
        curl \
    && rm -rf /var/lib/apt/lists/*

VOLUME ["/etc/supervisor/conf.d"]

# ------------------------------------------------------------------------------
# Security changes
# - Determine runlevel and services at startup [BOOT-5180]
RUN update-rc.d supervisor defaults

# # - Check the output of apt-cache policy manually to determine why output is empty [KRNL-5788]
# RUN apt-get update | apt-get upgrade -y

# - Install a PAM module for password strength testing like pam_cracklib or pam_passwdqc [AUTH-9262]
RUN apt-get install libpam-cracklib -y
RUN ln -s /lib/x86_64-linux-gnu/security/pam_cracklib.so /lib/security

# Define working directory.
WORKDIR /etc/supervisor/conf.d

# ------------------------------------------------------------------------------
# Start supervisor, define default command.
CMD ["supervisord", "-c", "/etc/supervisor/conf.d"]

# ------------------------------------------------------------------------------
# Install and Load NVM
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 4.5.0

# Install nvm with node and npm
RUN curl https://raw.githubusercontent.com/creationix/nvm/v0.31.6/install.sh | bash \
    && source $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH      $NVM_DIR/v$NODE_VERSION/bin:$PATH
# ------------------------------------------------------------------------------
# Install Node
RUN nvm install v4.5.0

# ------------------------------------------------------------------------------
# Install Cloud9
RUN mkdir -p /.dloads/c9
RUN git clone https://github.com/c9/core.git /.dloads/c9
RUN cd /.dloads/c9 && scripts/install-sdk.sh
RUN mv /.dloads/c9 /cloud9
WORKDIR /cloud9

# Tweak standlone.js conf
RUN sed -i -e 's_127.0.0.1_0.0.0.0_g' /cloud9/configs/standalone.js

# Set default workspace dir
ENV C9_WORKSPACE /cloud9/workspace

# ------------------------------------------------------------------------------
# Add supervisord conf
ADD supervisord.conf /etc/supervisor/conf.d/

# ------------------------------------------------------------------------------
# Add volumes
RUN mkdir /workspace
VOLUME /workspace

# ------------------------------------------------------------------------------
# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /.dloads/*

# ------------------------------------------------------------------------------
# Expose ports.
EXPOSE 3000-4000
EXPOSE 8000-9000

# ------------------------------------------------------------------------------
# Start supervisor, define default command.
ENTRYPOINT /usr/bin/supervisord