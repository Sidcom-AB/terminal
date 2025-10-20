#!/usr/bin/env bash
# ================== CONFIG ==================
REPO_RAW_BASE="https://raw.githubusercontent.com/Sidcom-AB/terminal/master"
LIVE_PROFILE_URL="$REPO_RAW_BASE/dotfiles/profile.sh"
LIVE_LOGO_URL="$REPO_RAW_BASE/dotfiles/logo.txt"

DOTSTRAP_DIR="$HOME/.cache/dotstrap"
DOTSTRAP_CONFIG="$HOME/.bashrc.d/99-dotstrap.sh"

# Lokal mode (sätts via environment variable om körs från wsl_setup.ps1)
LOCAL_PROFILE_PATH="${LOCAL_PROFILE_PATH:-}"
LOCAL_LOGO_PATH="${LOCAL_LOGO_PATH:-}"
# ============================================

set -e

clear
echo ""
echo "  ███████╗██╗██████╗  ██████╗ ██████╗ ███╗   ███╗"
echo "  ██╔════╝██║██╔══██╗██╔════╝██╔═══██╗████╗ ████║"
echo "  ███████╗██║██║  ██║██║     ██║   ██║██╔████╔██║"
echo "  ╚════██║██║██║  ██║██║     ██║   ██║██║╚██╔╝██║"
echo "  ███████║██║██████╔╝╚██████╗╚██████╔╝██║ ╚═╝ ██║"
echo "  ╚══════╝╚═╝╚═════╝  ╚═════╝ ╚═════╝ ╚═╝     ╚═╝"
echo ""
echo "  TERMINAL SETUP FOR UNIX"
echo "  Automated bash profile configuration"
echo ""

# Detect OS
detect_os() {
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v apt-get >/dev/null 2>&1; then
      echo "debian"
    elif command -v yum >/dev/null 2>&1; then
      echo "redhat"
    elif command -v apk >/dev/null 2>&1; then
      echo "alpine"
    else
      echo "linux-other"
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macos"
  else
    echo "unknown"
  fi
}

OS_TYPE=$(detect_os)
echo "  [1/4] Detected OS: $OS_TYPE"

# Install dependencies
install_deps() {
  echo "  [2/4] Installing dependencies"

  case "$OS_TYPE" in
    debian)
      echo "        - Updating package lists"
      sudo apt-get update -y >/dev/null 2>&1 || true
      echo "        - Installing curl, git, neofetch"
      sudo apt-get install -y curl git neofetch >/dev/null 2>&1 || echo "      WARNING: Could not install all packages (requires sudo)"
      echo "        - Installing vivid (optional)"
      sudo apt-get install -y vivid >/dev/null 2>&1 || echo "      NOTE: vivid not available (skipping)"
      ;;
    redhat)
      echo "        - Installing packages (yum)"
      sudo yum install -y curl git neofetch >/dev/null 2>&1 || echo "      WARNING: Could not install all packages (requires sudo)"
      ;;
    alpine)
      echo "        - Installing packages (apk)"
      sudo apk add --no-cache bash curl git neofetch >/dev/null 2>&1 || echo "      WARNING: Could not install all packages (requires sudo)"
      ;;
    macos)
      if ! command -v brew >/dev/null 2>&1; then
        echo "        - NOTE: Homebrew not found. Install from https://brew.sh"
      else
        echo "        - Installing packages (brew)"
        brew install curl git neofetch 2>/dev/null || true
        brew install vivid 2>/dev/null || true
      fi
      ;;
    *)
      echo "        - WARNING: Unknown OS - skipping package installation"
      echo "        - NOTE: Ensure curl and git are installed"
      ;;
  esac

  # Starship (universal installer)
  if ! command -v starship >/dev/null 2>&1; then
    echo "        - Installing Starship prompt"
    sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- -y >/dev/null 2>&1 || echo "      WARNING: Starship installation failed (optional)"
  else
    echo "        - Starship already installed"
  fi

  echo ""
  echo "        - Dependencies complete"
  echo ""
}

