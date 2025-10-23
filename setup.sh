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
    apt purge -y hexchat celluloid hypnotix rhythmbox rhythmbox-data \
        rhythmbox-plugin-tray-icon libreoffice*
    apt autoremove -y
}

# 3. Eigene Programme installieren
install_programs() {
    echo -e "${GREEN}>>> Installiere Basisprogramme...${RESET}"
    apt update
    apt install -y git curl htop neofetch vlc heif-gdk-pixbuf heif-thumbnailer \
        ca-certificates gimp ffmpeg ffmpegthumbnailer gparted wget gpg
    echo -e "${GREEN}Basisprogramme wurden installiert.${RESET}"
    echo -e "${GREEN}>>> Firefox und Thunderbrid um notwendige Pakete erweitern...${RESET}"
    apt install -y firefox-locale-de thunderbird-locale-de
    echo -e "${GREEN}Firefox und Thunderbird wurden erweitert.${RESET}"
    echo -e "${GREEN}>>> Frage nach weiteren Programmen...${RESET}"

    repo_added=false
    app_from_repo=""
    brave_added=false
    docker_added=false
    gitkraken_added=false
    fancontrol_added=false
    office_added=false
    synology_added=false
    ulauncher_added=false
    vscode_added=false

    declare -a repo_programs=(
        [audacity]="" 
        [fancontrol]="fancontrol lm-sensors"
        [filezilla]=""
        [handbrake]="handbrake handbrake-cli"
        [inkscape]=""
        [keepassxc]=""
        [lutris]=""
        [papirus-icon-theme]=""
        [steam-installer]="steam-installer steam-devices"
    )

    for program in "${!repo_programs[@]}"; 
    do
        if ask_yes_no "$program installieren?"; then
            #app_from_repo+="${repo_programs[$program]} "
            echo $program
            echo ${repo_programs[$program]}        
        fi
    done

    if ask_yes_no "Audacity installieren?"; then
        app_from_repo+="audacity "
    fi

    if ask_yes_no "Brave installieren?"; then
        curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
        curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources https://brave-browser-apt-release.s3.brave.com/brave-browser.sources
        repo_added=true
        brave_added=true
    fi

    if ask_yes_no "Docker installieren?"; then
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

    if ask_yes_no "Fancontrol (für Lüftersteuerung) installieren?"; then
        app_from_repo+="fancontrol lm-sensors "
    fi

    if ask_yes_no "FileZilla installieren?"; then
        app_from_repo+="filezilla "
    fi

    if ask_yes_no "GitKraken installieren?"; then
        curl -s https://release.gitkraken.com/linux/gitkraken-amd64.deb -o /tmp/gitkraken.deb
        gitkraken_added=true
    fi

    if ask_yes_no "Handbrake installieren?"; then
        app_from_repo+="handbrake handbrake-cli "
    fi

    if ask_yes_no "Inkscape installieren?"; then
        app_from_repo+="inkscape "
    fi

    if ask_yes_no "KeePassXC installieren?"; then
        app_from_repo+="keepassxc "
    fi

    if ask_yes_no "Lutris installieren?"; then
        app_from_repo+="lutris "
    fi

    if ask_yes_no "Papirus Icon Theme installieren?"; then
        app_from_repo+="papirus-icon-theme "
    fi

    if ask_yes_no "Möchtest du SoftMaker Office installieren?"; then
        install_softmaker
    fi

    if ask_yes_no "Steam installieren?"; then
        app_from_repo+="steam-installer steam-devices "
    fi

    # Synology Drive Client, nur .deb verfügbar, muss daher regelmäßig aktualisiert werden
    if ask_yes_no "Synology Drive Client installieren?"; then
        wget -O /tmp/synology-drive-client.deb https://global.synologydownload.com/download/Utility/SynologyDriveClient/3.5.2-16111/Ubuntu/Installer/synology-drive-client-16111.x86_64.deb
        synology_added=true
    fi

    if ask_yes_no "VS Code installieren?"; then
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
        install -D -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/microsoft.gpg
        rm microsoft.gpg
        repo_added=true
        vscode_added=true
    fi

    #Paketlisten nur aktualisieren, wenn ein neues Repository hinzugefügt wurde
    if [ "$repo_added" = true ]; then
        echo -e "${GREEN}>>> Aktualisiere Paketlisten...${RESET}"
        apt update 
    fi

    if [ -n "$app_from_repo" ]; then
        echo -e "${GREEN}>>> Installiere ausgewählte Programme aus dem Standard Repo...${RESET}"
        apt install -y $app_from_repo
        if [ $fancontrol_added = true ]; then
            sensors-detect --auto
            pwmconfig
            systemctl enable fancontrol
            echo -e "${YELLOW}Bitte starte den Computer neu, damit die Sensoren erkannt werden.${RESET}"
        fi
        echo -e "${GREEN}>>> Ausgewählte Programme wurden installiert.${RESET}"
    fi

    if [ "$gitkraken_added" = true ]; then
        apt install -y /tmp/gitkraken.deb
        rm /tmp/gitkraken.deb
        echo -e "${GREEN}>>> GitKraken wurde installiert.${RESET}"
    fi

    if [ "$vscode_added" = true ]; then
        apt install -y code
        echo -e "${GREEN}>>> VS Code wurde installiert.${RESET}"
    fi

    if [ "$docker_added" = true ]; then
        apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        systemctl enable docker
        usermod -aG docker "$SUDO_USER"
        echo -e "${GREEN}>>> Docker wurde installiert. Bitte melde dich ab und wieder an, damit du Docker ohne sudo nutzen kannst.${RESET}"
    fi

    if [ "$brave_added" = true ]; then
        apt install -y brave-browser
        echo -e "${GREEN}>>> Brave wurde installiert.${RESET}"
    fi

    if [ "$synology_added" = true ]; then
        apt install -y /tmp/synology-drive-client.deb
        rm /tmp/synology-drive-client.deb
        echo -e "${GREEN}>>> Synology Drive Client wurde installiert.${RESET}"
    fi

} 

