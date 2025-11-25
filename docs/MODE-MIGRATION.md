# Mode Migration Guide

This guide helps you safely switch between different n8n modes (internal, external, queue) while managing your data correctly.

## 🎯 Overview

n8n supports three operational modes with different database requirements:
- **Internal Mode**: Single container with embedded task runners (see [PYTHON-SETUP.md](PYTHON-SETUP.md) for Python support) **Internal Mode**: Single container with embedded task runners
- **External Mode**: Separate task runner container for enhanced security
- **Queue Mode**: Distributed execution with Redis queue and worker processes

## ⚠️ Critical Warning: PostgreSQL Volume Conflicts

### The Problem

**Switching modes while reusing the same PostgreSQL data directory causes database initialization failures.**

#### Why This Happens

1. **Different Schema Requirements**: Each mode requires specific database tables and columns
2. **Initialization Timing**: n8n only creates mode-specific schema when it detects an **empty database**
3. **No Auto-Migration**: n8n cannot automatically migrate between mode schemas
4. **Shared Volume Issue**: All docker-compose files by default use `./data/postgres` directory

#### Example Scenario (What We Encountered)

```bash
# Day 1: Running internal mode successfully
docker compose -f docker-compose.internal.dev.yml up -d
# Database created at: ./data/postgres
# Schema: Standard n8n tables for single-instance mode

# Day 2: Switch to queue mode
docker compose -f docker-compose.internal.dev.yml down
docker compose -f docker-compose.queue.dev.yml up -d
# ❌ FAILS! Database exists but lacks queue-specific tables

# Error messages:
# - "role 'n8n_queue_dev' does not exist"
# - "There was an error initializing DB"
# - "Missing required column for queue mode"
```

### What Fails

When switching to queue mode with existing database:
- ✅ PostgreSQL container starts normally
- ❌ n8n main instance cannot initialize (missing queue tables)
- ❌ Workers cannot connect (missing worker management tables)
- ❌ Redis connections fail (missing queue configuration)

## ✅ Solutions

### Solution 1: Fresh Database (Testing/Development)

**Best for**: Development, testing, or when you can afford to lose existing data.

⚠️ **WARNING**: This deletes ALL your workflows, credentials, and execution history!

```bash
# Step 1: Stop current mode
docker compose -f docker-compose.internal.dev.yml down

# Step 2: BACKUP EVERYTHING (Do not skip!)
tar czf backup_$(date +%Y%m%d_%H%M%S).tar.gz data/

# Step 3: Remove PostgreSQL volume
rm -rf data/postgres/

# Step 4: Start new mode with fresh database
docker compose -f docker-compose.queue.dev.yml up -d

# Step 5: Verify initialization
docker compose -f docker-compose.queue.dev.yml logs -f n8n-main
# Look for: "Database migrations completed successfully"
```

### Solution 2: Separate Volumes Per Mode (Recommended)

**Best for**: Production, or when you need to switch modes frequently without data loss.

#### Implementation

**Option A: Manual Directory Structure**

```bash
# Create mode-specific directories
mkdir -p data/postgres-internal
mkdir -p data/postgres-external  
mkdir -p data/postgres-queue

# Modify each docker-compose file
# In docker-compose.internal.dev.yml:
volumes:
  - ./data/postgres-internal:/var/lib/postgresql/data

# In docker-compose.external.dev.yml:
volumes:
  - ./data/postgres-external:/var/lib/postgresql/data

# In docker-compose.queue.dev.yml:
volumes:
  - ./data/postgres-queue:/var/lib/postgresql/data
```

**Option B: Environment Variable Pattern**

Create a `.env.local` file (not tracked in git):

```env
# .env.local
POSTGRES_DATA_PATH=./data/postgres-internal
```

Then in docker-compose files:

```yaml
volumes:
  - ${POSTGRES_DATA_PATH:-./data/postgres}:/var/lib/postgresql/data
```

Switch modes by changing the env var:

```bash
# Use internal mode
echo "POSTGRES_DATA_PATH=./data/postgres-internal" > .env.local
docker compose -f docker-compose.internal.dev.yml up -d

# Switch to queue mode
echo "POSTGRES_DATA_PATH=./data/postgres-queue" > .env.local
docker compose -f docker-compose.queue.dev.yml up -d
```

### Solution 3: Data Export/Import (Preserve Content)

**Best for**: When you need to migrate workflows and credentials to a new mode.

**Limitations**: 
- ❌ Execution history cannot be migrated
- ❌ Some credentials may need reconfiguration
- ✅ Workflows are fully preserved
- ✅ Connections and settings preserved

```bash
# Step 1: Export from current mode
# In n8n UI: Settings → Export Data
# Download: workflows.json, credentials.json

# Step 2: Stop current mode
docker compose -f docker-compose.internal.dev.yml down

# Step 3: Backup and clear database
tar czf backup_$(date +%Y%m%d_%H%M%S).tar.gz data/
rm -rf data/postgres/

# Step 4: Start new mode
docker compose -f docker-compose.queue.dev.yml up -d

# Step 5: Import data
# In n8n UI: Settings → Import Data
# Upload: workflows.json, credentials.json
```

