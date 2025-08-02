#!/bin/bash

# Configure Gemini CLI to use Infrastructure MCP
set -e

echo "=== Gemini CLI MCP Configuration ==="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Directories
INFRA_DIR="$HOME/infrastructure"
MCP_DIR="$INFRA_DIR/mcp"

# Check if MCP servers are installed
if [ ! -d "$MCP_DIR/servers" ]; then
    echo -e "${RED}Error: MCP servers not found at $MCP_DIR${NC}"
    echo "Please run ./install-all-mcp.sh first"
    exit 1
fi

# Possible Gemini config locations
POSSIBLE_CONFIGS=(
    "$HOME/.gemini/config.json"
    "$HOME/.config/gemini/settings.json"
    "$HOME/.gemini/settings.json"
    "$HOME/.config/gemini-cli/config.json"
)

# Find or create config
CONFIG_FILE=""
echo "Searching for Gemini configuration file..."

for config in "${POSSIBLE_CONFIGS[@]}"; do
    if [ -f "$config" ]; then
        CONFIG_FILE="$config"
        echo -e "${GREEN}✓ Found existing config at: $CONFIG_FILE${NC}"
        break
    fi
done

if [ -z "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}No existing Gemini configuration found${NC}"
    # Default to first option
    CONFIG_FILE="${POSSIBLE_CONFIGS[0]}"
    echo "Creating new configuration at: $CONFIG_FILE"
fi

# Create config directory
CONFIG_DIR=$(dirname "$CONFIG_FILE")
mkdir -p "$CONFIG_DIR"

# Backup existing config if it exists
if [ -f "$CONFIG_FILE" ]; then
    BACKUP_FILE="$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    echo "Backing up existing config to: $BACKUP_FILE"
    cp "$CONFIG_FILE" "$BACKUP_FILE"
fi

# Create new configuration
echo "Creating Gemini configuration..."

cat > "$CONFIG_FILE" << EOF
{
  "mcpServers": {
    "filesystem": {
      "command": "node",
      "args": ["$MCP_DIR/servers/src/filesystem/dist/index.js"],
      "enabled": true,
      "env": {
        "FILESYSTEM_ROOT": "/",
        "FILESYSTEM_WATCH_ENABLED": "true"
      }
    },
    "playwright": {
      "command": "node",
      "args": ["$MCP_DIR/servers/src/playwright/dist/index.js"],
      "enabled": true,
      "env": {}
    },
    "fetch": {
      "command": "node",
      "args": ["$MCP_DIR/servers/src/fetch/dist/index.js"],
      "enabled": true,
      "env": {
        "FETCH_USER_AGENT": "Mozilla/5.0 (compatible; GeminiMCP/1.0)"
      }
    },
    "memory": {
      "command": "node",
      "args": ["$MCP_DIR/servers/src/memory/dist/index.js"],
      "enabled": true,
      "env": {}
    },
    "thinking": {
      "command": "node",
      "args": ["$MCP_DIR/servers/src/sequentialthinking/dist/index.js"],
      "enabled": true,
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

# Check if Gemini CLI is installed
echo ""
if command -v gemini &> /dev/null; then
    echo -e "${GREEN}✓ Gemini CLI detected${NC}"
    GEMINI_CMD="gemini"
elif command -v gemini-cli &> /dev/null; then
    echo -e "${GREEN}✓ Gemini CLI detected (gemini-cli)${NC}"
    GEMINI_CMD="gemini-cli"
else
    echo -e "${YELLOW}⚠ Gemini CLI not found in PATH${NC}"
    echo ""
    echo "Please ensure Gemini CLI is installed and in your PATH"
    echo "Installation guide: https://github.com/google/gemini-cli"
fi

# Create test script
TEST_SCRIPT="$CONFIG_DIR/test-mcp.sh"
cat > "$TEST_SCRIPT" << 'EOF'
#!/bin/bash
# Test MCP connections for Gemini

echo "Testing MCP connections..."
echo ""

# Test commands
echo "Try these commands in Gemini CLI:"
echo "1. List files in current directory (filesystem)"
echo "2. Open a webpage (playwright)"
echo "3. Fetch content from a URL (fetch)"
echo "4. Create a memory note (memory)"
echo "5. Solve a problem step by step (thinking)"
EOF

chmod +x "$TEST_SCRIPT"

echo ""
echo "=== Project-Specific MCP Configuration ==="
echo ""
echo "To add project-specific MCP (e.g., PostgreSQL), add to your project's .mcp/config.json:"
echo ""
cat << 'EOF'
{
  "postgresql-myproject": {
    "command": "node",
    "args": ["${env:HOME}/infrastructure/mcp/servers/src/postgresql/dist/index.js"],
    "enabled": true,
    "env": {
      "POSTGRES_HOST": "localhost",
      "POSTGRES_PORT": "5432",
      "POSTGRES_USER": "project_user",
      "POSTGRES_PASSWORD": "${env:PROJECT_DB_PASSWORD}",
      "POSTGRES_DATABASE": "project_db"
    }
  }
}
EOF

echo ""
echo -e "${BLUE}Note: MCP support in Gemini CLI may vary${NC}"
echo "Please check Gemini documentation for the latest MCP compatibility"
echo ""
echo -e "${GREEN}Configuration complete!${NC}"