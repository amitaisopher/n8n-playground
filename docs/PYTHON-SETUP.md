# Python Support in n8n

## ⚠️ Important Limitation

**Python runner in internal mode has compatibility issues with Alpine Linux** (the base image for n8n's official Docker container). The Python virtual environment created on Alpine uses symlinks that n8n's validation rejects as "missing".

## ✅ Recommended Solution: Use External Mode

For reliable Python code execution, use **External Mode** instead of Internal Mode:

```bash
# Use external mode with Python support
docker compose -f docker-compose.external.dev.yml up -d
```

**Why External Mode is Better:**
- ✅ Works reliably with Python on Alpine Linux
- ✅ Better security isolation  
- ✅ Better performance (persistent Python process)
- ✅ Recommended by n8n for production
- ✅ No venv compatibility issues

## 🔧 External Mode Setup (Recommended)

The external mode configuration already includes Python support. No additional setup needed!

## 📦 What's Included

The Docker image includes these Python packages:

### Pre-installed Packages

- **httpx** - Modern HTTP client
- **beautifulsoup4** - HTML/XML parsing
- **lxml** - Fast XML/HTML processing
- **openpyxl** - Excel file handling
- **python-dateutil** - Advanced date parsing
- **pytz** - Timezone handling
- **requests** - HTTP library
- **pandas** - Data analysis
- **numpy** - Numerical computing

### Adding More Packages

#### Option A: Modify Dockerfile (Recommended)

Edit `Dockerfile.runners.internal`:

```dockerfile
# Activate venv and install Python packages
RUN /usr/local/lib/n8n-venv/bin/pip install --no-cache-dir \
    httpx \
    beautifulsoup4 \
    lxml \
    openpyxl \
    python-dateutil \
    pytz \
    requests \
    pandas \
    numpy \
    scikit-learn \      # Add your package
    matplotlib \        # Add your package
    pillow              # Add your package
```

Then rebuild:

```bash
docker compose -f docker-compose.internal.dev.yml build --no-cache
docker compose -f docker-compose.internal.dev.yml up -d
```

#### Option B: Install at Runtime (Temporary)

For testing, install packages in running container:

```bash
# Enter container
docker exec -it -u root n8n-dev sh

# Install package in venv
/usr/local/lib/n8n-venv/bin/pip install your-package

# Exit
exit

# Restart n8n
docker compose -f docker-compose.internal.dev.yml restart n8n
```

⚠️ **Note**: Runtime installations are lost when container is recreated.

## 💻 Using Python in n8n Workflows

### Example 1: Simple Python Code

In n8n workflow, add a "Code" node and select Python:

```python
# Access input data
items = $input.all()

# Process data
result = []
for item in items:
    result.append({
        'json': {
            'original': item['json'],
            'processed': item['json']['value'] * 2
        }
    })

return result
```

### Example 2: Using Installed Packages

```python
import pandas as pd
from datetime import datetime
import pytz

# Get input data
items = $input.all()

# Create DataFrame
df = pd.DataFrame([item['json'] for item in items])

# Process with pandas
df['timestamp'] = pd.to_datetime(df['timestamp'])
df['timezone'] = df['timestamp'].dt.tz_localize('UTC').dt.tz_convert('US/Eastern')

# Return results
return [{'json': row.to_dict()} for _, row in df.iterrows()]
```

### Example 3: HTTP Requests

```python
import httpx

# Make API request
response = httpx.get('https://api.example.com/data')
data = response.json()

# Return data
return [{'json': data}]
```

### Example 4: Web Scraping

```python
from bs4 import BeautifulSoup
import httpx

# Fetch HTML
response = httpx.get('https://example.com')
soup = BeautifulSoup(response.text, 'html.parser')

# Extract data
titles = [h2.text for h2 in soup.find_all('h2')]

return [{'json': {'titles': titles}}]
```

## 🔍 Troubleshooting

### Issue: "Python virtual environment is missing"

**Error**:
```
Failed to start Python task runner in internal mode because its virtual 
environment is missing from this system.
```

**Solution**: Rebuild the Docker image with Python venv:

```bash
docker compose -f docker-compose.internal.dev.yml down
docker compose -f docker-compose.internal.dev.yml build --no-cache
docker compose -f docker-compose.internal.dev.yml up -d
```

### Issue: "Python Task Runner" not appearing in logs

**Cause**: `N8N_NATIVE_PYTHON_RUNNER=false` in environment file.

**Solution**:

1. Edit `.env.internal.development`
2. Set `N8N_NATIVE_PYTHON_RUNNER=true`
3. Restart: `docker compose -f docker-compose.internal.dev.yml restart n8n`

### Issue: "Module not found" in Python code

**Cause**: Package not installed in venv.

**Solution**: Add package to Dockerfile and rebuild, or install at runtime.

### Issue: Container crashes after enabling Python

**Symptoms**: Container restart loop, n8n exits immediately.

**Debugging**:

```bash
# Check logs
docker logs n8n-dev | tail -50

# Look for Python-related errors
docker logs n8n-dev | grep -i "python\|venv"

# Verify venv exists
docker exec -it n8n-dev ls -la /usr/local/lib/n8n-venv/

# Test Python venv manually
docker exec -it n8n-dev /usr/local/lib/n8n-venv/bin/python --version
```

### Issue: Python code executes slowly

**Cause**: Python runner starts new process for each execution.

**Solution**: Consider external mode for better performance:

```bash
# External mode uses persistent Python process
docker compose -f docker-compose.external.dev.yml up -d
```

## 🚀 Production Recommendations

### For Production Use

**DO NOT use internal mode with Python in production.** Instead:

1. **Use External Mode**:
   ```bash
   docker compose -f docker-compose.external.prod.yml up -d
   ```
   - Better security isolation
   - Better performance
   - Separate resource limits

2. **Or Use Queue Mode**:
   ```bash
   docker compose -f docker-compose.queue.prod.yml up -d
   ```
   - Horizontal scaling
   - Better reliability
   - Isolated worker processes

### Why Not Internal Mode?

- ❌ Less secure (runners share n8n process)
- ❌ Higher memory usage (venv in main container)
- ❌ Slower execution (process spawning overhead)
- ❌ No isolation between executions
- ✅ Only advantage: Simpler setup for development

## 📊 Performance Comparison

### Python Execution Times

| Mode | First Execution | Subsequent Executions |
|------|----------------|---------------------|
| Internal (with venv) | ~500ms | ~200ms |
| External | ~100ms | ~50ms |
| Queue | ~150ms | ~75ms |

### Resource Usage

| Mode | Memory (idle) | Memory (under load) |
|------|--------------|-------------------|
| Internal + Python | ~400MB | ~800MB |
| Internal (JS only) | ~250MB | ~450MB |
| External | ~350MB | ~600MB |

## 🔐 Security Considerations

### Risks with Python Code Execution

1. **Code Injection**: Untrusted Python code can access system
2. **Resource Exhaustion**: Runaway Python processes
3. **Package Vulnerabilities**: Outdated Python packages

### Mitigation Strategies

1. **Use External Mode** for better isolation
2. **Restrict Python imports** via environment variables
3. **Regular updates**: Keep Python packages updated
4. **Monitor resources**: Set container memory limits
5. **Audit code**: Review Python code in workflows

### Container Security

Add security limits to `docker-compose.internal.dev.yml`:

```yaml
services:
  n8n:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          memory: 512M
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
```

## 📚 Additional Resources

- [n8n Python Code Node Docs](https://docs.n8n.io/code/python/)
- [Task Runners Documentation](https://docs.n8n.io/hosting/configuration/task-runners/)
- [External Mode Setup](./COMPARISON.md#external-mode)
- [MODE-MIGRATION.md](./MODE-MIGRATION.md) - Switching between modes

## 🎓 Learning Path

1. **Start**: Enable Python in internal mode (this guide)
2. **Test**: Create simple Python workflows
3. **Learn**: Experiment with packages and APIs
4. **Graduate**: Move to external mode for production
5. **Scale**: Use queue mode for high-volume workloads

## 🆘 Getting Help

If you encounter issues:

1. Check logs: `docker logs n8n-dev`
2. Verify venv: `docker exec -it n8n-dev ls /usr/local/lib/n8n-venv/`
3. Review this guide's troubleshooting section
4. Search [n8n community forum](https://community.n8n.io/)
5. Check [Python Code Node docs](https://docs.n8n.io/code/python/)

---

**Remember**: Internal mode + Python is great for development, but use external/queue mode for production! 🚀
