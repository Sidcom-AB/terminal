# ================== CONFIG ==================
$TerminalName   = "Sidcom"
$TabTitle       = "Sidcom Terminal"
$ColorScheme    = "nord"
$FontName       = "Fira Code"
$FontSize       = 10
$CursorColor    = "#6AE4F1"
$CursorShape    = "filledBox"

# WSL-distro (ändra vid behov)
$DistroName     = "Debian"

# Raw-bas för detta repo
$RepoRawBase    = "https://raw.githubusercontent.com/Sidcom-AB/terminal/main"

# Asset-filer i repo (Windows Terminal)
$BgFile   = "background.png"
$IconFile = "logo.png"
$FontFile = "FiraCode-Regular.ttf"

# Stabil GUID för profilen (ändra inte när det är i bruk)
$ProfileGuid    = "{f4302025-1111-4aaa-aaaa-123456789abc}"
# ============================================

# Kräver admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
  [Security.Principal.WindowsBuiltInRole] "Administrator")) {
  Write-Error "Kör PowerShell som Administratör."
  exit 1
}

function Get-TerminalPaths {
  $store = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe"
  $unpkg = Join-Path $env:LOCALAPPDATA "Microsoft\Windows Terminal"
  if (Test-Path $store) {
    return [pscustomobject]@{
      Settings = Join-Path $store "LocalState\settings.json"
      Roaming  = Join-Path $store "RoamingState"
    }
  } else {
    return [pscustomobject]@{
      Settings = Join-Path $unpkg "settings.json"
      Roaming  = Join-Path $unpkg "RoamingState"
    }
  }
}

Write-Host "Kontrollerar WSL-funktioner..." -ForegroundColor Cyan
$wslFeature = (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux)
if ($wslFeature.State -ne "Enabled") {
  Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart -All | Out-Null
}
$vmFeat = (Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform)
if ($vmFeat.State -ne "Enabled") {
  Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart -All | Out-Null
}

$existing = & wsl.exe -l -q 2>$null
if ($existing -notcontains $DistroName) {
  Write-Host "Installerar WSL-distro: $DistroName..." -ForegroundColor Yellow
  & wsl.exe --install -d $DistroName
  Write-Host "OBS: En omstart kan krävas första gången." -ForegroundColor Yellow
}

$paths = Get-TerminalPaths
New-Item -ItemType Directory -Force -Path $paths.Roaming | Out-Null

# Hämta assets till RoamingState
Invoke-WebRequest -UseBasicParsing -Uri "$RepoRawBase/assets/$BgFile"   -OutFile (Join-Path $paths.Roaming $BgFile)
Invoke-WebRequest -UseBasicParsing -Uri "$RepoRawBase/assets/$IconFile" -OutFile (Join-Path $paths.Roaming $IconFile)
Invoke-WebRequest -UseBasicParsing -Uri "$RepoRawBase/assets/$FontFile" -OutFile (Join-Path $paths.Roaming $FontFile)

# Installera font (tyst)
$FontDst = Join-Path $env:WINDIR "Fonts\$FontFile"
Copy-Item (Join-Path $paths.Roaming $FontFile) $FontDst -Force
$fontRegName = "Fira Code (TrueType)"
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" -Name $fontRegName -Value $FontFile -PropertyType String -Force | Out-Null

# Ladda & uppdatera Windows Terminal settings.json
if (!(Test-Path $paths.Settings)) { throw "Hittar inte Windows Terminal settings: $($paths.Settings)" }
$json = Get-Content $paths.Settings -Raw | ConvertFrom-Json

if (-not $json.schemes) { $json | Add-Member -NotePropertyName schemes -NotePropertyValue @() }
$hasNord = $false
foreach ($s in $json.schemes) { if ($s.name -eq "nord") { $hasNord = $true; break } }
if (-not $hasNord) {
  $json.schemes += [pscustomobject]@{
    name="nord"; background="#2E3440"; black="#3B4252"; blue="#81A1C1"; brightBlack="#4C566A"; brightBlue="#81A1C1";
    brightCyan="#8FBCBB"; brightGreen="#A3BE8C"; brightPurple="#B48EAD"; brightRed="#BF616A"; brightWhite="#ECEFF4";
    brightYellow="#EBCB8B"; cursorColor="#FFFFFF"; cyan="#88C0D0"; foreground="#D8DEE9"; green="#A3BE8C";
    purple="#B48EAD"; red="#BF616A"; selectionBackground="#FFFFFF"; white="#E5E9F0"; yellow="#EBCB8B"
  }
}

if (-not $json.profiles) { $json | Add-Member -NotePropertyName profiles -NotePropertyValue ([pscustomobject]@{defaults=@{}; list=@()}) }
if (-not $json.profiles.list) { $json.profiles.list = @() }

$profile = [pscustomobject]@{
  guid = $ProfileGuid
  name = $TerminalName
  tabTitle = $TabTitle
  source = $null
  hidden = $false
  commandline = "wsl.exe -d $DistroName"
  colorScheme = $ColorScheme
  icon = "ms-appdata:///roaming/$IconFile"
  backgroundImage = "ms-appdata:///roaming/$BgFile"
  backgroundImageOpacity = 0.3
  backgroundImageStretchMode = "fill"
  cursorColor = $CursorColor
  cursorShape = $CursorShape
  "experimental.retroTerminalEffect" = $false
  font = @{ face = $FontName; size = $FontSize }
  intenseTextStyle = "bright"
  opacity = 100
  useAcrylic = $false
}

$idx = ($json.profiles.list | ForEach-Object { $_.guid }) -indexOf $ProfileGuid
if ($idx -ge 0) { $json.profiles.list[$idx] = $profile } else { $json.profiles.list += $profile }
$json.defaultProfile = $ProfileGuid

($json | ConvertTo-Json -Depth 100) | Set-Content -Encoding UTF8 $paths.Settings
Write-Host "Windows Terminal-profil '$TerminalName' uppdaterad." -ForegroundColor Green

# --- WSL inre setup (kör unix_setup.sh) ---
Write-Host "Konfigurerar WSL ($DistroName)..." -ForegroundColor Cyan
Write-Host "Laddar ner och kör unix_setup.sh..." -ForegroundColor Yellow

$unixSetupUrl = "$RepoRawBase/unix_setup.sh"
$wslCmd = "curl -fsSL $unixSetupUrl | bash"

& wsl.exe -d $DistroName -- bash -lc "$wslCmd"
Write-Host "WSL-bashprofil klar." -ForegroundColor Green

Write-Host "Allt klart. Starta Windows Terminal – defaultprofilen är '$TerminalName'." -ForegroundColor Green
