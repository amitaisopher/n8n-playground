# n8n Self-Hosted Setup - Complete Overview

## 📂 Repository Structure

```
n8n-playground/
├── 📘 Documentation
│   ├── README.md                          # Main documentation with setup instructions
│   ├── CHANGELOG.md                       # Version history and changes
│   └── docs/                              # Additional documentation
│       ├── OVERVIEW.md                    # This file - Visual overview
│       ├── SETUP.md                       # Comprehensive setup guide & decision matrix
│       ├── COMPARISON.md                  # Detailed mode comparison & benchmarks
│       └── AGENTS.md                      # AI assistant configuration template
│
├── 🐳 Docker Configurations
│   ├── docker-compose.internal.dev.yml   # Internal mode - Development
│   ├── docker-compose.internal.prod.yml  # Internal mode - Production
│   ├── docker-compose.external.dev.yml   # External mode - Development
│   └── docker-compose.external.prod.yml  # External mode - Production
│
├── 🏗️ Docker Images
│   ├── Dockerfile.runners.internal       # Internal: n8n + embedded runners
│   └── Dockerfile.runners.external       # External: separate task runner container
│
├── ⚙️ Configuration Files
│   ├── .env.development                  # Internal mode dev environment
│   ├── .env.production                   # Internal mode prod environment
│   ├── .env.external.development         # External mode dev environment
│   ├── .env.external.production          # External mode prod environment
│   ├── .env.example                      # Example with all variables
│   ├── n8n-task-runners.json            # Task runner package allowlist (external mode)
│   └── .gitignore                        # Git ignore patterns
│
└── 💾 Data (created on first run)
    └── data/
        ├── n8n/                          # Workflows, credentials, settings
        └── postgres/                     # Database files
```

---

## 🎯 Four Configurations Explained

### 1️⃣ Internal Mode - Development
**File:** `docker-compose.internal.dev.yml`
**Environment:** `.env.development`
**Use for:** Learning n8n, prototyping, development

```
┌─────────────────────────────┐
│   n8n-internal-dev          │
│  ┌─────────────────────┐   │
│  │  n8n Main           │   │
│  │  Task Broker        │   │
│  └─────────┬───────────┘   │
│            │                │
│     ┌──────┴──────┐        │
│     │             │        │
│  ┌──▼───┐    ┌───▼──┐     │
│  │ JS   │    │Python│     │
│  │Runner│    │Runner│     │
│  └──────┘    └──────┘     │
└─────────────────────────────┘
         +
┌─────────────────┐
│ n8n-postgres    │
│ (PostgreSQL 16) │
└─────────────────┘
```

**Characteristics:**
- 2 containers (n8n + postgres)
- Task runners embedded in n8n
- PostgreSQL port 5432 exposed for debugging
- Simple configuration (~5 env vars)
- Best for: Development, testing

---

### 2️⃣ Internal Mode - Production
**File:** `docker-compose.internal.prod.yml`
**Environment:** `.env.production`
**Use for:** Most production deployments

```
┌─────────────────────────────┐
│   n8n-internal-prod         │
│  (2 CPU / 2GB RAM limits)   │
│  ┌─────────────────────┐   │
│  │  n8n Main           │   │
│  │  Task Broker        │   │
│  └─────────┬───────────┘   │
│            │                │
│     ┌──────┴──────┐        │
│     │             │        │
│  ┌──▼───┐    ┌───▼──┐     │
│  │ JS   │    │Python│     │
│  │Runner│    │Runner│     │
│  └──────┘    └──────┘     │
└─────────────────────────────┘
         +
┌─────────────────────────────┐
│ n8n-postgres-internal-prod  │
│ (1 CPU / 1GB RAM limits)    │
│ NO exposed ports            │
└─────────────────────────────┘
```

**Characteristics:**
- 2 containers with resource limits
- PostgreSQL not exposed (security)
- Production encryption keys required
- Best for: Most production use cases

---

### 3️⃣ External Mode - Development
**File:** `docker-compose.external.dev.yml`
**Environment:** `.env.external.development`
**Use for:** Testing external mode, advanced development

```
┌─────────────────┐       ┌──────────────────────┐
│ n8n-external-   │◄─────►│ n8n-runners-external-│
│ dev             │  WS   │ dev                  │
│                 │ 5679  │  ┌────────────────┐  │
│ Task Broker     │       │  │ JS Runner      │  │
│                 │       │  └────────────────┘  │
│                 │       │  ┌────────────────┐  │
│                 │       │  │ Python Runner  │  │
│                 │       │  └────────────────┘  │
└─────────────────┘       └──────────────────────┘
         +
┌─────────────────┐
│ n8n-postgres    │
│ (PostgreSQL 16) │
└─────────────────┘
```

