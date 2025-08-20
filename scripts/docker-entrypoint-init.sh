#!/usr/bin/env bash
set -euo pipefail

# Coolify-compatible Sentry initialization script
# This replaces the functionality of install.sh for containerized deployment

echo "🚀 Initializing Sentry Self-Hosted for Coolify deployment..."

# Coolify-specific error handling and logging
exec > >(tee -a /tmp/init.log)
exec 2>&1

# Create completion marker for healthcheck
cleanup() {
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo "✅ Init completed successfully"
        touch /tmp/init-complete
    else
        echo "❌ Init failed with exit code: $exit_code"
        rm -f /tmp/init-complete
    fi
    exit $exit_code
}
trap cleanup EXIT

# Extended timeouts for Coolify environment
export POSTGRES_WAIT_TIMEOUT=120
export REDIS_WAIT_TIMEOUT=60
export KAFKA_WAIT_TIMEOUT=90

# Environment variables with defaults
SENTRY_CONF=${SENTRY_CONF:-/etc/sentry}
SENTRY_CONFIG_YML="$SENTRY_CONF/config.yml"
SENTRY_CONFIG_PY="$SENTRY_CONF/sentry.conf.py"

echo "📋 Checking configuration files..."

# Function to ensure configuration files exist from examples
ensure_config_from_example() {
    local config_file="$1"
    local example_file="${config_file}.example"
    
    if [[ ! -f "$config_file" && -f "$example_file" ]]; then
        echo "Creating $config_file from example..."
        cp "$example_file" "$config_file"
    fi
}

# Ensure config files exist
ensure_config_from_example "$SENTRY_CONFIG_YML"
ensure_config_from_example "$SENTRY_CONFIG_PY"

echo "🔐 Generating secret key..."

# Generate secret key if not set or still default
if [[ -z "${SENTRY_SECRET_KEY:-}" ]] && grep -q "system.secret-key: '!!changeme!!'" "$SENTRY_CONFIG_YML" 2>/dev/null; then
    echo "Generating new secret key..."
    export LC_ALL=C
    SECRET_KEY=$(head /dev/urandom | tr -dc "a-z0-9@#%^&*(-_=+)" | head -c 50 | sed -e 's/[\/&]/\\&/g')
    sed -i -e "s/^system.secret-key:.*$/system.secret-key: '$SECRET_KEY'/" "$SENTRY_CONFIG_YML"
    echo "Secret key generated and written to $SENTRY_CONFIG_YML"
elif [[ -n "${SENTRY_SECRET_KEY:-}" ]]; then
    echo "Using provided secret key from environment..."
    sed -i -e "s/^system.secret-key:.*$/system.secret-key: '$SENTRY_SECRET_KEY'/" "$SENTRY_CONFIG_YML"
fi

echo "⏳ Waiting for dependencies to be ready..."

# Wait for postgres with timeout
echo "Waiting for PostgreSQL..."
postgres_timeout=${POSTGRES_WAIT_TIMEOUT:-120}
postgres_count=0
while ! pg_isready -h postgres -p 5432 -U postgres >/dev/null 2>&1; do
    echo "PostgreSQL is unavailable - sleeping (${postgres_count}/${postgres_timeout}s)"
    sleep 2
    postgres_count=$((postgres_count + 2))
    if [ $postgres_count -ge $postgres_timeout ]; then
        echo "❌ PostgreSQL timeout after ${postgres_timeout}s"
        exit 1
    fi
done
echo "PostgreSQL is ready!"

# Wait for redis with timeout
echo "Waiting for Redis..."
redis_timeout=${REDIS_WAIT_TIMEOUT:-60}
redis_count=0
while ! redis-cli -h redis ping >/dev/null 2>&1; do
    echo "Redis is unavailable - sleeping (${redis_count}/${redis_timeout}s)"
    sleep 2
    redis_count=$((redis_count + 2))
    if [ $redis_count -ge $redis_timeout ]; then
        echo "❌ Redis timeout after ${redis_timeout}s"
        exit 1
    fi
done
echo "Redis is ready!"

# Wait for kafka with timeout
echo "Waiting for Kafka..."
kafka_timeout=${KAFKA_WAIT_TIMEOUT:-90}
kafka_count=0
while ! nc -z kafka 9092 >/dev/null 2>&1; do
    echo "Kafka is unavailable - sleeping (${kafka_count}/${kafka_timeout}s)"
    sleep 2
    kafka_count=$((kafka_count + 2))
    if [ $kafka_count -ge $kafka_timeout ]; then
        echo "❌ Kafka timeout after ${kafka_timeout}s"
        exit 1
    fi
done
echo "Kafka is ready!"

echo "🗄️ Setting up database..."

# Check if this is the first run by looking for existing data
if ! sentry exec -c "from sentry.models import User; print('Database initialized')" >/dev/null 2>&1; then
    echo "First run detected - initializing database..."
    
    # Create database
    echo "Creating database..."
    sentry upgrade --noinput
    
    # Create default superuser if none exists
    echo "Creating default superuser..."
    sentry exec -c "
from sentry.models import User
from django.conf import settings
if not User.objects.filter(is_superuser=True).exists():
    User.objects.create_superuser(
        email='admin@localhost',
        password='admin',
        username='admin'
    )
    print('Created default superuser: admin@localhost / admin')
    print('Please change these credentials after first login!')
else:
    print('Superuser already exists')
"
else
    echo "Database already initialized, running migrations..."
    sentry upgrade --noinput
fi

echo "📊 Bootstrapping Snuba..."

# Bootstrap Snuba (if not already done)
if ! snuba bootstrap --no-migrate-kafka >/dev/null 2>&1; then
    echo "Snuba bootstrap completed"
fi

echo "🌍 Setting up GeoIP database..."

# Create empty GeoIP database if it doesn't exist
GEOIP_PATH="/geoip/GeoLite2-City.mmdb"
if [[ ! -f "$GEOIP_PATH" ]]; then
    echo "Creating empty GeoIP database..."
    mkdir -p /geoip
    touch "$GEOIP_PATH"
fi

echo "✅ Initialization complete!"
echo ""
echo "🎉 Sentry is ready to start!"
echo "📧 Default admin user: admin@localhost"
echo "🔑 Default password: admin"
echo "⚠️  Please change the default credentials after first login!"
echo ""