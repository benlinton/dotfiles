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

# ----------------------------------------------------------------------------
# Run playbooks
# Windows: WSL playbook via ansible, Windows native via PowerShell script
# ----------------------------------------------------------------------------
if is_macos; then
    ansible-playbook ~/.bootstrap/provision-workstation-macos.yml
elif is_windows; then
    ansible-playbook ~/.bootstrap/provision-workstation-wsl.yml --ask-become-pass
    # run Windows native provisioning without ansible
    WIN_SCRIPT="$(wslpath -w ~/.bootstrap/provision-workstation-windows.ps1)"
    powershell.exe -ExecutionPolicy Bypass -File "$WIN_SCRIPT"
else
    ansible-playbook ~/.bootstrap/provision-workstation-linux.yml --ask-become-pass
fi

echo "Ansible installation complete."
