#!/usr/bin/env bash

install_on_debian() {
    sudo apt update
    sudo apt install -y ansible
}

install_on_fedora() {
    sudo dnf install -y ansible
}

install_homebrew() {
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

install_on_macos() {
    if ! command -v brew &>/dev/null; then
        install_homebrew
    fi
    brew install ansible
}

OS="$(uname -s)"
case "${OS}" in
    Linux*)
        if [ -f /etc/fedora-release ]; then
            install_on_fedora
        elif [ -f /etc/lsb-release ]; then
            install_on_debian
        else
            echo "Unsupported Linux distribution"
            exit 1
        fi
        ;;
    Darwin*)
        install_on_macos
        ;;
    *)
        echo "Unsupported operating system: ${OS}"
        exit 1
        ;;
esac

is_wsl() {
    grep -qi microsoft /proc/version 2>/dev/null
}

if [ "$(uname -s)" = "Darwin" ]; then
    ansible-playbook ~/.bootstrap/provision-workstation-macos.yml
elif is_wsl; then
    ansible-playbook ~/.bootstrap/provision-workstation-wsl.yml --ask-become-pass
    WIN_PS1="$(wslpath -w ~/.bootstrap/bootstrap-windows.ps1)"
    WIN_PLAYBOOK="$(wslpath -w ~/.bootstrap/provision-workstation-windows.yml)"
    powershell.exe -ExecutionPolicy Bypass -File "$WIN_PS1" "$WIN_PLAYBOOK"
else
    ansible-playbook ~/.bootstrap/provision-workstation-linux.yml --ask-become-pass
fi

echo "Ansible installation complete."