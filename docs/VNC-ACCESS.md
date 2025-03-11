# VNC-Zugriff auf den ICC debian XFCE Desktop

Diese Anleitung beschreibt, wie Sie mit verschiedenen VNC-Clients auf den debian XFCE Desktop zugreifen können. VNC (Virtual Network Computing) bietet eine alternative Zugriffsmethode zum Browser und RDP und kann in bestimmten Netzwerkkonfigurationen Vorteile bieten.

## Inhaltsverzeichnis

1. [Voraussetzungen](#voraussetzungen)
2. [VNC-Unterstützung konfigurieren](#vnc-unterstützung-konfigurieren)
3. [Port-Forwarding einrichten](#port-forwarding-einrichten)
4. [VNC-Clients für verschiedene Plattformen](#vnc-clients-für-verschiedene-plattformen)
5. [Sicherheitshinweise](#sicherheitshinweise)
6. [Fehlerbehebung](#fehlerbehebung)

## Voraussetzungen

- Ein erfolgreich installierter ICC debian XFCE Desktop
- Ein VNC-Client für Ihr Betriebssystem
- Port-Forwarding zum Desktop-Pod

## VNC-Unterstützung konfigurieren

Der Container hat bereits einen integrierten VNC-Server. Sie müssen lediglich sicherstellen, dass das richtige Passwort gesetzt ist:

1. **Überprüfen Sie das VNC-Passwort in der Konfigurationsdatei:**

   ```bash
   cat configs/webtop-config.sh | grep VNC_PASSWORD
   ```

2. **Passwort ändern (falls nötig):**

   Bearbeiten Sie die Datei `configs/webtop-config.sh` und ändern Sie den Wert für `VNC_PASSWORD`.

3. **Neustarten des Containers, um Änderungen zu übernehmen:**

   ```bash
   POD_NAME=$(kubectl -n $NAMESPACE get pods -l service=webtop -o jsonpath='{.items[0].metadata.name}')
   kubectl -n $NAMESPACE delete pod $POD_NAME
   ```

   Ein neuer Pod wird automatisch erstellt und verwendet das neue Passwort.

## Port-Forwarding einrichten

Um auf den VNC-Server zuzugreifen, müssen Sie Port-Forwarding für den VNC-Port (5900) einrichten:

```bash
# Port-Forwarding für VNC einrichten
POD_NAME=$(kubectl -n $NAMESPACE get pods -l service=webtop -o jsonpath='{.items[0].metadata.name}')
kubectl -n $NAMESPACE port-forward $POD_NAME 5900:5900
```

Halten Sie dieses Terminal geöffnet, während Sie den VNC-Client verwenden.

## VNC-Clients für verschiedene Plattformen

### Windows

**VNC Viewer von RealVNC (empfohlen):**

1. [VNC Viewer herunterladen](https://www.realvnc.com/de/connect/download/viewer/)
2. Installieren und starten
3. Verbindungsadresse: `localhost:5900` eingeben
4. Bei Aufforderung das VNC-Passwort eingeben

**TightVNC:**

1. [TightVNC herunterladen](https://www.tightvnc.com/download.php)
2. Installieren und TightVNC Viewer starten
3. Remote Host: `localhost:5900` eingeben
4. Passwort eingeben und verbinden

### macOS

**macOS integrierter Screen Sharing:**

1. Drücken Sie `Cmd + Space`, geben Sie "Screen Sharing" ein und starten Sie die App
2. Geben Sie `vnc://localhost:5900` ein
3. Authentifizieren Sie sich mit dem VNC-Passwort

**VNC Viewer für Mac:**

1. [VNC Viewer herunterladen](https://www.realvnc.com/de/connect/download/viewer/)
2. Installieren und starten
3. Verbindungsadresse: `localhost:5900` eingeben
4. VNC-Passwort eingeben

### Linux

**Remmina (für Ubuntu/Debian):**

1. Installation (falls nicht bereits installiert):
   ```bash
   sudo apt-get install remmina remmina-plugin-vnc
   ```

2. Starten Sie Remmina
3. Klicken Sie auf "+" zum Erstellen einer neuen Verbindung
4. Wählen Sie "VNC" als Protokoll
5. Server: `localhost:5900`
6. Passwort eingeben
7. Klicken Sie auf "Speichern und verbinden"

**Vinagre (für GNOME):**

1. Installation:
   ```bash
   sudo apt-get install vinagre
   ```

2. Starten Sie Vinagre
3. Klicken Sie auf "Verbinden"
4. Protokoll: VNC
5. Host: localhost:5900
6. Passwort eingeben und verbinden

## Sicherheitshinweise

VNC überträgt Daten standardmäßig unverschlüsselt. Da wir jedoch Port-Forwarding über kubectl verwenden, werden die Daten durch die Kubernetes-API verschlüsselt. Dennoch sollten Sie einige Sicherheitsaspekte beachten:

1. **Starkes Passwort verwenden**: Setzen Sie ein sicheres VNC-Passwort in der Konfigurationsdatei.

2. **Keine direkte Exposition**: Exponieren Sie den VNC-Port nicht direkt im Internet oder außerhalb der Kubernetes-Umgebung.

3. **SSH-Tunnel bei externem Zugriff**: Wenn Sie von außerhalb auf den VNC-Server zugreifen müssen, verwenden Sie einen SSH-Tunnel:
   ```bash
   ssh -L 5900:localhost:5900 benutzer@icc-zugriffsserver
   ```

4. **Sitzung beenden**: Schließen Sie Ihre VNC-Sitzung, wenn Sie sie nicht verwenden.

## Fehlerbehebung

### Problem: Verbindung fehlgeschlagen

**Lösung:**
- Stellen Sie sicher, dass das Port-Forwarding aktiv ist
- Überprüfen Sie, ob der VNC-Port (5900) nicht durch eine lokale Firewall blockiert wird
- Versuchen Sie, den Container neu zu starten:
  ```bash
  kubectl -n $NAMESPACE delete pod $POD_NAME
  ```

### Problem: Schwarzer Bildschirm oder nur Mauszeiger sichtbar

**Lösung:**
```bash
# Im Container ausführen
kubectl -n $NAMESPACE exec -it $POD_NAME -- bash

# XFCE Desktop neu starten
pkill -f xfce
startxfce4 &
```

### Problem: Langsame Performance

**Lösung:**
- Reduzieren Sie die Bildqualität und Farbtiefe in Ihrem VNC-Client
- Deaktivieren Sie Desktop-Effekte im XFCE:
  ```bash
  # Im Container ausführen
  xfconf-query -c xfwm4 -p /general/use_compositing -s false
  ```
- Verwenden Sie einen Client mit besserer Kompression wie TigerVNC oder TightVNC

### Problem: Tastatureingaben funktionieren nicht korrekt

**Lösung:**
- Stellen Sie sicher, dass die Tastaturlayout-Einstellungen in XFCE und im VNC-Client übereinstimmen
- Bei nicht-deutschen Tastaturlayouts passen Sie die Konfiguration an:
  ```bash
  # Im Container ausführen
  setxkbmap us  # Für US-Tastaturlayout (oder 'de' für Deutsch)
  ```

Bei weiteren Problemen konsultieren Sie bitte die allgemeine Fehlerbehebungsdokumentation oder eröffnen Sie ein Issue im Projekt-Repository.
