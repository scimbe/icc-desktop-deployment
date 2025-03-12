#!/bin/bash

# Skript zur direkten Ausführung des VS Playbooks im Container
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
    exit 1
fi

# Prüfe, ob Namespace existiert
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo -e "${RED}Fehler: Namespace $NAMESPACE existiert nicht.${NC}"
    exit 1
fi

# Prüfe, ob mindestens ein Pod läuft
POD_NAME=$(kubectl -n "$NAMESPACE" get pods -l service=webtop -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$POD_NAME" ]; then
    echo -e "${RED}Fehler: Kein Pod für das Webtop-Deployment gefunden.${NC}"
    exit 1
fi

# Prüfe, ob der Pod im Status "Running" ist
POD_STATUS=$(kubectl -n "$NAMESPACE" get pod "$POD_NAME" -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
    echo -e "${RED}Fehler: Pod ist nicht im Status 'Running', sondern '$POD_STATUS'.${NC}"
    exit 1
fi

# Repository-Auswahl anzeigen
echo -e "${GREEN}=== VS Repository Checkout und Playbook Ausführung ===${NC}"
echo "Namespace: $NAMESPACE"
echo "Pod: $POD_NAME"
echo "Repository-Auswahl: ${DESKTOP_INSTALLATION:-0}"
echo

# Bestätigung einholen
read -p "Möchten Sie mit dem Repository-Checkout und der Playbook-Ausführung fortfahren? (j/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Jj]$ ]]; then
    echo "Abbruch"
    exit 0
fi

# Prüfe, ob das Repository-Skript existiert und ausführbar ist
if [ ! -f "$SCRIPT_DIR/repo_checkout_script.sh" ]; then
    echo -e "${RED}Fehler: Repository-Checkout-Skript nicht gefunden.${NC}"
    exit 1
fi
chmod +x "$SCRIPT_DIR/repo_checkout_script.sh"

# Kopiere und führe das Repository-Skript im Container aus
echo -e "${YELLOW}Führe Repository-Checkout im Container aus...${NC}"
kubectl -n "$NAMESPACE" cp "$SCRIPT_DIR/repo_checkout_script.sh" "$NAMESPACE/$POD_NAME:/tmp/repo_checkout_script.sh"
kubectl -n "$NAMESPACE" exec -i "$POD_NAME" -- bash -c "chmod +x /tmp/repo_checkout_script.sh && export DESKTOP_INSTALLATION=\"${DESKTOP_INSTALLATION}\" && sudo /tmp/repo_checkout_script.sh"

# Führe das Ansible-Playbook direkt aus
echo -e "${YELLOW}Führe Ansible-Playbook im Container aus...${NC}"
kubectl -n "$NAMESPACE" exec -i "$POD_NAME" -- bash -c "cd /config && sudo -u abc ansible-playbook -i ansible-basic/localhost ansible-basic/playbooks/linux/xfc4/pl-xfc4-playbook.yml --extra-vars \"repo_choice_var=0\""

echo -e "\n${GREEN}Git-Repository wurde ausgecheckt und Ansible-Playbook wurde ausgeführt.${NC}"
