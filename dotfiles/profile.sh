# ===== DOTSTRAP PROFILE (live) =====

# Cargo (Rust)
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Starship (om installerad)
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi

# LS_COLORS via vivid (fallback till dircolors om du vill bygga ut)
if command -v vivid >/dev/null 2>&1; then
  export LS_COLORS="$(vivid generate nord)"
fi

# Aliases
alias ls='ls --color=auto'
alias ll='ls -l --color=auto'
alias repo='cd /mnt/c/Repositories'

# Git helper
gpush() {
  local msg="${1:-Commit $(date '+%Y-%m-%d %H:%M:%S')}"
  git add .
  git commit -m "$msg" || true
  git push
}

# ASCII + systeminfo
__dotstrap_show_logo() {
  local ascii="${DOTSTRAP_CACHE_ASCII:-$HOME/.cache/dotstrap/logo.txt}"
  [ -f "$ascii" ] && cat "$ascii"
  if command -v fastfetch >/dev/null 2>&1; then
    fastfetch --logo none
  elif command -v neofetch >/dev/null 2>&1; then
    if [ -f "$ascii" ]; then
      neofetch --ascii "$ascii" --ascii_colors 4 6 7 --disable packages gpu --bold off
    else
      neofetch --disable packages gpu --bold off
    fi
  fi
}
[ -t 1 ] && __dotstrap_show_logo
