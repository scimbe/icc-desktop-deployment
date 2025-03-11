#!/bin/bash

# Skript zum Deployment von Ubuntu XFCE Desktop mit Entwicklungstools auf der ICC
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

# Prüfe, ob kubectl verfügbar ist
if ! command -v kubectl &> /dev/null; then
    echo "Fehler: kubectl ist nicht installiert oder nicht im PATH."
    echo "Bitte installieren Sie kubectl gemäß der Anleitung: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

# Prüfe, ob Namespace existiert
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo "Fehler: Namespace $NAMESPACE existiert nicht."
    echo "Bitte überprüfen Sie Ihre Konfiguration und stellen Sie sicher, dass Sie bei der ICC eingeloggt sind."
    exit 1
fi

echo "=== ICC Ubuntu XFCE Desktop mit Entwicklungstools Deployment ==="
echo "Namespace: $NAMESPACE"
echo "Ressourcen: $MEMORY_LIMIT RAM, $CPU_LIMIT CPU"
echo "Persistenter Speicher: $STORAGE_SIZE"
echo

# Erstelle temporäre YAML-Dateien für das Deployment
PVC_TMP_FILE=$(mktemp)
DEPLOY_TMP_FILE=$(mktemp)

# Ersetze Variablen in der PVC-YAML-Datei
cat "$ROOT_DIR/templates/webtop-pvc.yaml" | \
    sed "s/\$NAMESPACE/$NAMESPACE/g" | \
    sed "s/\$STORAGE_SIZE/$STORAGE_SIZE/g" > "$PVC_TMP_FILE"

# Ersetze Variablen in der Deployment-YAML-Datei
cat "$ROOT_DIR/templates/webtop-deployment.yaml" | \
    sed "s/\$NAMESPACE/$NAMESPACE/g" | \
    sed "s/\$MEMORY_LIMIT/$MEMORY_LIMIT/g" | \
    sed "s/\$CPU_LIMIT/$CPU_LIMIT/g" | \
    sed "s/\$VNC_PASSWORD/$VNC_PASSWORD/g" > "$DEPLOY_TMP_FILE"

# Zeige Kubernetes-Ereignisse im Namespace an
echo "Aktuelle Kubernetes-Ereignisse im Namespace:"
kubectl -n "$NAMESPACE" get events --sort-by=.metadata.creationTimestamp | tail -5

# Anwenden der PVC-Konfiguration
echo -e "\nSchritt 1: Erstelle PersistentVolumeClaim..."
kubectl apply -f "$PVC_TMP_FILE"

# Warte kurz, um sicherzustellen, dass der PVC erstellt wurde
echo "Warte auf PVC-Erstellung..."
sleep 5

# Versuche 3 Mal, den PVC zu überprüfen, mit zunehmender Wartezeit
for i in {1..3}; do
    if kubectl -n "$NAMESPACE" get pvc webtop-pvc &> /dev/null; then
        echo "PVC 'webtop-pvc' erfolgreich erstellt."
        break
    else
        echo "Warte weitere $((5*i)) Sekunden auf PVC-Erstellung..."
        sleep $((5*i))
        
        if [ $i -eq 3 ] && ! kubectl -n "$NAMESPACE" get pvc webtop-pvc &> /dev/null; then
            echo -e "\n${RED}Fehler: PVC 'webtop-pvc' wurde nicht erstellt.${NC}"
            echo "PVC-Ereignisse:"
            kubectl -n "$NAMESPACE" get events --field-selector involvedObject.kind=PersistentVolumeClaim
            
            echo -e "\nMöchten Sie dennoch versuchen, das Deployment zu erstellen? (j/N)"
            read -r CONTINUE
            if [[ ! $CONTINUE =~ ^[Jj]$ ]]; then
                rm "$PVC_TMP_FILE" "$DEPLOY_TMP_FILE"
                exit 1
            fi
        fi
    fi
done

# Anwenden der Deployment-Konfiguration
echo -e "\nSchritt 2: Erstelle Deployment und Service..."
kubectl apply -f "$DEPLOY_TMP_FILE"

# Aufräumen
rm "$PVC_TMP_FILE" "$DEPLOY_TMP_FILE"

# Warte auf das Deployment
echo "Warte auf das Ubuntu XFCE Deployment..."
echo "Dies kann einige Minuten dauern, da die Installation von VS Code, Sublime Text und Ansible Zeit benötigt..."
kubectl -n "$NAMESPACE" rollout status deployment/"$WEBTOP_DEPLOYMENT_NAME" --timeout=600s || {
    echo -e "\nWARNUNG: Timeout beim Warten auf das Deployment."
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
        echo -e "\nUbuntu XFCE Desktop mit Entwicklungstools erfolgreich bereitgestellt."
    else
        echo -e "\nWARNUNG: Pod ist im Status '$POD_STATUS'. Möglicherweise gibt es Probleme."
        echo "Pod-Logs anzeigen? (j/N)"
        read -r SHOW_LOGS
        if [[ $SHOW_LOGS =~ ^[Jj]$ ]]; then
            kubectl -n "$NAMESPACE" logs "$POD_NAME"
        fi
    fi
else
    echo -e "\nFehler: Kein Pod für das Webtop-Deployment gefunden."
    echo "Überprüfen Sie die Deployment-Events:"
    kubectl -n "$NAMESPACE" get events --field-selector involvedObject.kind=Deployment
fi

echo
echo "HINWEIS: Die Installation aller Tools kann noch im Hintergrund laufen."
echo "Beim ersten Start könnten einige Anwendungen noch nicht verfügbar sein."
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