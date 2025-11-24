# n8n Task Runner Setup Guide

## Overview

This repository provides **four complete Docker Compose configurations** for running self-hosted n8n with task runners:

1. **Internal Mode - Development** (`docker-compose.internal.dev.yml`)
2. **Internal Mode - Production** (`docker-compose.internal.prod.yml`)
3. **External Mode - Development** (`docker-compose.external.dev.yml`)
4. **External Mode - Production** (`docker-compose.external.prod.yml`)

Each configuration is fully independent and ready to use.

---

## 🎯 Choosing Your Configuration

### Decision Matrix

| Your Priority | Recommended Mode | File to Use |
|--------------|------------------|-------------|
| Quick setup, development | Internal | `docker-compose.internal.dev.yml` |
| Production, simple architecture | Internal | `docker-compose.internal.prod.yml` |
| Maximum security isolation | External | `docker-compose.external.prod.yml` |
| Testing external mode | External | `docker-compose.external.dev.yml` |
| Resource efficiency | Internal | Either internal file |
| Independent scaling | External | Either external file |

### Mode Comparison

#### Internal Mode ✅ **Recommended for Most Users**

**Architecture:** Task runners run as child processes inside the n8n container

**Pros:**
- ✅ Simple setup (single container for n8n)
- ✅ No network communication overhead
- ✅ Easier to debug and maintain
- ✅ Lower resource usage
- ✅ Works immediately (no external dependencies)

**Cons:**
- ⚠️ Shares resources with n8n main process
- ⚠️ Process-level isolation only

**Use When:**
- Getting started with n8n
- Running in development
- Running small-to-medium production workloads
- Resource efficiency is important
- You want simple maintenance

#### External Mode 🔐 **Advanced Users**

**Architecture:** Task runners run in a separate container (sidecar)

**Pros:**
- ✅ Container-level isolation (better security)
- ✅ Independent resource limits
- ✅ Can scale independently
- ✅ Recommended by n8n for production

**Cons:**
- ⚠️ More complex setup (two containers)
- ⚠️ Requires `n8nio/runners` image (may not be available yet)
- ⚠️ Additional network communication
- ⚠️ More configuration (auth tokens, broker URIs)

**Use When:**
- Running high-scale production workloads
- Maximum security is required
- You need to scale task execution independently
- You're comfortable with multi-container architectures
- The official `n8nio/runners` image is available

---

## 🚀 Quick Start

### Option 1: Internal Mode (Recommended)

#### Development

```bash
# 1. Configure environment
cp .env.development .env.development.local
nano .env.development.local

# Generate encryption key
openssl rand -hex 32

# Update N8N_ENCRYPTION_KEY in .env.development.local

# 2. Build and start
docker compose -f docker-compose.internal.dev.yml build
docker compose -f docker-compose.internal.dev.yml up -d

# 3. Check logs
docker compose -f docker-compose.internal.dev.yml logs -f

# 4. Access n8n at http://localhost:5678
```

#### Production

```bash
# 1. Configure environment
cp .env.production .env.production.local
nano .env.production.local

# Generate unique keys
openssl rand -hex 32  # For N8N_ENCRYPTION_KEY

# Update all production values (encryption key, passwords, domain)

# 2. Build and start
docker compose -f docker-compose.internal.prod.yml build
docker compose -f docker-compose.internal.prod.yml up -d

# 3. Monitor
docker compose -f docker-compose.internal.prod.yml logs -f
```

### Option 2: External Mode (Advanced)

#### Development

```bash
# 1. Configure environment
cp .env.external.development .env.external.development.local
nano .env.external.development.local

# Generate keys
openssl rand -hex 32  # For N8N_ENCRYPTION_KEY
openssl rand -hex 32  # For N8N_RUNNERS_AUTH_TOKEN

# Update both keys in .env.external.development.local

# 2. Build and start
docker compose -f docker-compose.external.dev.yml build
docker compose -f docker-compose.external.dev.yml up -d

# 3. Check both containers
docker compose -f docker-compose.external.dev.yml logs -f n8n
docker compose -f docker-compose.external.dev.yml logs -f task-runners

# 4. Verify connection
docker compose -f docker-compose.external.dev.yml logs task-runners | grep -i connected
```

