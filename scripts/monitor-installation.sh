#!/bin/bash

# Monitor-Skript für den Installationsprozess des debian XFCE Development Desktop
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

# Farbdefinitionen
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Pod-Namen holen
POD_NAME=$(kubectl -n "$NAMESPACE" get pods -l service=webtop -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$POD_NAME" ]; then
    echo -e "${RED}Fehler: Kein laufender Pod für das Webtop Deployment gefunden.${NC}"
    echo "Überprüfen Sie den Status des Deployments mit:"
    echo "kubectl -n $NAMESPACE get pods"
    exit 1
fi

echo -e "${GREEN}=== Überwache Installationsprozess für debian XFCE Desktop ===${NC}"
echo "Pod: $POD_NAME"
echo "Namespace: $NAMESPACE"
echo
echo "Drücken Sie Ctrl+C, um die Überwachung zu beenden."
echo "-----------------------------------------------------------"

# Funktion zum Anzeigen von Pod-Informationen
show_pod_info() {
    echo -e "\n${YELLOW}Pod Status:${NC}"
    kubectl -n "$NAMESPACE" get pod "$POD_NAME" -o wide
    
    echo -e "\n${YELLOW}Pod Details:${NC}"
    kubectl -n "$NAMESPACE" describe pod "$POD_NAME" | grep -E "Status:|Message:|Reason:|Container ID:|Image:|Started:|Ready:|Restart Count:"
}

# Funktion zum Anzeigen der letzten Ereignisse
show_recent_events() {
    echo -e "\n${YELLOW}Neueste Ereignisse:${NC}"
    kubectl -n "$NAMESPACE" get events --sort-by=.metadata.creationTimestamp | grep "$POD_NAME" | tail -5
}

# Funktion zum Anzeigen der Logs
show_logs() {
    echo -e "\n${YELLOW}Container Logs (letzte 30 Zeilen):${NC}"
    kubectl -n "$NAMESPACE" logs "$POD_NAME" --tail=30
}

# Hauptüberwachungsschleife
while true; do
    clear
    echo -e "${GREEN}=== debian XFCE Desktop Installationsmonitor ===${NC}"
    echo "Zeitstempel: $(date)"
    echo "Pod: $POD_NAME"
    echo "Namespace: $NAMESPACE"
    echo "-----------------------------------------------------------"
    
    # Zeige Pod-Informationen
    show_pod_info
    
    # Zeige Ereignisse
    show_recent_events
    
    # Zeige Logs
    show_logs
    
    echo -e "\n${YELLOW}Drücken Sie Ctrl+C zum Beenden der Überwachung.${NC}"
    echo "Nächste Aktualisierung in 10 Sekunden..."
    
    # Warte 10 Sekunden oder bis zur Unterbrechung
    sleep 10
done