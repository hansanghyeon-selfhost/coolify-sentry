# Coolify용 Sentry Self-Hosted

Coolify에 최적화된 Sentry Self-Hosted 배포 및 설정 동기화 스크립트

## 🚀 빠른 시작

### Coolify에 배포하기

1. **Docker Compose 애플리케이션 생성** - Coolify에서 새 애플리케이션 생성
2. **Git 저장소 설정**: `https://github.com/hansanghyeon-selfhost/coolify-sentry`
3. **도메인 설정**: 도메인 구성 (예: `https://sentry.yourdomain.com`)
4. **배포**: 초기화까지 10-15분 대기
5. **접속**: `admin@localhost` / `admin`으로 로그인 (즉시 변경 필요!)

### Git에서 설정 동기화

Git 저장소의 최신 설정으로 Coolify 배포 업데이트:

```bash
# YOUR_APPLICATION_ID를 실제 Coolify 앱 ID로 변경
curl -fsSL https://raw.githubusercontent.com/hansanghyeon-selfhost/coolify-sentry/main/sync-coolify-config.sh | sudo bash -s -- YOUR_APPLICATION_ID
```

**애플리케이션 ID 찾는 방법**:
- Coolify URL에서: `/applications/YOUR_APPLICATION_ID`
- 컨테이너에서: `docker ps | grep sentry`
- 디렉토리에서: `ls /data/coolify/applications/`

## 📋 요구사항

- **최소**: 4GB RAM, 2 CPU 코어, 20GB 스토리지
- **권장**: 8GB RAM, 4 CPU 코어, 50GB 스토리지

## 📚 참고 문서

- **공식 문서**: [Sentry Self-Hosted 가이드](https://develop.sentry.dev/self-hosted/)
