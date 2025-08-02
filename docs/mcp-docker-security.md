# MCP Docker 보안 격리 가이드

## 개요

MCP 서버들의 보안 취약점을 최소화하기 위한 격리 전략 문서입니다.

## Docker 기반 격리의 한계

### MCP 통신 구조
```
Claude Desktop/VS Code <--stdio/pipe--> MCP Server <--file access--> File System
```

MCP는 stdio/pipe를 통해 직접 통신하므로, Docker 컨테이너로 완전히 격리하면:
- Claude가 컨테이너 내부 프로세스를 직접 실행할 수 없음
- 복잡한 프록시 레이어 필요
- 성능 저하 및 안정성 문제 발생

## 권장 보안 전략

### 1. 파일시스템 수준 격리

```bash
# filesystem MCP 설정
"env": {
  "FILESYSTEM_ROOT": "/home/user/projects",
  "FILESYSTEM_WATCH_ENABLED": "true"
}
```

### 2. 하이브리드 접근 방식

```
Host System
├── MCP Servers (격리된 권한으로 실행)
│   └── 접근 가능: ~/projects/* 만
├── ~/projects/
│   ├── client/domaeka/ (Docker 프로젝트)
│   │   ├── docker-compose.yml
│   │   └── Dockerfile
│   └── server/api/ (Docker 프로젝트)
│       ├── docker-compose.yml
│       └── Dockerfile
```

### 3. Docker 프로젝트와의 공존

각 프로젝트가 Docker를 사용해도 충돌 없음:
- MCP는 호스트에서 파일만 읽고 씀
- Docker 컨테이너는 필요한 디렉토리만 마운트
- 네트워크 격리로 포트 충돌 방지

## 보안 강화 옵션

### Linux 보안 모듈 활용

#### AppArmor 프로파일
```bash
# MCP 서버에 대한 접근 제한
profile mcp-filesystem {
  # ~/projects 읽기/쓰기 허용
  /home/*/projects/** rw,
  
  # 민감한 영역 차단
  deny /etc/** rwx,
  deny /root/** rwx,
}
```

#### SELinux 컨텍스트
```bash
# MCP 전용 SELinux 컨텍스트 생성
semanage fcontext -a -t mcp_file_t "/home/*/projects(/.*)?"
restorecon -R ~/projects
```

### systemd 샌드박싱

```ini
[Service]
# 파일시스템 보호
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths=/home/user/projects

# 권한 제한
NoNewPrivileges=yes
PrivateDevices=yes
PrivateTmp=yes

# 시스템 콜 필터링
SystemCallFilter=@system-service
SystemCallErrorNumber=EPERM
```

## 실제 구현 예시

### 1. 프로젝트 구조
```
~/projects/
├── .mcp-config/          # MCP 설정
├── client/
│   └── domaeka/
│       ├── docker-compose.yml
│       ├── Dockerfile
│       └── src/
└── server/
    └── api/
        ├── docker-compose.yml
        └── src/
```

### 2. docker-compose.yml 예시
```yaml
version: '3.8'
services:
  app:
    build: .
    volumes:
      # 특정 디렉토리만 마운트
      - ./src:/app/src:ro
      - ./public:/app/public
    networks:
      - app-network
```

### 3. MCP 설정
```json
{
  "filesystem": {
    "env": {
      "FILESYSTEM_ROOT": "/home/user/projects",
      "FILESYSTEM_ALLOWED_DIRECTORIES": [
        "/home/user/projects/client",
        "/home/user/projects/server"
      ]
    }
  }
}
```

## 보안 체크리스트

- [ ] MCP 서버 접근 범위를 ~/projects로 제한
- [ ] 민감한 프로젝트는 읽기 전용으로 설정
- [ ] 정기적인 접근 로그 검토
- [ ] MCP 서버 정기 업데이트
- [ ] 불필요한 MCP 서버 비활성화
- [ ] 프로젝트별 .mcp-ignore 파일로 제외 규칙 설정

## 결론

완전한 Docker 격리보다는 **권한 기반 격리**가 MCP 서버에 더 적합합니다:
- 실용성과 보안성의 균형
- Docker 프로젝트와 충돌 없음
- 성능 저하 최소화
- 관리 복잡도 감소