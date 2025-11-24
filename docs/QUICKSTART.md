# Getting Started - 5 Minute Guide

## 🚀 Fastest Path to Running n8n

Follow these steps to have n8n running in 5 minutes:

---

## Step 1: Prerequisites Check (1 minute)

Open terminal and run:

```bash
docker --version
docker compose version
```

✅ If you see version numbers, you're ready!
❌ If not, [install Docker](https://docs.docker.com/get-docker/) first.

---

## Step 2: Clone/Download (30 seconds)

```bash
cd ~/projects  # or wherever you keep projects
git clone <your-repo-url> n8n-playground
cd n8n-playground
```

Or download and extract the ZIP file, then `cd` into the directory.

---

## Step 3: Generate Encryption Key (30 seconds)

```bash
# Generate a secure key
openssl rand -hex 32

# You'll see something like:
# 4f8a3b2c1d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2
```

Copy this key! You'll need it in the next step.

---

## Step 4: Configure Environment (1 minute)

```bash
# Open the development environment file
nano .env.development
```

Find this line:
```env
N8N_ENCRYPTION_KEY=REPLACE_THIS_WITH_RANDOM_STRING
```

Replace `REPLACE_THIS_WITH_RANDOM_STRING` with the key you generated.

**Optional:** Change the PostgreSQL password:
```env
DB_POSTGRESDB_PASSWORD=change-me-to-secure-password
```

Press `Ctrl+X`, then `Y`, then `Enter` to save.

---

## Step 5: Start n8n (2 minutes)

```bash
# Build the containers (first time only)
docker compose -f docker-compose.internal.dev.yml build

# Start everything
docker compose -f docker-compose.internal.dev.yml up -d

# Watch the startup logs
docker compose -f docker-compose.internal.dev.yml logs -f
```

Wait for this message:
```
n8n ready on 0.0.0.0, port 5678
```

Press `Ctrl+C` to exit the logs (n8n keeps running).

---

## Step 6: Access n8n (30 seconds)

Open your browser and go to:
```
http://localhost:5678
```

You'll see the n8n welcome screen! 🎉

---

## Step 7: Create Your Account (1 minute)

On the welcome screen:
1. Enter your email
2. Create a password
3. Set your first name and last name (optional)
4. Click "Continue"

You're now inside n8n!

---

## 🎯 Test It Works

Let's create a simple workflow to test task runners:

### Test JavaScript

1. Click **"+ Add workflow"**
2. Click **"+ Add node"**
3. Search for **"Code"**
4. Select **"Code"** node
5. Paste this code:

```javascript
const axios = require('axios');
const response = await axios.get('https://api.github.com');
return { status: response.status, message: 'It works!' };
```

6. Click **"Execute node"**
7. You should see `{ status: 200, message: 'It works!' }`

### Test Python

1. Click **"+ Add node"** again
2. Select **"Code"** node
3. Change language to **"Python"**
4. Paste this code:

```python
import httpx

with httpx.Client() as client:
    response = client.get('https://api.github.com')
    return {'status': response.status_code, 'message': 'Python works!'}
```

5. Click **"Execute node"**
6. You should see `{ status: 200, message: 'Python works!' }`

✅ If both work, your setup is perfect!

---

## 📊 What You Just Did

You're now running:

- ✅ n8n workflow automation platform
- ✅ PostgreSQL database (for storing workflows)
- ✅ Task runners (for executing JavaScript & Python)
- ✅ Pre-installed packages (axios, lodash, httpx, beautifulsoup4, etc.)

---

## 🛑 Stopping n8n

When you're done:

```bash
docker compose -f docker-compose.internal.dev.yml down
```

---

## 🔄 Starting Again

Next time you want to use n8n:

```bash
cd ~/projects/n8n-playground
docker compose -f docker-compose.internal.dev.yml up -d
```

Then open http://localhost:5678

Your workflows and settings are automatically preserved!

---

## 📚 Next Steps

Now that you have n8n running:

1. **Learn n8n:** Check out [n8n documentation](https://docs.n8n.io/)
2. **Explore templates:** Visit [n8n workflows](https://n8n.io/workflows/)
3. **Add more packages:** See [README.md](README.md#adding-custom-packages)
4. **Switch to production:** See [SETUP.md](SETUP.md) when ready

---

## 🆘 Something Not Working?

### n8n won't start

```bash
# Check what's running
docker compose -f docker-compose.internal.dev.yml ps

# Check logs for errors
docker compose -f docker-compose.internal.dev.yml logs
```

### Port 5678 already in use

Someone else is using port 5678. Stop that service or change the port:

1. Edit `.env.development`
2. Change `N8N_PORT=5678` to `N8N_PORT=5679`
3. Restart: `docker compose -f docker-compose.internal.dev.yml up -d`
4. Access at http://localhost:5679

### Can't access localhost:5678

- Are the containers running? Run: `docker compose -f docker-compose.internal.dev.yml ps`
- Check logs: `docker compose -f docker-compose.internal.dev.yml logs n8n`
- Try restarting: 
  ```bash
  docker compose -f docker-compose.internal.dev.yml restart
  ```

### Code execution error

If you get "Blocked for security reasons":

1. Make sure you used the **Internal Mode** compose file (docker-compose.internal.dev.yml)
2. Check environment: `docker compose -f docker-compose.internal.dev.yml exec n8n env | grep RUNNERS`
3. Should show: `N8N_RUNNERS_ENABLED=true` and `N8N_RUNNERS_MODE=internal`

### Database connection error

1. Check postgres is running: `docker compose -f docker-compose.internal.dev.yml ps postgres`
2. Check if healthy: Should say "healthy" in STATUS column
3. If not healthy, check logs: `docker compose -f docker-compose.internal.dev.yml logs postgres`

---

## 💡 Common Questions

**Q: Where is my data stored?**
A: In `./data/n8n/` and `./data/postgres/` directories.

**Q: How do I backup?**
A: `tar czf backup.tar.gz data/`

**Q: How do I restore?**
A: Stop containers, extract backup, start containers.

**Q: Can I use this for production?**
A: Yes! Switch to `docker-compose.internal.prod.yml`. See [SETUP.md](SETUP.md).

**Q: What's the difference between internal and external mode?**
A: See [COMPARISON.md](COMPARISON.md). TL;DR: Use internal unless you need maximum isolation.

**Q: Can I add more Python/Node packages?**
A: Yes! See [README.md](README.md#adding-custom-packages).

**Q: Why can't I use Python async/await?**
A: Security restrictions. Use synchronous code. See [SETUP.md](SETUP.md#important-limitations).

**Q: How do I update n8n?**
A: See [README.md](README.md#updating-n8n).

---

## ✅ Success Checklist

After following this guide, you should have:

- [ ] Docker and Docker Compose installed
- [ ] n8n running at http://localhost:5678
- [ ] Created your n8n account
- [ ] Successfully executed JavaScript code with axios
- [ ] Successfully executed Python code with httpx
- [ ] Understand how to start and stop n8n
- [ ] Know where your data is stored

---

## 🎉 You're All Set!

You now have a fully functional n8n setup with:
- PostgreSQL database
- Task runners for code execution
- Pre-installed useful packages
- Persistent data storage

**Happy automating! 🚀**

Need more details? Check out:
- [README.md](README.md) - Full documentation
- [OVERVIEW.md](OVERVIEW.md) - Visual guide
- [SETUP.md](SETUP.md) - Comprehensive setup guide
- [COMPARISON.md](COMPARISON.md) - Technical comparison

---

## 📞 Getting Help

- [n8n Community Forum](https://community.n8n.io/)
- [n8n Documentation](https://docs.n8n.io/)
- [GitHub Issues](https://github.com/n8n-io/n8n/issues)