install_softmaker() {
    echo -e "${GREEN}>>> SoftMaker Office Installation${RESET}"
    echo "Welche Version von SoftMaker Office möchtest du installieren?"
    echo "1) FreeOffice (kostenlos)"
    echo "2) SoftMaker Office Standard (kommerziell)"
    echo "3) SoftMaker Office NX Universal (Abo)"
    echo "0) Keine Installation"

    read -p "Bitte wähle [0-3]: " choice
    case $choice in
        1)
            add_softmaker_repo
            apt update
            apt install -y softmaker-freeoffice-2024            ;;
        2)
            echo -e "${GREEN}Installiere SoftMaker Office Standard...${RESET}"
            wget -qO- https://shop.softmaker.com/repo/linux-repo-public.key | gpg --dearmor -o /usr/share/keyrings/softmaker-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/softmaker-keyring.gpg] https://shop.softmaker.com/repo/apt stable non-free" > /etc/apt/sources.list.d/softmaker.list
            apt update
            apt install -y softmaker-office-2021
            ;;
        3)
            echo -e "${GREEN}Installiere SoftMaker Office NX Universal...${RESET}"
            wget -qO- https://shop.softmaker.com/repo/linux-repo-public.key | gpg --dearmor -o /usr/share/keyrings/softmaker-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/softmaker-keyring.gpg] https://shop.softmaker.com/repo/apt stable non-free" > /etc/apt/sources.list.d/softmaker.list
            apt update
            apt install -y softmaker-office-nx
            ;;
        0)
            echo -e "${YELLOW}SoftMaker Office wird nicht installiert.${RESET}"
            ;;
        *)
            echo -e "${RED}Ungültige Auswahl!${RESET}"
            ;;
    esac
}

