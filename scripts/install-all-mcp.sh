#!/bin/bash

# Infrastructure MCP Installation Script
# Installs all MCP servers to ~/infrastructure/mcp

set -e  # Exit on error

echo "=== Infrastructure MCP Installation ==="
echo "Installing MCP servers to ~/infrastructure/mcp"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Base directories
INFRA_DIR="$HOME/infrastructure"
MCP_DIR="$INFRA_DIR/mcp"
SCRIPTS_DIR="$MCP_DIR/scripts"

# Check prerequisites
echo "Checking prerequisites..."

# Check Node.js version
if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: Node.js is not installed${NC}"
    echo "Please install Node.js 18 or higher"
    exit 1
fi

NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo -e "${RED}Error: Node.js version must be 18 or higher${NC}"
    echo "Current version: $(node -v)"
    exit 1
fi

echo -e "${GREEN}✓ Node.js $(node -v) detected${NC}"

# Check for Python and uv/uvx for Python-based servers
if command -v uvx &> /dev/null; then
    echo -e "${GREEN}✓ uvx detected (for Python MCP servers)${NC}"
elif command -v python3 &> /dev/null || command -v python &> /dev/null; then
    echo -e "${YELLOW}⚠ Python detected but uvx not found${NC}"
    echo "  Consider installing uv for easier Python MCP server management:"
    echo "  curl -LsSf https://astral.sh/uv/install.sh | sh"
else
    echo -e "${YELLOW}⚠ Python not detected${NC}"
    echo "  Some MCP servers (fetch, git) require Python"
fi

# Check git
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: Git is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Git detected${NC}"

cd "$MCP_DIR"

# Clone or update official MCP servers repository
echo ""
echo -e "${YELLOW}Installing official MCP servers...${NC}"

if [ -d "servers" ]; then
    echo "Updating existing servers repository..."
    cd servers
    git pull origin main
else
    echo "Cloning MCP servers repository..."
    git clone https://github.com/modelcontextprotocol/servers.git
    cd servers
fi

# Build TypeScript/JavaScript MCP servers
echo ""
echo "Building TypeScript/JavaScript MCP servers..."

TS_SERVERS=(
    "filesystem"
    "memory"
    "sequentialthinking"
    "everything"
)

for server in "${TS_SERVERS[@]}"; do
    if [ -d "src/$server" ]; then
        echo ""
        echo -e "${YELLOW}Building $server MCP...${NC}"
        cd "src/$server"
        
        # Check if package.json exists
        if [ -f "package.json" ]; then
            # Install dependencies
            echo "Installing dependencies..."
            npm install --silent
            
            # Build
            echo "Building..."
            npm run build
            
            if [ -f "dist/index.js" ]; then
                echo -e "${GREEN}✓ $server MCP built successfully${NC}"
            else
                echo -e "${RED}✗ Failed to build $server MCP${NC}"
            fi
        else
            echo -e "${YELLOW}⚠ $server is not a Node.js project, skipping build${NC}"
        fi
        
        cd ../..
    else
        echo -e "${YELLOW}⚠ $server directory not found, skipping${NC}"
    fi
done

# Note about Python servers
echo ""
echo -e "${YELLOW}Python-based MCP servers:${NC}"
echo "  • fetch - Install with: pip install mcp-server-fetch"
echo "  • git   - Install with: pip install mcp-server-git"
echo "  These servers don't need building and can be run with uvx or python -m"

# All servers are now built, check for sequential thinking
echo ""
echo "Checking Sequential Thinking MCP..."
if [ -f "$MCP_DIR/servers/src/sequentialthinking/dist/index.js" ]; then
    echo -e "${GREEN}✓ Sequential Thinking MCP built successfully${NC}"
else
    echo -e "${YELLOW}⚠ Sequential Thinking might have a different path${NC}"
fi

# Create helper scripts
cd "$SCRIPTS_DIR"

# Create update script
cat > update-mcp.sh << 'EOF'
#!/bin/bash
# Update all MCP servers

set -e
MCP_DIR="$HOME/infrastructure/mcp"

echo "Updating MCP servers..."

# Update official servers
cd "$MCP_DIR/servers"
git pull origin main

# Rebuild TypeScript servers only
for server in filesystem memory sequentialthinking everything; do
    if [ -d "src/$server" ] && [ -f "src/$server/package.json" ]; then
        echo "Rebuilding $server..."
        cd "src/$server"
        npm install
        npm run build
        cd ../..
    fi
done

echo ""
echo "Note: Python servers (fetch, git) and npx-based servers (playwright)"
echo "are automatically updated when run."

echo "✓ All MCP servers updated"
EOF

chmod +x update-mcp.sh

# Create backup script
cat > backup-mcp.sh << 'EOF'
#!/bin/bash
# Backup MCP installation

MCP_DIR="$HOME/infrastructure/mcp"
BACKUP_DIR="$MCP_DIR/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

echo "Creating backup..."
tar -czf "$BACKUP_DIR/mcp-backup-$DATE.tar.gz" \
    --exclude="*/node_modules" \
    --exclude="*/.git" \
    -C "$HOME/infrastructure" \
    mcp/servers

echo "✓ Backup created: $BACKUP_DIR/mcp-backup-$DATE.tar.gz"

# Keep only last 5 backups
cd "$BACKUP_DIR"
ls -t mcp-backup-*.tar.gz | tail -n +6 | xargs -r rm

echo "✓ Old backups cleaned up"
EOF

chmod +x backup-mcp.sh

# Summary
echo ""
echo "=== Installation Summary ==="
echo ""
echo "MCP servers installed to: $MCP_DIR"
echo ""
echo "Available servers:"
echo "  • filesystem - File system access (TypeScript)"
echo "  • playwright - Browser automation (install via npx @playwright/mcp)"
echo "  • fetch     - Web content fetching (Python - use uvx mcp-server-fetch)"
echo "  • memory    - Knowledge graph storage (TypeScript)"
echo "  • thinking  - Sequential problem solving (TypeScript)"
echo "  • git       - Git repository access (Python - use uvx mcp-server-git)"
echo ""
echo "Helper scripts created in: $SCRIPTS_DIR"
echo "  • update-mcp.sh - Update all MCP servers"
echo "  • backup-mcp.sh - Backup MCP installation"
echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Run ./configure-claude-code.sh to configure Claude Code"
echo "2. Run ./configure-gemini.sh to configure Gemini CLI"