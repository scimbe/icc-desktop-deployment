# Fehlerbehebung: Ubuntu XFCE Desktop auf der ICC

Diese Anleitung bietet Hilfestellung zur Lösung von Problemen, die bei der Installation und Nutzung des Ubuntu XFCE Desktops auf der ICC auftreten können.

## Segmentation Fault im VNC-Server

Wenn Sie eine Fehlermeldung ähnlich der folgenden sehen:
```
(EE) Segmentation fault at address...
(EE) Caught signal 11 (Segmentation fault). Server aborting
```

Dies deutet auf ein Problem mit dem VNC-Server innerhalb des Containers hin. Diese Probleme können verschiedene Ursachen haben, darunter Speichermangel, Inkompatibilitäten oder Speicherfehler im Container.

### Lösungsansätze:

1. **Minimale Installation verwenden**
   ```bash
   # Alte Deployment bereinigen
   ./scripts/cleanup-webtop.sh
   
   # Minimale Version installieren
   ./scripts/deploy-webtop-minimal.sh
   ```
   
   Dieser Ansatz verwendet eine vereinfachte Installation, die zuerst nur den Desktop ohne Entwicklungstools bereitstellt, um Stabilitätsprobleme zu umgehen.

2. **Container neu starten**
   ```bash
   # Pod-Namen ermitteln
   POD_NAME=$(kubectl -n $NAMESPACE get pods -l service=webtop -o jsonpath='{.items[0].metadata.name}')
   
   # Pod löschen (wird automatisch neu erstellt)
   kubectl -n $NAMESPACE delete pod $POD_NAME
   ```

3. **Ressourcen erhöhen**
   Bearbeiten Sie die Datei `configs/webtop-config.sh` und erhöhen Sie die Werte für `MEMORY_LIMIT` und `CPU_LIMIT`:
   ```bash
   # Beispiel für erhöhte Ressourcen
   export MEMORY_LIMIT="16Gi"
   export CPU_LIMIT="8000m"
   ```

## Probleme bei der Paketinstallation

Wenn Pakete wie VSCode, Sublime Text oder Ansible nicht installiert werden können:

### Lösungsansätze:

1. **Manuelle Installation nach dem Start**
   Verbinden Sie sich mit dem Desktop und führen Sie die Installation manuell über das Terminal durch:
   
   **VSCode:**
   ```bash
   sudo apt-get update
   sudo apt-get install -y apt-transport-https wget
   wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
   sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
   sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
   sudo apt-get update
   sudo apt-get install -y code
   ```
   
   **Sublime Text:**
   ```bash
   sudo apt-get update
   sudo apt-get install -y apt-transport-https wget
   wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
   echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
   sudo apt-get update
   sudo apt-get install -y sublime-text
   ```
   
   **Ansible:**
   ```bash
   sudo apt-get update
   sudo apt-get install -y software-properties-common
   sudo add-apt-repository --yes --update ppa:ansible/ansible
   sudo apt-get install -y ansible
   ```

2. **Container-Logs überprüfen**
   ```bash
   # Pod-Namen ermitteln
   POD_NAME=$(kubectl -n $NAMESPACE get pods -l service=webtop -o jsonpath='{.items[0].metadata.name}')
   
   # Logs anzeigen
   kubectl -n $NAMESPACE logs $POD_NAME
   ```

## Probleme beim Desktop-Zugriff

Wenn Sie nicht auf den Desktop zugreifen können, nachdem die Installation abgeschlossen ist:

### Lösungsansätze:

1. **Port-Forwarding überprüfen**
   ```bash
   # Port-Forwarding neu starten
   ./scripts/port-forward-webtop.sh
   ```

2. **Alternativen Browser oder Client verwenden**
   Testen Sie den Zugriff mit einem anderen Browser oder VNC/RDP-Client, um browserabhängige Probleme auszuschließen.

3. **Verbindungsdetails überprüfen**
   ```bash
   # Service-Details anzeigen
   kubectl -n $NAMESPACE get service ubuntu-xfce -o wide
   ```

## Probleme mit dem persistenten Speicher

Wenn Daten nicht dauerhaft gespeichert werden oder der persistente Speicher nicht funktioniert:

### Lösungsansätze:

1. **PVC Status überprüfen**
   ```bash
   kubectl -n $NAMESPACE get pvc webtop-pvc
   kubectl -n $NAMESPACE describe pvc webtop-pvc
   ```

2. **Temporären Speicher verwenden**
   ```bash
   # Alte Deployment bereinigen
   ./scripts/cleanup-webtop.sh
   
   # EmptyDir statt PVC verwenden
   ./scripts/deploy-webtop-simple.sh
   ```

## Allgemeine Debugging-Tipps

1. **Pod-Details anzeigen**
   ```bash
   POD_NAME=$(kubectl -n $NAMESPACE get pods -l service=webtop -o jsonpath='{.items[0].metadata.name}')
   kubectl -n $NAMESPACE describe pod $POD_NAME
   ```

2. **In den Container einloggen**
   ```bash
   POD_NAME=$(kubectl -n $NAMESPACE get pods -l service=webtop -o jsonpath='{.items[0].metadata.name}')
   kubectl -n $NAMESPACE exec -it $POD_NAME -- /bin/bash
   ```

3. **Ereignisse im Namespace anzeigen**
   ```bash
   kubectl -n $NAMESPACE get events --sort-by=.metadata.creationTimestamp
   ```

4. **DNS prüfen**
   Innerhalb des Containers:
   ```bash
   apt-get update && apt-get install -y dnsutils
   nslookup google.com
   ping -c 4 8.8.8.8
   ```

5. **Monitoring-Skript verwenden**
   ```bash
   ./scripts/monitor-installation.sh
   ```

Falls Sie weiterhin Probleme haben, wenden Sie sich bitte an den ICC-Support mit den Details aus den obigen Diagnose-Schritten.