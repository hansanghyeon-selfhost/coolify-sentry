# Coolify용 Sentry Self-Hosted

이 저장소는 `install.sh` 스크립트 없이 git 저장소에서 직접 배포할 수 있도록 Coolify에 최적화된 Sentry Self-Hosted 버전을 포함합니다.

## 🚀 빠른 배포

### 사전 요구사항
- 실행 중인 Coolify 인스턴스
- 서버에 최소 4GB RAM과 20GB 스토리지
- Coolify 인스턴스에 구성된 도메인 이름

### 배포 단계

1. **이 저장소 포크 또는 클론**
   ```bash
   git clone <this-repository-url>
   cd sentry-self-hosted-coolify
   ```

2. **Coolify에서 새 애플리케이션 생성**
   - Coolify 대시보드로 이동
   - 새로운 "Docker Compose" 애플리케이션 생성
   - Git 저장소 URL을 이 저장소로 설정
   - 브랜치 설정 (보통 `main` 또는 `master`)

3. **환경 변수 구성**
   - Coolify에서 애플리케이션의 Environment 탭으로 이동
   - `.env.coolify`의 내용을 복사하여 환경 변수로 붙여넣기
   - 필요에 따라 값 커스터마이징 (특히 `SENTRY_MAIL_HOST`)

4. **배포**
   - Coolify에서 "Deploy" 클릭
   - 배포 완료까지 대기 (첫 실행 시 10-15분 소요될 수 있음)

5. **Sentry 인스턴스 접속**
   - Coolify에서 제공하는 URL 사용
   - 기본 자격증명:
     - 이메일: `admin@localhost`
     - 비밀번호: `admin`
   - **⚠️ 첫 로그인 후 즉시 이 자격증명을 변경하세요!**

## 📋 구성

### 환경 변수

커스터마이징해야 할 주요 환경 변수:

```env
# 이메일 알림용 도메인
SENTRY_MAIL_HOST=your-domain.com

# 데이터 보존 기간 (일)
SENTRY_EVENT_RETENTION_DAYS=90

# 선택사항: 커스텀 비밀키 (제공하지 않으면 자동 생성)
SENTRY_SECRET_KEY=your-secret-key-here

# 선택사항: 알림용 이메일 구성
SENTRY_MAIL_USERNAME=smtp-username
SENTRY_MAIL_PASSWORD=smtp-password
SENTRY_MAIL_USE_TLS=true
```

### 리소스 요구사항

**최소:**
- 4GB RAM
- 2 CPU 코어
- 20GB 스토리지

**권장:**
- 8GB RAM
- 4 CPU 코어
- 50GB 스토리지

## 🏗️ 아키텍처

이 배포는 모든 필수 Sentry 서비스를 포함합니다:

### 핵심 서비스
- **Web**: Sentry 웹 인터페이스
- **Worker**: 백그라운드 작업 처리
- **Cron**: 예약된 작업 실행
- **Init**: 데이터베이스 초기화 및 마이그레이션

### 데이터 서비스
- **PostgreSQL**: 주 데이터베이스
- **Redis**: 캐시 및 메시지 브로커
- **ClickHouse**: 분석 데이터베이스
- **Kafka + Zookeeper**: 이벤트 스트리밍

### 처리 서비스
- **Snuba**: 이벤트 처리 및 분석
- **Symbolicator**: 디버그 심볼 처리
- **Relay**: 이벤트 전달
- **Vroom**: 프로파일링 서비스

### 인프라
- **SMTP**: 이메일 전송
- **Memcached**: 추가 캐싱

## 🔧 커스터마이징

### 커스텀 인증서 추가

1. `config/certificates/` 디렉토리에 인증서를 배치
2. 애플리케이션 재배포

### 외부 서비스 구성

`config/` 디렉토리의 구성 파일 편집:

- `config/sentry/config.yml` - 메인 Sentry 구성
- `config/sentry/sentry.conf.py` - Python 구성
- `config/relay/config.yml` - Relay 구성
- `config/symbolicator/config.yml` - Symbolicator 구성

### 이메일 구성

프로덕션 사용을 위해 SMTP 설정 구성:

```yaml
# config/sentry/config.yml에서
mail.backend: 'smtp'
mail.host: 'your-smtp-server.com'
mail.port: 587
mail.username: 'your-username'
mail.password: 'your-password'
mail.use-tls: true
```

## 🔍 문제 해결

### 일반적인 문제

1. **"No Available Server" 오류**
   - Coolify 로그에서 컨테이너 상태 확인
   - 모든 서비스가 실행 중이고 정상인지 확인
   - 초기화 완료 대기 (10-15분 소요 가능)

2. **데이터베이스 연결 오류**
   - PostgreSQL 서비스 상태 확인
   - 데이터베이스 초기화 완료 확인
   - init 컨테이너 로그 검토

3. **메모리 문제**
   - 서버 리소스 증가
   - `SENTRY_EVENT_RETENTION_DAYS` 감소
   - Coolify에서 리소스 사용량 모니터링

### 로그 접근

Coolify에서:
1. 애플리케이션으로 이동
2. "Logs" 탭 클릭
3. 검사할 서비스 선택
4. 실시간 또는 과거 로그 확인

### 컨테이너 셸 접근

Coolify의 컨테이너 관리 사용 또는 서버에 SSH 접속:

```bash
# 컨테이너 목록
docker ps | grep sentry

# Sentry 웹 컨테이너 접근
docker exec -it <container-name> bash

# Sentry 명령 실행
docker exec -it <container-name> sentry help
```

## 🔄 업데이트

Sentry 업데이트 방법:

1. `.env.coolify`에서 이미지 태그 업데이트
2. git 저장소에 변경사항 커밋
3. Coolify에서 재배포
4. 배포 로그에서 문제 모니터링

## 🛡️ 보안 고려사항

1. **기본 자격증명 변경**: 즉시 기본 관리자 자격증명 변경
2. **비밀키**: 강력하고 고유한 비밀키 사용
3. **데이터베이스 보안**: 프로덕션에서는 외부 관리형 데이터베이스 사용 고려
4. **HTTPS**: Coolify가 SSL 인증서로 구성되었는지 확인
5. **방화벽**: 필요한 포트에만 액세스 제한
6. **백업**: 데이터 볼륨의 정기 백업 설정

## 📚 추가 리소스

- [Sentry Self-Hosted 문서](https://develop.sentry.dev/self-hosted/)
- [Coolify 문서](https://coolify.io/docs)
- [Sentry 구성 참조](https://docs.sentry.io/product/sentry-basics/installation/config/)

## 🆘 지원

문제가 발생하면:

1. 위의 문제 해결 섹션 확인
2. Coolify 및 컨테이너 로그 검토
3. 공식 Sentry 문서 참조
4. 상세한 로그와 구성을 포함하여 이 저장소에 이슈 열기

## 📝 표준 설치와의 차이점

이 저장소는 표준 Sentry self-hosted 설치를 수정합니다:

1. **install.sh 없음**: 모든 설정이 Docker 초기화로 처리됨
2. **사전 구성됨**: 구성 파일이 저장소에 포함됨
3. **Coolify 최적화**: Docker Compose가 Coolify 배포에 최적화됨
4. **자동 초기화**: 데이터베이스 설정 및 마이그레이션이 자동으로 수행됨
5. **비밀키 생성**: 제공하지 않으면 비밀키가 자동으로 생성됨

기능은 표준 설치와 동일하며, Coolify와 같은 컨테이너화된 배포 플랫폼에 최적화되었습니다.