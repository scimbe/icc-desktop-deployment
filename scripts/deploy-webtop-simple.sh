#!/bin/bash

# Skript zum Deployment von debian XFCE Desktop mit Entwicklungstools auf der ICC
# Vereinfachte Version ohne PVC (EmptyDir)
set -e

# Pfad zum Skriptverzeichnis
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Lade Konfiguration
if [ -f "$ROOT_DIR/configs/webtop-config.sh" ]; then
    source "$ROOT_DIR/configs/webtop-config.sh"
else
    echo "Fehler: webtop-config.sh nicht gefunden."
    echo "Bitte kopieren Sie configs/webtop-config.example.sh nach configs/webtop-config.sh und passen Sie die Werte an."
    exit 1
fi

# Farbdefinitionen
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Prüfe, ob kubectl verfügbar ist
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Fehler: kubectl ist nicht installiert oder nicht im PATH.${NC}"
    echo "Bitte installieren Sie kubectl gemäß der Anleitung: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

# Prüfe, ob Namespace existiert
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo -e "${RED}Fehler: Namespace $NAMESPACE existiert nicht.${NC}"
    echo "Bitte überprüfen Sie Ihre Konfiguration und stellen Sie sicher, dass Sie bei der ICC eingeloggt sind."
    exit 1
fi

echo -e "${GREEN}=== ICC XFCE Desktop mit Entwicklungstools Deployment ===${NC}"
echo "Namespace: $NAMESPACE"
echo "Ressourcen: $MEMORY_LIMIT RAM, $CPU_LIMIT CPU"
echo -e "${YELLOW}HINWEIS: Diese Version verwendet einen temporären Speicher (EmptyDir).${NC}"
echo -e "${YELLOW}Alle Ihre Daten gehen verloren, wenn der Pod neu gestartet wird!${NC}"
echo

# Bestätigung einholen
read -p "Möchten Sie mit dem Deployment fortfahren? (j/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Jj]$ ]]; then
    echo "Abbruch"
    exit 0
fi

# Erstelle temporäre YAML-Datei für das Deployment
TMP_FILE=$(mktemp)

# Ersetze Variablen in der Deployment-YAML-Datei
cat "$ROOT_DIR/templates/webtop-emptydir.yaml" | \
    sed "s/\$NAMESPACE/$NAMESPACE/g" | \
    sed "s/\$MEMORY_LIMIT/$MEMORY_LIMIT/g" | \
    sed "s/\$CPU_LIMIT/$CPU_LIMIT/g" | \
    sed "s/\$VNC_PASSWORD/$VNC_PASSWORD/g" > "$TMP_FILE"

# Zeige Kubernetes-Ereignisse im Namespace an
echo "Aktuelle Kubernetes-Ereignisse im Namespace:"
kubectl -n "$NAMESPACE" get events --sort-by=.metadata.creationTimestamp | tail -5

# Anwenden der Deployment-Konfiguration
echo -e "\n${GREEN}Erstelle Deployment und Service...${NC}"
kubectl apply -f "$TMP_FILE"

# Aufräumen
rm "$TMP_FILE"

# Warte auf das Deployment
echo "Warte auf das XFCE Deployment..."
echo "Dies kann einige Minuten dauern, da die Installation von VS Code, Sublime Text und Ansible Zeit benötigt..."
kubectl -n "$NAMESPACE" rollout status deployment/"$WEBTOP_DEPLOYMENT_NAME" --timeout=600s || {
    echo -e "\n${YELLOW}WARNUNG: Timeout beim Warten auf das Deployment.${NC}"
    echo "Aktueller Status des Deployments:"
    kubectl -n "$NAMESPACE" get pods -l app=webtop
    echo -e "\nÜberprüfen Sie die Pod-Events:"
    kubectl -n "$NAMESPACE" get events --field-selector involvedObject.kind=Pod --sort-by=.metadata.creationTimestamp | tail -10
}

# Zeige den aktuellen Status an
POD_NAME=$(kubectl -n "$NAMESPACE" get pods -l app=webtop -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$POD_NAME" ]; then
    echo -e "\nPod-Status:"
    kubectl -n "$NAMESPACE" get pod "$POD_NAME" -o wide
    
    # Prüfe, ob der Pod im Status "Running" ist
    POD_STATUS=$(kubectl -n "$NAMESPACE" get pod "$POD_NAME" -o jsonpath='{.status.phase}')
    if [ "$POD_STATUS" = "Running" ]; then
        echo -e "\n${GREEN} XFCE Desktop mit Entwicklungstools erfolgreich bereitgestellt.${NC}"
    else
        echo -e "\n${YELLOW}WARNUNG: Pod ist im Status '$POD_STATUS'. Möglicherweise gibt es Probleme.${NC}"
        echo "Pod-Logs anzeigen? (j/N)"
        read -r SHOW_LOGS
        if [[ $SHOW_LOGS =~ ^[Jj]$ ]]; then
            kubectl -n "$NAMESPACE" logs "$POD_NAME"
        fi
    fi
else
    echo -e "\n${RED}Fehler: Kein Pod für das Webtop-Deployment gefunden.${NC}"
    echo "Überprüfen Sie die Deployment-Events:"
    kubectl -n "$NAMESPACE" get events --field-selector involvedObject.kind=Deployment
fi

echo
echo -e "${YELLOW}WICHTIGER HINWEIS:${NC} Diese Version verwendet einen temporären Speicher (EmptyDir)."
echo "Alle Ihre Daten gehen verloren, wenn der Pod neu gestartet wird!"
echo "Sichern Sie wichtige Daten regelmäßig durch Download."
echo
echo "Zugriff über Port-Forwarding:"
echo "  kubectl -n $NAMESPACE port-forward svc/$WEBTOP_SERVICE_NAME 3000:3000"
echo "Öffnen Sie dann http://localhost:3000 in Ihrem Browser."
echo
echo "Für eine sichere HTTPS-Verbindung:"
echo "  kubectl -n $NAMESPACE port-forward svc/$WEBTOP_SERVICE_NAME 3001:3001"
echo "Öffnen Sie dann https://localhost:3001 in Ihrem Browser."
echo
echo "Verwenden Sie das konfigurierte Passwort für den Zugriff."
echo
echo "Wollen Sie das Port-Forwarding jetzt starten? (j/n)"
read -r START_PORT_FORWARD

if [[ "$START_PORT_FORWARD" =~ ^[Jj]$ ]]; then
    echo "Starte Port-Forwarding..."
    "$SCRIPT_DIR/port-forward-webtop.sh"
else
    echo "Port-Forwarding nicht gestartet. Sie können es später mit ./scripts/port-forward-webtop.sh starten."
fi