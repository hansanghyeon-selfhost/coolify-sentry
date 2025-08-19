# Sentry Self-Hosted Coolify Deployment Checklist

Use this checklist to ensure a successful deployment to Coolify.

## Pre-Deployment Checklist

### 📋 Repository Preparation
- [ ] Repository is accessible from your Coolify instance
- [ ] All configuration files are present in the `config/` directory
- [ ] Scripts are executable (`chmod +x scripts/*.sh`)
- [ ] Environment variables are configured in `.env.coolify`

### 🔧 Configuration Review
- [ ] `SENTRY_MAIL_HOST` is set to your domain
- [ ] `SENTRY_EVENT_RETENTION_DAYS` is configured appropriately
- [ ] Custom secret key is set (optional - will auto-generate if not provided)
- [ ] SMTP configuration is updated if email notifications are needed
- [ ] Resource requirements are met on your server

### 🐳 Docker Configuration
- [ ] `docker-compose.yml` is valid (run `docker-compose config` to verify)
- [ ] No ports are exposed (Coolify handles this)
- [ ] Coolify labels are present on the web service
- [ ] Volume mounts are correctly configured

## Deployment Steps

### 1. DNS and Domain Setup
- [ ] Set up DNS A records before deployment
  - [ ] Example: `sentry.yourdomain.com` → `your-server-ip`
  - [ ] Or wildcard: `*.yourdomain.com` → `your-server-ip`
- [ ] Verify DNS propagation with `nslookup` or `dig`

### 2. Coolify Application Setup
- [ ] Create new "Docker Compose" application in Coolify
- [ ] Set Git repository URL
- [ ] Set correct branch (usually `main` or `master`)
- [ ] Configure base directory if needed (leave empty for root)

### 3. Domain Configuration in Coolify
- [ ] Go to Configuration tab → Services section
- [ ] Select "web" service (main service with coolify.main=true)
- [ ] Enter domain in Domains field: `https://sentry.yourdomain.com`
- [ ] Save domain configuration

### 4. Environment Configuration
- [ ] Copy environment variables from `.env.coolify`
- [ ] Set `SENTRY_MAIL_HOST` to match your domain
- [ ] Customize values as needed for your environment
- [ ] Set any additional environment variables required

### 5. Resource Allocation
- [ ] Ensure server has minimum 4GB RAM
- [ ] Ensure sufficient storage (minimum 20GB recommended)
- [ ] Configure resource limits in Coolify if needed

### 6. Deployment
- [ ] Run validation script: `./scripts/validate-deployment.sh`
- [ ] Start deployment in Coolify
- [ ] Monitor deployment logs for any errors
- [ ] Wait for all services to become healthy (10-15 minutes)

## Post-Deployment Checklist

### 🎯 Initial Setup
- [ ] Access Sentry web interface via Coolify-provided URL
- [ ] Login with default credentials (`admin@localhost` / `admin`)
- [ ] **IMMEDIATELY** change default admin credentials
- [ ] Configure organization settings
- [ ] Set up first project

### 🔐 Security Hardening
- [ ] Change default admin password
- [ ] Review user access permissions
- [ ] Configure SMTP for email notifications
- [ ] Set up SSL certificates (handled by Coolify)
- [ ] Review security settings in Sentry admin

### 📧 Email Configuration
- [ ] Test email notifications
- [ ] Configure SMTP settings if not done pre-deployment
- [ ] Verify email delivery works
- [ ] Set up alert rules and notifications

### 🔍 Monitoring & Health Checks
- [ ] Verify all services are running and healthy
- [ ] Check container logs for any warnings or errors
- [ ] Test creating and sending test events to Sentry
- [ ] Verify data retention settings are working
- [ ] Set up monitoring for the Sentry instance itself

### 📊 Performance Tuning
- [ ] Monitor resource usage in first few days
- [ ] Adjust worker count if needed
- [ ] Configure data retention policies
- [ ] Set up regular backups

## Troubleshooting Common Issues

### Service Health Issues
- [ ] Check individual service logs in Coolify
- [ ] Verify all dependencies are healthy
- [ ] Check resource consumption
- [ ] Restart unhealthy services if needed

### Database Issues
- [ ] Verify PostgreSQL is running and accessible
- [ ] Check database migrations completed successfully
- [ ] Verify database user permissions
- [ ] Check database disk space

### Memory Issues
- [ ] Monitor RAM usage across all services
- [ ] Adjust worker counts if memory usage is high
- [ ] Consider reducing retention period
- [ ] Scale server resources if needed

### Network Issues
- [ ] Verify service-to-service communication
- [ ] Check Kafka and Redis connectivity
- [ ] Verify external connectivity (if using external services)
- [ ] Test Coolify routing and SSL

## Backup Strategy

### What to Backup
- [ ] PostgreSQL database (`sentry-postgres` volume)
- [ ] ClickHouse data (`sentry-clickhouse` volume)
- [ ] Sentry data (`sentry-data` volume)
- [ ] Configuration files
- [ ] Environment variables

### Backup Schedule
- [ ] Daily database backups
- [ ] Weekly full volume backups
- [ ] Monthly configuration backups
- [ ] Test restore procedures

## Maintenance Tasks

### Regular Tasks
- [ ] Monitor disk space usage
- [ ] Review error logs weekly
- [ ] Update Docker images monthly
- [ ] Review retention policies quarterly
- [ ] Security updates as needed

### Scaling Considerations
- [ ] Monitor performance metrics
- [ ] Plan for user growth
- [ ] Consider external database for heavy usage
- [ ] Implement load balancing if needed

## Emergency Procedures

### Service Recovery
- [ ] Document service restart procedures
- [ ] Create runbooks for common issues
- [ ] Test disaster recovery procedures
- [ ] Document escalation procedures

### Data Recovery
- [ ] Test backup restoration procedures
- [ ] Document data recovery steps
- [ ] Plan for different failure scenarios
- [ ] Maintain contact information for support

---

## Validation Command

Before deployment, run:
```bash
./scripts/validate-deployment.sh
```

This will check all configuration files and dependencies are properly set up.

## Support Resources

- [Sentry Documentation](https://docs.sentry.io/)
- [Coolify Documentation](https://coolify.io/docs)
- [Self-Hosted Troubleshooting](https://develop.sentry.dev/self-hosted/troubleshooting/)
- This repository's README.coolify.md