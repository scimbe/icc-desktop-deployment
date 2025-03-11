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

# Erstelle temporäre YAML-Datei für das Deployment
TMP_FILE=$(mktemp)

# Ersetze Variablen in der Deployment-YAML-Datei
cat "$ROOT_DIR/templates/ubuntu-xfce-deployment.yaml" | \
    sed "s/\$NAMESPACE/$NAMESPACE/g" | \
    sed "s/\$MEMORY_LIMIT/$MEMORY_LIMIT/g" | \
    sed "s/\$CPU_LIMIT/$CPU_LIMIT/g" | \
    sed "s/\$VNC_PASSWORD/$VNC_PASSWORD/g" | \
    sed "s/\$STORAGE_SIZE/$STORAGE_SIZE/g" > "$TMP_FILE"

# Anwenden der Konfiguration
echo "Deploying Ubuntu XFCE mit Entwicklungstools zu namespace $NAMESPACE..."
kubectl apply -f "$TMP_FILE"

# Aufräumen
rm "$TMP_FILE"

# Warte auf das Deployment
echo "Warte auf das Ubuntu XFCE Deployment..."
echo "Dies kann einige Minuten dauern, da die Installation von VS Code, Sublime Text und Ansible Zeit benötigt..."
kubectl -n "$NAMESPACE" rollout status deployment/"$WEBTOP_DEPLOYMENT_NAME" --timeout=600s

echo "Ubuntu XFCE Desktop mit Entwicklungstools erfolgreich bereitgestellt."
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