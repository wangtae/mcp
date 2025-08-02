# Playwright MCP 보안 설정 가이드

## 개요

Playwright MCP는 웹 브라우저 자동화를 제공하는 MCP 서버입니다. 브라우저를 제어할 수 있는 강력한 기능 때문에 적절한 보안 설정이 중요합니다.

## 주요 보안 기능

### 1. 격리 모드 (--isolated)
```bash
npx @playwright/mcp@latest --isolated
```
- 브라우저 프로파일을 메모리에만 유지
- 세션 종료 시 모든 데이터 자동 삭제
- 쿠키, 로컬 스토리지 등이 세션 간에 유지되지 않음

### 2. 도메인 접근 제한

#### 허용 목록 (--allowed-origins)
```bash
npx @playwright/mcp@latest --allowed-origins "https://example.com;https://api.example.com"
```
- 세미콜론으로 구분된 도메인 목록
- 지정된 도메인만 접근 가능

#### 차단 목록 (--blocked-origins)
```bash
npx @playwright/mcp@latest --blocked-origins "https://malicious.com;*.tracking.com"
```
- 특정 도메인 차단
- 차단 목록이 허용 목록보다 우선

### 3. 헤드리스 모드 (--headless)
```bash
npx @playwright/mcp@latest --headless
```
- GUI 없이 브라우저 실행
- 서버 환경에서 안전하게 실행

### 4. 출력 디렉토리 제한 (--output-dir)
```bash
npx @playwright/mcp@latest --output-dir=/home/user/projects/.playwright-output
```
- 스크린샷, PDF 등의 출력 파일 저장 위치 제한
- 시스템 디렉토리 접근 방지

## 보안 강화 설정 예시

### 기본 보안 설정
```json
{
  "playwright": {
    "command": "npx",
    "args": [
      "@playwright/mcp@latest",
      "--isolated",
      "--headless",
      "--block-service-workers"
    ]
  }
}
```

### 프로젝트 범위 제한 설정
```json
{
  "playwright": {
    "command": "npx",
    "args": [
      "@playwright/mcp@latest",
      "--isolated",
      "--headless",
      "--output-dir=/home/user/projects/.playwright-output",
      "--allowed-origins=file:///home/user/projects/*",
      "--blocked-origins=*.malicious.com"
    ]
  }
}
```

### 설정 파일 사용
```json
// playwright-config.json
{
  "browser": {
    "browserName": "chromium",
    "isolated": true,
    "launchOptions": {
      "headless": true,
      "args": ["--no-sandbox", "--disable-setuid-sandbox"]
    }
  },
  "capabilities": ["core", "tabs", "pdf"],
  "outputDir": "/home/user/projects/.playwright-output"
}
```

사용:
```bash
npx @playwright/mcp@latest --config /path/to/playwright-config.json
```

## 프로파일 관리

### 지속적 프로파일 (기본값)
- 위치:
  - Windows: `%USERPROFILE%\AppData\Local\ms-playwright\mcp-{channel}-profile`
  - macOS: `~/Library/Caches/ms-playwright/mcp-{channel}-profile`
  - Linux: `~/.cache/ms-playwright/mcp-{channel}-profile`
- 로그인 정보 등이 세션 간에 유지됨

### 격리 프로파일 (권장)
- `--isolated` 옵션 사용
- 매 세션마다 깨끗한 상태로 시작
- 초기 상태는 `--storage-state` 옵션으로 제공 가능

## 보안 체크리스트

- [ ] `--isolated` 모드 사용으로 세션 격리
- [ ] `--allowed-origins`로 접근 가능한 도메인 제한
- [ ] `--headless` 모드로 GUI 노출 방지
- [ ] `--output-dir`로 파일 저장 위치 제한
- [ ] `--block-service-workers`로 서비스 워커 차단
- [ ] 민감한 사이트는 `--blocked-origins`에 추가
- [ ] 프록시 사용 시 `--proxy-server` 설정
- [ ] HTTPS 오류 무시하지 않기 (`--ignore-https-errors` 사용 금지)

## Docker와 함께 사용하기

프로젝트가 Docker를 사용하는 경우:
1. Playwright MCP는 호스트에서 실행
2. 브라우저가 접근할 수 있는 URL만 Docker 컨테이너에서 노출
3. 네트워크 격리로 추가 보안 확보

```yaml
# docker-compose.yml
services:
  web:
    ports:
      - "127.0.0.1:3000:3000"  # localhost만 접근 가능
```

## 문제 해결

### 권한 오류
```bash
# --no-sandbox 옵션 추가 (Docker 환경)
npx @playwright/mcp@latest --no-sandbox
```

### 메모리 사용량
```bash
# 뷰포트 크기 제한
npx @playwright/mcp@latest --viewport-size "1280,720"
```

### 디버깅
```bash
# 트레이스 저장
npx @playwright/mcp@latest --save-trace --output-dir=/tmp/playwright-traces
```