# Setup dotstrap
setup_dotstrap() {
  echo "  [3/4] Configuring bash profile (auto-sync)..."

  mkdir -p ~/.bashrc.d "$DOTSTRAP_DIR"

  cat > "$DOTSTRAP_CONFIG" <<'EOF'
DOTSTRAP_REMOTE_PROFILE="https://raw.githubusercontent.com/Sidcom-AB/terminal/master/dotfiles/profile.sh"
DOTSTRAP_REMOTE_ASCII="https://raw.githubusercontent.com/Sidcom-AB/terminal/master/dotfiles/logo.txt"
DOTSTRAP_CACHE_DIR="$HOME/.cache/dotstrap"
DOTSTRAP_CACHE_PROFILE="$DOTSTRAP_CACHE_DIR/profile.sh"
DOTSTRAP_CACHE_ASCII="$DOTSTRAP_CACHE_DIR/logo.txt"
DOTSTRAP_TTL_DAYS=1

mkdir -p "$DOTSTRAP_CACHE_DIR"

__dotstrap_stale() {
  [ ! -f "$1" ] && return 0
  find "$1" -mtime +"$DOTSTRAP_TTL_DAYS" -print -quit 2>/dev/null | grep -q . && return 0
  return 1
}
__dotstrap_fetch() { curl -fsSL "$1" -o "$2.tmp" && mv "$2.tmp" "$2"; }

__dotstrap_stale "$DOTSTRAP_CACHE_PROFILE" && __dotstrap_fetch "$DOTSTRAP_REMOTE_PROFILE" "$DOTSTRAP_CACHE_PROFILE" || true
__dotstrap_stale "$DOTSTRAP_CACHE_ASCII"    && __dotstrap_fetch "$DOTSTRAP_REMOTE_ASCII"    "$DOTSTRAP_CACHE_ASCII"    || true

[ -f "$DOTSTRAP_CACHE_PROFILE" ] && . "$DOTSTRAP_CACHE_PROFILE"
EOF

  # Update bashrc if needed
  if ! grep -q '.bashrc.d/99-dotstrap.sh' ~/.bashrc 2>/dev/null; then
    cat >> ~/.bashrc <<'EOF'

# Load dotstrap (live profile + ascii logo)
[ -f "$HOME/.bashrc.d/99-dotstrap.sh" ] && . "$HOME/.bashrc.d/99-dotstrap.sh"
EOF
    echo "        - ~/.bashrc updated"
  else
    echo "        - ~/.bashrc already configured"
  fi

  echo ""
}

# Initial fetch
initial_fetch() {
  echo "  [4/4] Fetching profile and assets..."

  if [ -n "$LOCAL_PROFILE_PATH" ] && [ -n "$LOCAL_LOGO_PATH" ]; then
    echo "        - Copying local assets..."

    cp "$LOCAL_PROFILE_PATH" "$DOTSTRAP_DIR/profile.sh" || {
      echo "        - ERROR: Could not copy local profile.sh"
      exit 1
    }

    cp "$LOCAL_LOGO_PATH" "$DOTSTRAP_DIR/logo.txt" || {
      echo "        - ERROR: Could not copy local logo.txt"
      exit 1
    }

    echo "        - Local files copied to $DOTSTRAP_DIR"
  else
    echo "        - Downloading from GitHub..."

    curl -fsSL "$LIVE_PROFILE_URL" -o "$DOTSTRAP_DIR/profile.sh" || {
      echo "        - ERROR: Could not download profile.sh"
      exit 1
    }

    curl -fsSL "$LIVE_LOGO_URL" -o "$DOTSTRAP_DIR/logo.txt" || {
      echo "        - ERROR: Could not download logo.txt"
      exit 1
    }

    echo "        - Files downloaded to $DOTSTRAP_DIR"
  fi
  echo ""
}

# Main execution
install_deps
setup_dotstrap
initial_fetch

echo "  UNIX SETUP COMPLETE"
