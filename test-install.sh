#!/bin/bash
# Test the dotfiles install script in Docker

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Dotfiles Installation Test Suite    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker is not installed${NC}"
    echo -e "${YELLOW}Install Docker Desktop or Docker Engine first${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker detected${NC}"
echo ""

# Build test image
echo -e "${BLUE}[1/3] Building test Docker image...${NC}"
docker build -f "$SCRIPT_DIR/Dockerfile.test" -t dotfiles-test "$SCRIPT_DIR"
echo -e "${GREEN}✓ Test image built${NC}"
echo ""

# Run installation test
echo -e "${BLUE}[2/3] Running installation test...${NC}"
echo -e "${YELLOW}This will test the install.sh script in a clean Ubuntu environment${NC}"
echo ""

# Pass GITHUB_TOKEN if available to avoid rate limits
DOCKER_ENV_ARGS=""
if [ -n "$GITHUB_TOKEN" ]; then
    echo -e "${GREEN}✓ Using GITHUB_TOKEN for mise downloads${NC}"
    DOCKER_ENV_ARGS="-e GITHUB_TOKEN=$GITHUB_TOKEN"
else
    echo -e "${YELLOW}⚠ No GITHUB_TOKEN - may hit GitHub API rate limits${NC}"
    echo -e "${YELLOW}  Set GITHUB_TOKEN env var to increase rate limit${NC}"
fi
echo ""

docker run --rm -it $DOCKER_ENV_ARGS dotfiles-test bash -c '
set -e

echo "========================================="
echo "Testing: dotfiles installation"
echo "========================================="
echo ""

# Initialize git repository so submodules can be initialized
git init
git add .
git -c user.name="Test" -c user.email="test@example.com" commit -m "Initial commit"

# Create minimal .env for testing
cp .env.example .env

# Run the install script
./install.sh

echo ""
echo "========================================="
echo "Verifying installation..."
echo "========================================="
echo ""

# Check if mise was installed
if command -v mise &> /dev/null; then
    echo "✓ mise installed successfully"
    mise --version
else
    echo "✗ mise installation failed"
    exit 1
fi

# Check if symlinks were created
if [ -L ~/.zshrc ]; then
    echo "✓ .zshrc symlink created"
else
    echo "✗ .zshrc symlink missing"
    exit 1
fi

if [ -L ~/.tmux.conf ]; then
    echo "✓ .tmux.conf symlink created"
else
    echo "✗ .tmux.conf symlink missing"
    exit 1
fi

if [ -f ~/.claude/settings.json ]; then
    echo "✓ Claude settings generated"
else
    echo "✗ Claude settings missing"
    exit 1
fi

# Check some key mise tools (these should install quickly)
echo ""
echo "Testing mise tool installation..."
if command -v git &> /dev/null; then
    echo "✓ git available"
else
    echo "⚠ git not available (expected if mise install was skipped)"
fi

echo ""
echo "✓ All basic checks passed!"
'

EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   Installation Test: PASSED ✓         ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
else
    echo -e "${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║   Installation Test: FAILED ✗         ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
fi

echo ""
echo -e "${BLUE}[3/3] Cleanup...${NC}"
echo -e "${YELLOW}Test container automatically removed${NC}"
echo ""

exit $EXIT_CODE
