#!/bin/bash

# Skript zum Starten des Port-Forwardings für den debian XFCE Desktop
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

# Überprüfe ob das Deployment existiert
if ! kubectl -n "$NAMESPACE" get deployment "$WEBTOP_DEPLOYMENT_NAME" &> /dev/null; then
    echo "Fehler: Webtop Deployment '$WEBTOP_DEPLOYMENT_NAME' nicht gefunden."
    echo "Bitte führen Sie zuerst deploy-webtop.sh aus."
    exit 1
fi

# Prüfe, ob ein Pod läuft
POD_NAME=$(kubectl -n "$NAMESPACE" get pods -l app=webtop -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$POD_NAME" ]; then
    echo "Fehler: Kein laufender Pod für das Webtop Deployment gefunden."
    exit 1
fi

POD_STATUS=$(kubectl -n "$NAMESPACE" get pod "$POD_NAME" -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
    echo "Fehler: Pod ist nicht im Status 'Running', sondern im Status '$POD_STATUS'."
    echo "Bitte warten Sie, bis der Pod vollständig gestartet ist."
    exit 1
fi

# Starte Port-Forwarding in separaten Prozessen
echo "Starte Port-Forwarding für debian XFCE Desktop:"
echo "- HTTP auf Port 3000"
kubectl -n "$NAMESPACE" port-forward svc/"$WEBTOP_SERVICE_NAME" 3000:3000 &
HTTP_PID=$!

echo "- HTTPS auf Port 3001"
kubectl -n "$NAMESPACE" port-forward svc/"$WEBTOP_SERVICE_NAME" 3001:3001 &
HTTPS_PID=$!

echo
echo "Port-Forwarding gestartet."
echo "Zugriffsmöglichkeiten für den Development Desktop:"
echo "==================================================="
echo "1. Webbrowser (empfohlen für einfachen Zugriff):"
echo "   HTTP: http://localhost:3000"
echo "   HTTPS: https://localhost:3001"
echo
echo "2. Native Clients (für verbesserte Performance):"
echo "   - VNC-Clients: localhost:5900 (nach Port-Forwarding für VNC)"
echo "   - Microsoft Remote Desktop: localhost:3389 (nach RDP-Freigabe)"
echo "   - NoMachine: localhost:4000 (nach NoMachine-Installation)"
echo
echo "Weitere Informationen finden Sie in der README-Datei auf dem Desktop der virtuellen Maschine."
echo "==================================================="
echo
echo "Zugriff mit Passwort: Verwenden Sie das in webtop-config.sh konfigurierte Passwort."
echo
echo "Drücken Sie CTRL+C, um das Port-Forwarding zu beenden."

# Funktion zum Aufräumen beim Beenden
cleanup() {
    echo "Beende Port-Forwarding..."
    kill $HTTP_PID $HTTPS_PID 2>/dev/null || true
    exit 0
}

# Registriere Signal-Handler
trap cleanup SIGINT SIGTERM

# Optional: Öffne Browser nach 3 Sekunden
if command -v xdg-open &> /dev/null; then
    (sleep 3 && xdg-open http://localhost:3000) &
elif command -v open &> /dev/null; then
    (sleep 3 && open http://localhost:3000) &
fi

# Warte auf Benutzerabbruch
wait