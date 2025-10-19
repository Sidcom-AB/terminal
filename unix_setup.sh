#!/usr/bin/env bash
# ================== CONFIG ==================
REPO_RAW_BASE="https://raw.githubusercontent.com/Sidcom-AB/terminal/main"
LIVE_PROFILE_URL="$REPO_RAW_BASE/dotfiles/profile.sh"
LIVE_LOGO_URL="$REPO_RAW_BASE/dotfiles/logo.txt"

DOTSTRAP_DIR="$HOME/.cache/dotstrap"
DOTSTRAP_CONFIG="$HOME/.bashrc.d/99-dotstrap.sh"
# ============================================

set -e

echo "🚀 Sidcom Terminal Setup för Unix"
echo "=================================="
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
echo "📋 Detekterat OS: $OS_TYPE"
echo ""

# Install dependencies
install_deps() {
  echo "📦 Installerar dependencies..."

  case "$OS_TYPE" in
    debian)
      sudo apt-get update -y >/dev/null 2>&1 || true
      sudo apt-get install -y curl git neofetch >/dev/null 2>&1 || echo "  ⚠️  Kunde inte installera alla apt-paket (kräver sudo)"
      sudo apt-get install -y vivid >/dev/null 2>&1 || echo "  ℹ️  vivid ej tillgänglig (valfritt)"
      ;;
    redhat)
      sudo yum install -y curl git neofetch >/dev/null 2>&1 || echo "  ⚠️  Kunde inte installera alla yum-paket (kräver sudo)"
      ;;
    alpine)
      sudo apk add --no-cache bash curl git neofetch >/dev/null 2>&1 || echo "  ⚠️  Kunde inte installera alla apk-paket (kräver sudo)"
      ;;
    macos)
      if ! command -v brew >/dev/null 2>&1; then
        echo "  ℹ️  Homebrew saknas. Installera från https://brew.sh"
      else
        brew install curl git neofetch 2>/dev/null || true
        brew install vivid 2>/dev/null || true
      fi
      ;;
    *)
      echo "  ⚠️  Okänt OS - hoppar över paketinstallation"
      echo "  ℹ️  Se till att curl och git finns installerade"
      ;;
  esac

  # Starship (universal installer)
  if ! command -v starship >/dev/null 2>&1; then
    echo "  📥 Installerar Starship prompt..."
    sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- -y >/dev/null 2>&1 || echo "  ⚠️  Starship-installation misslyckades (valfritt)"
  fi

  echo "  ✅ Dependencies klara"
  echo ""
}

# Setup dotstrap
setup_dotstrap() {
  echo "⚙️  Sätter upp dotstrap (auto-sync)..."

  mkdir -p ~/.bashrc.d "$DOTSTRAP_DIR"

  cat > "$DOTSTRAP_CONFIG" <<EOF
DOTSTRAP_REMOTE_PROFILE="$LIVE_PROFILE_URL"
DOTSTRAP_REMOTE_ASCII="$LIVE_LOGO_URL"
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
    echo "  ✅ ~/.bashrc uppdaterad"
  else
    echo "  ℹ️  ~/.bashrc redan konfigurerad"
  fi

  echo ""
}

# Initial fetch
initial_fetch() {
  echo "📥 Hämtar profile och logo från GitHub..."

  curl -fsSL "$LIVE_PROFILE_URL" -o "$DOTSTRAP_DIR/profile.sh" || {
    echo "  ⚠️  Kunde inte ladda ner profile.sh"
    exit 1
  }

  curl -fsSL "$LIVE_LOGO_URL" -o "$DOTSTRAP_DIR/logo.txt" || {
    echo "  ⚠️  Kunde inte ladda ner logo.txt"
    exit 1
  }

  echo "  ✅ Filer hämtade till $DOTSTRAP_DIR"
  echo ""
}

# Main execution
install_deps
setup_dotstrap
initial_fetch

echo "✨ Installation klar!"
echo ""
echo "Nästa steg:"
echo "  1. Kör 'source ~/.bashrc' eller starta ny terminal"
echo "  2. Din profil synkas automatiskt varje dag från GitHub"
echo "  3. Redigera alias i: dotfiles/profile.sh i repot"
echo ""
