# n8n Task Runner Modes - Detailed Comparison

## Executive Summary

This repository provides **4 configurations** across **2 task runner modes**:

| Configuration | File | Best For |
|--------------|------|----------|
| **Internal Dev** | `docker-compose.internal.dev.yml` | Development, testing, learning n8n |
| **Internal Prod** | `docker-compose.internal.prod.yml` | Production (most use cases) |
| **External Dev** | `docker-compose.external.dev.yml` | Testing external mode, advanced development |
| **External Prod** | `docker-compose.external.prod.yml` | High-security/high-scale production |

---

## Mode Comparison Matrix

### Architecture

| Aspect | Internal Mode | External Mode |
|--------|---------------|---------------|
| **Container Count** | 2 (n8n + postgres) | 3 (n8n + task-runners + postgres) |
| **Task Runner Location** | Inside n8n container (child processes) | Separate sidecar container |
| **Isolation Level** | Process-level | Container-level |
| **Communication** | IPC (Inter-Process Communication) | WebSocket (port 5679) |
| **Docker Image** | `n8nio/n8n` (extended) | `n8nio/n8n` + `n8nio/runners` (placeholder) |
| **Network Overhead** | None (same process space) | Minimal (localhost WebSocket) |

### Configuration

| Aspect | Internal Mode | External Mode |
|--------|---------------|---------------|
| **Dockerfile** | `Dockerfile.runners.internal` | `Dockerfile.runners.external` |
| **Compose File (Dev)** | `docker-compose.internal.dev.yml` | `docker-compose.external.dev.yml` |
| **Compose File (Prod)** | `docker-compose.internal.prod.yml` | `docker-compose.external.prod.yml` |
| **Environment File (Dev)** | `.env.development` | `.env.external.development` |
| **Environment File (Prod)** | `.env.production` | `.env.external.production` |
| **Package Allowlist** | `NODE_FUNCTION_ALLOW_EXTERNAL` env var | Environment variables |
| **Authentication** | Not required (same container) | Required (`N8N_RUNNERS_AUTH_TOKEN`) |
| **Setup Complexity** | ✅ Simple (5 env vars) | ⚠️ Moderate (8+ env vars) |
| **Image Customization** | Full (custom Dockerfile) | Limited (official image) |

### Resource Management

| Aspect | Internal Mode | External Mode |
|--------|---------------|---------------|
| **Memory Usage** | Shared with n8n | Dedicated allocation |
| **CPU Usage** | Shared with n8n | Dedicated allocation |
| **Resource Limits** | Single limit for n8n | Separate limits for n8n and runners |
| **Scaling** | Scale entire n8n container | Scale runners independently |
| **Typical RAM (Dev)** | ~500MB (n8n) | ~300MB (n8n) + ~200MB (runners) |
| **Typical RAM (Prod)** | 1-2GB (n8n) | 1-2GB (n8n) + 0.5-1GB (runners) |

### Security

| Aspect | Internal Mode | External Mode |
|--------|---------------|---------------|
| **Code Isolation** | Process sandbox (RestrictedPython) | Container + Process sandbox |
| **Network Isolation** | Same container | Separate containers |
| **Security Level** | ✅ Good | ✅✅ Better |
| **Attack Surface** | Single container | Reduced (runners isolated) |
| **Blast Radius** | Affects n8n | Limited to runners container |

### Performance

| Aspect | Internal Mode | External Mode |
|--------|---------------|---------------|
| **Code Execution Speed** | ✅ Fast (no network) | ✅ Fast (minimal WS latency) |
| **Startup Time** | ✅ Fast (single container) | ⚠️ Slower (multi-container) |
| **Resource Efficiency** | ✅ Better (shared memory) | ⚠️ Good (separate overhead) |
| **Throughput** | High | Very High (independent scaling) |

### Operations

| Aspect | Internal Mode | External Mode |
|--------|---------------|---------------|
| **Build Time** | Fast (single image) | Slower (two images) |
| **Debugging** | ✅ Simple (one container) | ⚠️ Moderate (check both containers) |
| **Log Inspection** | Single log stream | Multiple log streams |
| **Health Monitoring** | Monitor n8n only | Monitor n8n + runners |
| **Package Updates** | Rebuild n8n image | Rebuild runners image |
| **Deployment** | ✅ Simple | ⚠️ Coordinate two services |

