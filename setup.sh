#!/bin/bash

# Farben für Ausgabe
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

# Funktion für interaktive Abfrage (Ja/Nein)
ask_yes_no() {
    while true; do
        read -rp "$1 (y/n): " yn
        case $yn in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo -e "${YELLOW}Bitte y oder n eingeben.${RESET}" ;;
        esac
    done
}

# 1. Spiegelserver ändern
change_mirrors() {
    echo -e "${GREEN}>>> Spiegelserver werden auf die schnellsten Quellen aktualisiert...${RESET}"
    sed -i 's|http://archive.ubuntu.com/ubuntu/|http://mirror.hetzner.de/ubuntu/|g' /etc/apt/sources.list
    sed -i 's|http://packages.linuxmint.com|http://mirror.hetzner.de/linuxmint/packages|g' /etc/apt/sources.list.d/official-package-repositories.list
}

# 2. Unnötige Programme deinstallieren
remove_unneeded() {
    echo -e "${GREEN}>>> Entferne unnötige Standardprogramme...${RESET}"
    apt purge -y hexchat celluloid hypnotix libreoffice*
    apt autoremove -y
}

# 3. Eigene Programme installieren
install_programs() {
    echo -e "${GREEN}>>> Installiere Basisprogramme...${RESET}"
    apt install -y git curl htop neofetch vlc heif-gdk-pixbuf heif-thumbnailer ca-certificates

    local repo_added=false
    local vscode_added=false
    local office_added=false
    local docker_added=false
    local brave_added=false

    if ask_yes_no "Möchtest du VS Code installieren?"; then
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /usr/share/keyrings/ms-vscode.gpg > /dev/null
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/ms-vscode.gpg] https://packages.microsoft.com/repos/code stable main" | \
            tee /etc/apt/sources.list.d/vscode.list
        repo_added=true
        vscode_added=true
    fi

    if ask_yes_no "Möchtest du Docker installieren?"; then
        # Entferne alte Docker- und Container-Pakete in mehreren Zeilen zur besseren Lesbarkeit
        packages_to_remove=(
            docker.io
            docker-doc
            docker-compose
            docker-compose-v2
            podman-docker
            containerd
            runc
        )
        for pkg in "${packages_to_remove[@]}"; do
            apt-get remove -y "$pkg"
        done
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        chmod a+r /etc/apt/keyrings/docker.asc
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
            $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
            tee /etc/apt/sources.list.d/docker.list > /dev/null
        repo_added=true
        docker_added=true
    fi

    if ask_yes_no "Möchtest du Softmaker Office installieren?"; then
        mkdir -p /etc/apt/keyrings
        wget -qO- https://shop.softmaker.com/repo/linux-repo-public.key | gpg --dearmor > /etc/apt/keyrings/softmaker.gpg
        echo "deb [signed-by=/etc/apt/keyrings/softmaker.gpg] https://shop.softmaker.com/repo/apt stable non-free" > /etc/apt/sources.list.d/softmaker.list
        repo_added=true
        vscode_added=true
    fi

    if ask_yes_no "Möchtest du Brave installieren?"; then
        curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
        curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources https://brave-browser-apt-release.s3.brave.com/brave-browser.sources
        repo_added=true
    fi

    if [ "$repo_added" = true ]; then
        apt update
    fi

    if [ "$vscode_added" ]; then
        apt install -y code
    fi

    if [ "$office_added" ]; then
        apt install -y softmaker-freeoffice-2024
    fi

    if [ "$docker_added" ]; then
        apt install -y docker.io docker-compose
        systemctl enable docker
        usermod -aG docker "$SUDO_USER"
    fi

    if [ "$brave_added" ]; then
        apt install -y brave-browser
    fi
}

### Hauptprogramm
clear
echo -e "${GREEN}Willkommen beim Linux Mint Setup-Skript!${RESET}"

# Prüfen ob Root
if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}Du bist kein Root. Soll das Skript mit sudo neu gestartet werden?${RESET}"
    read -rp "Weiter mit sudo? (y/n): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        exec sudo bash "$0" "$@"
    else
        echo "Abgebrochen."
        exit 1
    fi
fi

if ask_yes_no "Möchtest du die Spiegelserver ändern?"; then
    change_mirrors
    apt update
fi

if ask_yes_no "Möchtest du unnötige Standardprogramme entfernen?"; then
    remove_unneeded
fi

if ask_yes_no "Möchtest du gewünschte Programme installieren?"; then
    install_programs
fi

echo -e "${GREEN}Setup abgeschlossen! Bitte ggf. neu starten.${RESET}"

