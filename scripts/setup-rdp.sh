#!/bin/bash

# Skript zum Einrichten von RDP-Unterstützung im Development Desktop
set -e

# Pfad zum Skriptverzeichnis
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Lade Konfiguration
if [ -f "$ROOT_DIR/configs/webtop-config.sh" ]; then
    source "$ROOT_DIR/configs/webtop-config.sh"
else
    echo "Fehler: webtop-config.sh nicht gefunden."
    exit 1
fi

# Hole den Pod-Namen
POD_NAME=$(kubectl -n "$NAMESPACE" get pods -l service=webtop -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$POD_NAME" ]; then
    echo "Fehler: Kein laufender Pod für das Webtop Deployment gefunden."
    exit 1
fi

echo "=== RDP-Unterstützung für Development Desktop einrichten ==="
echo "Dieser Prozess installiert und konfiguriert xrdp im Development Desktop."
echo "Nach der Installation können Sie sich mit einem RDP-Client verbinden."
echo

# Installationsskript vorbereiten
INSTALL_SCRIPT=$(cat << 'EOF'
#!/bin/bash
set -e

# Funktion zum Ausgeben von Infos
log() {
    echo "[$(date +%T)] $1"
}

# Debugging-Funktion
debug_log() {
    echo "[DEBUG] $1" >> /tmp/rdp-setup-debug.log
}

# Prüfen, ob als root ausgeführt
if [ "$(id -u)" -ne 0 ]; then
    log "Dieses Skript muss als root ausgeführt werden."
    exit 1
fi

# Debug-Datei erstellen
touch /tmp/rdp-setup-debug.log
chmod 666 /tmp/rdp-setup-debug.log
debug_log "RDP Setup gestartet: $(date)"
debug_log "Benutzerkonten vor Einrichtung:"
debug_log "$(cat /etc/passwd | grep abc)"
debug_log "$(cat /etc/shadow | grep abc)"

log "Aktualisiere Paketindex..."
apt-get update

log "Installiere xrdp und benötigte Pakete..."
apt-get install -y xrdp xorgxrdp pwgen

log "Konfiguriere xrdp für XFCE..."
echo "xfce4-session" > /etc/xrdp/xsession

# Anpassen der xrdp.ini
log "Konfiguriere xrdp.ini..."
sed -i 's/max_bpp=32/max_bpp=24/g' /etc/xrdp/xrdp.ini
sed -i 's/xserverbpp=24/xserverbpp=24/g' /etc/xrdp/xrdp.ini

# Aktiviere SSL für sicheren Zugriff
sed -i 's/ssl_protocols=TLSv1.2, TLSv1.3/ssl_protocols=TLSv1.2, TLSv1.3/g' /etc/xrdp/xrdp.ini

# Deaktiviere Authentifizierungsprüfung für einfacheren Zugang
sed -i 's/security_layer=negotiate/security_layer=rdp/g' /etc/xrdp/xrdp.ini
sed -i 's/crypt_level=high/crypt_level=none/g' /etc/xrdp/xrdp.ini
sed -i 's/bitmap_compression=true/bitmap_compression=false/g' /etc/xrdp/xrdp.ini
sed -i 's/require_credentials=true/require_credentials=false/g' /etc/xrdp/xrdp.ini

# Stelle sicher, dass das Home-Verzeichnis existiert
log "Überprüfe und erstelle das Home-Verzeichnis wenn nötig..."
if [ ! -d "/home/abc" ]; then
    log "Erstelle Home-Verzeichnis für Benutzer abc..."
    mkdir -p /home/abc
    chown abc:abc /home/abc
    chmod 750 /home/abc
fi

# Setze ein eindeutiges und klares Passwort für den abc Benutzer
RDP_PASSWORD="rdpuser123"
log "Setze Passwort für Benutzer abc auf: $RDP_PASSWORD"
debug_log "Setze Passwort für abc auf: $RDP_PASSWORD"

# Passwort mit verschiedenen Methoden setzen, um sicherzustellen, dass es funktioniert
echo "abc:$RDP_PASSWORD" | chpasswd
usermod -aG ssl-cert abc

# Debugging: Prüfe, ob der Benutzer existiert und aktiv ist
debug_log "Benutzerkonten nach Einrichtung:"
debug_log "$(cat /etc/passwd | grep abc)"
debug_log "$(cat /etc/shadow | grep abc)"

# Prüfe ob das Home-Verzeichnis in /config/home/abc oder /home/abc ist
if [ -d "/config/home/abc" ]; then
    log "Webtop-Container verwendet /config/home/abc als Home-Verzeichnis"
    debug_log "Webtop-Container verwendet /config/home/abc als Home-Verzeichnis"
    
    # Erstelle symlink für Home-Verzeichnis
    if [ ! -L "/home/abc" ]; then
        log "Erstelle Symlink von /home/abc zu /config/home/abc..."
        rm -rf /home/abc
        ln -s /config/home/abc /home/abc
    fi
    
    # Setze Berechtigungen für .Xauthority im tatsächlichen Home-Verzeichnis
    touch /config/home/abc/.Xauthority
    chown abc:abc /config/home/abc/.Xauthority
    chmod 600 /config/home/abc/.Xauthority
    
    HOME_DIR="/config/home/abc"
else
    # Setze Berechtigungen für .Xauthority
    touch /home/abc/.Xauthority
    chown abc:abc /home/abc/.Xauthority
    chmod 600 /home/abc/.Xauthority
    
    HOME_DIR="/home/abc"
fi

debug_log "Home-Verzeichnis: $HOME_DIR"

# XFCE-Einstellungen für den Benutzer anpassen
mkdir -p ${HOME_DIR}/.config/xfce4/xfconf/xfce-perchannel-xml/
cat > ${HOME_DIR}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml << 'XFCECONFIG'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-session" version="1.0">
  <property name="general" type="empty">
    <property name="FailsafeSessionName" type="string" value="Failsafe"/>
    <property name="LockCommand" type="string" value=""/>
  </property>
  <property name="sessions" type="empty">
    <property name="Failsafe" type="empty">
      <property name="IsFailsafe" type="bool" value="true"/>
      <property name="Count" type="int" value="5"/>
      <property name="Client0_Command" type="array">
        <value type="string" value="xfwm4"/>
      </property>
      <property name="Client1_Command" type="array">
        <value type="string" value="xfsettingsd"/>
      </property>
      <property name="Client2_Command" type="array">
        <value type="string" value="xfce4-panel"/>
      </property>
      <property name="Client3_Command" type="array">
        <value type="string" value="Thunar"/>
        <value type="string" value="--daemon"/>
      </property>
      <property name="Client4_Command" type="array">
        <value type="string" value="xfdesktop"/>
      </property>
    </property>
  </property>
</channel>
XFCECONFIG

# Erstelle .xsession Datei im Home-Verzeichnis
cat > ${HOME_DIR}/.xsession << 'XSESSION'
#!/bin/bash
xfce4-session
XSESSION
chmod +x ${HOME_DIR}/.xsession

# Erlaube Passwortlose Anmeldungen für RDP
log "Konfiguriere RDP für einfache Anmeldung..."
if [ -f "/etc/pam.d/xrdp-sesman" ]; then
    cp /etc/pam.d/xrdp-sesman /etc/pam.d/xrdp-sesman.bak
    cat > /etc/pam.d/xrdp-sesman << 'PAMSESSION'
#%PAM-1.0
@include common-auth
@include common-account
@include common-session
@include common-password
PAMSESSION
fi

# Setze Berechtigungen für alle Dateien im Home-Verzeichnis
chown -R abc:abc ${HOME_DIR}

# Container-freundlicher Dienst-Start (ohne systemd)
log "Starte xrdp-Dienste direkt (ohne systemd)..."

# Stoppe xrdp falls es bereits läuft
if pgrep xrdp >/dev/null; then
    log "Stoppe xrdp-Prozesse..."
    pkill -f xrdp || true
    sleep 2
fi

# Starte xrdp und speichere die Prozess-ID
log "Starte xrdp-Server..."
/usr/sbin/xrdp &
XRDP_PID=$!
sleep 2

# Starte xrdp-Sesman und speichere die Prozess-ID
log "Starte xrdp-Sitzungsmanager..."
/usr/sbin/xrdp-sesman &
SESMAN_PID=$!

# Überprüfe, ob die Prozesse laufen
sleep 2
if ps -p $XRDP_PID > /dev/null && ps -p $SESMAN_PID > /dev/null; then
    log "xrdp-Dienste wurden erfolgreich gestartet."
else
    log "WARNUNG: xrdp-Dienste konnten nicht gestartet werden."
    log "Versuche alternative Startmethode..."
    
    # Alternative Startmethode
    nohup /etc/init.d/xrdp start >/tmp/xrdp-start.log 2>&1 &
    sleep 3
    
    if pgrep xrdp >/dev/null; then
        log "xrdp-Server läuft jetzt."
    else
        log "FEHLER: xrdp-Server konnte nicht gestartet werden!"
        log "Überprüfen Sie die Logs mit: cat /tmp/xrdp-start.log"
    fi
fi

# Erstelle einen Startup-Eintrag für automatischen Start bei Container-Neustart
if [ -d "/etc/cont-init.d" ]; then
    log "Erstelle Container-Init-Skript für xrdp..."
    cat > /etc/cont-init.d/99-xrdp-autostart << 'CONTSCRIPT'
#!/bin/bash
echo "Starte xrdp-Dienste automatisch..."
/usr/sbin/xrdp &
sleep 2
/usr/sbin/xrdp-sesman &
CONTSCRIPT
    chmod +x /etc/cont-init.d/99-xrdp-autostart
fi

debug_log "RDP Setup abgeschlossen: $(date)"
log "RDP-Einrichtung abgeschlossen!"
log "Verbinden Sie sich mit einem RDP-Client über Port 3389"
log "Benutzername: abc"
log "Passwort: $RDP_PASSWORD"
log "Debug-Log: /tmp/rdp-setup-debug.log"

# Füge diese Informationen zur Desktop-README hinzu
if [ -f "$HOME_DIR/Desktop/README.txt" ]; then
    echo "" >> "$HOME_DIR/Desktop/README.txt"
    echo "== RDP-Zugangsdaten ==" >> "$HOME_DIR/Desktop/README.txt"
    echo "Benutzername: abc" >> "$HOME_DIR/Desktop/README.txt"
    echo "Passwort: $RDP_PASSWORD" >> "$HOME_DIR/Desktop/README.txt"
fi

# Erstellle Dokument mit RDP-Zugangsdaten
cat > "$HOME_DIR/Desktop/RDP-CREDENTIALS.txt" << RDPCRED
============== RDP ZUGANGSINFORMATIONEN ==============

Diese Datei enthält die Zugangsinformationen für den RDP-Zugriff
auf diesen Development Desktop.

BENUTZERNAME: abc
PASSWORT: $RDP_PASSWORD

Unterstützte RDP-Clients:
- Windows: Microsoft Remote Desktop (vorinstalliert)
- macOS: Microsoft Remote Desktop (App Store)
- Linux: Remmina oder FreeRDP

============== HINWEISE ==============
Bei Verbindungsproblemen bitte folgende Punkte prüfen:
1. Port-Forwarding ist aktiv (kubectl port-forward)
2. Firewall blockiert nicht den Zugriff
3. Richtige Eingabe von Benutzername und Passwort
RDPCRED

chmod 644 "$HOME_DIR/Desktop/RDP-CREDENTIALS.txt"
chown abc:abc "$HOME_DIR/Desktop/RDP-CREDENTIALS.txt"

EOF
)

# Skript in den Pod kopieren
echo "Kopiere Installationsskript in den Pod..."
echo "$INSTALL_SCRIPT" | kubectl -n "$NAMESPACE" exec -i "$POD_NAME" -- bash -c "cat > /tmp/setup-rdp.sh && chmod +x /tmp/setup-rdp.sh"

# Skript im Pod ausführen
echo "Führe Installationsskript im Pod aus..."
kubectl -n "$NAMESPACE" exec -it "$POD_NAME" -- bash -c "sudo /tmp/setup-rdp.sh"

# Holen des festgelegten RDP-Passworts aus dem Pod
RDP_CRED=$(kubectl -n "$NAMESPACE" exec -it "$POD_NAME" -- cat /config/home/abc/Desktop/RDP-CREDENTIALS.txt | grep PASSWORT | awk '{print $2}')

# Port-Forwarding für RDP einrichten
echo "Richte Port-Forwarding für RDP ein..."
kubectl -n "$NAMESPACE" port-forward "$POD_NAME" 3389:3389 &
RDP_PID=$!

echo
echo "=== RDP-Einrichtung abgeschlossen ==="
echo "Sie können sich jetzt mit einem RDP-Client verbinden:"
echo "  Adresse: localhost:3389"
echo "  Benutzername: abc"
echo "  Passwort: $RDP_CRED"
echo
echo "Empfohlene RDP-Clients:"
echo "  Windows: Microsoft Remote Desktop (vorinstalliert)"
echo "  macOS: Microsoft Remote Desktop (App Store)"
echo "  Linux: Remmina oder FreeRDP (xfreerdp)"
echo
echo "Port-Forwarding für RDP läuft im Hintergrund."
echo "Drücken Sie CTRL+C, um das Port-Forwarding zu beenden."

# Cleanup bei Beendigung
trap 'kill $RDP_PID 2>/dev/null || true' EXIT

# Warte auf Benutzerabbruch
wait $RDP_PID