#### Production

```bash
# 1. Configure environment
cp .env.external.production .env.external.production.local
nano .env.external.production.local

# Generate unique production keys
openssl rand -hex 32  # For N8N_ENCRYPTION_KEY
openssl rand -hex 32  # For N8N_RUNNERS_AUTH_TOKEN

# Update all production values

# 2. Build and start
docker compose -f docker-compose.external.prod.yml build
docker compose -f docker-compose.external.prod.yml up -d

# 3. Monitor both services
docker compose -f docker-compose.external.prod.yml logs -f
```

---

## 📂 File Structure Reference

### Docker Compose Files

| File | Purpose | Services | Environment File |
|------|---------|----------|------------------|
| `docker-compose.internal.dev.yml` | Internal dev | n8n, postgres | `.env.development` |
| `docker-compose.internal.prod.yml` | Internal prod | n8n, postgres | `.env.production` |
| `docker-compose.external.dev.yml` | External dev | n8n, task-runners, postgres | `.env.external.development` |
| `docker-compose.external.prod.yml` | External prod | n8n, task-runners, postgres | `.env.external.production` |

### Dockerfiles

| File | Used By | Purpose |
|------|---------|---------|
| `Dockerfile.runners.internal` | Internal mode | Extends n8n with embedded runners & packages |

### Configuration Files

| File | Used By | Purpose |
|------|---------|---------|
| `.env.development` | Internal dev | Environment variables |
| `.env.production` | Internal prod | Environment variables |
| `.env.external.development` | External dev | Environment variables |
| `.env.external.production` | External prod | Environment variables |

---

## 🔧 Configuration Details

### Internal Mode Environment Variables

Key differences in `.env.development` or `.env.production`:

```env
# Task runner mode
N8N_RUNNERS_ENABLED=true
N8N_RUNNERS_MODE=internal

# Package allowlist (simple)
NODE_FUNCTION_ALLOW_EXTERNAL=axios,lodash,moment,uuid,csv-parse,csv-stringify
```

### External Mode Environment Variables

Key additions in `.env.external.development` or `.env.external.production`:

```env
# Task runner mode
N8N_RUNNERS_ENABLED=true
N8N_RUNNERS_MODE=external

# External mode specific
N8N_RUNNERS_BROKER_LISTEN_ADDRESS=0.0.0.0
N8N_RUNNERS_AUTH_TOKEN=your-32-char-token-here
N8N_NATIVE_PYTHON_RUNNER=true
N8N_RUNNERS_TASK_BROKER_URI=http://n8n-external-dev:5679
N8N_RUNNERS_AUTO_SHUTDOWN_TIMEOUT=15
```

---

## 📦 Pre-installed Packages

Both modes include the same packages (configured differently):

### Python Packages
- `httpx` - HTTP client (use `.Client()` not `.AsyncClient()`)
- `beautifulsoup4` - Web scraping
- `lxml` - XML/HTML processing
- `openpyxl` - Excel files
- `python-dateutil` - Date utilities
- `pytz` - Timezone support

### Node.js Packages
- `axios` - HTTP client
- `lodash` - Utilities
- `moment` - Date/time
- `uuid` - UUID generation
- `csv-parse` - CSV parsing
- `csv-stringify` - CSV generation

---

## 🔄 Common Operations

### Adding Packages

#### Internal Mode

1. Edit `Dockerfile.runners.internal`:
   ```dockerfile
   RUN pip3 install --no-cache-dir --break-system-packages \
       your-package
   
   RUN npm install -g your-node-package
   ```

