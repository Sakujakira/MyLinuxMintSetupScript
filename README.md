# MyLinuxMintSetupScript

Ein Bash-Skript zur schnellen und komfortablen Einrichtung eines frischen Linux Mint Systems.
Die Zielgruppe bin ich selbst, wenn das Skript anderen das Leben auch leichter machen kann, desto besser.

## Funktionen

- **Spiegelserver wechseln:** Automatische Auswahl schnellerer Paketquellen.
- **Unnötige Programme entfernen:** Deinstallation vorinstallierter, meist ungenutzter Software.
- **Programme installieren:** Interaktive Auswahl und Installation nützlicher Programme (z.B. Git, VLC, GIMP, Docker, Brave, VS Code, u.v.m.).
- **Flatpak-Unterstützung:** Installation beliebter Anwendungen, die nur als Flatpak verfügbar sind (z.B. Spotify, Signal, Discord, Threema).
- **Automatische Einrichtung:** Viele Einstellungen und Installationen laufen automatisiert ab, inklusive Repository-Management.

## Nutzung

1. Repository klonen oder Skript herunterladen:
    ```bash
    git clone https://github.com/Sakujakira/MyLinuxMintSetupScript.git
    cd MyLinuxMintSetupScript
    ```

2. Skript ausführbar machen:
    ```bash
    chmod +x setup.sh
    ```

3. Skript starten:
    ```bash
    ./setup.sh
    ```

4. Den interaktiven Anweisungen folgen.

> **Hinweis:** Das Skript benötigt Root-Rechte und fragt diese bei Bedarf automatisch an.

## Hinweise

- Das Skript ist für Linux Mint (bzw. Ubuntu-basierte Systeme) erstellt.
- Die Installation zusätzlicher Programme erfolgt nach Rückfrage.
- Flatpak-Programme werden optional installiert.
- Nach der Installation von Docker ist ein Neustart oder eine Ab-/Anmeldung empfohlen.

## Haftungsausschluss

Die Nutzung erfolgt auf eigene Gefahr. Prüfe die vorgeschlagenen Änderungen und Installationen vor der Ausführung.

---

Viel Spaß mit deinem neuen Linux Mint System!
