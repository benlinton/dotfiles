#!/bin/bash

install_on_debian() {
    sudo apt update
    sudo apt install -y ansible
}

install_on_fedora() {
    sudo dnf install -y ansible
}

install_on_macos() {
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

ansible-playbook ~/.bootstrap/setup.yml --ask-become-pass

echo "Ansible installation complete."