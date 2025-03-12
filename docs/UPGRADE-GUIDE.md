# Upgrade-Guide und Migrationsplan

Diese Anleitung beschreibt den Prozess zum Upgrade und zur Migration des ICC debian XFCE Desktop-Systems. Sie können hiermit Ihr bestehendes Deployment auf die neueste Version aktualisieren oder Daten zwischen verschiedenen Deployments migrieren.

## Inhaltsverzeichnis

1. [Vorbereitung](#vorbereitung)
2. [Daten sichern](#daten-sichern)
3. [Upgrade durchführen](#upgrade-durchführen)
4. [Daten migrieren](#daten-migrieren)
5. [Problembehebung](#problembehebung)

## Vorbereitung

Bevor Sie ein Upgrade oder eine Migration durchführen, überprüfen Sie die aktuelle Version und den Status:

```bash
# Deployment-Status überprüfen
kubectl -n $NAMESPACE get pods,pvc,deployment

# Aktuelle Version der Konfiguration überprüfen
grep -r "VERSION" configs/webtop-config.sh
```

Stellen Sie sicher, dass alle wichtigen Anwendungen geschlossen sind und keine laufenden Prozesse im Container aktiv sind.

## Daten sichern

Es ist wichtig, Ihre Daten zu sichern, bevor Sie ein Upgrade durchführen:

### Methode 1: Backup via PVC-Snapshot (empfohlen)

```bash
# Erstellen Sie einen Snapshot des PVC (falls von der ICC unterstützt)
kubectl -n $NAMESPACE get pvc webtop-pvc -o yaml > webtop-pvc-backup.yaml
```

### Methode 2: Manueller Export wichtiger Daten

Verbinden Sie sich mit dem Desktop und exportieren Sie wichtige Dateien:

1. Über die Web-Oberfläche: Nutzen Sie die Upload/Download-Funktion
2. Via Terminal:
   ```bash
   # Pod-Namen ermitteln
   POD_NAME=$(kubectl -n $NAMESPACE get pods -l service=webtop -o jsonpath='{.items[0].metadata.name}')
   
   # Wichtige Daten kopieren
   kubectl -n $NAMESPACE cp $POD_NAME:/config/projects/ ./backup-projects/
   kubectl -n $NAMESPACE cp $POD_NAME:/config/.config/ ./backup-config/
   ```

## Upgrade durchführen

### Option 1: In-Place Upgrade (ohne Datenverlust)

Diese Methode aktualisiert das Deployment, behält aber den persistenten Speicher bei:

```bash
# Repository aktualisieren
git pull origin main

# Alte Deployment bereinigen (nur Deployment, nicht PVC)
kubectl -n $NAMESPACE delete deployment debian-xfce
kubectl -n $NAMESPACE delete service debian-xfce

# Neues Deployment starten
./deploy-webtop.sh
```

### Option 2: Vollständige Neuinstallation

Nutzen Sie diese Option nur, wenn die In-Place-Aktualisierung nicht funktioniert:

```bash
# Altes Deployment vollständig entfernen
./scripts/cleanup-webtop.sh

# Neues Deployment starten
./deploy-webtop.sh
```

## Daten migrieren

Wenn Sie zwischen verschiedenen Deployments migrieren möchten:

### Zwischen zwei PVCs migrieren

1. Erstellen Sie einen temporären Pod zum Kopieren:

```bash
cat <<EOF | kubectl apply -n $NAMESPACE -f -
apiVersion: v1
kind: Pod
metadata:
  name: data-migration-helper
spec:
  containers:
  - name: helper
    image: debian:buster
    command: ["sleep", "3600"]
    volumeMounts:
    - name: source-data
      mountPath: /source
    - name: target-data
      mountPath: /target
  volumes:
  - name: source-data
    persistentVolumeClaim:
      claimName: source-pvc-name
  - name: target-data
    persistentVolumeClaim:
      claimName: target-pvc-name
EOF
```

2. Kopieren Sie die Daten:

```bash
kubectl -n $NAMESPACE exec -it data-migration-helper -- bash -c "cp -rp /source/home/abc/* /target/home/abc/"
```

3. Bereinigen Sie nach dem Kopieren:

```bash
kubectl -n $NAMESPACE delete pod data-migration-helper
```

### Anwendungsdaten manuell migrieren

Für spezifische Anwendungsdaten:

1. **VS Code Settings**:
   ```bash
   kubectl -n $NAMESPACE cp ./backup-config/Code $POD_NAME:/config/.config/Code
   ```

2. **Sublime Text Settings**:
   ```bash
   kubectl -n $NAMESPACE cp ./backup-config/sublime-text-3 $POD_NAME:/config/.config/sublime-text-3
   ```

3. **SSH-Schlüssel und Git-Konfiguration**:
   ```bash
   kubectl -n $NAMESPACE cp ./backup-home/.ssh $POD_NAME:/config/.ssh
   kubectl -n $NAMESPACE cp ./backup-home/.gitconfig $POD_NAME:/config/.gitconfig
   ```

## Problembehebung

Bei Problemen während des Upgrades oder der Migration:

### Desktop startet nach Upgrade nicht

```bash
# Logs überprüfen
POD_NAME=$(kubectl -n $NAMESPACE get pods -l service=webtop -o jsonpath='{.items[0].metadata.name}')
kubectl -n $NAMESPACE logs $POD_NAME

# Pod neu starten
kubectl -n $NAMESPACE delete pod $POD_NAME
```

### Berechtigungsprobleme nach Migration

```bash
# Berechtigungen korrigieren
kubectl -n $NAMESPACE exec -it $POD_NAME -- bash -c "chown -R abc:abc /config"
```

### PVC kann nicht gelöscht werden (PVC protection)

```bash
# Prüfen, welche Pods das PVC verwenden
kubectl -n $NAMESPACE get pod --all-namespaces -o json | jq '.items[] | select(.spec.volumes[] | select(.persistentVolumeClaim != null and .persistentVolumeClaim.claimName == "webtop-pvc")) | .metadata.name'

# Manuell löschen der Finalizer
kubectl -n $NAMESPACE patch pvc webtop-pvc -p '{"metadata":{"finalizers":null}}'
```

Wenn weitere Probleme auftreten, konsultieren Sie die `FEHLERBEHEBUNG.md` oder eröffnen Sie ein Issue im Projekt-Repository.
