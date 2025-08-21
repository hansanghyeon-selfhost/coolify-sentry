# Sentry Self-Hosted for Coolify

Coolify-optimized Sentry Self-Hosted deployment with one-click setup and configuration sync script.

## 🚀 Quick Start

### Deploy on Coolify

1. **Create Docker Compose Application** in Coolify
2. **Set Git Repository**: `https://github.com/hansanghyeon-selfhost/coolify-sentry`
3. **Configure Domain**: Set your domain (e.g., `https://sentry.yourdomain.com`)
4. **Deploy**: Wait 10-15 minutes for initialization
5. **Access**: Login with `admin@localhost` / `admin` (change immediately!)

### Sync Configuration from Git

Update your Coolify deployment with latest config from Git:

```bash
# Replace YOUR_APPLICATION_ID with your actual Coolify app ID
curl -fsSL https://raw.githubusercontent.com/hansanghyeon-selfhost/coolify-sentry/main/sync-coolify-config.sh | sudo bash -s -- YOUR_APPLICATION_ID
```

**Find your Application ID**:
- From Coolify URL: `/applications/YOUR_APPLICATION_ID`
- From containers: `docker ps | grep sentry`
- From directory: `ls /data/coolify/applications/`

## 📋 Requirements

- **Minimum**: 4GB RAM, 2 CPU cores, 20GB storage
- **Recommended**: 8GB RAM, 4 CPU cores, 50GB storage

## 📚 Documentation

- **English**: [README.coolify.md](./README.coolify.md) - Complete setup guide
- **한국어**: [README-kr.md](./README-kr.md) - 한국어 설정 가이드
- **Official**: [Sentry Self-Hosted Docs](https://develop.sentry.dev/self-hosted/)
