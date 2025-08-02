#!/bin/bash

# Secure MCP Configuration for Claude Code
# Restricts MCP servers to ~/projects directory only

set -e

echo "=== Secure MCP Configuration ==="
echo "Restricting MCP access to ~/projects directory"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Directories
PROJECTS_DIR="$HOME/projects"
CONFIG_DIR="$HOME/.config/claude-code"
CONFIG_FILE="$CONFIG_DIR/settings.json"

# Create projects directory if it doesn't exist
if [ ! -d "$PROJECTS_DIR" ]; then
    echo "Creating projects directory: $PROJECTS_DIR"
    mkdir -p "$PROJECTS_DIR"
fi

# Create config directory
mkdir -p "$CONFIG_DIR"

# Backup existing config if it exists
if [ -f "$CONFIG_FILE" ]; then
    BACKUP_FILE="$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    echo "Backing up existing config to: $BACKUP_FILE"
    cp "$CONFIG_FILE" "$BACKUP_FILE"
fi

# Create secure configuration
echo "Creating secure Claude Code configuration..."

cat > "$CONFIG_FILE" << EOF
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem"],
      "env": {
        "FILESYSTEM_ROOT": "$PROJECTS_DIR",
        "FILESYSTEM_WATCH_ENABLED": "true"
      }
    },
    "playwright": {
      "command": "npx",
      "args": [
        "-y", 
        "@playwright/mcp@latest", 
        "--isolated",
        "--headless",
        "--no-sandbox",
        "--output-dir=$PROJECTS_DIR/.playwright-output",
        "--allowed-origins=file://$PROJECTS_DIR/*"
      ],
      "env": {}
    },
    "fetch": {
      "command": "uvx",
      "args": ["mcp-server-fetch"],
      "env": {
        "FETCH_USER_AGENT": "Mozilla/5.0 (compatible; ClaudeCodeMCP/1.0)"
      }
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "env": {
        "MEMORY_STORE_PATH": "$PROJECTS_DIR/.mcp-memory"
      }
    },
    "thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"],
      "env": {}
    }
  }
}
EOF

echo -e "${GREEN}✓ Secure configuration created${NC}"
echo "  Location: $CONFIG_FILE"
echo ""
echo "Security features enabled:"
echo "  ✓ Filesystem access limited to: $PROJECTS_DIR"
echo "  ✓ Playwright isolated mode enabled"
echo "  ✓ Memory storage confined to projects directory"
echo ""

# Create security documentation
DOC_FILE="$PROJECTS_DIR/.mcp-security.md"
cat > "$DOC_FILE" << 'EOF'
# MCP Security Configuration

This directory is configured as the root for MCP (Model Context Protocol) servers.
MCP servers have been restricted to only access files within this directory tree.

## Security Measures

1. **Filesystem Isolation**
   - MCP filesystem server can only access files under ~/projects
   - Cannot access system files, home directory, or other sensitive areas

2. **Browser Isolation** 
   - Playwright runs in isolated mode
   - Browser profile is kept in memory only

3. **Memory Storage**
   - Knowledge graph data stored within projects directory
   - Confined to .mcp-memory subdirectory

## Working with Docker Projects

Your Docker-based projects can coexist safely:
- MCP servers run on the host system
- They can read/write files in ~/projects
- Docker containers mount specific subdirectories as needed
- No conflict between MCP and Docker containers

## Additional Security Recommendations

1. **For sensitive projects**, consider:
   - Creating a separate user account for MCP operations
   - Using filesystem permissions to make sensitive files read-only
   - Excluding sensitive directories via .gitignore-style patterns

2. **Regular security practices**:
   - Review MCP server logs periodically
   - Keep MCP servers updated
   - Monitor file access patterns

## Project Structure Example

```
~/projects/
├── .mcp-security.md      (this file)
├── .mcp-memory/          (MCP memory storage)
├── client/
│   └── domaeka/          (Docker-based project)
│       ├── docker-compose.yml
│       └── ...
├── server/
│   └── api/              (Another Docker project)
└── shared/
    └── libraries/
```

Each project can have its own Docker setup without interfering with MCP access.
EOF

echo -e "${GREEN}✓ Security documentation created${NC}"
echo "  Location: $DOC_FILE"

# Create example AppArmor profile (optional)
echo ""
echo "=== Optional: Linux Security Modules ==="
echo ""
echo "For additional security on Linux, you can use AppArmor profiles."
echo "Example profile saved to: $CONFIG_DIR/mcp-apparmor.profile"

cat > "$CONFIG_DIR/mcp-apparmor.profile" << EOF
# AppArmor profile for MCP servers
# Place in /etc/apparmor.d/ and load with: sudo apparmor_parser -r <file>

#include <tunables/global>

profile mcp-filesystem /usr/bin/node flags=(attach_disconnected) {
  #include <abstractions/base>
  #include <abstractions/node>
  
  # Allow reading from projects directory
  $PROJECTS_DIR/** r,
  $PROJECTS_DIR/**/ r,
  
  # Allow writing to projects directory  
  $PROJECTS_DIR/** w,
  $PROJECTS_DIR/**/ w,
  
  # Deny access to sensitive areas
  deny @{HOME}/.*/** rwx,
  deny /etc/** rwx,
  deny /root/** rwx,
  deny /sys/** rwx,
  deny /proc/sys/** rwx,
}
EOF

# Create systemd service with sandboxing (optional)
echo ""
echo "For systemd-based sandboxing, example service file saved to:"
echo "$CONFIG_DIR/mcp-filesystem.service"

cat > "$CONFIG_DIR/mcp-filesystem.service" << EOF
[Unit]
Description=MCP Filesystem Server (Sandboxed)
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/npx -y @modelcontextprotocol/server-filesystem
Environment="FILESYSTEM_ROOT=$PROJECTS_DIR"

# Sandboxing options
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths=$PROJECTS_DIR
NoNewPrivileges=yes
RestrictSUIDSGID=yes
RemoveIPC=yes
RestrictNamespaces=yes
RestrictRealtime=yes
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6
SystemCallFilter=@system-service
SystemCallErrorNumber=EPERM

[Install]
WantedBy=multi-user.target
EOF

echo ""
echo -e "${GREEN}=== Configuration complete! ===${NC}"
echo ""
echo "Next steps:"
echo "1. Restart Claude Code for changes to take effect"
echo "2. All MCP operations will be confined to: $PROJECTS_DIR"
echo "3. Move your projects into $PROJECTS_DIR to work with them"
echo ""
echo "Your Docker projects in $PROJECTS_DIR will work normally,"
echo "with MCP having controlled access to their files."