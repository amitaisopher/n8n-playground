# Production Deployment Guide - n8n with Nginx

This guide walks you through deploying n8n with nginx reverse proxy in a production environment.

## 📋 Pre-Deployment Checklist

Before deploying, ensure you have:

- [ ] Server with Docker and Docker Compose installed
- [ ] Domain name pointing to your server
- [ ] SSL certificate (or ability to generate with Let's Encrypt)
- [ ] Firewall configured (ports 80, 443 open)
- [ ] Backup strategy planned
- [ ] Monitoring solution ready
- [ ] At least 4GB RAM and 2 CPU cores
- [ ] Sufficient disk space (20GB+ recommended)

## 🚀 Quick Deployment

### Step 1: Configure Environment

```bash
# Copy production environment template
cp .env.external-nginx.production .env.external.production

# Edit with your values
nano .env.external.production
```

**Critical values to update:**
```bash
# Generate encryption key
openssl rand -hex 32

# Generate runner auth token
openssl rand -hex 32

# Update these in .env.external.production:
N8N_ENCRYPTION_KEY=<generated-key>
N8N_RUNNERS_AUTH_TOKEN=<generated-token>
DB_POSTGRESDB_PASSWORD=<strong-password>
N8N_HOST=yourdomain.com
WEBHOOK_URL=https://yourdomain.com/
```

### Step 2: Configure SSL Certificates

#### Option A: Let's Encrypt (Recommended)

```bash
# Install certbot
sudo apt update
sudo apt install certbot

# Stop nginx if running
docker compose -f docker-compose.external-nginx.prod.yml down

# Generate certificate
sudo certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com

# Copy certificates to nginx directory
sudo mkdir -p nginx/ssl
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem nginx/ssl/
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem nginx/ssl/
sudo cp /etc/letsencrypt/live/yourdomain.com/chain.pem nginx/ssl/

# Set permissions
sudo chown -R $(id -u):$(id -g) nginx/ssl
```

#### Option B: Custom Certificate

```bash
# Create ssl directory
mkdir -p nginx/ssl

# Copy your certificates
cp /path/to/fullchain.pem nginx/ssl/
cp /path/to/privkey.pem nginx/ssl/
cp /path/to/chain.pem nginx/ssl/
```

### Step 3: Update Nginx Configuration

```bash
# Edit nginx configuration
nano nginx/conf.d/n8n-prod.conf

# Replace 'yourdomain.com' with your actual domain
sed -i 's/yourdomain.com/your-actual-domain.com/g' nginx/conf.d/n8n-prod.conf
```

### Step 4: Deploy

```bash
# Build and start services
docker compose -f docker-compose.external-nginx.prod.yml up -d

# Verify all containers are running
docker compose -f docker-compose.external-nginx.prod.yml ps

# Check logs
docker compose -f docker-compose.external-nginx.prod.yml logs -f
```

### Step 5: Verify Deployment

```bash
# Test HTTP to HTTPS redirect
curl -I http://yourdomain.com

# Test HTTPS access
curl -I https://yourdomain.com

# Check SSL certificate
openssl s_client -connect yourdomain.com:443 -servername yourdomain.com

# Test n8n is responding
curl https://yourdomain.com/healthz
```

## 🔐 Security Configuration

### Firewall Setup

```bash
# Using UFW (Ubuntu)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Using firewalld (RHEL/CentOS)
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

### Enable Fail2Ban (Optional but Recommended)

```bash
# Install fail2ban
sudo apt install fail2ban

# Create n8n jail
sudo nano /etc/fail2ban/jail.d/n8n.conf
```

Add:
```ini
[n8n]
enabled = true
port = http,https
filter = n8n
logpath = /var/log/nginx/n8n-prod-access.log
maxretry = 5
bantime = 3600
```

### Add Basic Authentication (Optional)

```bash
# Install apache2-utils
sudo apt install apache2-utils

# Create password file
htpasswd -c nginx/.htpasswd admin

# Update nginx/conf.d/n8n-prod.conf
# Add inside 'location /' block:
auth_basic "n8n Access";
auth_basic_user_file /etc/nginx/.htpasswd;

# Mount in docker-compose.external-nginx.prod.yml:
volumes:
  - ./nginx/.htpasswd:/etc/nginx/.htpasswd:ro
```

## 📊 Resource Limits

The production compose file includes resource limits:

| Service | CPU Limit | Memory Limit | CPU Reserved | Memory Reserved |
|---------|-----------|--------------|--------------|-----------------|
| nginx | 0.5 cores | 512MB | 0.25 cores | 256MB |
| n8n | 2 cores | 2GB | 1 core | 1GB |
| task-runners | 1 core | 1GB | 0.5 cores | 512MB |
| postgres | 1 core | 1GB | 0.5 cores | 512MB |

**Total Requirements**: 4.5 CPU cores, 4.5GB RAM

Adjust in docker-compose if needed:
```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 2G
```

## 💾 Backup Strategy

### Automated Backup Script

Create `backup-n8n.sh`:

```bash
#!/bin/bash
# n8n Production Backup Script

BACKUP_DIR="/var/backups/n8n"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup PostgreSQL database
docker exec n8n-postgres-external-nginx-prod pg_dump \
  -U n8n_prod n8n_prod | gzip > "$BACKUP_DIR/n8n_db_$DATE.sql.gz"

# Backup n8n data directory
tar czf "$BACKUP_DIR/n8n_data_$DATE.tar.gz" ./data/n8n

# Backup environment file (securely)
gpg --encrypt --recipient your@email.com \
  .env.external.production > "$BACKUP_DIR/env_$DATE.gpg"

# Remove old backups
find "$BACKUP_DIR" -name "*.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "*.gpg" -mtime +$RETENTION_DAYS -delete

echo "Backup completed: $DATE"
```

Schedule with cron:
```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * /path/to/backup-n8n.sh >> /var/log/n8n-backup.log 2>&1
```

### Manual Backup

```bash
# Backup database
docker exec n8n-postgres-external-nginx-prod pg_dump \
  -U n8n_prod n8n_prod > n8n_backup_$(date +%Y%m%d).sql

# Backup n8n data
tar czf n8n_data_$(date +%Y%m%d).tar.gz ./data/n8n

# Backup encryption key (CRITICAL!)
echo "N8N_ENCRYPTION_KEY=your-key-here" > encryption_key_backup.txt
# Store this file securely offline!
```

### Restore from Backup

```bash
# Stop services
docker compose -f docker-compose.external-nginx.prod.yml down

# Restore database
cat n8n_backup_YYYYMMDD.sql | docker exec -i n8n-postgres-external-nginx-prod \
  psql -U n8n_prod n8n_prod

# Restore n8n data
tar xzf n8n_data_YYYYMMDD.tar.gz

# Restart services
docker compose -f docker-compose.external-nginx.prod.yml up -d
```

## 📈 Monitoring

### Health Check Endpoint

```bash
# Add to monitoring system (Uptime Robot, Pingdom, etc.)
https://yourdomain.com/healthz

# Expected response: 200 OK
```

### Docker Container Monitoring

```bash
# Check container status
docker compose -f docker-compose.external-nginx.prod.yml ps

# Check resource usage
docker stats n8n-external-nginx-prod n8n-runners-external-nginx-prod \
  n8n-postgres-external-nginx-prod n8n-nginx-prod

# View logs
docker compose -f docker-compose.external-nginx.prod.yml logs -f --tail=100
```

### Log Monitoring

```bash
# nginx access logs
docker exec n8n-nginx-prod tail -f /var/log/nginx/n8n-prod-access.log

# nginx error logs
docker exec n8n-nginx-prod tail -f /var/log/nginx/n8n-prod-error.log

# n8n logs
docker logs -f n8n-external-nginx-prod

# Database logs
docker logs -f n8n-postgres-external-nginx-prod
```

### Prometheus Metrics (Optional)

Uncomment in `.env.external.production`:
```bash
N8N_METRICS=true
N8N_METRICS_PREFIX=n8n_
```

Access metrics at: `https://yourdomain.com/metrics`

## 🔄 Updates and Maintenance

### Update n8n

```bash
# Pull latest images
docker compose -f docker-compose.external-nginx.prod.yml pull

# Restart with new images
docker compose -f docker-compose.external-nginx.prod.yml up -d

# Verify update
docker compose -f docker-compose.external-nginx.prod.yml logs n8n
```

### Update SSL Certificate

```bash
# Renew Let's Encrypt certificate
sudo certbot renew

# Copy new certificates
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem nginx/ssl/
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem nginx/ssl/
sudo cp /etc/letsencrypt/live/yourdomain.com/chain.pem nginx/ssl/

# Reload nginx
docker exec n8n-nginx-prod nginx -s reload
```

Automate renewal:
```bash
# Add to crontab
0 3 * * * certbot renew --quiet && cp /etc/letsencrypt/live/yourdomain.com/*.pem /path/to/nginx/ssl/ && docker exec n8n-nginx-prod nginx -s reload
```

### Database Maintenance

```bash
# Vacuum database (monthly recommended)
docker exec n8n-postgres-external-nginx-prod psql -U n8n_prod -d n8n_prod -c "VACUUM ANALYZE;"

# Check database size
docker exec n8n-postgres-external-nginx-prod psql -U n8n_prod -d n8n_prod -c "\l+"

# Prune old execution data (if not auto-pruning)
# Done automatically if EXECUTIONS_DATA_PRUNE=true in .env
```

## 🐛 Troubleshooting

### SSL Certificate Issues

```bash
# Test SSL configuration
docker exec n8n-nginx-prod nginx -t

# Check certificate expiry
openssl x509 -in nginx/ssl/fullchain.pem -noout -dates

# View detailed certificate info
openssl x509 -in nginx/ssl/fullchain.pem -text -noout
```

### nginx not starting

```bash
# Check configuration syntax
docker exec n8n-nginx-prod nginx -t

# View error logs
docker logs n8n-nginx-prod

# Check port conflicts
sudo lsof -i :80
sudo lsof -i :443
```

### n8n not accessible

```bash
# Check all containers are healthy
docker compose -f docker-compose.external-nginx.prod.yml ps

# Test n8n directly (bypass nginx)
curl http://localhost:5678

# Check nginx → n8n connection
docker exec n8n-nginx-prod wget -O- http://n8n-external-nginx-prod:5678
```

### High memory usage

```bash
# Check container memory
docker stats --no-stream

# Increase limits in docker-compose.external-nginx.prod.yml
# Or reduce concurrency in .env.external.production:
N8N_CONCURRENCY_PRODUCTION_LIMIT=5
```

### Database connection issues

```bash
# Check PostgreSQL is healthy
docker exec n8n-postgres-external-nginx-prod pg_isready -U n8n_prod

# Test connection from n8n container
docker exec n8n-external-nginx-prod nc -zv postgres 5432

# View database logs
docker logs n8n-postgres-external-nginx-prod
```

## 📝 Production Checklist

Before going live:

- [ ] SSL certificate installed and tested
- [ ] Domain DNS configured correctly
- [ ] Firewall rules configured
- [ ] Environment file secured (not in git)
- [ ] Strong passwords set everywhere
- [ ] Backup script configured and tested
- [ ] Monitoring alerts configured
- [ ] Resource limits appropriate for load
- [ ] Health checks passing
- [ ] Logs being collected
- [ ] Disaster recovery plan documented
- [ ] Team trained on deployment
- [ ] Support contacts documented

## 📚 Additional Resources

- [n8n Production Docs](https://docs.n8n.io/hosting/installation/docker/)
- [nginx SSL Configuration](https://ssl-config.mozilla.org/)
- [Let's Encrypt Best Practices](https://letsencrypt.org/docs/)
- [Docker Security](https://docs.docker.com/engine/security/)
- [PostgreSQL Backup & Recovery](https://www.postgresql.org/docs/current/backup.html)

---

**Production URL**: https://yourdomain.com 🚀  
**Remember**: Always test updates in staging first!
