# n8n with Nginx Reverse Proxy

This configuration runs n8n with nginx as a reverse proxy, providing a production-ready setup for external mode.

## 🎯 Architecture

```
Internet/Client
     ↓
nginx (Port 80) → n8n (Port 5678)
                    ↓
            Task Runners (JS + Python)
                    ↓
            PostgreSQL Database
```

## 🚀 Quick Start

```bash
# Start all services
docker compose -f docker-compose.external-nginx.dev.yml up -d

# Access n8n through nginx
open http://localhost:80
```

## 📦 What's Included

- **nginx**: Alpine-based reverse proxy on port 80
- **n8n**: Workflow automation platform (internal port 5678)
- **Task Runners**: Separate container for JS and Python code execution
- **PostgreSQL**: Database for n8n data persistence

## 🔧 Configuration Files

### docker-compose.external-nginx.dev.yml
Main orchestration file defining all services and their relationships.

### nginx/nginx.conf
Global nginx configuration with:
- Worker processes optimization
- Gzip compression enabled
- 50MB client max body size
- Custom logging format

### nginx/conf.d/n8n.conf
n8n-specific nginx configuration with:
- WebSocket support (required for n8n UI)
- Long timeout values for workflows (300 seconds)
- Proper proxy headers
- Health check endpoint at `/healthz`
- Buffering optimizations

## 🌐 Access Points

| Service | URL | Purpose |
|---------|-----|---------|
| n8n UI | http://localhost:80 | Main n8n interface (via nginx) |
| Health Check | http://localhost:80/healthz | Service health status |
| n8n Direct | http://localhost:5678 | Direct n8n access (for debugging) |

## ⚙️ Environment Variables

Uses `.env.external.development` with key configurations:
- Database connection settings
- Task runner mode (external)
- Encryption keys
- Webhook URLs (configured for nginx proxy)

## 🔐 Why Use Nginx?

### Benefits

1. **SSL/TLS Termination**: Easy to add HTTPS support
2. **Load Balancing**: Can distribute traffic across multiple n8n instances
3. **Caching**: Can cache static assets
4. **Security**: Additional security layer (rate limiting, WAF, etc.)
5. **Compression**: Reduces bandwidth usage
6. **Logging**: Centralized access logs
7. **Custom Headers**: Add security headers easily

### Production Features

The nginx configuration includes:
- **WebSocket Support**: Required for n8n's real-time UI updates
- **Large Upload Support**: 50MB max body size for webhooks
- **Connection Timeouts**: 300s for long-running workflows
- **Buffering**: Optimized for n8n's needs
- **Health Checks**: Dedicated endpoint for monitoring

## 📝 Customization

### Change Port

Edit `docker-compose.external-nginx.dev.yml`:

```yaml
nginx:
  ports:
    - "80:80"  # Change 80 to your preferred port
```

### Add SSL/HTTPS

1. Generate or obtain SSL certificates
2. Update nginx configuration:

```nginx
server {
    listen 443 ssl http2;
    server_name yourdomain.com;
    
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    
    # ... rest of configuration
}
```

3. Mount certificates in docker-compose:

```yaml
nginx:
  volumes:
    - ./nginx/ssl:/etc/nginx/ssl:ro
```

### Add Rate Limiting

Add to `nginx/conf.d/n8n.conf`:

```nginx
# Define rate limit zone (in http block of nginx.conf)
limit_req_zone $binary_remote_addr zone=n8n_limit:10m rate=10r/s;

server {
    # Apply rate limiting
    limit_req zone=n8n_limit burst=20 nodelay;
    
    # ... rest of configuration
}
```

### Add Authentication

For basic HTTP auth, add to `nginx/conf.d/n8n.conf`:

```nginx
server {
    auth_basic "n8n Access";
    auth_basic_user_file /etc/nginx/.htpasswd;
    
    # ... rest of configuration
}
```

Create password file:
```bash
htpasswd -c nginx/.htpasswd admin
```

## 🔍 Monitoring

### View Nginx Logs

