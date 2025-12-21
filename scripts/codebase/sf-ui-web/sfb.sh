#!/bin/bash
# sf - Build/clean utility for sf-ui-web
# Usage: sf [OPTIONS]

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Flags
CLEAN_DIST=false
CLEAN_TURBO=false
CLEAN_GENERATED=false
REBUILD=false
CODEGEN=false
DRY_RUN=false
SHOW_HELP=false

# Find sf-ui-web directory
find_sf_ui_web() {
    local current_dir="$PWD"

    # Check if we're already in sf-ui-web
    if [[ -f "package.json" ]] && grep -q '"name": "sf-ui-web"' package.json 2>/dev/null; then
        echo "$PWD"
        return 0
    fi

    # Check if we're in a subdirectory of sf-ui-web
    while [[ "$current_dir" != "/" ]]; do
        if [[ -f "$current_dir/package.json" ]] && grep -q '"name": "sf-ui-web"' "$current_dir/package.json" 2>/dev/null; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done

    # Default to ~/codebase/sf-ui-web
    if [[ -d "$HOME/codebase/sf-ui-web" ]]; then
        echo "$HOME/codebase/sf-ui-web"
        return 0
    fi

    echo ""
    return 1
}

# Show help
show_help() {
    printf '%b\n' "${BLUE}sf${NC} - Build/clean utility for sf-ui-web"
    printf '\n'
    printf '%b\n' "${YELLOW}USAGE:${NC}"
    printf '%b\n' "    sf [OPTIONS]"
    printf '\n'
    printf '%b\n' "${YELLOW}OPTIONS:${NC}"
    printf '%b\n' "    -d, --dist          Clean build artifacts (dist/, .next/)"
    printf '%b\n' "    -t, --turbo         Clean turbo cache (.turbo/)"
    printf '%b\n' "    -g, --generated     Clean generated GraphQL files (*.generated.ts)"
    printf '%b\n' "    -a, --all           Clean everything (dist + turbo + generated)"
    printf '%b\n' "    -r, --rebuild       Rebuild libraries after cleaning"
    printf '%b\n' "    -c, --codegen       Run GraphQL codegen"
    printf '%b\n' "    -f, --full          Full clean + codegen + rebuild (equivalent to -a -c -r)"
    printf '%b\n' "    -n, --dry-run       Show what would be cleaned without actually cleaning"
    printf '%b\n' "    -h, --help          Show this help message"
    printf '\n'
    printf '%b\n' "${YELLOW}EXAMPLES:${NC}"
    printf '%b\n' "    sf                  Quick rebuild (codegen + lib:build)"
    printf '%b\n' "    sf -d -r            Clean dist folders and rebuild"
    printf '%b\n' "    sf -f               Full clean, codegen, and rebuild"
    printf '%b\n' "    sf -c -r            Run codegen and rebuild (common after branch switch)"
    printf '%b\n' "    sf -n -a            Dry-run to see what would be cleaned with --all"
    printf '\n'
    printf '%b\n' "${YELLOW}COMMON WORKFLOWS:${NC}"
    printf '%b\n' "    After switching branches:   sf -c -r"
    printf '%b\n' "    Full reset:                 sf -f"
    printf '%b\n' "    Just clean artifacts:       sf -d"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dist)
            CLEAN_DIST=true
            shift
            ;;
        -t|--turbo)
            CLEAN_TURBO=true
            shift
            ;;
        -g|--generated)
            CLEAN_GENERATED=true
            shift
            ;;
        -a|--all)
            CLEAN_DIST=true
            CLEAN_TURBO=true
            CLEAN_GENERATED=true
            shift
            ;;
        -r|--rebuild)
            REBUILD=true
            shift
            ;;
        -c|--codegen)
            CODEGEN=true
            shift
            ;;
        -f|--full)
            CLEAN_DIST=true
            CLEAN_TURBO=true
            CLEAN_GENERATED=true
            CODEGEN=true
            REBUILD=true
            shift
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Find sf-ui-web directory
SF_UI_WEB=$(find_sf_ui_web)
if [[ -z "$SF_UI_WEB" ]]; then
    echo -e "${RED}✗ Could not find sf-ui-web directory${NC}"
    echo "  Searched current directory and ~/codebase/sf-ui-web"
    exit 1
