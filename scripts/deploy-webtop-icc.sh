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
echo "Repository-Auswahl: ${DESKTOP_INSTALLATION:-0}"
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
        
        # Git-Repository auschecken und Ansible-Playbook ausführen
        echo -e "\n${GREEN}Schritt 3: Repository auschecken und Ansible-Playbook ausführen...${NC}"
        
        # Einfaches Skript zur Einrichtung von Ansible
        SETUP_SCRIPT=$(cat << 'EOF'
#!/bin/bash
set -e

# Wechsle ins Home-Verzeichnis des Benutzers abc
cd /config/home/abc

# Installiere benötigte Pakete (falls noch nicht vorhanden)
if ! command -v git &> /dev/null || ! command -v ansible &> /dev/null; then
    echo "Installiere benötigte Pakete..."
    apt-get update
    apt-get install -y git ansible
fi

# Clone das Repository mit dem spezifischen Branch
echo "Clone ansible-basic Repository (Branch: icc)..."
if [ -d "ansible-basic" ]; then
    echo "Repository existiert bereits, update wird durchgeführt..."
    cd ansible-basic
    git fetch
    git checkout icc
    git pull
else
    git clone -b icc https://github.com/scimbe/ansible-basic.git
    cd ansible-basic
fi

# Erstelle localhost Inventar-Datei falls nicht vorhanden
if [ ! -f "localhost" ]; then
    echo "Erstelle localhost Inventar-Datei..."
    echo "localhost ansible_connection=local" > localhost
fi

# Setze Berechtigungen
cd ..
chown -R abc:abc ansible-basic

echo "Ansible-Repository wurde ausgecheckt."
EOF
)
        
        # Temporäre Datei im Container erstellen und ausführen
        echo -e "${YELLOW}Führe Git-Checkout im Container aus...${NC}"
        echo "$SETUP_SCRIPT" | kubectl -n "$NAMESPACE" exec -i "$POD_NAME" -- bash -c "cat > /tmp/setup_script.sh && chmod +x /tmp/setup_script.sh"
        
        # Skript im Container ausführen
        kubectl -n "$NAMESPACE" exec -i "$POD_NAME" -- bash -c "sudo /tmp/setup_script.sh"
        
        # Kopiere und führe das Repository-Skript im Container aus
        echo -e "${YELLOW}Führe Repository-Checkout im Container aus...${NC}  .... ${DESKTOP_INSTALLATION}"
        kubectl -n "$NAMESPACE" cp "$SCRIPT_DIR/repo_checkout_script.sh" "$NAMESPACE/$POD_NAME:/tmp/repo_checkout_script.sh"
        # FIX: Verwende sudo -E, um Umgebungsvariablen zu erhalten
        kubectl -n "$NAMESPACE" exec -i "$POD_NAME" -- bash -c "chmod +x /tmp/repo_checkout_script.sh && export DESKTOP_INSTALLATION=\"${DESKTOP_INSTALLATION}\" && sudo -E /tmp/repo_checkout_script.sh"
        
        # Führe das Ansible-Playbook direkt aus
        echo -e "${YELLOW}Führe Ansible-Playbook im Container aus...${NC}"
        kubectl -n "$NAMESPACE" exec -i "$POD_NAME" -- bash -c "cd /config/home/abc && sudo -u abc ansible-playbook -i ansible-basic/localhost ansible-basic/playbooks/linux/xfc4/pl-xfc4-playbook.yml --extra-vars 'repo_choice_var=0'"
        
        echo -e "\n${GREEN}Git-Repository wurde ausgecheckt und Ansible-Playbook wurde ausgeführt.${NC}"
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