**Characteristics:**
- 3 containers (n8n + task-runners + postgres)
- Separate task runner container
- WebSocket communication on port 5679
- Requires authentication token
- Configuration via `n8n-task-runners.json`
- PostgreSQL port 5432 exposed for debugging
- Best for: Testing external mode, advanced scenarios

---

### 4️⃣ External Mode - Production
**File:** `docker-compose.external.prod.yml`
**Environment:** `.env.external.production`
**Use for:** High-security/high-scale production

```
┌──────────────────┐       ┌───────────────────────┐
│ n8n-external-    │◄─────►│ n8n-runners-external- │
│ prod             │  WS   │ prod                  │
│ (2 CPU / 2GB)    │ 5679  │ (1 CPU / 1GB limits)  │
│                  │       │  ┌────────────────┐   │
│ Task Broker      │       │  │ JS Runner      │   │
│                  │       │  └────────────────┘   │
│                  │       │  ┌────────────────┐   │
│                  │       │  │ Python Runner  │   │
│                  │       │  └────────────────┘   │
└──────────────────┘       └───────────────────────┘
         +
┌──────────────────────────┐
│ n8n-postgres-external-   │
│ prod                     │
│ (1 CPU / 1GB limits)     │
│ NO exposed ports         │
└──────────────────────────┘
```

**Characteristics:**
- 3 containers with dedicated resource limits
- Maximum isolation (container-level)
- Independent scaling possible
- Separate authentication token
- PostgreSQL not exposed
- Best for: Enterprise, high-security, high-scale

---

## 📋 Quick Start Cheat Sheet

### Choose Your Path

```
Are you new to n8n?
└─ YES → Use Configuration 1 (Internal Dev)
   │
   └─ Start here:
      docker compose -f docker-compose.internal.dev.yml up -d

Are you deploying to production?
└─ YES → Answer: Do you need maximum isolation?
   │
   ├─ NO → Use Configuration 2 (Internal Prod)
   │  │
   │  └─ Start here:
   │     docker compose -f docker-compose.internal.prod.yml up -d
   │
   └─ YES → Use Configuration 4 (External Prod)
      │
      └─ Start here:
         docker compose -f docker-compose.external.prod.yml up -d
```

---

## 🔑 Required Configuration Per Mode

### Internal Mode (Configurations 1 & 2)

**Minimum required in `.env.development` or `.env.production`:**
```env
N8N_ENCRYPTION_KEY=<openssl rand -hex 32>
DB_POSTGRESDB_PASSWORD=<strong-password>
N8N_RUNNERS_ENABLED=true
N8N_RUNNERS_MODE=internal
NODE_FUNCTION_ALLOW_EXTERNAL=axios,lodash,moment
```

### External Mode (Configurations 3 & 4)

**Minimum required in `.env.external.development` or `.env.external.production`:**
```env
N8N_ENCRYPTION_KEY=<openssl rand -hex 32>
DB_POSTGRESDB_PASSWORD=<strong-password>
N8N_RUNNERS_ENABLED=true
N8N_RUNNERS_MODE=external
N8N_RUNNERS_AUTH_TOKEN=<openssl rand -hex 32>
N8N_RUNNERS_BROKER_LISTEN_ADDRESS=0.0.0.0
N8N_RUNNERS_TASK_BROKER_URI=http://n8n-external-dev:5679
```

**Plus:** Edit `n8n-task-runners.json` with package allowlist

---

## 📦 Pre-installed Packages

Available in **all configurations**:

### Python
- `httpx` - HTTP client (use `.Client()` not `.AsyncClient()`)
- `beautifulsoup4` - Web scraping
- `lxml` - XML/HTML parsing
- `openpyxl` - Excel files
- `python-dateutil` - Date utilities
- `pytz` - Timezone support

### Node.js
- `axios` - HTTP client
- `lodash` - Utility functions
- `moment` - Date/time manipulation
- `uuid` - UUID generation
- `csv-parse` - CSV parsing
- `csv-stringify` - CSV writing

---

## 🚀 Common Commands

### Starting

```bash
# Internal Development
docker compose -f docker-compose.internal.dev.yml up -d

# Internal Production
docker compose -f docker-compose.internal.prod.yml up -d

# External Development
docker compose -f docker-compose.external.dev.yml up -d

# External Production
docker compose -f docker-compose.external.prod.yml up -d
```

### Stopping

```bash
# Replace filename with your configuration
docker compose -f docker-compose.internal.dev.yml down
```

### Viewing Logs

```bash
# Internal mode
docker compose -f docker-compose.internal.dev.yml logs -f n8n

# External mode (check both)
docker compose -f docker-compose.external.dev.yml logs -f n8n
docker compose -f docker-compose.external.dev.yml logs -f task-runners
```

