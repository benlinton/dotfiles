# Windows workstation provisioning (using winget, not ansible)
$ErrorActionPreference = 'Stop'

# ----------------------------------------------------------------------------
# Ensure winget is available
# ----------------------------------------------------------------------------
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "Installing WinGet..."
    $progressPreference = 'silentlyContinue'
    Install-PackageProvider -Name NuGet -Force | Out-Null
    Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
    Repair-WinGetPackageManager
}

# ----------------------------------------------------------------------------
# Install applications
# Pass the -Silent flag if you don't want an interactive install
# ----------------------------------------------------------------------------
function Install-App {
    param([string]$Id, [string]$Name, [switch]$Silent)
    Write-Host "Installing $Name..."
    $silentArg = if ($Silent) { '--silent' } else { '' }
    winget install --id $Id $silentArg --accept-package-agreements --accept-source-agreements
    # 0 = success; -1978335189 (0x8A150011) = already installed / no upgrade available
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne -1978335189) {
        Write-Error "Failed to install ${Name} (exit code: $LASTEXITCODE)"
        exit $LASTEXITCODE
    }
}

Install-App 'Microsoft.VisualStudioCode' 'Visual Studio Code'
Install-App '7zip.7zip' '7-Zip' -Silent

# ----------------------------------------------------------------------------
# Install fonts
# ----------------------------------------------------------------------------
$fontsDir = "$env:USERPROFILE\AppData\Local\Microsoft\Windows\Fonts"
if (-not (Get-ChildItem $fontsDir -Filter 'JetBrainsMonoNerd*FontMono*.ttf' -ErrorAction SilentlyContinue)) {
    Write-Host "Installing JetBrains Mono Nerd Font..."
    $tmp = "$env:TEMP\win-fonts-setup"
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    Invoke-WebRequest -Uri 'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip' -OutFile "$tmp\JetBrainsMono.zip"
    Expand-Archive -Path "$tmp\JetBrainsMono.zip" -DestinationPath $tmp -Force
    $shell = New-Object -ComObject Shell.Application
    $fontsFolder = $shell.Namespace(0x14)
    Get-ChildItem $tmp -Filter 'JetBrainsMonoNerd*FontMono*.ttf' | ForEach-Object { $fontsFolder.CopyHere($_.FullName) }
    Remove-Item $tmp -Recurse -Force
    Write-Host "Fonts installed."
} else {
    Write-Host "JetBrains Mono Nerd Font already installed."
}
