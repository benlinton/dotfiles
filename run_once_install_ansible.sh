#!/usr/bin/env bash

# ----------------------------------------------------------------------------
# Check for OS
# ----------------------------------------------------------------------------
is_windows() {
    grep -qi microsoft /proc/version 2>/dev/null
}

is_fedora() {
    [ -f /etc/fedora-release ]
}

is_debian() {
    [ -f /etc/lsb-release ]
}

is_macos() {
    [ "$(uname -s)" = "Darwin" ]
}

# ----------------------------------------------------------------------------
# Ansible installers
# ----------------------------------------------------------------------------
maybe_sudo() {
    if [ "$(id -u)" = "0" ]; then
        "$@"
    else
        sudo "$@"
    fi
}

install_ansible_on_debian() {
    maybe_sudo apt update
    maybe_sudo apt install -y ansible
}

install_ansible_on_fedora() {
    maybe_sudo dnf install -y ansible
}

install_homebrew() {
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

install_ansible_on_macos() {
    if ! command -v brew &>/dev/null; then
        install_homebrew
    fi
    brew install ansible
}

install_ansible_on_windows() {
    powershell.exe -ExecutionPolicy Bypass -Command '
        $ErrorActionPreference = "Stop"

        function Refresh-Path {
            $machine = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
            $user    = [System.Environment]::GetEnvironmentVariable("PATH", "User")
            $env:PATH = "$machine;$user"
        }

        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            Write-Host "Installing winget..."
            $installer = "$env:TEMP\AppInstaller.msixbundle"
            Invoke-WebRequest -Uri "https://aka.ms/getwinget" -OutFile $installer
            Add-AppxPackage $installer
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
    '
}

# ----------------------------------------------------------------------------
# Determine how to install ansible 
# Assuming windows gets installed from wsl - default: ubuntu (debian)
# ----------------------------------------------------------------------------
if is_macos; then
    install_ansible_on_macos
elif is_fedora; then
    install_ansible_on_fedora
elif is_debian; then
    install_ansible_on_debian
elif ! is_windows; then
    echo "Unsupported operating system."
    exit 1
fi

if is_windows; then
    install_ansible_on_windows
fi

# ----------------------------------------------------------------------------
# Run playbooks
# Windows will run both the workstation-wls and workstation-windows playbooks
# ----------------------------------------------------------------------------
if is_macos; then
    ansible-playbook ~/.bootstrap/provision-workstation-macos.yml
elif is_windows; then
    ansible-playbook ~/.bootstrap/provision-workstation-wsl.yml --ask-become-pass

    WIN_PLAYBOOK="$(wslpath -w ~/.bootstrap/provision-workstation-windows.yml)"
    powershell.exe -ExecutionPolicy Bypass -Command "ansible-playbook '$WIN_PLAYBOOK'"
else
    ansible-playbook ~/.bootstrap/provision-workstation-linux.yml --ask-become-pass
fi

echo "Ansible installation complete."
