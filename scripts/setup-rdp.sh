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
POD_NAME=$(kubectl -n "$NAMESPACE" get pods -l app=webtop -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
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

# Prüfen, ob als root ausgeführt
if [ "$(id -u)" -ne 0 ]; then
    log "Dieses Skript muss als root ausgeführt werden."
    exit 1
fi

log "Aktualisiere Paketindex..."
apt-get update

log "Installiere xrdp..."
apt-get install -y xrdp

log "Konfiguriere xrdp für XFCE..."
echo "xfce4-session" > /etc/xrdp/xsession

# Anpassen der xrdp.ini
log "Konfiguriere xrdp.ini..."
sed -i 's/max_bpp=32/max_bpp=24/g' /etc/xrdp/xrdp.ini
sed -i 's/xserverbpp=24/xserverbpp=24/g' /etc/xrdp/xrdp.ini

# Aktiviere SSL für sicheren Zugriff
sed -i 's/ssl_protocols=TLSv1.2, TLSv1.3/ssl_protocols=TLSv1.2, TLSv1.3/g' /etc/xrdp/xrdp.ini

# Stelle sicher, dass xrdp-Sitzungen als Benutzer 'abc' laufen
log "Konfiguriere Benutzereinstellungen..."
echo 'abc:abc' | chpasswd
usermod -aG ssl-cert abc

# Setze Berechtigungen für .Xauthority
touch /home/abc/.Xauthority
chown abc:abc /home/abc/.Xauthority
chmod 600 /home/abc/.Xauthority

# XFCE-Einstellungen für den Benutzer anpassen
mkdir -p /home/abc/.config/xfce4/xfconf/xfce-perchannel-xml/
cat > /home/abc/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml << 'XFCECONFIG'
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

chown -R abc:abc /home/abc/.config

# Passe Firewall an (falls ufw installiert ist)
if command -v ufw >/dev/null 2>&1; then
    log "Konfiguriere Firewall für RDP..."
    ufw allow 3389/tcp
fi

# Starte xrdp-Dienst neu
log "Starte xrdp-Dienst neu..."
systemctl enable xrdp
systemctl restart xrdp

log "RDP-Installation abgeschlossen!"
log "Verbinden Sie sich mit einem RDP-Client über Port 3389"
log "Benutzername: abc"
log "Passwort: [Ihr konfiguriertes Passwort]"
EOF
)

# Skript in den Pod kopieren
echo "Kopiere Installationsskript in den Pod..."
echo "$INSTALL_SCRIPT" | kubectl -n "$NAMESPACE" exec -i "$POD_NAME" -- bash -c "cat > /tmp/setup-rdp.sh && chmod +x /tmp/setup-rdp.sh"

# Skript im Pod ausführen
echo "Führe Installationsskript im Pod aus..."
kubectl -n "$NAMESPACE" exec -i "$POD_NAME" -- bash -c "sudo /tmp/setup-rdp.sh"

# Port-Forwarding für RDP einrichten
echo "Richte Port-Forwarding für RDP ein..."
kubectl -n "$NAMESPACE" port-forward "$POD_NAME" 3389:3389 &
RDP_PID=$!

echo
echo "=== RDP-Einrichtung abgeschlossen ==="
echo "Sie können sich jetzt mit einem RDP-Client verbinden:"
echo "  Adresse: localhost:3389"
echo "  Benutzername: abc"
echo "  Passwort: Ihr konfiguriertes Passwort (aus webtop-config.sh)"
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