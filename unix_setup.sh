#!/usr/bin/env bash
# ================== CONFIG ==================
REPO_RAW_BASE="https://raw.githubusercontent.com/Sidcom-AB/terminal/master"
LIVE_PROFILE_URL="$REPO_RAW_BASE/dotfiles/profile.sh"
LIVE_LOGO_URL="$REPO_RAW_BASE/dotfiles/logo.txt"
LIVE_STARSHIP_URL="$REPO_RAW_BASE/dotfiles/starship.toml"

DOTSTRAP_DIR="$HOME/.cache/dotstrap"
DOTSTRAP_CONFIG="$HOME/.bashrc.d/99-dotstrap.sh"

# Lokal mode (sätts via environment variable om körs från wsl_setup.ps1)
LOCAL_PROFILE_PATH="${LOCAL_PROFILE_PATH:-}"
LOCAL_LOGO_PATH="${LOCAL_LOGO_PATH:-}"
LOCAL_STARSHIP_PATH="${LOCAL_STARSHIP_PATH:-}"
# ============================================

# Pre-flight check: Ensure curl is available BEFORE set -e
if ! command -v curl >/dev/null 2>&1; then
  echo ""
  echo "  SIDCOM TERMINAL SETUP"
  echo "  Installing curl (required dependency)..."
  echo ""

  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -qq 2>/dev/null || true
    sudo apt-get install -y curl 2>/dev/null || {
      echo "  ERROR: Could not install curl. Please run: sudo apt-get install curl"
      exit 1
    }
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y curl 2>/dev/null || {
      echo "  ERROR: Could not install curl. Please run: sudo yum install curl"
      exit 1
    }
  elif command -v apk >/dev/null 2>&1; then
    sudo apk add --no-cache curl 2>/dev/null || {
      echo "  ERROR: Could not install curl. Please run: sudo apk add curl"
      exit 1
    }
  else
    echo "  ERROR: curl not found and package manager not recognized"
    echo "  Please install curl manually and re-run this script"
    exit 1
  fi

  echo "  curl installed successfully"
  echo ""
fi

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
      echo "        - Installing curl, git"
      sudo apt-get install -y curl git >/dev/null 2>&1 || echo "      WARNING: Could not install all packages (requires sudo)"
      echo "        - Installing vivid (optional)"
      sudo apt-get install -y vivid >/dev/null 2>&1 || echo "      NOTE: vivid not available (skipping)"

      # Fastfetch installation
      if ! command -v fastfetch >/dev/null 2>&1; then
        echo "        - Installing fastfetch"
        if sudo apt-get install -y fastfetch >/dev/null 2>&1; then
          echo "        - Fastfetch installed from apt"
        else
          echo "        - Downloading fastfetch from GitHub releases"
          ARCH=$(uname -m)
          if [[ "$ARCH" == "x86_64" ]]; then
            FF_URL="https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.deb"
          elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
            FF_URL="https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-aarch64.deb"
          else
            echo "      WARNING: Unsupported architecture for fastfetch: $ARCH"
            FF_URL=""
          fi

          if [ -n "$FF_URL" ]; then
            curl -fsSL "$FF_URL" -o /tmp/fastfetch.deb && \
            sudo dpkg -i /tmp/fastfetch.deb >/dev/null 2>&1 && \
            rm /tmp/fastfetch.deb && \
            echo "        - Fastfetch installed from GitHub"
          fi
        fi
      else
        echo "        - Fastfetch already installed"
      fi
      ;;
    redhat)
      echo "        - Installing packages (yum)"
      sudo yum install -y curl git >/dev/null 2>&1 || echo "      WARNING: Could not install all packages (requires sudo)"
      ;;
    alpine)
      echo "        - Installing packages (apk)"
      sudo apk add --no-cache bash curl git >/dev/null 2>&1 || echo "      WARNING: Could not install all packages (requires sudo)"
      ;;
    macos)
      if ! command -v brew >/dev/null 2>&1; then
        echo "        - NOTE: Homebrew not found. Install from https://brew.sh"
      else
        echo "        - Installing packages (brew)"
        brew install curl git 2>/dev/null || true
        brew install vivid 2>/dev/null || true
        brew install fastfetch 2>/dev/null || true
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
DOTSTRAP_REMOTE_STARSHIP="https://raw.githubusercontent.com/Sidcom-AB/terminal/master/dotfiles/starship.toml"
DOTSTRAP_CACHE_DIR="$HOME/.cache/dotstrap"
DOTSTRAP_CACHE_PROFILE="$DOTSTRAP_CACHE_DIR/profile.sh"
DOTSTRAP_CACHE_ASCII="$DOTSTRAP_CACHE_DIR/logo.txt"
DOTSTRAP_CACHE_STARSHIP="$DOTSTRAP_CACHE_DIR/starship.toml"
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
__dotstrap_stale "$DOTSTRAP_CACHE_STARSHIP" && __dotstrap_fetch "$DOTSTRAP_REMOTE_STARSHIP" "$DOTSTRAP_CACHE_STARSHIP" || true

# Symlink starship config to standard location
[ -f "$DOTSTRAP_CACHE_STARSHIP" ] && mkdir -p "$HOME/.config" && ln -sf "$DOTSTRAP_CACHE_STARSHIP" "$HOME/.config/starship.toml"

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

    if [ -n "$LOCAL_STARSHIP_PATH" ] && [ -f "$LOCAL_STARSHIP_PATH" ]; then
      cp "$LOCAL_STARSHIP_PATH" "$DOTSTRAP_DIR/starship.toml" || true
    fi

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

    curl -fsSL "$LIVE_STARSHIP_URL" -o "$DOTSTRAP_DIR/starship.toml" || {
      echo "        - WARNING: Could not download starship.toml (optional)"
    }

    echo "        - Files downloaded to $DOTSTRAP_DIR"
  fi

  # Symlink starship config
  if [ -f "$DOTSTRAP_DIR/starship.toml" ]; then
    mkdir -p "$HOME/.config"
    ln -sf "$DOTSTRAP_DIR/starship.toml" "$HOME/.config/starship.toml"
    echo "        - Starship config linked to ~/.config/starship.toml"
  fi

  echo ""
}

# Main execution
install_deps
setup_dotstrap
initial_fetch

echo ""
echo "  UNIX SETUP COMPLETE"
echo ""

# Only reload shell if run standalone (not from wsl_setup.ps1)
if [ -z "$LOCAL_PROFILE_PATH" ]; then
  echo "  Reloading shell..."
  echo ""
  exec bash -l
else
  echo "  Close this terminal and open a new Windows Terminal tab to see changes!"
  echo ""
fi
