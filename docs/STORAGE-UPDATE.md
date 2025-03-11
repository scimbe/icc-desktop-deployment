# README-Aktualisierung: rook-ceph-block StorageClass-Support

Die folgenden Änderungen wurden implementiert, um die korrekte Nutzung der `rook-ceph-block` StorageClass für persistenten Speicher in der ICC-Umgebung zu gewährleisten:

## 1. Geänderte PVC-Templates

Alle PersistentVolumeClaim (PVC) Templates wurden aktualisiert, um die `storageClassName: rook-ceph-block` Spezifikation zu enthalten:

- `templates/webtop-pvc-icc.yaml`
- `templates/webtop-pvc.yaml`
- Inline-PVC in `templates/debian-xfce-deployment.yaml`

## 2. Neue Hilfsskripte und Dokumentation

### Neues PVC-Erstellungsskript

Ein neues Hilfsskript `scripts/create-rook-ceph-pvc.sh` wurde erstellt, das:
- Die Existenz der `rook-ceph-block` StorageClass prüft
- Den aktuellen Status existierender PVCs überprüft
- Bei Bedarf einen neuen PVC mit der korrekten StorageClass erstellt
- Fehlerbehandlung für gängige Probleme bei der PVC-Erstellung bietet

### Neue Dokumentation

Eine neue Dokumentationsdatei `docs/STORAGE-CLASS-INFO.md` wurde erstellt, die:
- Die korrekte Verwendung der `rook-ceph-block` StorageClass beschreibt
- Ein Beispiel für eine korrekte PVC-Definition enthält
- Hinweise für die Verwendung persistenten Speichers in der ICC-Umgebung gibt

## 3. Unveränderte Konfigurationen

Die folgenden Dateien wurden absichtlich nicht geändert:

- `templates/webtop-emptydir.yaml` - Diese Datei verwendet bewusst einen temporären Speicher (EmptyDir) ohne persistenten Speicher und benötigt daher keine StorageClass.

## 4. Verwendung in den Deployment-Prozessen

Die Deployment-Skripte verwenden automatisch die aktualisierte Konfiguration mit der `rook-ceph-block` StorageClass, wenn sie ausgeführt werden.

Falls Sie die Storage-Konfiguration separat validieren oder erstellen möchten, können Sie das neue Skript verwenden:

```bash
# PVC mit rook-ceph-block StorageClass prüfen und erstellen
./scripts/create-rook-ceph-pvc.sh
```

## 5. Empfohlene Tests nach den Änderungen

Nach der Implementierung dieser Änderungen empfehlen wir folgende Tests:

1. Überprüfen Sie die korrekte StorageClass-Angabe in den PVCs:
   ```bash
   kubectl -n $NAMESPACE get pvc webtop-pvc -o jsonpath='{.spec.storageClassName}'
   ```
   Das Ergebnis sollte `rook-ceph-block` sein.

2. Überprüfen Sie den Bindungsstatus des PVC:
   ```bash
   kubectl -n $NAMESPACE get pvc webtop-pvc
   ```
   Der Status sollte `Bound` sein.

3. Testen Sie die Persistenz über Pod-Neustarts hinweg.