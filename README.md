# Self-Hosted n8n Server

A complete Docker-based setup for running a self-hosted n8n workflow automation platform with PostgreSQL database, organized for both development and production environments.

## 📋 Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Environment Configuration](#environment-configuration)
- [Running the Server](#running-the-server)
- [Accessing n8n](#accessing-n8n)
- [Data Persistence](#data-persistence)
- [Updating n8n](#updating-n8n)
- [Backup and Restore](#backup-and-restore)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)
- [Additional Resources](#additional-resources)

## 🌟 Overview

This project provides a production-ready setup for running n8n with:

- **PostgreSQL database** for reliable data persistence
- **Docker containerization** for easy deployment and isolation
- **Separate configurations** for development and production environments
- **Local directory volumes** for persistent data storage (easy to backup)
- **Network isolation** with Docker networks
- **Environment-based configuration** using env files

## 📁 Project Structure

```
n8n-playground/
├── Dockerfile                  # Custom n8n image with Python & Node modules
├── docker-compose.dev.yml      # Complete development environment
├── docker-compose.prod.yml     # Complete production environment
├── .env.example                # Example environment variables
├── .env.development            # Development environment variables
├── .env.production             # Production environment variables
├── .gitignore                  # Git ignore patterns
├── data/                       # Data directory (created on first run)
│   ├── n8n/                    # n8n workflows, credentials, settings
│   └── postgres/               # PostgreSQL database files
├── CHANGELOG.md                # Project changelog
└── README.md                   # This file
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

## 🛠️ Custom Modules

This setup includes a custom Dockerfile that extends the official n8n image with pre-installed Python and Node.js modules for use in n8n Code nodes.

### Pre-installed Python Packages

- `requests` - HTTP library
- `pandas` - Data manipulation and analysis
- `numpy` - Numerical computing
- `beautifulsoup4` - Web scraping
- `lxml` - XML/HTML processing
- `openpyxl` - Excel file handling
- `python-dateutil` - Date/time utilities
- `pytz` - Timezone support

### Pre-installed Node.js Packages

- `axios` - HTTP client
- `lodash` - Utility functions
- `moment` - Date/time manipulation
- `uuid` - UUID generation
- `csv-parse` - CSV parsing
- `csv-stringify` - CSV generation

### Adding Custom Modules

To add more Python or Node.js packages:

1. **Edit the Dockerfile**:
   ```dockerfile
   # Add Python packages
   RUN pip3 install --no-cache-dir \
       your-package-name \
       another-package
   
   # Add Node.js packages
   RUN npm install -g \
       your-node-package \
       another-node-package
   ```

2. **Rebuild the image**:
   ```bash
   # Development
   docker compose -f docker-compose.dev.yml build
   
   # Production
   docker compose -f docker-compose.prod.yml build
   ```

3. **Restart the containers**:
   ```bash
   docker compose -f docker-compose.dev.yml up -d
   ```

### Using Modules in n8n

**Python Code Node**:
```python
import requests
import pandas as pd

# Your code here
response = requests.get('https://api.example.com/data')
df = pd.DataFrame(response.json())
return df.to_dict('records')
```

**JavaScript Code Node**:
```javascript
const axios = require('axios');
const _ = require('lodash');

// Your code here
const response = await axios.get('https://api.example.com/data');
const filtered = _.filter(response.data, { active: true });
return filtered;
```

## 🚀 Quick Start

### 1. Clone or Download

Clone this repository or download the files to your local machine.

### 2. Configure Environment Variables

**Important**: All environment variables are loaded from `.env.development` or `.env.production` files. You don't need to copy them to a `.env` file.

For **Development**:

```bash
# Edit the development environment file directly
nano .env.development  # or use your preferred editor

# Generate a secure encryption key (IMPORTANT!)
openssl rand -hex 32

# Replace the N8N_ENCRYPTION_KEY value in .env.development
```

For **Production**:

```bash
# Edit the production environment file directly
nano .env.production  # or use your preferred editor

# Generate a strong encryption key
openssl rand -hex 32

# Update ALL values in .env.production (especially passwords, encryption key, and domain)
```

### 3. Build and Start n8n

**Development environment**:

```bash
# Build the custom n8n image
docker compose -f docker-compose.dev.yml build

# Start all services
docker compose -f docker-compose.dev.yml up -d

# View logs
docker compose -f docker-compose.dev.yml logs -f
```

**Production environment**:

```bash
# Build the custom n8n image
docker compose -f docker-compose.prod.yml build

# Start all services
docker compose -f docker-compose.prod.yml up -d

# View logs
docker compose -f docker-compose.prod.yml logs -f
```

### 4. Access n8n

Open your browser and navigate to:

- **Development**: http://localhost:5678
- **Production**: https://your-domain.com (or http://localhost:5678 if testing locally)

## ⚙️ Environment Configuration

All environment variables are defined in:
- `.env.development` - For development environment
- `.env.production` - For production environment

These files are loaded automatically via the `env_file:` directive in the docker-compose override files.

### Essential Variables

You **must** configure these variables in your `.env.development` or `.env.production` file:

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

### Start the Server

**Development**:
```bash
docker compose -f docker-compose.dev.yml up -d
```

**Production**:
```bash
docker compose -f docker-compose.prod.yml up -d
```

### Stop the Server

```bash
# Stop development
docker compose -f docker-compose.dev.yml down

# Stop production
docker compose -f docker-compose.prod.yml down
```

### Restart the Server

```bash
# Restart development
docker compose -f docker-compose.dev.yml restart

# Restart production
docker compose -f docker-compose.prod.yml restart
```

### View Logs

```bash
# View all logs (development)
docker compose -f docker-compose.dev.yml logs -f

# View n8n logs only
docker compose -f docker-compose.dev.yml logs -f n8n

# View PostgreSQL logs only
docker compose -f docker-compose.dev.yml logs -f postgres
```

### Check Status

```bash
# Development
docker compose -f docker-compose.dev.yml ps

# Production
docker compose -f docker-compose.prod.yml ps
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

### 1. Backup Your Data (Recommended)

```bash
# Backup directories
tar czf n8n_backup_$(date +%Y%m%d).tar.gz data/

# Or use rsync
rsync -avz data/ backup/n8n_$(date +%Y%m%d)/
```

### 2. Pull Latest Base Image

```bash
docker pull docker.n8n.io/n8nio/n8n:latest
```

### 3. Rebuild Custom Image

```bash
# Development
docker compose -f docker-compose.dev.yml build --no-cache

# Production
docker compose -f docker-compose.prod.yml build --no-cache
```

### 4. Restart with New Image

```bash
# Development
docker compose -f docker-compose.dev.yml down
docker compose -f docker-compose.dev.yml up -d

# Production
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d
```

### 5. Verify Update

```bash
docker compose -f docker-compose.dev.yml logs n8n | grep version
```

## 🔄 Updating Custom Modules

To add, remove, or update Python/Node.js packages:

1. **Edit the Dockerfile** to modify the package lists

2. **Rebuild and restart**:
   ```bash
   docker compose -f docker-compose.dev.yml build
   docker compose -f docker-compose.dev.yml up -d
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
6. **Module not found in Code node**: Rebuild the image with `docker compose -f docker-compose.dev.yml build --no-cache`
7. **Python version issues**: Check version with `docker exec n8n-dev python --version`
8. **Node.js package issues**: List installed packages with `docker exec n8n-dev npm list -g --depth=0`

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

```bash
# Build (first time or after Dockerfile changes)
docker compose -f docker-compose.dev.yml build

# Start (Development)
docker compose -f docker-compose.dev.yml up -d

# Start (Production)
docker compose -f docker-compose.prod.yml up -d

# Stop (specify environment)
docker compose -f docker-compose.dev.yml down

# View logs (specify environment)
docker compose -f docker-compose.dev.yml logs -f

# Update (rebuild and restart)
docker pull docker.n8n.io/n8nio/n8n:latest
docker compose -f docker-compose.dev.yml build --no-cache
docker compose -f docker-compose.dev.yml up -d

# Backup data
tar czf backup.tar.gz data/

# Restore data
tar xzf backup.tar.gz

# Enter n8n container (development)
docker compose -f docker-compose.dev.yml exec n8n sh

# Enter PostgreSQL container (development)
docker compose -f docker-compose.dev.yml exec postgres psql -U n8n_user -d n8n
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
