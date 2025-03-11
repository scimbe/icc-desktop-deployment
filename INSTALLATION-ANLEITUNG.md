# Installation des debian XFCE Development Desktop auf der ICC

Diese Anleitung hilft Ihnen bei der Installation des debian XFCE Development Desktops auf der Informatik Compute Cloud (ICC) der HAW Hamburg mit den korrigierten Deployment-Dateien.

## Problemlösung - Paketinstallation

Die Hauptprobleme bei der ursprünglichen Installation waren:

1. Die Paketinstallation mit `DOCKER_MODS` und `INSTALL_PACKAGES` funktionierte nicht zuverlässig
2. Die Repositories für VS Code, Sublime Text und Ansible wurden nicht korrekt konfiguriert

Diese Probleme wurden in den aktualisierten Deployment-Dateien behoben.

## Installation durchführen

### Vorbereitung

1. Stellen Sie sicher, dass Sie Zugang zur ICC haben und kubectl konfiguriert ist
2. Überprüfen Sie, ob Sie die richtige Konfiguration in `configs/webtop-config.sh` haben:
   ```bash
   cat configs/webtop-config.sh
   ```
   Falls nicht vorhanden, kopieren Sie die Beispieldatei und passen Sie sie an:
   ```bash
   cp configs/webtop-config.example.sh configs/webtop-config.sh
   # Editieren Sie die Datei und passen Sie insbesondere den NAMESPACE an
   nano configs/webtop-config.sh
   ```

### Option 1: Installation mit permanentem Speicher (empfohlen)

Diese Option verwendet einen PersistentVolumeClaim (PVC), der sicherstellt, dass Ihre Daten auch nach einem Neustart des Pods erhalten bleiben.

```bash
# Bereinigen Sie zuerst das vorhandene Deployment (falls vorhanden)
./scripts/cleanup-webtop.sh

# Starten Sie das Deployment
./deploy-webtop.sh

# Überwachen Sie den Installationsprozess
./scripts/monitor-installation.sh
```

### Option 2: Installation mit temporärem Speicher (für Tests)

Diese Option verwendet einen EmptyDir-Speicher. Daten gehen verloren, wenn der Pod neu gestartet wird, aber die Installation ist einfacher.

```bash
# Bereinigen Sie zuerst das vorhandene Deployment (falls vorhanden)
./scripts/cleanup-webtop.sh

# Starten Sie das Deployment mit temporärem Speicher
./scripts/deploy-webtop-simple.sh
```

## Zugriff auf den Desktop

Nachdem die Installation abgeschlossen ist, können Sie auf den Desktop zugreifen:

```bash
# Starten Sie das Port-Forwarding
./scripts/port-forward-webtop.sh
```

Öffnen Sie dann einen Browser und gehen Sie zu:
- http://localhost:3000 (HTTP)
- https://localhost:3001 (HTTPS, selbstsigniertes Zertifikat)

Verwenden Sie das in der Konfigurationsdatei angegebene Passwort (Standard: `haw-password`).

## Fehlerbehebung

Wenn während der Installation Probleme auftreten:

1. Überprüfen Sie die Logs des Pods:
   ```bash
   POD_NAME=$(kubectl -n $NAMESPACE get pods -l service=webtop -o jsonpath='{.items[0].metadata.name}')
   kubectl -n $NAMESPACE logs $POD_NAME
   ```

2. Installationsstatus überwachen:
   ```bash
   ./scripts/monitor-installation.sh
   ```

3. Bei schwerwiegenden Problemen können Sie das Deployment bereinigen und neu starten:
   ```bash
   ./scripts/cleanup-webtop.sh
   ./deploy-webtop.sh
   ```

4. Falls die Installation sehr lange dauert, kann es an der Netzwerkverbindung oder Ressourcenbeschränkungen liegen. Versuchen Sie in diesem Fall:
   ```bash
   # Überprüfen Sie den Ressourcenverbrauch
   kubectl -n $NAMESPACE top pod $POD_NAME
   
   # Erhöhen Sie die Ressourcen in configs/webtop-config.sh (falls möglich)
   nano configs/webtop-config.sh
   ```

## RDP-Unterstützung einrichten (optional)

Für eine bessere Performance können Sie RDP-Unterstützung hinzufügen:

```bash
./scripts/setup-rdp.sh
```

Dies installiert xrdp im Container und leitet Port 3389 für RDP-Verbindungen weiter.