### Adding Packages

**Internal Mode:**
1. Edit `Dockerfile.runners.internal`
2. Update `NODE_FUNCTION_ALLOW_EXTERNAL` in env file
3. Rebuild: `docker compose -f docker-compose.internal.dev.yml build n8n`
4. Restart: `docker compose -f docker-compose.internal.dev.yml up -d`

**External Mode:**
1. Edit `Dockerfile.runners.external`
2. Update `n8n-task-runners.json`
3. Rebuild: `docker compose -f docker-compose.external.dev.yml build task-runners`
4. Restart: `docker compose -f docker-compose.external.dev.yml restart task-runners`

---

## 🔀 Switching Between Configurations

Your data in `./data/` is shared across all configurations. You can switch modes anytime:

```bash
# Stop current mode
docker compose -f docker-compose.internal.dev.yml down

# Start different mode
docker compose -f docker-compose.external.dev.yml up -d

# Your workflows and credentials are preserved!
```

---

## 📊 Recommendation Summary

| Your Situation | Recommended Configuration | File |
|----------------|--------------------------|------|
| 🎓 Learning n8n | Internal Dev | `docker-compose.internal.dev.yml` |
| 💻 Local development | Internal Dev | `docker-compose.internal.dev.yml` |
| 🏢 Small team production | Internal Prod | `docker-compose.internal.prod.yml` |
| 🏭 Medium business | Internal Prod | `docker-compose.internal.prod.yml` |
| 🏛️ Enterprise (standard) | Internal Prod | `docker-compose.internal.prod.yml` |
| 🔒 High security requirements | External Prod | `docker-compose.external.prod.yml` |
| 📈 Very high scale | External Prod | `docker-compose.external.prod.yml` |
| 🧪 Testing external mode | External Dev | `docker-compose.external.dev.yml` |

**Rule of thumb:** 90% of users should use **Internal Mode**.

---

## 📚 Documentation Guide

| Document | Location | Purpose | Read When |
|----------|----------|---------|-----------|
| **README.md** | Root | Main setup instructions | Starting setup |
| **OVERVIEW.md** (this file) | docs/ | Visual structure overview | Getting oriented |
| **SETUP.md** | docs/ | Comprehensive guide with decision matrix | Choosing configuration |
| **COMPARISON.md** | docs/ | Detailed technical comparison | Need deep understanding |
| **CHANGELOG.md** | Root | Version history | Upgrading or reviewing changes |

---

## ⚠️ Important Notes

### Python Async Limitation

❌ **This will NOT work:**
```python
import httpx
async with httpx.AsyncClient() as client:
    result = await client.get('https://api.example.com')
```

✅ **Use synchronous code:**
```python
import httpx
with httpx.Client() as client:
    result = client.get('https://api.example.com')
```

**Reason:** Task runners use RestrictedPython which blocks `asyncio` for security.

### External Mode Image Availability

The official `n8nio/runners` image may not be publicly available yet. Current `Dockerfile.runners.external` uses `n8nio/n8n` as a placeholder. Update the Dockerfile when the official image is released.

---

## 🆘 Quick Troubleshooting

**Code execution error "Blocked for security reasons":**
- Internal: Check `N8N_RUNNERS_MODE=internal` and `NODE_FUNCTION_ALLOW_EXTERNAL`
- External: Check task-runners container is running and auth token matches

**Module not found:**
- Internal: Add to `NODE_FUNCTION_ALLOW_EXTERNAL` and rebuild n8n
- External: Add to `n8n-task-runners.json` and rebuild task-runners

**Can't connect to database:**
- Check postgres container is healthy: `docker compose ps`
- Verify `DB_POSTGRESDB_PASSWORD` matches in environment

**External mode runners won't connect:**
- Check `N8N_RUNNERS_AUTH_TOKEN` matches in both containers
- Verify `N8N_RUNNERS_TASK_BROKER_URI` points to correct container
- Check logs: `docker compose logs task-runners`

---

## ✅ Post-Setup Checklist

After running your chosen configuration:

- [ ] All containers are running (`docker compose ps`)
- [ ] No errors in logs (`docker compose logs`)
- [ ] Can access n8n at http://localhost:5678
- [ ] Created owner account in n8n
- [ ] Tested Python Code node with `import httpx`
- [ ] Tested JavaScript Code node with `const axios = require('axios')`
- [ ] External mode: Verified runners connected
- [ ] Configured automated backups

---

**You're all set! Start building workflows! 🎉**

For detailed information, see:
- **[README.md](../README.md)** - Setup instructions
- **[SETUP.md](SETUP.md)** - Comprehensive guide
- **[COMPARISON.md](COMPARISON.md)** - Technical comparison
