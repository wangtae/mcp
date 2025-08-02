# Infrastructure MCP 설치 현황

## 설치 완료된 MCP 서버

### 전역 MCP (모든 프로젝트 공통)
- ✅ **filesystem**: 파일 시스템 접근
  - 경로: `~/infrastructure/mcp/servers/src/filesystem/dist/index.js`
- ✅ **memory**: 지식 그래프 저장소
  - 경로: `~/infrastructure/mcp/servers/src/memory/dist/index.js`
- ✅ **thinking** (sequentialthinking): 순차적 사고 문제 해결
  - 경로: `~/infrastructure/mcp/servers/src/sequentialthinking/dist/index.js`

### 추가 사용 가능 서버 (servers 저장소)
- ✅ **everything**: 모든 기능 통합
  - 경로: `~/infrastructure/mcp/servers/src/everything/dist/index.js`
- ⏳ **git**: Git 저장소 작업 (빌드 필요)
- ⏳ **time**: 시간 관련 기능 (빌드 필요)

### 현재 미지원 서버
- ❌ **playwright**: 별도 저장소 없음 (puppeteer 사용 고려)
- ❌ **fetch**: 별도 저장소 없음

## 설정 파일 위치

- **Claude Code**: `~/.config/claude-code/settings.json`
- **Gemini CLI**: `~/.gemini/settings.json`

## 프로젝트별 MCP 설정 예시

각 프로젝트 루트에 `.mcp/config.json` 파일 생성:

```json
{
  "mysql-myproject": {
    "command": "node",
    "args": ["${env:HOME}/infrastructure/mcp/servers/src/mysql/dist/index.js"],
    "env": {
      "MYSQL_HOST": "localhost",
      "MYSQL_PORT": "3306",
      "MYSQL_USER": "project_user",
      "MYSQL_PASSWORD": "${env:PROJECT_DB_PASSWORD}",
      "MYSQL_DATABASE": "project_db"
    }
  }
}
```

## 관리 스크립트

- `scripts/install-all-mcp.sh`: MCP 서버 설치
- `scripts/configure-claude-code.sh`: Claude Code 설정
- `scripts/configure-gemini.sh`: Gemini CLI 설정
- `scripts/update-mcp.sh`: MCP 서버 업데이트
- `scripts/backup-mcp.sh`: MCP 백업

## 업데이트 방법

```bash
cd ~/infrastructure/mcp/scripts
./update-mcp.sh
```

## 백업 방법

```bash
cd ~/infrastructure/mcp/scripts
./backup-mcp.sh
```

## 추가 MCP 설치가 필요한 경우

1. MySQL/PostgreSQL MCP가 필요한 경우:
   ```bash
   cd ~/infrastructure/mcp/servers/src
   # mysql 또는 postgresql 디렉토리가 있는지 확인
   # 있다면 해당 디렉토리에서 npm install && npm run build
   ```

2. Playwright 대체 (Puppeteer) 설치:
   ```bash
   npm install -g puppeteer-mcp-server
   # 또는 로컬 빌드 방식으로 설치
   ```

## 주의사항

- 모든 MCP 실행 파일은 `~/infrastructure/mcp`에 중앙 관리
- 프로젝트별로는 설정 파일만 관리 (`.mcp/config.json`)
- 업데이트 시 백업 필수
- Claude Code 재시작 필요 (설정 변경 후)