#!/bin/bash

# Coolify 애플리케이션 설정 파일 Git 동기화 스크립트
# 사용법: ./sync-coolify-config.sh <application-id>
# 또는: curl -fsSL https://raw.githubusercontent.com/hansanghyeon/selfhost/main/sentry/self-hosted/sync-coolify-config.sh | bash -s -- <application-id>

set -euo pipefail

# 설정 변수들
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/coolify-sync.log"
COOLIFY_BASE_PATH="/data/coolify/applications"
GIT_REPO_URL="${GIT_REPO_URL:-https://github.com/hansanghyeon/selfhost.git}"
GIT_BRANCH="${GIT_BRANCH:-main}"
CONFIG_SOURCE_PATH="sentry/self-hosted"

# 로깅 함수
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

# 실행 권한 확인
check_permissions() {
    if [ "$EUID" -ne 0 ]; then
        error_exit "이 스크립트는 root 권한이 필요합니다. sudo를 사용하거나 root로 실행해주세요."
    fi
}

# 사용법 출력
usage() {
    cat << EOF
사용법: $0 <application-id>

예시:
  $0 l80ook0sgk8o4okg880gw00s
  
curl로 실행:
  curl -fsSL https://raw.githubusercontent.com/hansanghyeon/selfhost/main/sentry/self-hosted/sync-coolify-config.sh | sudo bash -s -- l80ook0sgk8o4okg880gw00s

환경변수:
  GIT_REPO_URL: Git 저장소 URL (기본값: https://github.com/hansanghyeon/selfhost.git)
  GIT_BRANCH: Git 브랜치 (기본값: main)
  RESTART_SERVICES: 동기화 후 서비스 재시작 여부 (기본값: false)
EOF
    exit 1
}

# 필수 명령어 확인
check_dependencies() {
    local missing_deps=()
    
    for cmd in git curl docker; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        error_exit "필수 명령어가 설치되지 않았습니다: ${missing_deps[*]}"
    fi
}

# 파라미터 검증
if [ $# -ne 1 ]; then
    usage
fi

# 권한 및 의존성 확인
check_permissions
check_dependencies

APPLICATION_ID="$1"
APP_PATH="${COOLIFY_BASE_PATH}/${APPLICATION_ID}"
CONFIG_PATH="${APP_PATH}/config"
TEMP_REPO_PATH="/tmp/coolify-sync-${APPLICATION_ID}-$$"

log "=== Coolify 설정 동기화 시작 ==="
log "Application ID: ${APPLICATION_ID}"
log "Config Path: ${CONFIG_PATH}"

# 필수 디렉토리 확인 및 생성
if [ ! -d "$COOLIFY_BASE_PATH" ]; then
    error_exit "Coolify base path가 존재하지 않습니다: $COOLIFY_BASE_PATH"
fi

# 애플리케이션 디렉토리 생성
mkdir -p "$APP_PATH"
mkdir -p "$CONFIG_PATH"

# 임시 디렉토리 정리 함수
cleanup() {
    if [ -d "$TEMP_REPO_PATH" ]; then
        log "임시 디렉토리 정리: $TEMP_REPO_PATH"
        rm -rf "$TEMP_REPO_PATH"
    fi
}
trap cleanup EXIT

# Git 저장소 클론
log "Git 저장소 클론 중..."
if ! git clone --depth 1 --branch "$GIT_BRANCH" "$GIT_REPO_URL" "$TEMP_REPO_PATH"; then
    error_exit "Git 저장소 클론 실패"
fi

# 설정 파일 소스 경로 확인
SOURCE_CONFIG_PATH="${TEMP_REPO_PATH}/${CONFIG_SOURCE_PATH}"
if [ ! -d "$SOURCE_CONFIG_PATH" ]; then
    error_exit "설정 파일 소스 디렉토리가 존재하지 않습니다: $SOURCE_CONFIG_PATH"
fi

log "설정 파일 동기화 중..."

# 필요한 설정 디렉토리 및 파일들 정의
declare -A CONFIG_ITEMS=(
    ["sentry"]="directory"
    ["geoip"]="directory"
    ["certificates"]="directory"
    ["symbolicator"]="directory"
    ["relay"]="directory"
    ["redis.conf"]="file"
    ["clickhouse"]="directory"
)

# 각 설정 항목 동기화
for item in "${!CONFIG_ITEMS[@]}"; do
    type="${CONFIG_ITEMS[$item]}"
    source_item="${SOURCE_CONFIG_PATH}/${item}"
    dest_item="${CONFIG_PATH}/${item}"
    
    log "처리 중: $item ($type)"
    
    if [ -e "$source_item" ]; then
        # 기존 파일/디렉토리 백업 (존재하는 경우)
        if [ -e "$dest_item" ]; then
            backup_name="${dest_item}.backup.$(date +%Y%m%d_%H%M%S)"
            log "기존 설정 백업: $backup_name"
            mv "$dest_item" "$backup_name"
        fi
        
        # 새 설정 복사
        if [ "$type" = "directory" ]; then
            cp -r "$source_item" "$dest_item"
        else
            cp "$source_item" "$dest_item"
        fi
        
        log "동기화 완료: $item"
    else
        log "WARNING: 소스에서 찾을 수 없음: $source_item"
    fi
done

# 권한 설정
log "권한 설정 중..."
chown -R root:root "$CONFIG_PATH"
find "$CONFIG_PATH" -type d -exec chmod 755 {} \;
find "$CONFIG_PATH" -type f -exec chmod 644 {} \;

# 특별 권한이 필요한 파일들 처리
if [ -f "${CONFIG_PATH}/redis.conf" ]; then
    chmod 644 "${CONFIG_PATH}/redis.conf"
fi

if [ -d "${CONFIG_PATH}/certificates" ]; then
    find "${CONFIG_PATH}/certificates" -name "*.key" -exec chmod 600 {} \; 2>/dev/null || true
fi

# .env 파일이 있다면 복사 (보안상 주의)
if [ -f "${SOURCE_CONFIG_PATH}/.env" ]; then
    log ".env 파일 복사 중..."
    cp "${SOURCE_CONFIG_PATH}/.env" "${CONFIG_PATH}/.env"
    chmod 600 "${CONFIG_PATH}/.env"
fi

# 동기화 정보 저장
sync_info_file="${CONFIG_PATH}/.sync-info"
cat > "$sync_info_file" << EOF
# Coolify Config 동기화 정보
SYNC_DATE=$(date -Iseconds)
GIT_REPO_URL=${GIT_REPO_URL}
GIT_BRANCH=${GIT_BRANCH}
APPLICATION_ID=${APPLICATION_ID}
SCRIPT_VERSION=1.0
EOF

log "동기화 정보 저장: $sync_info_file"

# Docker Compose 서비스 재시작 (옵션)
if command -v docker >/dev/null 2>&1 && [ "${RESTART_SERVICES:-false}" = "true" ]; then
    log "Docker Compose 서비스 재시작 중..."
    
    compose_file="${APP_PATH}/docker-compose.coolify.yml"
    if [ -f "$compose_file" ]; then
        cd "$APP_PATH"
        docker compose -f docker-compose.coolify.yml restart || log "WARNING: 서비스 재시작 실패"
    else
        log "WARNING: Docker Compose 파일을 찾을 수 없음: $compose_file"
    fi
fi

log "=== 동기화 완료 ==="
log "설정 경로: $CONFIG_PATH"
log "동기화된 항목 수: ${#CONFIG_ITEMS[@]}"

# 결과 요약 출력
echo
echo "✅ Coolify 설정 동기화 성공!"
echo "📁 설정 경로: $CONFIG_PATH"
echo "📋 동기화된 설정:"
for item in "${!CONFIG_ITEMS[@]}"; do
    if [ -e "${CONFIG_PATH}/${item}" ]; then
        echo "  ✓ $item"
    else
        echo "  ✗ $item (누락)"
    fi
done
echo
echo "💡 Docker Compose 서비스를 재시작하려면:"
echo "   cd $APP_PATH && docker compose -f docker-compose.coolify.yml restart"