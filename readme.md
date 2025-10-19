# 📘 **Sidcom Terminal**
## 🧠 Terminal Setup

Detta repo innehåller allt du behöver för att få en snygg, synkad och produktiv terminal-miljö.

**Två installationsvägar:**
1. **Windows + WSL** - komplett setup med Windows Terminal theming + Unix-miljö
2. **Unix standalone** - bara bash-profil, alias och färgtema (för Linux, macOS, etc.)

Båda varianterna ger dig:
- Automatisk synk mot detta repo – så framtida ändringar uppdateras automatiskt
- Starship-prompt med Nord-färgtema
- Praktiska alias och git-helpers
- ASCII-logo vid terminalstart

---

## 🪄 Installation

### **Variant 1: Windows 10/11 + WSL** (komplett setup)

> Kör PowerShell som **Administratör**  
> (högerklicka → *Kör som administratör*)

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
iwr -useb https://raw.githubusercontent.com/Sidcom-AB/terminal/main/wsl_setup.ps1 | iex
````

Scriptet:

1. Kontrollerar att **WSL** finns – installerar annars automatiskt
2. Installerar vald **WSL-distro** (standard: Debian)
3. Laddar ner och installerar alla **assets** (bakgrund, ikon, font)
4. Skapar eller uppdaterar din **Windows Terminal-profil**
5. Konfigurerar **bashrc-synk** inne i WSL med alias, färger och Starship-prompt

Efteråt:

* Starta **Windows Terminal**
* Profilen **Sidcom** (eller det namn du angivit i scriptet) finns färdig
* WSL har samma färgtema, alias och prompt på alla maskiner

### **Variant 2: Unix standalone** (Linux, macOS, befintlig WSL)

> Kör detta i din Unix-terminal (bash)

```bash
curl -fsSL https://raw.githubusercontent.com/Sidcom-AB/terminal/main/unix_setup.sh | bash
```

Scriptet:

1. Detekterar ditt OS (Debian, Ubuntu, macOS, etc.)
2. Installerar **dependencies** (curl, git, neofetch, Starship)
3. Laddar ner och konfigurerar **bashrc-synk** med alias, färger och prompt
4. Hämtar **logo.txt** och **profile.sh** från repot

Efteråt:

* Kör `source ~/.bashrc` eller starta ny terminal
* Din profil uppdateras automatiskt varje dag från GitHub
* Samma setup på alla dina Unix-maskiner

---

## 🧩 Struktur i detta repo

```
terminal/
│
├── assets/                # Grafiska filer & typsnitt (Windows Terminal)
│   ├── background.png     # Bakgrundsbild i terminalen
│   ├── logo.png           # Profilikon
│   └── FiraCode-Regular.ttf  # Typsnitt för terminalen
│
├── dotfiles/              # Bash-profil och ASCII-logo (delas av båda varianter)
│   ├── profile.sh         # Din "live" bashrc - synkas automatiskt
│   └── logo.txt           # ASCII-logo visas vid terminalstart
│
├── wsl_setup.ps1          # PowerShell-script (Windows + WSL)
└── unix_setup.sh          # Bash-script (Unix standalone)
```

---

## 🖌️ Anpassning

### Windows Terminal (endast Variant 1)
Vill du ändra utseende, färger eller distro?
Öppna `wsl_setup.ps1` och justera variablerna:

```powershell
$TerminalName   = "Sidcom"
$DistroName     = "Debian"
$ColorScheme    = "nord"
$FontName       = "Fira Code"
```

### Bash-profil (båda varianter)
Ändra alias, färger eller funktioner:
Redigera `dotfiles/profile.sh` i repot - uppdateras automatiskt nästa dag (eller kör `source ~/.bashrc`)

### Byt ASCII-logo
Redigera `dotfiles/logo.txt` - den synkas automatiskt till alla maskiner

---

## 💡 Tips

* Kör `gpush "din commit"` för snabb git-push (ingår i profilen)
* Lägg till fler alias i `dotfiles/profile.sh` så synkas de till alla maskiner
* Byt ASCII-logo i `dotfiles/logo.txt` för att personifiera din startbild
* För nya maskiner:
  - **Windows:** kör PowerShell-kommandot – klart på <1 minut
  - **Unix:** kör bash one-liner – klart på <30 sekunder

---

## ⚙️ Krav

### Variant 1 (Windows + WSL):
* **Windows 10 (21H2)** eller **Windows 11**
* **PowerShell 5+** (standard i Windows)
* Internetanslutning (för att hämta assets & WSL)

### Variant 2 (Unix standalone):
* **Bash 4+** (standard på de flesta Linux/macOS-system)
* **curl** (installeras automatiskt om den saknas)
* Internetanslutning (för att hämta profil & dependencies)

---

## 🧑‍💻 Licens

Detta repo är fritt att använda internt inom Sidcom AB och partners.
Alla tredjeparts-komponenter (t.ex. *Fira Code*, *Starship*) följer sina respektive öppna licenser.

---

### 🚀 Support & bidrag

Pull requests och förbättringsförslag välkomnas!
För frågor – kontakta Dev Labs / Platform Team.

````