#!/bin/bash

# Skript zum Deployment von debian XFCE Desktop mit Entwicklungstools auf der ICC
# Angepasst an die ICC-Umgebung
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

echo -e "${GREEN}=== ICC debian XFCE Desktop mit Entwicklungstools Deployment ===${NC}"
echo "Namespace: $NAMESPACE"
echo "Ressourcen: $MEMORY_LIMIT RAM, $CPU_LIMIT CPU"
echo "Persistenter Speicher: $STORAGE_SIZE"
echo

# Bestätigung einholen
read -p "Möchten Sie mit dem Deployment fortfahren? (j/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Jj]$ ]]; then
    echo "Abbruch"
    exit 0
fi

# Erstelle temporäre YAML-Dateien für das Deployment
PVC_TMP_FILE=$(mktemp)
DEPLOY_TMP_FILE=$(mktemp)

# Ersetze Variablen in der PVC-YAML-Datei
cat "$ROOT_DIR/templates/webtop-pvc-icc.yaml" | \
    sed "s/\$NAMESPACE/$NAMESPACE/g" | \
    sed "s/\$STORAGE_SIZE/$STORAGE_SIZE/g" > "$PVC_TMP_FILE"

# Ersetze Variablen in der Deployment-YAML-Datei
cat "$ROOT_DIR/templates/webtop-deployment-icc.yaml" | \
    sed "s/\$NAMESPACE/$NAMESPACE/g" | \
    sed "s/\$MEMORY_LIMIT/$MEMORY_LIMIT/g" | \
    sed "s/\$CPU_LIMIT/$CPU_LIMIT/g" | \
    sed "s/\$VNC_PASSWORD/$VNC_PASSWORD/g" > "$DEPLOY_TMP_FILE"

# Zeige aktuelle Ressourcen und Ereignisse
echo "Aktuelle Ressourcen im Namespace $NAMESPACE:"
kubectl -n "$NAMESPACE" get pvc,deployment,service

echo -e "\nAktuelle Kubernetes-Ereignisse im Namespace:"
kubectl -n "$NAMESPACE" get events --sort-by=.metadata.creationTimestamp | tail -5

# Anwenden der PVC-Konfiguration
echo -e "\n${GREEN}Schritt 1: Erstelle PersistentVolumeClaim...${NC}"
kubectl apply -f "$PVC_TMP_FILE"

# Warte kurz, um sicherzustellen, dass der PVC erstellt wurde
echo "Warte auf PVC-Erstellung..."
for i in {1..10}; do
    if kubectl -n "$NAMESPACE" get pvc webtop-pvc &> /dev/null; then
        echo -e "${GREEN}PVC 'webtop-pvc' wurde erstellt!${NC}"
        kubectl -n "$NAMESPACE" get pvc webtop-pvc
        break
    fi
    
    if [ $i -eq 10 ]; then
        echo -e "${YELLOW}PVC noch nicht verfügbar, versuche trotzdem fortzufahren...${NC}"
    else
        echo "Warte weitere 3 Sekunden... ($i/10)"
        sleep 3
    fi
done

# Anwenden der Deployment-Konfiguration
echo -e "\n${GREEN}Schritt 2: Erstelle Deployment und Service...${NC}"
kubectl apply -f "$DEPLOY_TMP_FILE"

# Aufräumen
rm "$PVC_TMP_FILE" "$DEPLOY_TMP_FILE"

# Warte auf das Deployment
echo "Warte auf das debian XFCE Deployment..."
echo "Dies kann einige Minuten dauern, da die Installation von VS Code, Sublime Text und Ansible Zeit benötigt..."
kubectl -n "$NAMESPACE" rollout status deployment/"$WEBTOP_DEPLOYMENT_NAME" --timeout=300s || {
    echo -e "\n${YELLOW}Timeout beim Warten auf das Deployment. Prüfe den Status...${NC}"
}

# Zeige den aktuellen Status an
echo -e "\n${GREEN}Status des Deployments:${NC}"
kubectl -n "$NAMESPACE" get deployment "$WEBTOP_DEPLOYMENT_NAME" -o wide

echo -e "\n${GREEN}Status der Pods:${NC}"
kubectl -n "$NAMESPACE" get pods -l service=webtop -o wide

echo -e "\n${GREEN}Status des Service:${NC}"
kubectl -n "$NAMESPACE" get service "$WEBTOP_SERVICE_NAME" -o wide

echo -e "\n${GREEN}Status des PVC:${NC}"
kubectl -n "$NAMESPACE" get pvc webtop-pvc -o wide

# Prüfe, ob mindestens ein Pod läuft
POD_NAME=$(kubectl -n "$NAMESPACE" get pods -l service=webtop -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$POD_NAME" ]; then
    # Prüfe, ob der Pod im Status "Running" ist
    POD_STATUS=$(kubectl -n "$NAMESPACE" get pod "$POD_NAME" -o jsonpath='{.status.phase}')
    if [ "$POD_STATUS" = "Running" ]; then
        echo -e "\n${GREEN}debian XFCE Desktop mit Entwicklungstools erfolgreich bereitgestellt.${NC}"
    else
        echo -e "\n${YELLOW}Pod ist im Status '$POD_STATUS'. Mögliche Probleme:${NC}"
        kubectl -n "$NAMESPACE" describe pod "$POD_NAME"
        
        echo -e "\n${YELLOW}Die letzten Pod-Ereignisse:${NC}"
        kubectl -n "$NAMESPACE" get events --sort-by=.metadata.creationTimestamp | grep "$POD_NAME" | tail -5
        
        echo -e "\n${YELLOW}Pod-Logs anzeigen? (j/N)${NC}"
        read -r SHOW_LOGS
        if [[ $SHOW_LOGS =~ ^[Jj]$ ]]; then
            kubectl -n "$NAMESPACE" logs "$POD_NAME"
        fi
    fi
else
    echo -e "\n${RED}Fehler: Kein Pod für das Webtop-Deployment gefunden.${NC}"
    echo "Ereignisse für das Deployment:"
    kubectl -n "$NAMESPACE" get events --field-selector involvedObject.kind=Deployment,involvedObject.name="$WEBTOP_DEPLOYMENT_NAME"
    
    echo -e "\nAlle aktuellen Ereignisse im Namespace:"
    kubectl -n "$NAMESPACE" get events --sort-by=.metadata.creationTimestamp | tail -10
fi

echo
echo "Zugriff über Port-Forwarding:"
echo "  kubectl -n $NAMESPACE port-forward svc/$WEBTOP_SERVICE_NAME 3000:3000"
echo "Öffnen Sie dann http://localhost:3000 in Ihrem Browser."
echo
echo "Für eine sichere HTTPS-Verbindung:"
echo "  kubectl -n $NAMESPACE port-forward svc/$WEBTOP_SERVICE_NAME 3001:3001"
echo "Öffnen Sie dann https://localhost:3001 in Ihrem Browser."
echo
echo "Verwenden Sie das konfigurierte Passwort für den Zugriff: $VNC_PASSWORD"
echo
echo "Wollen Sie das Port-Forwarding jetzt starten? (j/n)"
read -r START_PORT_FORWARD

if [[ "$START_PORT_FORWARD" =~ ^[Jj]$ ]]; then
    echo "Starte Port-Forwarding..."
    "$SCRIPT_DIR/port-forward-webtop.sh"
else
    echo "Port-Forwarding nicht gestartet. Sie können es später mit ./scripts/port-forward-webtop.sh starten."
fi