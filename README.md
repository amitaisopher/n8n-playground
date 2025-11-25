# Self-Hosted n8n Server

A complete Docker-based setup for running a self-hosted n8n workflow automation platform with PostgreSQL database. This repository provides **four production-ready configurations** supporting both **internal** and **external** task runner modes for secure code execution.

## 🎯 What's Included

This setup provides:

- ✅ **Six complete configurations**: Internal/External/Queue modes × Dev/Prod environments
- ✅ **PostgreSQL database** for reliable data persistence
- ✅ **Redis queue** for distributed workflow execution (queue mode)
- ✅ **Task runners** for secure JavaScript and Python code execution
- ✅ **Worker processes** for horizontal scaling (queue mode)
- ✅ **Pre-installed packages**: httpx, beautifulsoup4, axios, lodash, and more
- ✅ **Docker containerization** for easy deployment
- ✅ **Environment-based configuration** with separate dev/prod settings
- ✅ **Local directory volumes** for easy backups
- ✅ **Resource limits** in production configurations

## 🚦 Quick Decision Guide

**New to n8n or getting started?**
→ Use **Internal Mode Development**: `docker-compose.internal.dev.yml`

**Running production workload (most cases)?**
→ Use **Internal Mode Production**: `docker-compose.internal.prod.yml`

**Need maximum security and isolation?**
→ Use **External Mode Production**: `docker-compose.external.prod.yml`

**Need to scale workflow execution horizontally?**
→ Use **Queue Mode Production**: `docker-compose.queue.prod.yml`

**High-volume workflows (hundreds per hour)?**
→ Use **Queue Mode** with multiple workers for parallel execution

**See [SETUP.md](docs/SETUP.md) for detailed guidance and comparison.**

## 📋 Table of Contents

