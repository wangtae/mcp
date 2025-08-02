#!/bin/bash

# Configure Claude Code to use Infrastructure MCP
set -e

echo "=== Claude Code MCP Configuration ==="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Directories
INFRA_DIR="$HOME/infrastructure"
MCP_DIR="$INFRA_DIR/mcp"
CONFIG_DIR="$HOME/.config/claude-code"
CONFIG_FILE="$CONFIG_DIR/settings.json"

# Check if MCP servers are installed
if [ ! -d "$MCP_DIR/servers" ]; then
    echo -e "${RED}Error: MCP servers not found at $MCP_DIR${NC}"
    echo "Please run ./install-all-mcp.sh first"
    exit 1
fi

# Create config directory
mkdir -p "$CONFIG_DIR"

# Backup existing config if it exists
if [ -f "$CONFIG_FILE" ]; then
    BACKUP_FILE="$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    echo "Backing up existing config to: $BACKUP_FILE"
    cp "$CONFIG_FILE" "$BACKUP_FILE"
fi

# Create new configuration
echo "Creating Claude Code configuration..."

cat > "$CONFIG_FILE" << EOF
{
  "mcpServers": {
    "filesystem": {
      "command": "node",
      "args": ["$MCP_DIR/servers/src/filesystem/dist/index.js"],
      "env": {
        "FILESYSTEM_ROOT": "/",
        "FILESYSTEM_WATCH_ENABLED": "true"
      }
    },
    "playwright": {
      "command": "node",
      "args": ["$MCP_DIR/servers/src/playwright/dist/index.js"],
      "env": {}
    },
    "fetch": {
      "command": "node",
      "args": ["$MCP_DIR/servers/src/fetch/dist/index.js"],
      "env": {
        "FETCH_USER_AGENT": "Mozilla/5.0 (compatible; ClaudeCodeMCP/1.0)"
      }
    },
    "memory": {
      "command": "node",
      "args": ["$MCP_DIR/servers/src/memory/dist/index.js"],
      "env": {}
    },
    "thinking": {
      "command": "node",
      "args": ["$MCP_DIR/servers/src/sequentialthinking/dist/index.js"],
      "env": {}
    }
  }
}
EOF

echo -e "${GREEN}✓ Configuration created successfully${NC}"
echo "  Location: $CONFIG_FILE"

# Verify MCP installations
echo ""
echo "Verifying MCP installations:"
check_mcp() {
    if [ -f "$1" ]; then
        echo -e "  $2: ${GREEN}✓${NC}"
    else
        echo -e "  $2: ${RED}✗ Not found${NC}"
    fi
}

check_mcp "$MCP_DIR/servers/src/filesystem/dist/index.js" "filesystem"
check_mcp "$MCP_DIR/servers/src/playwright/dist/index.js" "playwright"
check_mcp "$MCP_DIR/servers/src/fetch/dist/index.js" "fetch"
check_mcp "$MCP_DIR/servers/src/memory/dist/index.js" "memory"
check_mcp "$MCP_DIR/servers/src/sequentialthinking/dist/index.js" "thinking"

# Check if Claude Code is running
echo ""
if pgrep -f "claude-code" > /dev/null; then
    echo -e "${YELLOW}Claude Code is currently running${NC}"
    echo "Please restart Claude Code for changes to take effect:"
    echo "  1. Close Claude Code"
    echo "  2. Run: claude-code"
else
    echo "Start Claude Code to use the configured MCP servers"
fi

# Create project-specific MCP example
echo ""
echo "=== Project-Specific MCP Configuration ==="
echo ""
echo "To add project-specific MCP (e.g., MySQL), add to your project's .mcp/config.json:"
echo ""
cat << 'EOF'
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
EOF

echo ""
echo -e "${GREEN}Configuration complete!${NC}"