```bash
# Access logs
docker logs n8n-nginx-dev 2>&1 | grep -v "healthz"

# Error logs only
docker exec n8n-nginx-dev cat /var/log/nginx/n8n-error.log

# Real-time access logs
docker exec n8n-nginx-dev tail -f /var/log/nginx/n8n-access.log
```

### Test Nginx Configuration

```bash
# Validate nginx config without restarting
docker exec n8n-nginx-dev nginx -t

# Reload nginx after config changes
docker exec n8n-nginx-dev nginx -s reload
```

### Health Checks

```bash
# Check n8n health through nginx
curl http://localhost:80/healthz

# Check nginx is running
curl -I http://localhost:80
```

## 🛠️ Troubleshooting

### nginx won't start

**Error**: `address already in use`

**Solution**: Port 80 is occupied. Either:
1. Stop the service using port 80
2. Change nginx port in docker-compose.external-nginx.dev.yml

```bash
# Find what's using port 80
lsof -i :80

# Change to different port
sed -i 's/"80:80"/"9080:80"/' docker-compose.external-nginx.dev.yml
```

### n8n UI not loading

**Check**: nginx → n8n connection

```bash
# Check all containers are running
docker compose -f docker-compose.external-nginx.dev.yml ps

# Check nginx can reach n8n
docker exec n8n-nginx-dev wget -O- http://n8n-external-nginx-dev:5678

# Check nginx logs for errors
docker logs n8n-nginx-dev
```

### WebSockets not working

**Symptom**: UI doesn't update in real-time

**Solution**: Verify WebSocket headers in nginx config:

```nginx
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
```

### Workflows timing out

**Solution**: Increase timeout values in `nginx/conf.d/n8n.conf`:

```nginx
proxy_connect_timeout 600;  # Increase from 300
proxy_send_timeout 600;
proxy_read_timeout 600;
```

## 🔄 Switching from Direct Access

If you're currently running without nginx:

```bash
# Stop direct access mode
docker compose -f docker-compose.external.dev.yml down

# Start nginx mode
docker compose -f docker-compose.external-nginx.dev.yml up -d

# Update bookmarks from :5678 to :80
```

**Note**: Database is shared (postgres-external), so your workflows are preserved!

## 📊 Performance Considerations

### Pros of Using Nginx
- ✅ Adds <10ms latency
- ✅ Reduces bandwidth (gzip compression)
- ✅ Better concurrent connection handling
- ✅ Can cache static assets

### Cons
- ❌ Adds complexity
- ❌ Requires nginx knowledge for advanced features
- ❌ One more container to manage

### When to Use
- ✅ Production deployments
- ✅ Need SSL/HTTPS
- ✅ Multiple n8n instances
- ✅ Advanced security requirements
- ❌ Simple development (use direct access)

## 🚀 Production Deployment

For production, additionally configure:

1. **SSL/TLS**: Use Let's Encrypt or commercial certificates
2. **Security Headers**: Add HSTS, CSP, X-Frame-Options
3. **Rate Limiting**: Protect against abuse
4. **Monitoring**: Integrate with Prometheus/Grafana
5. **Backup**: Regular PostgreSQL and n8n data backups
6. **Resource Limits**: Set Docker memory/CPU limits
7. **Logging**: Ship logs to centralized system (ELK, Loki)

Example production nginx additions:

```nginx
# Security headers
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;

# Rate limiting
limit_req_zone $binary_remote_addr zone=n8n_limit:10m rate=10r/s;
limit_req zone=n8n_limit burst=20 nodelay;

# IP whitelist (if needed)
allow 192.168.1.0/24;
deny all;
```

## 📚 Related Documentation

- [External Mode Setup](../README.md#external-mode)
- [Python Support](PYTHON-SETUP.md)
- [Mode Migration](MODE-MIGRATION.md)
- [Official nginx docs](https://nginx.org/en/docs/)
- [n8n Hosting Docs](https://docs.n8n.io/hosting/)

---

**Access n8n**: http://localhost:80 🚀