- [Overview](#overview)
- [Quick Decision Guide](#quick-decision-guide)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Task Runners - Secure Code Execution](#task-runners---secure-code-execution)
- [Quick Start](#quick-start)
- [Environment Configuration](#environment-configuration)
- [Running the Server](#running-the-server)
- [Accessing n8n](#accessing-n8n)
- [Data Persistence](#data-persistence)
- [Updating n8n](#updating-n8n)
- [Updating Custom Packages](#updating-custom-packages)
- [Backup and Restore](#backup-and-restore)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)
- [Additional Resources](#additional-resources)
- [Quick Reference Commands](#quick-reference-commands)

## 📚 Documentation

This repository includes comprehensive documentation:

- **[README.md](README.md)** (this file) - Main setup and configuration guide
- **[OVERVIEW.md](docs/OVERVIEW.md)** - Visual repository structure and quick reference
- **[SETUP.md](docs/SETUP.md)** - Comprehensive setup guide with decision matrix
- **[COMPARISON.md](docs/COMPARISON.md)** - Detailed technical comparison of all modes
- **[MODE-MIGRATION.md](docs/MODE-MIGRATION.md)** - ⚠️ **Critical guide for switching between modes**
- **[CHANGELOG.md](CHANGELOG.md)** - Version history and migration guide

**New to this setup?** Start with [OVERVIEW.md](docs/OVERVIEW.md) for a visual guide.

**Switching modes?** Read [MODE-MIGRATION.md](docs/MODE-MIGRATION.md) first to avoid data loss!

## 🌟 Overview

This project provides a production-ready setup for running n8n with:

- **PostgreSQL database** for reliable data persistence
- **Docker containerization** for easy deployment and isolation
- **Separate configurations** for development and production environments
- **Local directory volumes** for persistent data storage (easy to backup)
- **Network isolation** with Docker networks
- **Environment-based configuration** using env files

## 🔀 Understanding n8n Modes

This setup supports **three orthogonal dimensions** that can be combined:

### 1. Task Runner Modes (Code Execution)

Controls **where and how** JavaScript and Python code executes:

#### **Internal Mode** (Default)
- **What it does**: Task runners run as child processes inside the n8n container
- **Code execution**: Same container as n8n main process
- **Architecture**: Single container (n8n + embedded runners + PostgreSQL)
- **Security**: Process-level isolation with RestrictedPython
- **Best for**: Development, small-to-medium production, resource efficiency
- **Setup**: Simple - just one n8n container

#### **External Mode** (Enhanced Security)
- **What it does**: Task runners run in a separate sidecar container
- **Code execution**: Dedicated container isolated from n8n
- **Architecture**: Multi-container (n8n + task-runners + PostgreSQL)
- **Communication**: WebSocket on port 5679 with authentication token
- **Security**: Container-level isolation + process isolation
- **Best for**: High-security production, independent scaling of code execution
- **Setup**: Moderate - two containers with network communication

### 2. Queue Mode (Workflow Execution)

Controls **how workflow executions are distributed**:

#### **Regular Mode** (Default)
- **What it does**: n8n main process executes all workflows directly
- **Architecture**: Single n8n instance handles everything (UI + webhooks + execution)
- **Best for**: Low-to-medium volume workflows (< 100 executions/hour)
- **Scaling**: Vertical only (increase container resources)

#### **Queue Mode** (Horizontal Scaling)
- **What it does**: Separates execution into main instance + worker processes
- **Main instance**: Handles ONLY webhooks, timers, polling, and UI (no execution)
- **Worker processes**: Execute workflows from Redis queue in parallel
- **Architecture**: Multi-process (1 main + N workers + Redis + PostgreSQL)
- **Communication**: Redis pub/sub for job distribution
- **Best for**: High-volume workflows (hundreds/hour), long-running workflows
- **Scaling**: Horizontal (add more workers) + vertical (increase worker resources)
- **Requirements**: 
  - Redis for queue management
  - PostgreSQL (SQLite unsupported)
  - Shared encryption key across all processes
  - S3 or compatible storage for binary data (filesystem unsupported)

### 3. Combining Modes

You can **combine** task runner modes with queue mode:

| Combination | Architecture | Use Case |
|------------|--------------|----------|
| **Internal + Regular** | 1 container (n8n) | Default setup, development, small production |
| **External + Regular** | 2 containers (n8n + runners) | Security-focused, medium production |
| **Internal + Queue** | 1 main + N workers (all with embedded runners) | High-volume, resource-efficient |
| **External + Queue** | 1 main + N workers + dedicated runners | High-volume + maximum security |

#### **Queue + Internal Mode** (Current Setup)
```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Main Instance  │     │   Worker 1      │     │   Worker 2      │
│  ┌──────────┐   │     │  ┌──────────┐   │     │  ┌──────────┐   │
│  │ Webhooks │   │     │  │ Executes │   │     │  │ Executes │   │
│  │ UI       │   │     │  │ Workflows│   │     │  │ Workflows│   │
│  │ Timers   │   │     │  │          │   │     │  │          │   │
│  │          │   │     │  │ Embedded │   │     │  │ Embedded │   │
│  │          │   │     │  │ Runners  │   │     │  │ Runners  │   │
│  └──────────┘   │     │  └──────────┘   │     │  └──────────┘   │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                       │
         └───────────────────────┴───────────────────────┘
                              │
                         ┌────▼─────┐
                         │  Redis   │
                         │  Queue   │
                         └──────────┘
```

#### **Queue + External Mode** (Maximum Security + Scale)
```
┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│   Main      │   │  Worker 1   │   │  Worker 2   │
│ (Webhooks)  │   │  (Execute)  │   │  (Execute)  │
└──────┬──────┘   └──────┬──────┘   └──────┬──────┘
       │                 │                 │
       │                 │                 │
       ▼                 ▼                 ▼
┌──────────────────────────────────────────────┐
│           Task Runners Container             │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐      │
│  │  JS     │  │ Python  │  │  More   │      │
│  │ Runner  │  │ Runner  │  │ Runners │      │
│  └─────────┘  └─────────┘  └─────────┘      │
└──────────────────────────────────────────────┘
       │
       ▼
┌─────────────┐
│   Redis     │
│   Queue     │
└─────────────┘
```

### Quick Mode Selection Matrix

| Your Needs | Recommended Mode | Config File |
|------------|------------------|-------------|
| Just getting started | Internal + Regular | `docker-compose.internal.dev.yml` |
| Small production | Internal + Regular | `docker-compose.internal.prod.yml` |
| Need better code isolation | External + Regular | `docker-compose.external.prod.yml` |
| High workflow volume | Internal + Queue | `docker-compose.queue.dev.yml` |
| High volume + max security | External + Queue | Create custom compose (combine patterns) |
| Enterprise with HA | External + Queue + Multi-main | Create custom compose with multiple mains |

## 📁 Project Structure

```
n8n-playground/
├── Dockerfile.runners.internal        # Internal mode: n8n with embedded runners
├── Dockerfile.runners.external        # External mode: separate task runner image
├── n8n-task-runners.json             # Task runner configuration for allowlisted packages
├── docker-compose.internal.dev.yml   # Internal mode development
├── docker-compose.internal.prod.yml  # Internal mode production
├── docker-compose.external.dev.yml   # External mode development  
├── docker-compose.external.prod.yml  # External mode production
├── docker-compose.queue.dev.yml      # Queue mode development (1 main + 2 workers)
├── docker-compose.queue.prod.yml     # Queue mode production (1 main + 4 workers)
├── .env.development                  # Internal mode dev environment
├── .env.production                   # Internal mode prod environment
├── .env.external.development         # External mode dev environment
├── .env.external.production          # External mode prod environment
├── .env.queue.development            # Queue mode dev environment
├── .env.queue.production             # Queue mode prod environment
├── .env.example                      # Example environment variables
├── .gitignore                        # Git ignore patterns
├── data/                             # Data directory (created on first run)
│   ├── n8n/                          # n8n workflows, credentials, settings
│   ├── postgres/                     # PostgreSQL database files
│   └── redis/                        # Redis queue data (queue mode only)
├── CHANGELOG.md                      # Project changelog
└── README.md                         # This file
```

## ✅ Prerequisites

Before you begin, ensure you have the following installed:

- [Docker](https://docs.docker.com/get-docker/) (version 20.10 or later)
- [Docker Compose](https://docs.docker.com/compose/install/) (version 2.0 or later)
- At least 2GB of available RAM
- At least 10GB of available disk space

Verify your installation:

```bash
docker --version
docker compose version
```

## 🛠️ Task Runners - Secure Code Execution

This setup uses **n8n task runners** for secure and performant execution of custom JavaScript and Python code. Task runners can run in two modes:

### Choosing Your Task Runner Mode

| Feature | Internal Mode | External Mode |
|---------|--------------|---------------|
| **Architecture** | Child processes within n8n container | Separate sidecar container |
| **Isolation** | Process-level isolation | Container-level isolation |
| **Resource Control** | Limited (shared with n8n) | Full (dedicated CPU/memory limits) |
| **Setup Complexity** | ✅ Simple (single container) | ⚠️ Moderate (two containers) |
| **Performance** | ✅ Fast (no network overhead) | Good (minimal WS latency) |
| **Security** | ✅ Good (process isolation) | ✅✅ Better (container isolation) |
| **Scaling** | Limited to n8n container | Can scale independently |
| **Production Ready** | ✅ Yes | ✅ Yes (when image available) |
| **Recommended For** | Most use cases, development | High-security, high-scale production |

**🔹 Use Internal Mode when:**
- Running in development or small production environments
- Resource efficiency is important
- You need simpler setup and maintenance
- You're getting started with task runners

**🔹 Use External Mode when:**
- Running high-scale production workloads
- Maximum security isolation is required
- You need independent scaling of code execution
- You want dedicated resource limits for runners
- The official `n8nio/runners` image is available

✅ **Note**: External mode uses the official `n8nio/runners` image. Development uses version `1.121.2` (pinned), production uses `:latest` tag.

### Why Task Runners?

- **Security**: Code executes with restricted permissions (RestrictedPython)
- **Performance**: Automatic lifecycle management and resource optimization  
- **Flexibility**: Support for custom Python and Node.js packages
- **Production-Ready**: Recommended approach by n8n for self-hosted setups

### Architecture Comparison

**Internal Mode:**
```
┌─────────────────────────┐
│   n8n Container         │
│  ┌─────────────────┐   │
│  │  n8n Main       │   │
│  │  Task Broker    │   │
│  └────────┬────────┘   │
│           │             │
│     ┌─────┴──────┐     │
│     │            │     │
│  ┌──▼───┐   ┌───▼──┐  │
│  │ JS   │   │Python│  │
│  │Runner│   │Runner│  │
│  └──────┘   └──────┘  │
└─────────────────────────┘
```

**External Mode:**
```
┌─────────────┐       ┌──────────────────┐
│   n8n       │◄─────►│  task-runners    │
│  (main)     │  WS   │   (sidecar)      │
│             │ 5679  │  ┌────────────┐  │
│  Task       │       │  │ JS Runner  │  │
│  Broker     │       │  └────────────┘  │
│             │       │  ┌────────────┐  │
│             │       │  │Python Runner│ │
│             │       │  └────────────┘  │
└─────────────┘       └──────────────────┘
```

### Pre-installed Packages

#### Python Packages
- `httpx` - Async HTTP client
- `beautifulsoup4` - Web scraping
- `lxml` - XML/HTML processing
- `openpyxl` - Excel file handling
- `python-dateutil` - Date/time utilities
- `pytz` - Timezone support

#### Node.js Packages
- `axios` - HTTP client
- `lodash` - Utility functions
- `moment` - Date/time manipulation
- `uuid` - UUID generation
- `csv-parse` - CSV parsing
- `csv-stringify` - CSV generation

### Adding Custom Packages

The process differs slightly between internal and external modes:

#### Internal Mode

1. **Edit `Dockerfile.runners.internal`**:
   ```dockerfile
   # Add Python packages (use pip3 with --break-system-packages)
   RUN pip3 install --no-cache-dir --break-system-packages \
       your-package-name \
       another-package
   
   # Add Node.js packages (use npm global install)
   RUN npm install -g \
       your-node-package \
       another-node-package
   ```

2. **Update environment variable in `.env.development` or `.env.production`**:
   ```env
   NODE_FUNCTION_ALLOW_EXTERNAL=axios,lodash,your-new-package
   ```

3. **Rebuild and restart**:
   ```bash
   docker compose -f docker-compose.internal.dev.yml build n8n
   docker compose -f docker-compose.internal.dev.yml up -d
   ```

#### External Mode

⚠️ **Note**: External mode currently uses the official `n8nio/runners` image directly. Custom package installation requires extending the official image.

For now, use the pre-installed packages or contact n8n for guidance on extending the runners image.

To allowlist existing packages:

1. **Update environment variable** in `.env.external.development` or `.env.external.production`:
   ```env
   NODE_FUNCTION_ALLOW_EXTERNAL=axios,lodash,your-existing-package
   ```

2. **Restart the services**:
   ```bash
   docker compose -f docker-compose.external.dev.yml restart
   ```

### Using Custom Packages in n8n

**Python Code Node** (synchronous code only):
```python
import httpx
from bs4 import BeautifulSoup

# Synchronous HTTP request
with httpx.Client() as client:
    response = client.get('https://api.example.com/data')
    data = response.json()

# Parse HTML
soup = BeautifulSoup(data['html'], 'lxml')
titles = [h2.text for h2 in soup.find_all('h2')]

return {'titles': titles}
```

**JavaScript Code Node**:
```javascript
const axios = require('axios');
const _ = require('lodash');
const moment = require('moment');

// Make HTTP request
const response = await axios.get('https://api.example.com/data');

// Process with lodash
const filtered = _.filter(response.data, { active: true });

// Format dates
const formatted = filtered.map(item => ({
  ...item,
  date: moment(item.timestamp).format('YYYY-MM-DD')
}));

return formatted;
```

### Important Limitations

⚠️ **Python code must be synchronous** - Task runners use RestrictedPython which blocks:
- `asyncio` operations (use `httpx.Client` instead of `httpx.AsyncClient`)
- File system operations
- Subprocess execution
- Network operations via certain libraries

For async operations or unrestricted Python, consider using an external Python service (Flask/FastAPI) called via HTTP Request node.

## 🚀 Quick Start

Choose your task runner mode first (see [Choosing Your Task Runner Mode](#choosing-your-task-runner-mode)):
- **Internal Mode** (recommended for most users): Simpler setup, single container
- **External Mode** (advanced): Better isolation, requires `n8nio/runners` image

### 1. Clone or Download

Clone this repository or download the files to your local machine.

### 2. Configure Environment Variables

**For Internal Mode** (Development):

```bash
# Edit the internal development environment file
nano .env.development

# Generate a secure encryption key (IMPORTANT!)
openssl rand -hex 32

# Replace the N8N_ENCRYPTION_KEY value in .env.development
```

**For Internal Mode** (Production):

```bash
# Edit the internal production environment file
nano .env.production

# Generate a strong encryption key
openssl rand -hex 32

# Update ALL values in .env.production (especially passwords, encryption key, and domain)
```

**For External Mode** (Development):

```bash
# Edit the external development environment file
nano .env.external.development

# Generate encryption key and auth token
openssl rand -hex 32  # For N8N_ENCRYPTION_KEY
openssl rand -hex 32  # For N8N_RUNNERS_AUTH_TOKEN

# Update both values in .env.external.development
```

**For External Mode** (Production):

```bash
# Edit the external production environment file  
nano .env.external.production

# Generate unique keys for production
openssl rand -hex 32  # For N8N_ENCRYPTION_KEY
openssl rand -hex 32  # For N8N_RUNNERS_AUTH_TOKEN

# Update ALL values (passwords, encryption key, auth token, domain)
```

### 3. Build and Start n8n

**Internal Mode - Development**:

```bash
# Build the n8n image with embedded runners
docker compose -f docker-compose.internal.dev.yml build

# Start all services
docker compose -f docker-compose.internal.dev.yml up -d

# View logs
docker compose -f docker-compose.internal.dev.yml logs -f
```

**Internal Mode - Production**:

```bash
# Build and start
docker compose -f docker-compose.internal.prod.yml build
docker compose -f docker-compose.internal.prod.yml up -d

# View logs
docker compose -f docker-compose.internal.prod.yml logs -f
```

**External Mode - Development**:

```bash
# Build both n8n and task-runners images
docker compose -f docker-compose.external.dev.yml build

# Start all services (n8n, task-runners, postgres)
docker compose -f docker-compose.external.dev.yml up -d

# View logs
docker compose -f docker-compose.external.dev.yml logs -f

# Check task runner connection
docker compose -f docker-compose.external.dev.yml logs task-runners | grep -i connected
```

**External Mode - Production**:

```bash
# Build and start
docker compose -f docker-compose.external.prod.yml build
docker compose -f docker-compose.external.prod.yml up -d

# View logs
docker compose -f docker-compose.external.prod.yml logs -f
```

### 4. Access n8n

Open your browser and navigate to:

- **Development**: http://localhost:5678
- **Production**: https://your-domain.com (or http://localhost:5678 if testing locally)

## ⚙️ Environment Configuration

Environment variables are defined in separate files based on your chosen mode and environment:

**Internal Mode:**
- `.env.development` - Internal mode development
- `.env.production` - Internal mode production

**External Mode:**
- `.env.external.development` - External mode development
- `.env.external.production` - External mode production

These files are loaded automatically via the `env_file:` directive in docker-compose files.

### Essential Variables (All Modes)

#### Timezone Settings

```env
GENERIC_TIMEZONE=America/New_York  # Your timezone
TZ=America/New_York                # System timezone
```

Find your timezone: [List of tz database time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)

#### Host Configuration

```env
N8N_HOST=localhost              # Development: localhost, Production: your-domain.com
N8N_PORT=5678                   # Port for n8n
N8N_PROTOCOL=http               # Development: http, Production: https
WEBHOOK_URL=http://localhost:5678  # Full URL where n8n is accessible
```

#### Security

```env
N8N_ENCRYPTION_KEY=your-generated-key-here  # Generate with: openssl rand -hex 32
```

⚠️ **IMPORTANT**: Never use the same encryption key between development and production!

#### Task Runner Configuration - Internal Mode

```env
N8N_RUNNERS_ENABLED=true                           # Enable task runners
N8N_RUNNERS_MODE=internal                          # Use internal mode (child processes)
NODE_FUNCTION_ALLOW_EXTERNAL=axios,lodash,moment   # Allowlist for JS packages
```

#### Task Runner Configuration - External Mode

```env
N8N_RUNNERS_ENABLED=true                           # Enable task runners
N8N_RUNNERS_MODE=external                          # Use external mode (sidecar)
N8N_RUNNERS_BROKER_LISTEN_ADDRESS=0.0.0.0         # Allow connections from sidecar
N8N_RUNNERS_AUTH_TOKEN=your-secure-token-here      # Generate with: openssl rand -hex 32
N8N_NATIVE_PYTHON_RUNNER=true                      # Enable Python runner (beta)

# Task runner container configuration (set in runners container only)
N8N_RUNNERS_TASK_BROKER_URI=http://n8n-external-dev:5679   # Use http:// not ws://
N8N_RUNNERS_AUTO_SHUTDOWN_TIMEOUT=15               # Auto-shutdown after 15s idle
```

⚠️ **IMPORTANT**: 
- Use different `N8N_RUNNERS_AUTH_TOKEN` values for dev and production!
- `N8N_RUNNERS_TASK_BROKER_URI` must use `http://` protocol (not `ws://`)
- `N8N_RUNNERS_TASK_BROKER_URI` should only be set in the runners container environment

#### Database Configuration

```env
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=postgres
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n_user
DB_POSTGRESDB_PASSWORD=strong-password-here
DB_POSTGRESDB_SCHEMA=public
```

### Optional Variables

Additional variables you can configure in your environment file (see `.env.example` for full list):

- `N8N_LOG_LEVEL`: Logging verbosity (error, warn, info, verbose, debug)
- `EXECUTIONS_DATA_SAVE_ON_ERROR`: Save execution data on errors
- `EXECUTIONS_DATA_SAVE_ON_SUCCESS`: Save execution data on success
- `N8N_BASIC_AUTH_ACTIVE`: Enable basic authentication
- `N8N_DIAGNOSTICS_ENABLED`: Enable telemetry

## 🏃 Running the Server

Commands vary based on your chosen mode (internal or external) and environment (dev or prod).

### Start the Server

**Internal Mode - Development**:
```bash
docker compose -f docker-compose.internal.dev.yml up -d
```

**Internal Mode - Production**:
```bash
docker compose -f docker-compose.internal.prod.yml up -d
```

**External Mode - Development**:
```bash
docker compose -f docker-compose.external.dev.yml up -d
```

**External Mode - Production**:
```bash
docker compose -f docker-compose.external.prod.yml up -d
```

### Stop the Server

```bash
# Internal Dev
docker compose -f docker-compose.internal.dev.yml down

# Internal Prod
docker compose -f docker-compose.internal.prod.yml down

# External Dev
docker compose -f docker-compose.external.dev.yml down

# External Prod
docker compose -f docker-compose.external.prod.yml down
```

### Restart the Server

```bash
# Internal Dev
docker compose -f docker-compose.internal.dev.yml restart

# External Dev
docker compose -f docker-compose.external.dev.yml restart

# (Use corresponding commands for prod)
```

### View Logs

```bash
# View all logs (Internal Dev)
docker compose -f docker-compose.internal.dev.yml logs -f

# View all logs (External Dev)
docker compose -f docker-compose.external.dev.yml logs -f

# View specific service logs (example: External Dev task-runners)
docker compose -f docker-compose.external.dev.yml logs -f task-runners

# View n8n logs only (Internal Dev)
docker compose -f docker-compose.internal.dev.yml logs -f n8n

# View PostgreSQL logs (Internal Dev)
docker compose -f docker-compose.internal.dev.yml logs -f postgres
```

### Check Status

```bash
# Internal Dev
docker compose -f docker-compose.internal.dev.yml ps

# External Dev  
docker compose -f docker-compose.external.dev.yml ps
```

## 🌐 Accessing n8n

Once running, access n8n at:

- **Local Development**: http://localhost:5678
- **Production**: https://your-domain.com

On first access, you'll be prompted to:
1. Create an owner account
2. Set up your workspace
3. Start creating workflows

## 💾 Data Persistence

All data is stored in local directories (not Docker-managed volumes), making backups easy:

### n8n Data

- **Location**: `./data/n8n/`
- **Contains**: Workflows, credentials, settings, execution data
- **Mounted to**: `/home/node/.n8n` inside the container

### PostgreSQL Data

- **Location**: `./data/postgres/`
- **Contains**: Database files
- **Mounted to**: `/var/lib/postgresql/data` inside the container

These directories are created automatically on first run, or you can create them manually:

```bash
mkdir -p data/n8n data/postgres
```

### Setting Up Backups

Since data is stored in local directories, you can easily:

1. **Use rsync** for incremental backups:
   ```bash
   rsync -avz ./data/ /path/to/backup/location/
   ```

2. **Schedule with cron**:
   ```bash
   # Add to crontab (crontab -e)
   0 2 * * * rsync -avz /path/to/n8n-playground/data/ /backup/n8n/
   ```

3. **Use cloud sync** (Dropbox, Google Drive, etc.):
   ```bash
   # Example with rclone
   rclone sync ./data/ remote:n8n-backup/
   ```

### View Data

### View Data

```bash
# View n8n data
ls -la data/n8n/

# View postgres data
ls -la data/postgres/
```

## 🔄 Updating n8n

The update process varies by mode:

### Internal Mode

1. **Backup Your Data**:
```bash
tar czf n8n_backup_$(date +%Y%m%d).tar.gz data/
```

2. **Pull Latest n8n Image**:
```bash
docker pull docker.n8n.io/n8nio/n8n:latest
```

3. **Rebuild Image with Updated Packages**:
```bash
# Development
docker compose -f docker-compose.internal.dev.yml build n8n --no-cache

# Production
docker compose -f docker-compose.internal.prod.yml build n8n --no-cache
```

4. **Restart**:
```bash
# Development
docker compose -f docker-compose.internal.dev.yml down
docker compose -f docker-compose.internal.dev.yml up -d

# Production
docker compose -f docker-compose.internal.prod.yml down
docker compose -f docker-compose.internal.prod.yml up -d
```

### External Mode

1. **Backup Your Data**:
```bash
tar czf n8n_backup_$(date +%Y%m%d).tar.gz data/
```

2. **Pull Latest Images**:
```bash
# Pull n8n image
docker pull docker.n8n.io/n8nio/n8n:latest

# Pull runners image (when available)
docker pull docker.n8n.io/n8nio/runners:latest
```

3. **Rebuild Task Runners Image**:
```bash
# Development
docker compose -f docker-compose.external.dev.yml build task-runners --no-cache

# Production
docker compose -f docker-compose.external.prod.yml build task-runners --no-cache
```

4. **Restart All Services**:
```bash
# Development
docker compose -f docker-compose.external.dev.yml down
docker compose -f docker-compose.external.dev.yml up -d

# Production
docker compose -f docker-compose.external.prod.yml down
docker compose -f docker-compose.external.prod.yml up -d
```

5. **Verify Task Runner Connection**:
```bash
# Development
docker compose -f docker-compose.external.dev.yml logs task-runners | grep -i connected

# Check n8n logs for runner registration
docker compose -f docker-compose.external.dev.yml logs n8n | grep -i runner
```

## 🔄 Updating Custom Packages

The process differs by mode:

### Internal Mode

1. **Edit `Dockerfile.runners.internal`** to modify package lists

2. **Update `NODE_FUNCTION_ALLOW_EXTERNAL` in environment file**

3. **Rebuild and restart**:
   ```bash
   # Development
   docker compose -f docker-compose.internal.dev.yml build n8n
   docker compose -f docker-compose.internal.dev.yml up -d
   
   # Production
   docker compose -f docker-compose.internal.prod.yml build n8n
   docker compose -f docker-compose.internal.prod.yml up -d
   ```

### External Mode

1. **Edit `Dockerfile.runners.external`** to modify package lists

2. **Edit `n8n-task-runners.json`** to update allowlists

3. **Rebuild and restart**:
   ```bash
   # Development
   docker compose -f docker-compose.external.dev.yml build task-runners
   docker compose -f docker-compose.external.dev.yml restart task-runners
   
   # Production
   docker compose -f docker-compose.external.prod.yml build task-runners
   docker compose -f docker-compose.external.prod.yml restart task-runners
   ```

## 💿 Backup and Restore

### Backup

**Complete Backup** (simplest method):
```bash
# Create backup directory
mkdir -p backups

# Backup entire data directory
tar czf backups/n8n_complete_backup_$(date +%Y%m%d_%H%M%S).tar.gz data/
```

**Database Only**:
```bash
# Backup PostgreSQL database
docker compose exec postgres pg_dump -U n8n_user n8n > backups/n8n_db_$(date +%Y%m%d_%H%M%S).sql
```

**Using rsync** (for incremental backups):
```bash
rsync -avz --delete data/ backups/latest/
```

### Restore

**Complete Restore**:
```bash
# Stop containers (development)
docker compose -f docker-compose.dev.yml down

# Remove old data (CAREFUL!)
rm -rf data/

# Restore from backup
tar xzf backups/n8n_complete_backup_YYYYMMDD_HHMMSS.tar.gz

# Start containers
docker compose -f docker-compose.dev.yml up -d
```

**Database Only**:
```bash
# Stop n8n (development)
docker compose -f docker-compose.dev.yml stop n8n

# Restore database
cat backups/n8n_db_YYYYMMDD_HHMMSS.sql | docker compose -f docker-compose.dev.yml exec -T postgres psql -U n8n_user n8n

# Start n8n
docker compose -f docker-compose.dev.yml start n8n
```

## 🔧 Troubleshooting

### ⚠️ CRITICAL: Switching Between Modes with Shared PostgreSQL Volume

**Problem**: If you run n8n in one mode (e.g., internal/external) and then switch to **queue mode** using the same `./data/postgres` directory, the containers will fail to start with database initialization errors.

**Why This Happens**:
- Different modes require different database schemas and configurations
- Queue mode requires specific database tables and settings that are only created when n8n detects a **fresh, empty database**
- When you switch modes but reuse the existing PostgreSQL volume, the database contains the schema from the previous mode
- Queue mode expects certain tables/columns that don't exist in the regular mode database
- n8n cannot migrate an existing non-queue database to queue mode automatically

**Symptoms**:
```
n8n-postgres-queue-dev  | FATAL:  role "n8n_queue_dev" does not exist
OR
n8n-main-queue-dev      | Error: There was an error initializing DB
OR
n8n-main-queue-dev      | Missing required column for queue mode
```

**Solution 1: Fresh Database (Recommended for Testing/Development)**

⚠️ **WARNING**: This deletes all your workflows, credentials, and execution history!

```bash
# 1. Stop all containers
docker compose -f docker-compose.internal.dev.yml down  # or whichever mode you were using

# 2. Backup your data first (IMPORTANT!)
tar czf backup_before_queue_$(date +%Y%m%d_%H%M%S).tar.gz data/

# 3. Remove the PostgreSQL volume
rm -rf data/postgres/

# 4. Start queue mode - it will create a fresh database
docker compose -f docker-compose.queue.dev.yml up -d
```

**Solution 2: Use Separate PostgreSQL Volumes per Mode (Recommended for Production)**

Modify the docker-compose file to use mode-specific volume paths:

```yaml
# In docker-compose.queue.dev.yml, change:
volumes:
  - ./data/postgres-queue:/var/lib/postgresql/data  # Instead of ./data/postgres

# In docker-compose.internal.dev.yml, keep:
volumes:
  - ./data/postgres:/var/lib/postgresql/data
```

This allows you to:
- Switch between modes without conflicts
- Keep separate databases for each mode
- Test different modes without data loss
- Each mode maintains its own database state

**Best Practice**:
- Use **separate PostgreSQL volumes** for each mode in production
- Always **backup before switching modes**
- Consider using **different database names** for each mode
- Document which mode each database belongs to

**Alternative: Database Migration (Advanced)**

If you need to preserve data when switching to queue mode:
1. Export workflows and credentials from n8n UI
2. Switch to queue mode with fresh database
3. Import workflows and credentials into new instance
4. Note: Execution history cannot be migrated

---

### Container Won't Start

```bash
# Check logs (development)
docker compose -f docker-compose.dev.yml logs n8n

# Check if port is already in use
lsof -i :5678  # On Linux/Mac
netstat -ano | findstr :5678  # On Windows
```

### Database Connection Issues

```bash
# Check PostgreSQL is running (development)
docker compose -f docker-compose.dev.yml ps postgres

# Check PostgreSQL logs
docker compose -f docker-compose.dev.yml logs postgres

# Test database connection
docker compose -f docker-compose.dev.yml exec postgres psql -U n8n_user -d n8n -c "SELECT version();"
```

### Permission Issues

```bash
# Fix directory permissions
sudo chown -R $(id -u):$(id -g) data/
```

### Reset Everything

```bash
# WARNING: This will delete all data!
# Development
docker compose -f docker-compose.dev.yml down
rm -rf data/
mkdir -p data/n8n data/postgres
docker compose -f docker-compose.dev.yml up -d

# Production
docker compose -f docker-compose.prod.yml down
rm -rf data/
mkdir -p data/n8n data/postgres
docker compose -f docker-compose.prod.yml up -d
```

### Common Issues

1. **Port 5678 already in use**: Change `N8N_PORT` in your environment file
2. **PostgreSQL won't start**: Check if port 5432 is available
3. **Cannot access n8n**: Verify `WEBHOOK_URL` matches your actual URL
4. **Workflows not executing**: Check encryption key is set correctly
5. **Permission denied on data folders**: Run `sudo chown -R $(id -u):$(id -g) data/`

### Task Runner Issues

**Code node shows "Blocked for security reasons"**:
- Check that `N8N_RUNNERS_ENABLED=true` and `N8N_RUNNERS_MODE=external`
- Verify task-runners container is running: `docker ps | grep task-runners`
- Check `N8N_RUNNERS_AUTH_TOKEN` matches in both n8n and task-runners containers
- Review logs: `docker compose -f docker-compose.external.dev.yml logs task-runners`

**Python asyncio not working**:
- Task runners use RestrictedPython which blocks asyncio
- Use synchronous alternatives: `httpx.Client()` instead of `httpx.AsyncClient()`
- For async operations, consider using an external Python service

**Module not found in Code node**:
1. External mode uses official `n8nio/runners` image with pre-installed packages
2. Check the module is in the pre-installed list (see Pre-installed Packages section)
3. Verify `NODE_FUNCTION_ALLOW_EXTERNAL` environment variable includes the package
4. Restart: `docker compose -f docker-compose.external.dev.yml restart`

**Task runner won't connect to broker**:
- Verify `N8N_RUNNERS_BROKER_LISTEN_ADDRESS=0.0.0.0` in n8n environment
- Check `N8N_RUNNERS_TASK_BROKER_URI=http://n8n-external-dev:5679` (must use `http://` not `ws://`)
- Verify `N8N_RUNNERS_TASK_BROKER_URI` is only set in runners container, not in n8n container
- Ensure both containers are on same Docker network
- Check logs: `docker compose -f docker-compose.external.dev.yml logs n8n | grep -i runner`
- Check connection: `docker compose -f docker-compose.external.dev.yml logs task-runners | grep -i connected`

## 🔒 Security Considerations

### Production Deployment

1. **Use HTTPS**: Always use HTTPS in production
   - Set `N8N_PROTOCOL=https`
   - Configure SSL/TLS certificates (use Let's Encrypt with Nginx/Caddy)

2. **Strong Passwords**: Use strong, unique passwords
   - Database password
   - n8n encryption key (32+ characters)
   - Basic auth password (if enabled)

3. **Firewall Rules**: Restrict access to necessary ports only
   - Close PostgreSQL port (5432) to external access
   - Only open n8n port (5678) or use reverse proxy

4. **Regular Backups**: Automate database and volume backups

5. **Keep Updated**: Regularly update n8n and PostgreSQL

5. **Environment Variables**: Never commit `.env.development` or `.env.production` files to version control (they're in `.gitignore`)

6. **Data Directory**: Ensure `./data/` is included in your backup strategy

7. **Basic Authentication**: Consider enabling basic auth for additional security
   ```env
   N8N_BASIC_AUTH_ACTIVE=true
   N8N_BASIC_AUTH_USER=admin
   N8N_BASIC_AUTH_PASSWORD=strong-password
   ```

### Recommended Production Setup

For production, consider adding:

- **Reverse Proxy** (Nginx or Caddy) for SSL termination
- **Monitoring** (Prometheus + Grafana)
- **Automated Backups** (cron jobs with rsync or cloud sync)
- **Log Aggregation** (ELK stack or similar)
- **Regular data directory backups** to off-site location

## 📚 Additional Resources

- [Official n8n Documentation](https://docs.n8n.io/)
- [n8n Docker Installation Guide](https://docs.n8n.io/hosting/installation/docker/)
- [n8n Community Forum](https://community.n8n.io/)
- [n8n GitHub Repository](https://github.com/n8n-io/n8n)
- [n8n Workflow Templates](https://n8n.io/workflows/)

## 📝 Quick Reference Commands

### Internal Mode

```bash
# Build (first time or after changes)
docker compose -f docker-compose.internal.dev.yml build

# Start (Development)
docker compose -f docker-compose.internal.dev.yml up -d

# Start (Production)
docker compose -f docker-compose.internal.prod.yml up -d

# Stop
docker compose -f docker-compose.internal.dev.yml down

# View logs
docker compose -f docker-compose.internal.dev.yml logs -f n8n

# Update n8n
docker pull docker.n8n.io/n8nio/n8n:latest
docker compose -f docker-compose.internal.dev.yml build n8n --no-cache
docker compose -f docker-compose.internal.dev.yml up -d

# Rebuild after adding packages
docker compose -f docker-compose.internal.dev.yml build n8n
docker compose -f docker-compose.internal.dev.yml restart n8n

# Backup data
tar czf backup.tar.gz data/

# Enter container
docker compose -f docker-compose.internal.dev.yml exec n8n sh

# Enter PostgreSQL
docker compose -f docker-compose.internal.dev.yml exec postgres psql -U n8n_user -d n8n
```

### External Mode

```bash
# Build (first time or after changes)
docker compose -f docker-compose.external.dev.yml build

# Start (Development)
docker compose -f docker-compose.external.dev.yml up -d

# Start (Production)
docker compose -f docker-compose.external.prod.yml up -d

# Stop
docker compose -f docker-compose.external.dev.yml down

# View logs
docker compose -f docker-compose.external.dev.yml logs -f n8n
docker compose -f docker-compose.external.dev.yml logs -f task-runners

# Update n8n and task runners
docker pull docker.n8n.io/n8nio/n8n:latest
docker pull docker.n8n.io/n8nio/runners:latest
docker compose -f docker-compose.external.dev.yml build task-runners --no-cache
docker compose -f docker-compose.external.dev.yml up -d

# Rebuild just task runners
docker compose -f docker-compose.external.dev.yml build task-runners
docker compose -f docker-compose.external.dev.yml restart task-runners

# Backup data
tar czf backup.tar.gz data/

# Enter n8n container
docker compose -f docker-compose.external.dev.yml exec n8n sh

# Enter task-runners container
docker compose -f docker-compose.external.dev.yml exec task-runners sh

# Enter PostgreSQL
docker compose -f docker-compose.external.dev.yml exec postgres psql -U n8n_user -d n8n

# Check task runner connection status
docker compose -f docker-compose.external.dev.yml logs task-runners | grep -i "connected\|error"

# View task runner configuration
docker compose -f docker-compose.external.dev.yml exec task-runners cat /etc/n8n-task-runners.json
```

### Switching Between Modes

```bash
# Stop current mode (example: internal dev)
docker compose -f docker-compose.internal.dev.yml down

# Start different mode (example: external dev)
docker compose -f docker-compose.external.dev.yml build
docker compose -f docker-compose.external.dev.yml up -d

# Data in ./data/ is shared between modes
```

## 🆘 Support

If you encounter issues:

1. Check the [Troubleshooting](#troubleshooting) section
2. Review the [n8n documentation](https://docs.n8n.io/)
3. Search the [n8n community forum](https://community.n8n.io/)
4. Check container logs: `docker compose logs`

## 📄 License

This setup configuration is provided as-is. n8n itself is licensed under the [Sustainable Use License](https://docs.n8n.io/sustainable-use-license/).

---

**Happy Automating! 🚀**