### Reliability

| Aspect | Internal Mode | External Mode |
|--------|---------------|---------------|
| **Single Point of Failure** | n8n container | n8n OR runners can fail independently |
| **Restart Impact** | Full n8n restart | Can restart runners without n8n downtime |
| **Crash Recovery** | Restart entire n8n | Runners auto-restart, n8n unaffected |
| **Resilience** | Good | ✅ Better |

---

## Environment Variables Comparison

### Common Variables (Both Modes)

```env
# Core n8n
N8N_HOST=localhost
N8N_PORT=5678
N8N_PROTOCOL=http
WEBHOOK_URL=http://localhost:5678
N8N_ENCRYPTION_KEY=<generated-key>

# Timezone
GENERIC_TIMEZONE=America/New_York
TZ=America/New_York

# Database
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=postgres
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n_user
DB_POSTGRESDB_PASSWORD=<password>
DB_POSTGRESDB_SCHEMA=public

# Task Runners (base)
N8N_RUNNERS_ENABLED=true
```

### Internal Mode Only

```env
# Simple mode configuration
N8N_RUNNERS_MODE=internal

# Package allowlist (comma-separated)
NODE_FUNCTION_ALLOW_EXTERNAL=axios,lodash,moment,uuid,csv-parse,csv-stringify
```

**Total unique env vars:** ~3

### External Mode Additional Variables

```env
# External mode configuration
N8N_RUNNERS_MODE=external
N8N_RUNNERS_BROKER_LISTEN_ADDRESS=0.0.0.0
N8N_RUNNERS_AUTH_TOKEN=<generated-token>
N8N_NATIVE_PYTHON_RUNNER=true

# Task runner connection
N8N_RUNNERS_TASK_BROKER_URI=http://n8n-external-dev:5679
N8N_RUNNERS_AUTO_SHUTDOWN_TIMEOUT=15
```

**Total unique env vars:** ~7 additional

**Plus** requires `n8n-task-runners.json` configuration file.

---

## File Size Comparison

| Component | Internal Mode | External Mode |
|-----------|---------------|---------------|
| **Dockerfile** | ~1.5KB | ~2KB |
| **Docker Compose** | ~3KB | ~4KB |
| **Environment File** | ~1.5KB | ~2KB |
| **Configuration JSON** | N/A | ~1KB |
| **Total Config** | ~6KB | ~9KB |

---

## Use Case Recommendations

### Choose Internal Mode When:

✅ You're **getting started** with n8n
✅ Running in **development** environment
✅ Running **small to medium** production workloads
✅ **Resource efficiency** is important
✅ You want **simple maintenance** and debugging
✅ You're running on **limited hardware** (e.g., Raspberry Pi)
✅ You don't need independent runner scaling
✅ Process-level isolation is sufficient for your security needs

**Example scenarios:**
- Personal automation workflows
- Small team (< 10 users)
- Prototyping and testing
- Resource-constrained environments
- Simple CI/CD pipelines

### Choose External Mode When:

✅ Running **high-scale production** workloads
✅ **Maximum security** isolation is required
✅ You need to **scale code execution** independently from n8n
✅ You want **dedicated resource limits** for runners
✅ You're running **untrusted user code**
✅ You need **high availability** for code execution
✅ Container-level isolation is required for compliance
✅ The official `n8nio/runners` image is available

**Example scenarios:**
- Multi-tenant n8n deployments
- Enterprise production environments
- Handling sensitive data with strict isolation
- Large teams (> 50 users)
- Heavy code execution workloads
- Regulatory compliance requirements

---

## Migration Path

### From No Task Runners → Internal Mode

**Effort:** ⭐ (Very Easy)
**Time:** 5 minutes

```bash
# Update environment
echo "N8N_RUNNERS_ENABLED=true" >> .env.development
echo "N8N_RUNNERS_MODE=internal" >> .env.development

# Rebuild and restart
docker compose -f docker-compose.internal.dev.yml build
docker compose -f docker-compose.internal.dev.yml up -d
```

