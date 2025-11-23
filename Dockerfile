FROM docker.n8n.io/n8nio/n8n:latest

USER root

# Install Python and pip
RUN apk add --update --no-cache \
    python3 \
    py3-pip \
    python3-dev \
    build-base \
    && ln -sf python3 /usr/bin/python

# Install common Python packages (add/remove as needed)
RUN pip3 install --no-cache-dir --break-system-packages \
    httpx \
    beautifulsoup4 \
    lxml \
    openpyxl \
    python-dateutil \
    pytz

# Install additional Node.js packages globally (add/remove as needed)
RUN npm install -g \
    axios \
    lodash \
    moment \
    uuid \
    csv-parse \
    csv-stringify

# Create directory for custom modules
RUN mkdir -p /home/node/.n8n/custom-modules

# Switch back to node user for security
USER node

# Set working directory
WORKDIR /home/node/.n8n

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD node /usr/local/bin/n8n --version || exit 1