2. Update environment file:
   ```env
   NODE_FUNCTION_ALLOW_EXTERNAL=axios,lodash,your-new-package
   ```

3. Rebuild:
   ```bash
   docker compose -f docker-compose.internal.dev.yml build n8n
   docker compose -f docker-compose.internal.dev.yml up -d
   ```

#### External Mode

External mode uses the official `n8nio/runners` image with pre-installed packages. To use additional packages from the standard library or allowlist existing packages:

1. Update environment file (`.env.external.development` or `.env.external.production`):
   ```env
   NODE_FUNCTION_ALLOW_EXTERNAL=axios,lodash,moment,your-existing-package
   ```

2. Restart:
   ```bash
   docker compose -f docker-compose.external.dev.yml restart
   ```

**Note:** Custom package installation requires extending the official `n8nio/runners` image, which is not covered in this basic setup.

### Switching Modes

You can switch between modes at any time (data is shared):

```bash
# Stop internal mode
docker compose -f docker-compose.internal.dev.yml down

# Start external mode
docker compose -f docker-compose.external.dev.yml build
docker compose -f docker-compose.external.dev.yml up -d

# Your workflows, credentials, and data remain intact in ./data/
```

### Backup and Restore

```bash
# Backup (works for any mode)
tar czf backup_$(date +%Y%m%d).tar.gz data/

# Restore (works for any mode)
# Stop containers first
docker compose -f docker-compose.internal.dev.yml down
tar xzf backup_YYYYMMDD.tar.gz
docker compose -f docker-compose.internal.dev.yml up -d
```

---

## ⚠️ Important Limitations

### Python Async Not Supported

Task runners use RestrictedPython which **blocks `asyncio`**:

❌ **This will NOT work:**
```python
import httpx

async def fetch():
    async with httpx.AsyncClient() as client:
        return await client.get('https://api.example.com')
```

✅ **Use synchronous code instead:**
```python
import httpx

with httpx.Client() as client:
    response = client.get('https://api.example.com')
    return response.json()
```

### External Mode Configuration

External mode now uses the official `n8nio/runners` image:
- Development: `n8nio/runners:1.121.2` (pinned version)
- Production: `n8nio/runners:latest`

**Important configuration details:**

1. Broker URI must use `http://` protocol (not `ws://`):
   ```env
   N8N_RUNNERS_TASK_BROKER_URI=http://n8n-external-dev:5679
   ```

2. The `N8N_RUNNERS_TASK_BROKER_URI` variable should only be set in the runners container

3. Both containers must share the same authentication token:
   ```env
   N8N_RUNNERS_AUTH_TOKEN=<same-token-in-both-containers>
   ```

---

## 🐛 Troubleshooting

### Internal Mode Issues

**"Blocked for security reasons" error:**
```bash
# Check task runners are enabled
docker compose -f docker-compose.internal.dev.yml exec n8n env | grep RUNNERS

# Should show:
# N8N_RUNNERS_ENABLED=true
# N8N_RUNNERS_MODE=internal
```

**Module not found:**
```bash
# Check allowlist
docker compose -f docker-compose.internal.dev.yml exec n8n env | grep NODE_FUNCTION_ALLOW_EXTERNAL

# Rebuild after adding to allowlist
docker compose -f docker-compose.internal.dev.yml build n8n
docker compose -f docker-compose.internal.dev.yml up -d
```

### External Mode Issues

**Task runners won't connect:**
```bash
# Check logs
docker compose -f docker-compose.external.dev.yml logs task-runners

# Verify auth token matches in both containers
docker compose -f docker-compose.external.dev.yml exec n8n env | grep AUTH_TOKEN
docker compose -f docker-compose.external.dev.yml exec task-runners env | grep AUTH_TOKEN

# Check broker URI (must use http:// not ws://)
docker compose -f docker-compose.external.dev.yml exec task-runners env | grep BROKER_URI

# Verify connection
docker compose -f docker-compose.external.dev.yml logs task-runners | grep -i connected
docker compose -f docker-compose.external.dev.yml logs n8n | grep -i "registered runner"
```