### From Internal → External Mode

**Effort:** ⭐⭐⭐ (Moderate)
**Time:** 15-20 minutes

```bash
# Stop internal mode
docker compose -f docker-compose.internal.dev.yml down

# Configure external environment
cp .env.external.development.example .env.external.development
# Edit and add N8N_RUNNERS_AUTH_TOKEN

# Build and start external mode
docker compose -f docker-compose.external.dev.yml build
docker compose -f docker-compose.external.dev.yml up -d

# Data preserved in ./data/
```

### From External → Internal Mode

**Effort:** ⭐ (Very Easy)
**Time:** 5 minutes

```bash
# Stop external mode
docker compose -f docker-compose.external.dev.yml down

# Start internal mode (data preserved)
docker compose -f docker-compose.internal.dev.yml up -d
```

---

## Performance Benchmarks (Estimated)

Based on typical workloads:

### Code Execution Latency

| Metric | Internal Mode | External Mode | Winner |
|--------|---------------|---------------|--------|
| **First execution** | ~50ms | ~60ms | Internal |
| **Subsequent executions** | ~10ms | ~15ms | Internal |
| **Concurrent (10 workers)** | ~100ms | ~80ms | External |
| **Concurrent (100 workers)** | ~500ms | ~200ms | External |

### Resource Consumption

| Metric | Internal Mode | External Mode | Winner |
|--------|---------------|---------------|--------|
| **Idle RAM** | ~450MB | ~550MB | Internal |
| **Active RAM (light)** | ~600MB | ~700MB | Internal |
| **Active RAM (heavy)** | ~1.2GB | ~1.5GB | Internal |
| **CPU (idle)** | 0.5% | 0.7% | Internal |
| **CPU (active)** | 15-30% | 12-25% | External |

**Note:** External mode is more efficient under heavy concurrent loads due to better parallelization.

---

## Troubleshooting Decision Tree

```
Is your code execution failing?
│
├─ Are you using Internal Mode?
│  │
│  ├─ Check: Is N8N_RUNNERS_MODE=internal?
│  ├─ Check: Is package in NODE_FUNCTION_ALLOW_EXTERNAL?
│  └─ Check: docker compose logs n8n
│
└─ Are you using External Mode?
   │
   ├─ Check: Are both containers running? (docker compose ps)
   ├─ Check: Are runners connected? (logs task-runners | grep connected)
   ├─ Check: Do auth tokens match? (env | grep AUTH_TOKEN)
   ├─ Check: Is package in n8n-task-runners.json?
   └─ Check: docker compose logs task-runners
```

---

## Quick Command Reference

### Internal Mode

```bash
# Start
docker compose -f docker-compose.internal.dev.yml up -d

# Logs
docker compose -f docker-compose.internal.dev.yml logs -f n8n

# Rebuild after package changes
docker compose -f docker-compose.internal.dev.yml build n8n
docker compose -f docker-compose.internal.dev.yml restart n8n

# Stop
docker compose -f docker-compose.internal.dev.yml down
```

### External Mode

```bash
# Start
docker compose -f docker-compose.external.dev.yml up -d

# Logs
docker compose -f docker-compose.external.dev.yml logs -f n8n
docker compose -f docker-compose.external.dev.yml logs -f task-runners

# Rebuild after package changes
docker compose -f docker-compose.external.dev.yml build task-runners
docker compose -f docker-compose.external.dev.yml restart task-runners

# Check connection
docker compose -f docker-compose.external.dev.yml logs task-runners | grep -i connected

# Stop
docker compose -f docker-compose.external.dev.yml down
```

---

## Conclusion

### TL;DR Recommendation

- **90% of users** should use **Internal Mode**
- **10% with specific needs** (high security, high scale) should use **External Mode**

### When in Doubt

Start with **Internal Mode Development** (`docker-compose.internal.dev.yml`). You can always switch to external mode later if needed, and your data will be preserved.

---

**Need more details? See [SETUP.md](SETUP.md) for comprehensive setup guide.**
