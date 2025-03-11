#!/bin/bash

# Skript zum Löschen aller Webtop-Ressourcen von der ICC
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

echo -e "${YELLOW}=== Löschen aller Ubuntu XFCE Desktop Ressourcen ===${NC}"
echo "Namespace: $NAMESPACE"
echo "Diese Aktion wird alle Ressourcen des Ubuntu XFCE Desktops löschen,"
echo "einschließlich des persistenten Speichers und aller darin enthaltenen Daten!"
echo

# Bestätigung einholen
read -p "Sind Sie sicher, dass Sie alle Ressourcen löschen möchten? (j/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Jj]$ ]]; then
    echo "Abbruch"
    exit 0
fi

# Doppelte Bestätigung für Datenverlust
read -p "Warnung: Alle gespeicherten Daten werden unwiderruflich gelöscht! Fortfahren? (j/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Jj]$ ]]; then
    echo "Abbruch"
    exit 0
fi

echo -e "\n${YELLOW}Lösche Service...${NC}"
kubectl delete service "$WEBTOP_SERVICE_NAME" --namespace="$NAMESPACE" --ignore-not-found
echo -e "${GREEN}✓${NC} Service gelöscht oder nicht gefunden."

echo -e "\n${YELLOW}Lösche Deployment...${NC}"
kubectl delete deployment "$WEBTOP_DEPLOYMENT_NAME" --namespace="$NAMESPACE" --ignore-not-found
echo -e "${GREEN}✓${NC} Deployment gelöscht oder nicht gefunden."

# Warte kurz, damit Pods beendet werden können
echo -e "\n${YELLOW}Warte auf Beendigung der Pods...${NC}"
sleep 5

# Überprüfe, ob noch Pods mit dem Label "app=webtop" laufen
PODS=$(kubectl get pods --namespace="$NAMESPACE" -l app=webtop -o name 2>/dev/null || echo "")
if [ -n "$PODS" ]; then
    echo -e "${YELLOW}Es laufen noch einige Pods. Lösche diese...${NC}"
    kubectl delete pods --namespace="$NAMESPACE" -l app=webtop --force --grace-period=0
    echo -e "${GREEN}✓${NC} Pods gelöscht."
    
    # Warte nochmal kurz
    sleep 2
fi

echo -e "\n${YELLOW}Lösche PersistentVolumeClaim...${NC}"
kubectl delete pvc webtop-pvc --namespace="$NAMESPACE" --ignore-not-found
echo -e "${GREEN}✓${NC} PersistentVolumeClaim gelöscht oder nicht gefunden."

# Überprüfe, ob alle Ressourcen entfernt wurden
echo -e "\n${YELLOW}Überprüfe, ob alle Ressourcen entfernt wurden...${NC}"

# Überprüfe Deployment
if kubectl get deployment "$WEBTOP_DEPLOYMENT_NAME" --namespace="$NAMESPACE" &>/dev/null; then
    echo -e "${RED}✗${NC} Deployment '$WEBTOP_DEPLOYMENT_NAME' existiert noch."
else
    echo -e "${GREEN}✓${NC} Deployment '$WEBTOP_DEPLOYMENT_NAME' wurde gelöscht."
fi

# Überprüfe Service
if kubectl get service "$WEBTOP_SERVICE_NAME" --namespace="$NAMESPACE" &>/dev/null; then
    echo -e "${RED}✗${NC} Service '$WEBTOP_SERVICE_NAME' existiert noch."
else
    echo -e "${GREEN}✓${NC} Service '$WEBTOP_SERVICE_NAME' wurde gelöscht."
fi

# Überprüfe PVC
if kubectl get pvc webtop-pvc --namespace="$NAMESPACE" &>/dev/null; then
    echo -e "${RED}✗${NC} PersistentVolumeClaim 'webtop-pvc' existiert noch."
else
    echo -e "${GREEN}✓${NC} PersistentVolumeClaim 'webtop-pvc' wurde gelöscht."
fi

# Überprüfe Pods
PODS=$(kubectl get pods --namespace="$NAMESPACE" -l app=webtop -o name 2>/dev/null || echo "")
if [ -n "$PODS" ]; then
    echo -e "${RED}✗${NC} Es existieren noch webtop Pods:"
    echo "$PODS"
else
    echo -e "${GREEN}✓${NC} Keine webtop Pods mehr vorhanden."
fi

echo -e "\n${GREEN}Bereinigung abgeschlossen.${NC}"
echo "Alle Ressourcen des Ubuntu XFCE Desktops wurden gelöscht."