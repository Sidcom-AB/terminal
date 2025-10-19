# Sidcom Terminal

Automatisk terminal-setup med färgtema, alias och auto-sync från GitHub.

---

## Installera i Windows

Kör PowerShell som **Administratör**:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
iwr -useb https://raw.githubusercontent.com/Sidcom-AB/terminal/master/wsl_setup.ps1 | iex
```

Detta installerar:
- Windows Terminal med Sidcom-profil (bakgrund, font, färger)
- WSL (Debian) om det saknas
- Bash-profil med alias och auto-sync

---

## Installera i Unix

Kör i bash-terminal (Linux, macOS, befintlig WSL):

```bash
curl -fsSL https://raw.githubusercontent.com/Sidcom-AB/terminal/master/unix_setup.sh | bash
```

Detta installerar:
- Bash-profil med alias och färger
- Starship prompt
- Auto-sync från GitHub (uppdateras automatiskt varje dag)

---

## Vad ingår?

### Alias
- `ll` - ls -l med färger
- `repo` - cd /mnt/c/Repositories
- `gpush "meddelande"` - git add + commit + push (defaultar till timestamp om inget meddelande)

### Features
- Nord färgtema
- Starship prompt
- ASCII-logo vid start
- Auto-sync varje dag (profilen uppdateras automatiskt från GitHub)

---

## Anpassa

### Ändra alias eller funktioner
Redigera `dotfiles/profile.sh` i detta repo - synkas automatiskt till alla maskiner

### Ändra Windows Terminal-tema
Redigera variablerna i `wsl_setup.ps1`:
```powershell
$TerminalName = "Sidcom"
$ColorScheme  = "nord"
$FontName     = "Fira Code"
```

### Byt ASCII-logo
Redigera `dotfiles/logo.txt`

---

## Struktur

```
terminal/
├── assets/                    # Windows Terminal (bakgrund, ikon, font)
├── dotfiles/
│   ├── profile.sh             # Bash-profil (synkas automatiskt)
│   └── logo.txt               # ASCII-logo
├── wsl_setup.ps1              # Windows installer
└── unix_setup.sh              # Unix installer
```
