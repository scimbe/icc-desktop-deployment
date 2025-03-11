# RDP-Zugriff auf den ICC debian XFCE Desktop

Diese Anleitung beschreibt detailliert, wie Sie mit verschiedenen RDP-Clients auf den debian XFCE Desktop zugreifen können. Der RDP-Zugriff bietet im Vergleich zum Browser-basierten Zugriff oft eine bessere Performance und ermöglicht zusätzliche Funktionen wie gemeinsame Zwischenablage und Audioübertragung.

## Inhaltsverzeichnis

1. [Voraussetzungen](#voraussetzungen)
2. [RDP-Unterstützung einrichten](#rdp-unterstützung-einrichten)
3. [Windows-RDP-Client](#windows-rdp-client)
4. [macOS-RDP-Client](#macos-rdp-client)
5. [Linux-RDP-Client](#linux-rdp-client)
6. [RDP-Sitzungsoptimierung](#rdp-sitzungsoptimierung)
7. [Fehlerbehebung](#fehlerbehebung)

## Voraussetzungen

- Ein erfolgreich installierter ICC debian XFCE Desktop
- Ein RDP-Client für Ihr Betriebssystem
- Port-Forwarding zum Desktop-Pod

## RDP-Unterstützung einrichten

1. **Installation von xrdp im Container:**

   Verwenden Sie das bereitgestellte Skript zur RDP-Installation:

   ```bash
   ./scripts/setup-rdp.sh
   ```

   Dies führt automatisch folgende Schritte aus:
   - Installation des xrdp-Servers im Container
   - Konfiguration für XFCE
   - Einrichtung der Benutzerberechtigungen
   - Port-Forwarding von Port 3389

2. **Manuelle Installation (falls das Skript fehlschlägt):**

   Führen Sie die folgenden Befehle im Container aus:

   ```bash
   # Pod-Namen ermitteln
   POD_NAME=$(kubectl -n $NAMESPACE get pods -l service=webtop -o jsonpath='{.items[0].metadata.name}')
   
   # Shell im Container öffnen
   kubectl -n $NAMESPACE exec -it $POD_NAME -- bash
   
   # xrdp installieren
   apt-get update
   apt-get install -y xrdp
   
   # xrdp für XFCE konfigurieren
   echo "xfce4-session" > /etc/xrdp/xsession
   
   # xrdp-Dienst neustarten
   systemctl restart xrdp
   ```

3. **Port-Forwarding für RDP einrichten:**

   ```bash
   kubectl -n $NAMESPACE port-forward $POD_NAME 3389:3389
   ```

## Windows-RDP-Client

Windows enthält bereits den Remote Desktop Client (mstsc.exe):

1. Drücken Sie `Win + R`, geben Sie `mstsc` ein und drücken Sie Enter
2. Geben Sie als Computername `localhost:3389` ein
3. Klicken Sie auf "Verbinden"
4. Geben Sie die folgenden Anmeldedaten ein:
   - Benutzername: `abc`
   - Passwort: Das in der Konfiguration festgelegte Passwort (Standard: `haw-password`)

### Erweiterte Optionen für Windows-RDP:

1. Öffnen Sie den Remote Desktop Client (mstsc.exe)
2. Geben Sie `localhost:3389` ein und klicken Sie auf "Optionen anzeigen"
3. Konfigurieren Sie folgende Einstellungen für bessere Performance:
   - Reiter "Anzeige": Setzen Sie die Auflösung auf eine niedrigere Stufe für schnellere Verbindungen
   - Reiter "Lokale Ressourcen": Aktivieren Sie Zwischenablage und Drucker nach Bedarf
   - Reiter "Erfahrung": Wählen Sie "LAN (10 Mbit/s oder höher)" und deaktivieren Sie nicht benötigte visuelle Effekte

## macOS-RDP-Client

Für macOS empfehlen wir Microsoft Remote Desktop aus dem App Store:

1. Installieren Sie Microsoft Remote Desktop aus dem Mac App Store
2. Öffnen Sie die App und klicken Sie auf "+" um eine neue Verbindung hinzuzufügen
3. Konfigurieren Sie die Verbindung:
   - PC-Name: `localhost:3389`
   - Benutzerkonto: Klicken Sie auf "Konto hinzufügen" und geben Sie ein:
     - Benutzername: `abc`
     - Passwort: Das in der Konfiguration festgelegte Passwort
   - Klicken Sie auf "Speichern"
4. Doppelklicken Sie auf die erstellte Verbindung, um sie zu starten

### Alternative macOS-Clients:

- **Royal TSX**: Bietet erweiterte Features für professionelle Nutzer
- **CoRD**: Leichtgewichtiger RDP-Client für macOS

## Linux-RDP-Client

Unter Linux stehen mehrere RDP-Clients zur Verfügung:

### Remmina (empfohlen für Ubuntu/Debian):

1. Installation:
   ```bash
   sudo apt-get update
   sudo apt-get install remmina remmina-plugin-rdp
   ```

2. Konfiguration:
   - Starten Sie Remmina
   - Klicken Sie auf das "+" zum Erstellen einer neuen Verbindung
   - Protokoll: RDP
   - Server: localhost:3389
   - Benutzername: abc
   - Passwort: Das in der Konfiguration festgelegte Passwort
   - Klicken Sie auf "Speichern und verbinden"

### FreeRDP über Kommandozeile:

```bash
xfreerdp /v:localhost:3389 /u:abc /p:IhrPasswort /f
```

Parameter-Erklärung:
- `/v:localhost:3389`: Verbindungsadresse und Port
- `/u:abc`: Benutzername
- `/p:IhrPasswort`: Passwort
- `/f`: Vollbildmodus (optional)

## RDP-Sitzungsoptimierung

Um die bestmögliche Performance zu erzielen:

1. **Reduzierte Farbtiefe**: Verwenden Sie 16-bit Farbtiefe statt 32-bit
2. **Kompression aktivieren**: Die meisten RDP-Clients bieten Kompressionsoptionen
3. **Lokale Ressourcenfreigabe minimieren**: Deaktivieren Sie Laufwerksfreigabe und andere nicht benötigte Ressourcen
4. **Netzwerkoptimierer**: Bei schlechter Verbindung nutzen Sie die für langsame Verbindungen optimierten Einstellungen
5. **XFCE-Einstellungen im Container**:
   ```bash
   # Im Container ausführen
   xfconf-query -c xfwm4 -p /general/use_compositing -s false
   ```

## Fehlerbehebung

### Problem: Verbindung kann nicht hergestellt werden

**Lösung:**
- Überprüfen Sie, ob das Port-Forwarding aktiv ist
- Stellen Sie sicher, dass kein lokaler Dienst Port 3389 blockiert
- Prüfen Sie mit `kubectl -n $NAMESPACE logs $POD_NAME` die xrdp-Logs

### Problem: Schwarzer Bildschirm nach Verbindung

**Lösung:**
```bash
# Im Container ausführen
sudo systemctl restart xrdp
echo "xfce4-session" > ~/.xsession
chmod +x ~/.xsession
```

### Problem: Fehlende Berechtigungen

**Lösung:**
```bash
# Im Container ausführen
sudo usermod -aG ssl-cert abc
sudo chown abc:abc ~/.Xauthority
```

### Problem: Langsame Performance

**Lösung:**
- Reduzieren Sie die Auflösung und Farbtiefe im RDP-Client
- Deaktivieren Sie Desktop-Effekte im XFCE:
  ```bash
  # Im Container ausführen
  xfconf-query -c xfwm4 -p /general/use_compositing -s false
  ```

Bei weiteren Problemen konsultieren Sie bitte die allgemeine Fehlerbehebungsdokumentation oder eröffnen Sie ein Issue im Projekt-Repository.