add_softmaker_repo() {
    mkdir -p /etc/apt/keyrings
    wget -qO- https://shop.softmaker.com/repo/linux-repo-public.key | gpg --dearmor -o /usr/share/keyrings/softmaker-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/softmaker-keyring.gpg] https://shop.softmaker.com/repo/apt stable non-free" > /etc/apt/sources.list.d/softmaker.list
}


install_flatpak_programs() {
    flatpak_apps=""
    threema_access=false
    signal_access=false
    telegram_access=false
    discord_access=false
    if ask_yes_no "Spotify installieren?"; then
        flatpak_apps+="com.spotify.Client "
    fi
    if ask_yes_no "Signal installieren?"; then
        flatpak_apps+="org.signal.Signal "
        if ask_yes_no "Signal Zugriff auf dein Home-Verzeichnis geben?"; then
            signal_access=true
        fi
    fi
    if ask_yes_no "Discord installieren?"; then
        flatpak_apps+="com.discordapp.Discord "
        if ask_yes_no "Discord Zugriff auf dein Home-Verzeichnis geben?"; then
            discord_access=true
        fi
    fi
    if ask_yes_no "Plex Desktop App & PlexAmp installieren?"; then
        flatpak_apps+="com.plexapp.PlexDesktop "
        flatpak_apps+="com.plexapp.PlexAmp "
    fi
    if ask_yes_no "Bitwarden installieren?"; then
        flatpak_apps+="com.bitwarden.desktop "
    fi
    if ask_yes_no "Vuescan installieren?"; then
        flatpak_apps+="com.vuescan.VueScan "
    fi
    if ask_yes_no "Telegram installieren?"; then
        flatpak_apps+="org.telegram.desktop "
        if ask_yes_no "Telegram Zugriff auf dein Home-Verzeichnis geben?"; then
            telegram_access=true
        fi
    fi
    if ask_yes_no "Threema installieren?"; then
        flatpak_apps+="ch.threema.threema-web-desktop "
        if ask_yes_no "Threema Zugriff auf dein Home-Verzeichnis geben?"; then
            threema_access=true
        fi
    fi
    if ask_yes_no "FreeTube (Werbefreier Youtube Client) installieren?"; then
        flatpak_apps+="com.github.freetubeapp.FreeTube "
    fi
    if [[ -n "$flatpak_apps" ]]; then
        echo -e "${GREEN}>>> Installiere Flatpak-Programme...${RESET}"
        flatpak install -y flathub $flatpak_apps
    else
        echo -e "${YELLOW}Keine Flatpak Programme ausgewählt.${RESET}"
    fi
    echo -e "${GREEN}>>> Optionale Berechtigungen setzen...${RESET}"
    if [ "$threema_access" = true ]; then
        flatpak override ch.threema.threema-web-desktop --filesystem=home
    fi
    if [ "$signal_access" = true ]; then
        flatpak override org.signal.Signal --filesystem=home
    fi
    if [ "$telegram_access" = true ]; then
        flatpak override org.telegram.desktop --filesystem=home
    fi
    if [ "$discord_access" = true ]; then
        flatpak override com.discordapp.Discord --filesystem=home
    fi
    
    echo -e "${GREEN}Flatpak Programme wurden installiert.${RESET}"
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

if ask_yes_no "Spiegelserver ändern?"; then
    change_mirrors
    apt update
fi

if ask_yes_no "Unnötige Standardprogramme entfernen?"; then
    remove_unneeded
fi

if ask_yes_no "Ausgewählte Programme installieren?"; then
    install_programs
fi

if ask_yes_no "Manche Programme stehen nur als Flatpak zur Verfügung. Möchtest du Flatpak-Programme installieren?"; then
    apt install -y flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    echo -e "${GREEN}Flatpak und Flathub wurden installiert.${RESET}"
    install_flatpak_programs
fi

echo -e "${GREEN}Setup abgeschlossen! Bitte ggf. neu starten.${RESET}"

