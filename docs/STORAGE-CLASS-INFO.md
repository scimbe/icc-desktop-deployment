# Hinweise zur Verwendung der rook-ceph-block Storage-Klasse

Dieses Dokument beschreibt die korrekte Verwendung der `rook-ceph-block` Storage-Klasse in Kubernetes PersistentVolumeClaims (PVCs) für das ICC debian XFCE Desktop Deployment.

## Verwendung der Storage-Klasse

In allen PVC-Definitionen wurde die Storage-Klasse auf `rook-ceph-block` gesetzt, was die korrekte Implementierung für die ICC-Umgebung ist. Diese Storage-Klasse bietet:

- Block-Speicher mit ReadWriteOnce (RWO) Zugriffsmodus
- Persistenz der Daten über Pod-Neustarts hinweg
- Effiziente Speicherverwaltung durch Ceph

## Beispiel einer PVC-Definition

```yaml
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
```

## Betroffene Dateien

Die folgenden Dateien wurden aktualisiert, um diese Storage-Klasse zu verwenden:

1. `templates/webtop-pvc-icc.yaml`
2. `templates/webtop-pvc.yaml`
3. `templates/debian-xfce-deployment.yaml` (inline-PVC)

## Hinweise für Deployment-Skripte

Die Deployment-Skripte verwenden diese Vorlagen, um die tatsächlichen Kubernetes-Ressourcen zu erstellen. Die Storage-Klasse wird automatisch bei der Erstellung des PVC angewendet.

## Hinweise für persistenten Speicher

Bei der Verwendung persistenten Speichers mit der `rook-ceph-block` Storage-Klasse sollten Sie beachten:

- Die Daten bleiben nach Neustarts des Pods erhalten
- Es ist wichtig, ausreichend Speicherplatz in der Konfiguration anzugeben
- Der Zugriffsmodus ist auf ReadWriteOnce beschränkt, d.h. der PVC kann nur von einem Pod gleichzeitig verwendet werden

## Versionshinweise

- Diese Konfiguration wurde für die ICC-Umgebung der HAW Hamburg optimiert
- Die Storage-Klasse ist speziell für die Rook-Ceph-Implementierung in der ICC konfiguriert

---

**Hinweis**: Die temporäre Speicheroption mit `emptyDir` in `templates/webtop-emptydir.yaml` verwendet absichtlich keinen persistenten Speicher und wurde daher nicht angepasst.