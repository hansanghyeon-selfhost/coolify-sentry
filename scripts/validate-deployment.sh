#!/usr/bin/env bash
set -euo pipefail

# Coolify Deployment Validation Script
# This script validates that the Sentry deployment is correctly configured

echo "🔍 Validating Sentry Coolify deployment configuration..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Function to log errors
log_error() {
    echo -e "${RED}❌ ERROR: $1${NC}"
    ((ERRORS++))
}

# Function to log warnings
log_warning() {
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
    ((WARNINGS++))
}

# Function to log success
log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo "📂 Checking directory structure..."

# Check required directories
REQUIRED_DIRS=(
    "config"
    "config/sentry"
    "config/symbolicator"
    "config/relay"
    "config/geoip"
    "config/clickhouse"
    "scripts"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        log_success "Directory $dir exists"
    else
        log_error "Required directory $dir is missing"
    fi
done

echo -e "\n📄 Checking configuration files..."

# Check required configuration files
REQUIRED_FILES=(
    "docker-compose.yml"
    "config/sentry/config.yml"
    "config/sentry/sentry.conf.py"
    "config/sentry/config.example.yml"
    "config/sentry/sentry.conf.example.py"
    "config/symbolicator/config.yml"
    "config/relay/config.yml"
    "config/relay/credentials.json"
    "config/redis.conf"
    "config/clickhouse/config.xml"
    "scripts/docker-entrypoint-init.sh"
    ".env.coolify"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        log_success "File $file exists"
    else
        log_error "Required file $file is missing"
    fi
done

echo -e "\n🔐 Checking configuration security..."

# Check for default secret key
if grep -q "system.secret-key: '!!changeme!!'" config/sentry/config.yml 2>/dev/null; then
    log_warning "Default secret key detected in config.yml - will be auto-generated on deployment"
else
    log_success "Secret key appears to be configured"
fi

# Check for sensitive data in config files
if grep -r "password.*=" config/ 2>/dev/null | grep -v "example" | grep -v "#"; then
    log_warning "Potential passwords found in config files - ensure they're properly secured"
fi

echo -e "\n🐳 Checking Docker Compose configuration..."

# Check if docker-compose.yml is valid
if command -v docker-compose >/dev/null 2>&1; then
    if docker-compose config >/dev/null 2>&1; then
        log_success "Docker Compose configuration is valid"
    else
        log_error "Docker Compose configuration has syntax errors"
    fi
else
    log_warning "docker-compose not available for validation"
fi

# Check for exposed ports (shouldn't be any for Coolify)
if grep -q "ports:" docker-compose.yml; then
    log_warning "Ports are exposed in docker-compose.yml - Coolify handles this automatically"
fi

# Check for Coolify labels
if grep -q "coolify.main=true" docker-compose.yml; then
    log_success "Coolify labels configured correctly"
else
    log_warning "Coolify labels not found - ensure routing is configured properly"
fi

echo -e "\n🔧 Checking initialization script..."

# Check init script permissions
if [[ -x "scripts/docker-entrypoint-init.sh" ]]; then
    log_success "Initialization script is executable"
else
    log_warning "Initialization script may not be executable"
fi

# Check init script content
if grep -q "sentry upgrade" scripts/docker-entrypoint-init.sh; then
    log_success "Database migration commands found in init script"
else
    log_error "Database migration commands missing from init script"
fi

echo -e "\n📦 Checking environment configuration..."

# Check environment file
if [[ -f ".env.coolify" ]]; then
    # Check for required variables
    REQUIRED_ENV_VARS=(
        "SENTRY_IMAGE"
        "SNUBA_IMAGE"
        "RELAY_IMAGE"
        "SYMBOLICATOR_IMAGE"
        "COMPOSE_PROJECT_NAME"
    )
    
    for var in "${REQUIRED_ENV_VARS[@]}"; do
        if grep -q "^$var=" .env.coolify; then
            log_success "Environment variable $var is configured"
        else
            log_error "Required environment variable $var is missing"
        fi
    done
else
    log_error "Environment configuration file .env.coolify not found"
fi

echo -e "\n📊 Validation Summary"
echo "===================="

if [[ $ERRORS -eq 0 ]] && [[ $WARNINGS -eq 0 ]]; then
    echo -e "${GREEN}🎉 All checks passed! The deployment appears to be correctly configured for Coolify.${NC}"
    exit 0
elif [[ $ERRORS -eq 0 ]]; then
    echo -e "${YELLOW}✅ Configuration is valid with $WARNINGS warning(s). You can proceed with deployment.${NC}"
    exit 0
else
    echo -e "${RED}❌ Found $ERRORS error(s) and $WARNINGS warning(s). Please fix the errors before deploying.${NC}"
    exit 1
fi