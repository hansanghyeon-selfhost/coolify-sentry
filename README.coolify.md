# Sentry Self-Hosted for Coolify

This repository contains a Coolify-optimized version of Sentry Self-Hosted that can be deployed directly from a git repository without requiring the `install.sh` script.

## 🚀 Quick Deployment

### Prerequisites
- A Coolify instance running
- At least 4GB RAM and 20GB storage for your server
- Domain name configured for your Coolify instance

### Deployment Steps

1. **Fork or Clone this Repository**
   ```bash
   git clone <this-repository-url>
   cd sentry-self-hosted-coolify
   ```

2. **Create New Application in Coolify**
   - Go to your Coolify dashboard
   - Create a new "Docker Compose" application
   - Set the Git repository URL to this repository
   - Set the branch (usually `main` or `master`)

3. **Configure Domain (Important)**
   - **First, set up DNS records**: You must configure DNS A records before deployment
     - Example: `sentry.yourdomain.com` → `your-server-ip-address`
     - Or use wildcard: `*.yourdomain.com` → `your-server-ip-address`
   - **Configure domain in Coolify**:
     - Go to Configuration tab → Services section
     - Select "web" service (main service)
     - Enter domain in Domains field: `https://sentry.yourdomain.com`
     - Multiple domains supported: `https://sentry.yourdomain.com,https://sentry.example.com`

4. **Configure Environment Variables**
   - In Coolify, go to your application's Environment tab
   - Copy the contents of `.env.coolify` and paste them as environment variables
   - Set `SENTRY_MAIL_HOST` to match your domain
   - Customize other values as needed

5. **Deploy**
   - Click "Deploy" in Coolify
   - Wait for the deployment to complete (this may take 10-15 minutes on first run)

6. **Access Your Sentry Instance**
   - Access via your configured domain (e.g., `https://sentry.yourdomain.com`)
   - Default credentials:
     - Email: `admin@localhost`
     - Password: `admin`
   - **⚠️ Change these credentials immediately after first login!**

## 📋 Configuration

### Environment Variables

Key environment variables you should customize:

```env
# Your domain for email notifications
SENTRY_MAIL_HOST=your-domain.com

# Data retention period (days)
SENTRY_EVENT_RETENTION_DAYS=90

# Optional: Custom secret key (auto-generated if not provided)
SENTRY_SECRET_KEY=your-secret-key-here

# Optional: Email configuration for notifications
SENTRY_MAIL_USERNAME=smtp-username
SENTRY_MAIL_PASSWORD=smtp-password
SENTRY_MAIL_USE_TLS=true
```

### Resource Requirements

**Minimum:**
- 4GB RAM
- 2 CPU cores
- 20GB storage

**Recommended:**
- 8GB RAM
- 4 CPU cores
- 50GB storage

## 🏗️ Architecture

This deployment includes all essential Sentry services:

### Core Services
- **Web**: Sentry web interface
- **Worker**: Background task processing
- **Cron**: Scheduled task execution
- **Init**: Database initialization and migration

### Data Services
- **PostgreSQL**: Primary database
- **Redis**: Cache and message broker
- **ClickHouse**: Analytics database
- **Kafka + Zookeeper**: Event streaming

### Processing Services
- **Snuba**: Event processing and analytics
- **Symbolicator**: Debug symbol processing
- **Relay**: Event forwarding
- **Vroom**: Profiling service

### Infrastructure
- **SMTP**: Email delivery
- **Memcached**: Additional caching

## 🔧 Customization

### Adding Custom Certificates

1. Place your certificates in the `config/certificates/` directory
2. Redeploy the application

### Configuring External Services

Edit the configuration files in the `config/` directory:

- `config/sentry/config.yml` - Main Sentry configuration
- `config/sentry/sentry.conf.py` - Python configuration
- `config/relay/config.yml` - Relay configuration
- `config/symbolicator/config.yml` - Symbolicator configuration

### Email Configuration

For production use, configure SMTP settings:

```yaml
# In config/sentry/config.yml
mail.backend: 'smtp'
mail.host: 'your-smtp-server.com'
mail.port: 587
mail.username: 'your-username'
mail.password: 'your-password'
mail.use-tls: true
```

## 🔍 Troubleshooting

### Common Issues

1. **"No Available Server" Error**
   - Check container health in Coolify logs
   - Ensure all services are running and healthy
   - Wait for initialization to complete (can take 10-15 minutes)

2. **Database Connection Errors**
   - Check PostgreSQL service status
   - Verify database initialization completed
   - Review init container logs

3. **Memory Issues**
   - Increase server resources
   - Reduce `SENTRY_EVENT_RETENTION_DAYS`
   - Monitor resource usage in Coolify

### Accessing Logs

In Coolify:
1. Go to your application
2. Click on "Logs" tab
3. Select the service you want to inspect
4. View real-time or historical logs

### Accessing Container Shell

Use Coolify's container management or SSH into your server:

```bash
# List containers
docker ps | grep sentry

# Access Sentry web container
docker exec -it <container-name> bash

# Run Sentry commands
docker exec -it <container-name> sentry help
```

## 🔄 Updates

To update Sentry:

1. Update image tags in `.env.coolify`
2. Commit changes to your git repository
3. Redeploy in Coolify
4. Monitor deployment logs for any issues

## 🛡️ Security Considerations

1. **Change Default Credentials**: Immediately change the default admin credentials
2. **Secret Key**: Use a strong, unique secret key
3. **Database Security**: Consider using external managed databases for production
4. **HTTPS**: Ensure Coolify is configured with SSL certificates
5. **Firewall**: Restrict access to necessary ports only
6. **Backups**: Set up regular backups of your data volumes

## 📚 Additional Resources

- [Sentry Self-Hosted Documentation](https://develop.sentry.dev/self-hosted/)
- [Coolify Documentation](https://coolify.io/docs)
- [Sentry Configuration Reference](https://docs.sentry.io/product/sentry-basics/installation/config/)

## 🆘 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review Coolify and container logs
3. Consult the official Sentry documentation
4. Open an issue in this repository with detailed logs and configuration

## 📝 What's Different from Standard Install

This repository modifies the standard Sentry self-hosted installation:

1. **No install.sh**: All setup is handled by Docker initialization
2. **Pre-configured**: Configuration files are included in the repository
3. **Coolify Optimized**: Docker Compose is optimized for Coolify deployment
4. **Auto-initialization**: Database setup and migrations happen automatically
5. **Secret Generation**: Secret keys are generated automatically if not provided

The functionality remains the same as the standard installation, just optimized for containerized deployment platforms like Coolify.