fi

echo -e "${BLUE}📦 sf-ui-web location: ${NC}$SF_UI_WEB"
cd "$SF_UI_WEB" || exit 1

# Check if yarn is available
if ! command -v yarn &> /dev/null; then
    echo -e "${RED}✗ yarn is not installed${NC}"
    exit 1
fi

# Default behavior: if no options specified, do codegen + rebuild
if ! $CLEAN_DIST && ! $CLEAN_TURBO && ! $CLEAN_GENERATED && ! $REBUILD && ! $CODEGEN; then
    CODEGEN=true
    REBUILD=true
fi

# Dry run mode
if $DRY_RUN; then
    echo -e "${YELLOW}🔍 DRY RUN MODE - No changes will be made${NC}"
    echo ""
fi

# Clean dist folders
if $CLEAN_DIST; then
    echo -e "${YELLOW}🧹 Cleaning build artifacts (dist/, .next/)...${NC}"
    if $DRY_RUN; then
        find . -name "dist" -type d -not -path "*/node_modules/*" 2>/dev/null | while read -r dir; do
            echo "  Would remove: $dir"
        done
        find . -name ".next" -type d -not -path "*/node_modules/*" 2>/dev/null | while read -r dir; do
            echo "  Would remove: $dir"
        done
    else
        find . -name "dist" -type d -not -path "*/node_modules/*" -prune -exec rm -rf {} + 2>/dev/null
        find . -name ".next" -type d -not -path "*/node_modules/*" -prune -exec rm -rf {} + 2>/dev/null
        echo -e "${GREEN}✓ Build artifacts cleaned${NC}"
    fi
fi

# Clean turbo cache
if $CLEAN_TURBO; then
    echo -e "${YELLOW}🧹 Cleaning turbo cache (.turbo/)...${NC}"
    if $DRY_RUN; then
        if [[ -d ".turbo" ]]; then
            echo "  Would remove: .turbo/"
        else
            echo "  No .turbo/ directory found"
        fi
    else
        if [[ -d ".turbo" ]]; then
            rm -rf .turbo
            echo -e "${GREEN}✓ Turbo cache cleaned${NC}"
        else
            echo -e "${YELLOW}  No .turbo/ directory found${NC}"
        fi
    fi
fi

# Clean generated files
if $CLEAN_GENERATED; then
    echo -e "${YELLOW}🧹 Cleaning generated GraphQL files (*.generated.ts)...${NC}"
    if $DRY_RUN; then
        find . -name "*.generated.ts" -not -path "*/node_modules/*" 2>/dev/null | while read -r file; do
            echo "  Would remove: $file"
        done
    else
        find . -name "*.generated.ts" -not -path "*/node_modules/*" -delete 2>/dev/null
        echo -e "${GREEN}✓ Generated files cleaned${NC}"
    fi
fi

# Exit if dry run
if $DRY_RUN; then
    echo ""
    echo -e "${BLUE}ℹ  This was a dry run. Run without -n/--dry-run to apply changes.${NC}"
    exit 0
fi

# Run codegen
if $CODEGEN; then
    echo -e "${BLUE}🔧 Running GraphQL codegen...${NC}"
    if yarn gql:codegen; then
        echo -e "${GREEN}✓ Codegen complete${NC}"
    else
        echo -e "${RED}✗ Codegen failed${NC}"
        exit 1
    fi
fi

# Rebuild libraries
if $REBUILD; then
    echo -e "${BLUE}🔨 Rebuilding libraries...${NC}"
    if yarn lib:build; then
        echo -e "${GREEN}✓ Libraries rebuilt${NC}"
    else
        echo -e "${RED}✗ Build failed${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${GREEN}✅ Done!${NC}"
