param([string]$PlaybookPath)

$ErrorActionPreference = "Stop"

function Refresh-Path {
    $machine = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    $user    = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $env:PATH = "$machine;$user"
}

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Python 3..."
    winget install --id Python.Python.3.12 --silent --accept-package-agreements --accept-source-agreements
    Refresh-Path
}

if (-not (Get-Command ansible-playbook -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Ansible..."
    python -m pip install ansible
    Refresh-Path
}

ansible-playbook $PlaybookPath
