#!/bin/bash

# Skript zur Prüfung und Erstellung von PVCs mit rook-ceph-block StorageClass
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

echo -e "${GREEN}=== PVC mit rook-ceph-block StorageClass prüfen und erstellen ===${NC}"
echo "Namespace: $NAMESPACE"
echo "Storage Size: $STORAGE_SIZE"
echo

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

# Prüfe, ob die StorageClass existiert
if ! kubectl get storageclass rook-ceph-block &> /dev/null; then
    echo -e "${RED}Fehler: StorageClass 'rook-ceph-block' existiert nicht in diesem Cluster.${NC}"
    echo "Bitte stellen Sie sicher, dass Rook-Ceph korrekt im Cluster installiert ist."
    exit 1
fi

# Prüfe, ob der PVC bereits existiert
if kubectl -n "$NAMESPACE" get pvc webtop-pvc &> /dev/null; then
    echo -e "${YELLOW}PVC 'webtop-pvc' existiert bereits im Namespace $NAMESPACE.${NC}"
    
    # Details des vorhandenen PVC anzeigen
    echo -e "\nDetails des existierenden PVC:"
    kubectl -n "$NAMESPACE" get pvc webtop-pvc -o yaml | grep -E "storageClassName:|capacity:|phase:"
    
    # Status des PVC prüfen
    PVC_STATUS=$(kubectl -n "$NAMESPACE" get pvc webtop-pvc -o jsonpath='{.status.phase}')
    if [ "$PVC_STATUS" != "Bound" ]; then
        echo -e "${RED}WARNUNG: Der PVC hat den Status '$PVC_STATUS' und ist nicht gebunden.${NC}"
        echo "Dies könnte auf Probleme mit der Storage-Klasse oder dem verfügbaren Speicher hindeuten."
    else
        echo -e "${GREEN}Der PVC ist erfolgreich an ein PersistentVolume gebunden.${NC}"
    fi
    
    # StorageClass prüfen
    PVC_SC=$(kubectl -n "$NAMESPACE" get pvc webtop-pvc -o jsonpath='{.spec.storageClassName}')
    if [ "$PVC_SC" != "rook-ceph-block" ]; then
        echo -e "${YELLOW}Der PVC verwendet die StorageClass '$PVC_SC' anstelle von 'rook-ceph-block'.${NC}"
        
        # Frage, ob der PVC gelöscht und neu erstellt werden soll
        read -p "Möchten Sie den vorhandenen PVC löschen und mit 'rook-ceph-block' StorageClass neu erstellen? (j/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Jj]$ ]]; then
            echo -e "${YELLOW}Lösche vorhandenen PVC...${NC}"
            kubectl -n "$NAMESPACE" delete pvc webtop-pvc
            echo -e "${GREEN}Vorhandener PVC wurde gelöscht.${NC}"
        else
            echo -e "${YELLOW}Der vorhandene PVC wird beibehalten. Die StorageClass 'rook-ceph-block' wird nicht verwendet.${NC}"
            exit 0
        fi
    else
        echo -e "${GREEN}Der PVC verwendet bereits die korrekte StorageClass 'rook-ceph-block'.${NC}"
        exit 0
    fi
fi

# Erstelle temporäre YAML-Datei für den PVC
TMP_FILE=$(mktemp)

# Erstelle den PVC mit rook-ceph-block StorageClass
cat > "$TMP_FILE" << EOF
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: webtop-pvc
  namespace: $NAMESPACE
  labels:
    service: webtop
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: rook-ceph-block
  resources:
    requests:
      storage: $STORAGE_SIZE
EOF

echo -e "${GREEN}Erstelle PVC mit rook-ceph-block StorageClass...${NC}"
kubectl apply -f "$TMP_FILE"

# Aufräumen
rm "$TMP_FILE"

# Warte kurz, um sicherzustellen, dass der PVC erstellt wurde
echo "Warte auf PVC-Erstellung..."
for i in {1..10}; do
    if kubectl -n "$NAMESPACE" get pvc webtop-pvc &> /dev/null; then
        echo -e "${GREEN}PVC 'webtop-pvc' wurde erfolgreich erstellt!${NC}"
        kubectl -n "$NAMESPACE" get pvc webtop-pvc
        break
    fi
    
    if [ $i -eq 10 ]; then
        echo -e "${YELLOW}PVC noch nicht verfügbar. Bitte überprüfen Sie den Status später mit:${NC}"
        echo "kubectl -n $NAMESPACE get pvc webtop-pvc"
    else
        echo "Warte weitere 3 Sekunden... ($i/10)"
        sleep 3
    fi
done

# Überprüfe, ob der PVC an ein PV gebunden ist
PVC_STATUS=$(kubectl -n "$NAMESPACE" get pvc webtop-pvc -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PVC_STATUS" = "Bound" ]; then
    echo -e "${GREEN}PVC 'webtop-pvc' wurde erfolgreich an ein PersistentVolume gebunden.${NC}"
else
    echo -e "${YELLOW}PVC 'webtop-pvc' hat noch den Status '$PVC_STATUS'.${NC}"
    echo "Dies ist normal, wenn die Bindung noch läuft. Überprüfen Sie den Status später mit:"
    echo "kubectl -n $NAMESPACE get pvc webtop-pvc"
fi

echo -e "\n${GREEN}PVC-Erstellung abgeschlossen.${NC}"
echo "Der PVC 'webtop-pvc' mit StorageClass 'rook-ceph-block' wurde konfiguriert."
echo "Sie können nun mit dem Deployment des Desktops fortfahren."