## 🔄 Migration Scenarios

### Scenario 1: Internal → Queue Mode

**Use Case**: You started with internal mode and need horizontal scaling.

```bash
# Current: docker-compose.internal.dev.yml
# Target: docker-compose.queue.dev.yml

# Choose your approach:
# A) Fresh start (lose data):
docker compose -f docker-compose.internal.dev.yml down
rm -rf data/postgres/
docker compose -f docker-compose.queue.dev.yml up -d

# B) Keep both (recommended):
# Edit docker-compose.queue.dev.yml:
# Change: ./data/postgres → ./data/postgres-queue
docker compose -f docker-compose.queue.dev.yml up -d
```

### Scenario 2: External → Queue Mode

**Use Case**: You want to add horizontal scaling to your security-focused setup.

**Future Enhancement**: Queue + External mode (not in default configs yet)

```bash
# This combination requires custom docker-compose file
# that combines:
# - Queue mode architecture (main + workers + Redis)
# - External task runners (separate runner container)

# Manual steps:
# 1. Copy docker-compose.queue.dev.yml
# 2. Add task-runners service from docker-compose.external.dev.yml
# 3. Configure all workers to use external runners
# 4. Use separate PostgreSQL volume
```

### Scenario 3: Queue → Internal Mode

**Use Case**: Downscaling from queue mode back to simpler setup.

```bash
# Export data from queue mode first (if needed)
# Then:
docker compose -f docker-compose.queue.dev.yml down
rm -rf data/postgres-queue/  # or data/postgres if not separated
docker compose -f docker-compose.internal.dev.yml up -d
# Import data if exported
```

## 📋 Pre-Migration Checklist

Before switching modes:

- [ ] **Backup data directory**: `tar czf backup.tar.gz data/`
- [ ] **Export workflows**: Download from n8n UI
- [ ] **Export credentials**: Download from n8n UI (if possible)
- [ ] **Document active workflows**: Take screenshots of critical workflows
- [ ] **Note webhook URLs**: Save external webhook URLs
- [ ] **Check integrations**: List all external integrations
- [ ] **Stop all executions**: Ensure no workflows are running
- [ ] **Verify backup**: Check backup file was created successfully

## 🛡️ Safety Best Practices

1. **Never delete `data/` without backup**
   ```bash
   # Always backup first
   tar czf backup_$(date +%Y%m%d_%H%M%S).tar.gz data/
   ```

2. **Test migrations in development first**
   - Set up dev environment
   - Practice the migration
   - Verify everything works
   - Then migrate production

3. **Use separate volumes per mode**
   - Prevents accidental data conflicts
   - Allows easy mode switching
   - Keeps each mode's state isolated

4. **Document your mode choice**
   - Create a `DEPLOYMENT.md` file
   - Note which mode you're using
   - Document any customizations

5. **Version control your compose files**
   - Keep modified compose files in git
   - Tag each configuration version
   - Document why each mode was chosen

## 🔍 Troubleshooting Migration Issues

### Issue: "Role does not exist" Error

```
FATAL:  role "n8n_queue_dev" does not exist
```

**Cause**: Database was initialized with different credentials.

**Fix**:
```bash
docker compose down
rm -rf data/postgres/
docker compose up -d
```

### Issue: Database Initialization Hangs

**Cause**: Port conflict or permission issues.

**Fix**:
```bash
# Check port availability
lsof -i :5432

# Fix permissions
sudo chown -R $(id -u):$(id -g) data/

# Clear everything and restart
docker compose down
rm -rf data/postgres/
docker compose up -d
```

### Issue: Missing Queue-Specific Tables

**Cause**: Reusing non-queue database for queue mode.

**Fix**: Use Solution 1 (fresh database) or Solution 2 (separate volumes).

### Issue: Workers Can't Connect

**Symptoms**:
```
Worker failed to connect to Redis
Worker cannot find queue configuration
```

**Fix**:
1. Verify Redis is running: `docker compose ps redis`
2. Check encryption key matches across main and workers
3. Verify network connectivity: `docker compose logs redis`
4. Ensure fresh database with queue schema

## 📚 Additional Resources

- [README.md](../README.md) - Main setup guide
- [SETUP.md](SETUP.md) - Comprehensive setup instructions
- [COMPARISON.md](COMPARISON.md) - Mode comparison details
- [CHANGELOG.md](../CHANGELOG.md) - Version history and changes

## 🆘 Getting Help

If you encounter issues during migration:

1. Check logs: `docker compose logs -f`
2. Verify environment files match your mode
3. Ensure database is fresh or using correct volume
4. Review this guide's troubleshooting section
5. Search [n8n community forum](https://community.n8n.io/)
6. Check [n8n documentation](https://docs.n8n.io/)

---

**Remember**: Always backup before making changes! 🔐
