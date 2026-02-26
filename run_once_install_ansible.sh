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

install_homebrew() {
    if ! command -v brew &>/dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

install_ansible_on_debian() {
    maybe_sudo apt update
    maybe_sudo apt install -y ansible
}

install_ansible_on_fedora() {
    maybe_sudo dnf install -y ansible
}

install_ansible_on_macos() {
    install_homebrew
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
            # Persist Scripts dir so future PowerShell sessions can find ansible-playbook
            $pyScriptsDir = Join-Path (Split-Path (Get-Command python).Source -Parent) "Scripts"
            if (Test-Path (Join-Path $pyScriptsDir "ansible-playbook.exe")) {
                $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
                if ($userPath -notlike "*$pyScriptsDir*") {
                    [System.Environment]::SetEnvironmentVariable("PATH", "$userPath;$pyScriptsDir", "User")
                    Write-Host "Added $pyScriptsDir to Windows PATH"
                }
            }
            Refresh-Path
        }
    '
}

# ----------------------------------------------------------------------------
# Determine how to install ansible 
# Assuming windows has wsl running a supported distro
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
# Windows includes provision-workstation-wls and provision-workstation-windows playbooks
# ----------------------------------------------------------------------------
if is_macos; then
    ansible-playbook ~/.bootstrap/provision-workstation-macos.yml
elif is_windows; then
    ansible-playbook ~/.bootstrap/provision-workstation-wsl.yml --ask-become-pass

    WIN_PLAYBOOK="$(wslpath -w ~/.bootstrap/provision-workstation-windows.yml)"
    powershell.exe -ExecutionPolicy Bypass -Command "
        \$machine = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine')
        \$user = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
        \$env:PATH = \"\$machine;\$user\"
        ansible-playbook '$WIN_PLAYBOOK'
    "
else
    ansible-playbook ~/.bootstrap/provision-workstation-linux.yml --ask-become-pass
fi

echo "Ansible installation complete."