**Module not found in external mode:**
```bash
# External mode uses official n8nio/runners image with pre-installed packages
# Check allowlist in environment
docker compose -f docker-compose.external.dev.yml exec task-runners env | grep ALLOW_EXTERNAL

# Update allowlist and restart
# Edit .env.external.development and add to NODE_FUNCTION_ALLOW_EXTERNAL
docker compose -f docker-compose.external.dev.yml restart
```

---

## 📊 Resource Requirements

### Internal Mode

**Development:**
- n8n: ~500MB RAM, shared CPU
- PostgreSQL: ~100MB RAM

**Production:**
- n8n: 1-2GB RAM, 1-2 CPUs (configured in compose file)
- PostgreSQL: 512MB-1GB RAM, 0.5-1 CPU

### External Mode

**Development:**
- n8n: ~300MB RAM, shared CPU
- Task runners: ~200MB RAM, shared CPU
- PostgreSQL: ~100MB RAM

**Production:**
- n8n: 1-2GB RAM, 1-2 CPUs (configured)
- Task runners: 512MB-1GB RAM, 0.5-1 CPU (configured)
- PostgreSQL: 512MB-1GB RAM, 0.5-1 CPU (configured)

---

## 🎓 Learning Path

### If You're New to n8n

1. Start with **Internal Mode Development**
2. Create simple workflows to understand n8n
3. Test Python/JavaScript Code nodes with pre-installed packages
4. Once comfortable, consider production deployment

### If You're Ready for Production

1. Choose mode based on your security/scaling needs
2. Use **Internal Mode Production** for most cases
3. Use **External Mode Production** if you need:
   - Maximum isolation
   - Independent scaling
   - Very high security requirements

---

## 📚 Additional Resources

- [n8n Documentation](https://docs.n8n.io/)
- [Task Runners Documentation](https://docs.n8n.io/hosting/configuration/task-runners/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [n8n Community Forum](https://community.n8n.io/)

---

## 🔐 Security Checklist

### Development

- [ ] Generated unique `N8N_ENCRYPTION_KEY`
- [ ] Used localhost for `N8N_HOST`
- [ ] PostgreSQL password set (even for dev)
- [ ] External mode: Generated `N8N_RUNNERS_AUTH_TOKEN`

### Production

- [ ] Generated **new** unique `N8N_ENCRYPTION_KEY` (different from dev!)
- [ ] Set production domain for `N8N_HOST`
- [ ] Changed `N8N_PROTOCOL=https`
- [ ] Strong PostgreSQL password
- [ ] External mode: Generated **new** unique `N8N_RUNNERS_AUTH_TOKEN`
- [ ] All environment files excluded from git (`.gitignore`)
- [ ] Automated backups configured
- [ ] SSL/TLS configured (reverse proxy)
- [ ] Firewall rules applied

---

## ✅ Post-Installation Checklist

After running `docker compose up -d`:

1. [ ] Check all containers are running: `docker compose ps`
2. [ ] Check logs for errors: `docker compose logs -f`
3. [ ] Access n8n UI: http://localhost:5678
4. [ ] Create owner account
5. [ ] Test Code node with Python:
   ```python
   import httpx
   with httpx.Client() as client:
       response = client.get('https://api.github.com')
       return {'status': response.status_code}
   ```
6. [ ] Test Code node with JavaScript:
   ```javascript
   const axios = require('axios');
   const response = await axios.get('https://api.github.com');
   return {status: response.status};
   ```
7. [ ] External mode only: Verify task runner connection:
   ```bash
   docker compose logs task-runners | grep -i connected
   ```
8. [ ] Set up automated backups

---

**You're all set! Choose your configuration and get started! 🚀**
