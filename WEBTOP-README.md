# Ubuntu XFCE Development Desktop auf der ICC

Diese Dokumentation beschreibt, wie Sie einen Ubuntu XFCE Development Desktop in der Informatik Compute Cloud (ICC) der HAW Hamburg einrichten und verwenden können. Diese Umgebung enthält bereits vorinstallierte Entwicklungswerkzeuge wie Visual Studio Code, Sublime Text und Ansible.

## Inhaltsverzeichnis

1. [Überblick](#überblick)
2. [Voraussetzungen](#voraussetzungen)
3. [Schnellstart](#schnellstart)
4. [Zugriffsmöglichkeiten](#zugriffsmöglichkeiten)
5. [Vorinstallierte Entwicklungstools](#vorinstallierte-entwicklungstools)
6. [Anpassungen und Erweiterungen](#anpassungen-und-erweiterungen)
7. [Dateiaustausch](#dateiaustausch)
8. [Plattformübergreifender Zugriff](#plattformübergreifender-zugriff)
9. [Tipps und Tricks](#tipps-und-tricks)
10. [Fehlerbehebung](#fehlerbehebung)

## Überblick

Der ICC Development Desktop bietet:

- Ubuntu Linux mit XFCE Desktop-Umgebung
- Vorinstallierte Entwicklungstools (VS Code, Sublime Text, Ansible)
- Persistenten Speicher für Ihre Projekte und Konfigurationen
- Zugriff über verschiedene Clients (Browser, VNC, RDP) von Windows, macOS oder Linux
- GPU-Beschleunigung (falls verfügbar)

Diese Umgebung ist ideal für:
- Praktika und Übungen
- Softwareentwicklung
- Systemadministration und DevOps
- Kollaborative Projekte mit einheitlicher Umgebung

## Voraussetzungen

- HAW Hamburg infw-Account mit Zugang zur ICC
- kubectl installiert (für die Einrichtung)
- Internetbrowser oder VNC/RDP-Client (für den Zugriff)
- VPN-Verbindung zum HAW-Netz (wenn außerhalb des HAW-Netzes)

## Schnellstart

```bash
# Repository klonen
git clone <repository-url>
cd icc-ollama-deployment

# Ausführungsberechtigungen setzen
chmod +x deploy-webtop.sh
chmod +x scripts/*.sh

# ICC-Zugang einrichten (falls noch nicht geschehen)
./scripts/icc-login.sh

# Development Desktop deployen
./deploy-webtop.sh
```

Nach der Einrichtung können Sie über Ihren Browser auf den Desktop zugreifen:
- http://localhost:3000 (HTTP)
- https://localhost:3001 (HTTPS, selbstsigniertes Zertifikat)

## Zugriffsmöglichkeiten

Der Development Desktop unterstützt verschiedene Zugriffsmethoden:

### 1. Webbrowser (plattformunabhängig)

Die einfachste Methode ist der Zugriff über jeden modernen Webbrowser:

```bash
# Port-Forwarding starten
./scripts/port-forward-webtop.sh

# Browser öffnen
# http://localhost:3000 oder https://localhost:3001
```

### 2. VNC Clients

Für verbesserte Performance:

- **Windows**: VNC Viewer, TightVNC, UltraVNC
- **macOS**: VNC Viewer, Royal TSX, Screen Sharing (integriert)
- **Linux**: Remmina, Vinagre, TigerVNC

### 3. RDP Clients

Für optimale Windows-Kompatibilität:

```bash
# RDP-Unterstützung installieren und konfigurieren
./scripts/setup-rdp.sh
```

Dann verbinden mit:
- **Windows**: Microsoft Remote Desktop (integriert)
- **macOS**: Microsoft Remote Desktop (App Store)
- **Linux**: Remmina, FreeRDP

### 4. NoMachine (optional, für beste Performance)

NoMachine muss manuell installiert werden:

```bash
# Innerhalb des Development Desktop (über Browser-Zugriff)
sudo apt install nomachine
```

## Vorinstallierte Entwicklungstools

Der Development Desktop enthält folgende vorinstallierte Tools:

### Visual Studio Code

- Vollständige IDE mit Erweiterungssystem
- Integrierter Terminal und Debugger
- Unterstützung für Git und viele Programmiersprachen
- Live Share für Kollaboration

### Sublime Text

- Schneller, leichtgewichtiger Code-Editor
- Leistungsstarke Suche und Ersetzung
- Multi-Cursor-Bearbeitung
- Anpassbar durch Pakete

### Ansible

- Automatisierungstool für IT-Infrastruktur
- Deklarative YAML-Syntax
- Agentless (benötigt nur SSH)
- Idempotente Operationen

### Weitere Tools

- Git für Versionskontrolle
- Build-Essential (GCC, G++, Make)
- Python 3 mit Pip
- Verschiedene Dienstprogramme (curl, wget, etc.)

## Anpassungen und Erweiterungen

Sie können den Development Desktop nach Ihren Bedürfnissen anpassen:

### Weitere Software installieren

Öffnen Sie ein Terminal im Desktop und verwenden Sie apt:

```bash
sudo apt update
sudo apt install <paketname>

# Beispiele:
sudo apt install docker.io         # Docker
sudo apt install nodejs npm        # Node.js und NPM
sudo apt install openjdk-17-jdk    # Java Development Kit
sudo apt install mysql-server      # MySQL Datenbank
```

### VS Code Erweiterungen

Öffnen Sie VS Code und installieren Sie Erweiterungen über den Extensions Marketplace.

Empfohlene Erweiterungen:
- Python Extension Pack
- Remote Development Extension Pack
- Docker
- GitLens
- Live Share

### Persistenz der Anpassungen

Alle Änderungen werden im persistenten Speicher gespeichert und bleiben auch nach Neustarts erhalten.

## Dateiaustausch

Es gibt mehrere Möglichkeiten, Dateien zwischen Ihrem lokalen System und dem Development Desktop auszutauschen:

### 1. Browser-basierter Dateiaustausch

Die Web-Oberfläche des Development Desktops bietet einen integrierten Dateimanager mit Upload- und Download-Funktionen:

- Klicken Sie auf das Datei-Symbol in der oberen Menüleiste
- Nutzen Sie Drag & Drop zum Hochladen
- Rechtsklick auf Dateien zum Herunterladen

### 2. Zwischenablage

Text und Bilder können über die gemeinsame Zwischenablage ausgetauscht werden:
- Kopieren Sie Inhalte auf Ihrem lokalen System (Strg+C / Cmd+C)
- Fügen Sie sie im Development Desktop ein (Strg+V / Cmd+V)

### 3. Git und GitHub

Für Code-Projekte ist Git die empfohlene Methode:
```bash
# Im Development Desktop
git clone https://github.com/ihr-username/ihr-repository.git
git add .
git commit -m "Änderungen"
git push
```

### 4. SFTP/SCP (fortgeschritten)

Für direkten Dateizugriff können Sie SFTP einrichten:
```bash
# Im Development Desktop - SSH-Server installieren
sudo apt update
sudo apt install openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh

# Passwort für den Benutzer 'abc' setzen
sudo passwd abc
```

Anschließend können Sie mit SFTP-Clients wie FileZilla oder WinSCP verbinden.

## Plattformübergreifender Zugriff

Der Development Desktop ist speziell für den plattformübergreifenden Zugriff von Windows, macOS und Linux optimiert:

### Windows-Zugriff

- **Browser**: Chrome, Firefox oder Edge mit localhost:3000
- **RDP**: Integrierter Microsoft Remote Desktop Client
  ```
  Computername: localhost:3389
  Benutzername: abc
  ```
- **VNC**: VNC Viewer oder ähnliche Clients

### macOS-Zugriff

- **Browser**: Safari, Chrome oder Firefox mit localhost:3000
- **RDP**: Microsoft Remote Desktop aus dem App Store
  ```
  PC-Name: localhost:3389
  Benutzername: abc
  ```
- **VNC**: Integriertes Screen Sharing oder VNC Viewer

### Linux-Zugriff

- **Browser**: Firefox, Chrome oder andere Browser mit localhost:3000
- **RDP**: Remmina oder FreeRDP
  ```
  xfreerdp /v:localhost:3389 /u:abc
  ```
- **VNC**: Remmina, Vinagre, TigerVNC

## Tipps und Tricks

### Performance-Optimierung

1. **Browser-Einstellungen**:
   - Aktivieren Sie die Hardware-Beschleunigung in Ihrem Browser
   - Nutzen Sie Chrome oder Firefox für beste WebRTC-Performance

2. **Remote-Zugriffs-Qualität**:
   - Passen Sie in den Einstellungen des Web-Interfaces die Bitrate und Auflösung an
   - Reduzieren Sie die Auflösung bei langsamen Verbindungen

3. **Terminal statt GUI**:
   - Nutzen Sie für ressourcenintensive Operationen das Terminal
   - Verwenden Sie CLI-Tools wie vim, nano, tmux für bessere Performance

### Nützliche Tastaturkürzel

- **Strg+Alt+T**: Terminal öffnen
- **Alt+Tab**: Zwischen Anwendungen wechseln
- **Strg+Umschalt+Esc**: Taskmanager (System Monitor) öffnen
- **Strg+D**: Desktop anzeigen

### Multi-Monitor-Setup

Um mehrere Monitore zu simulieren:
1. Öffnen Sie die XFCE-Einstellungen → Anzeige
2. Klicken Sie auf "Virtuellen Ausgang hinzufügen"
3. Konfigurieren Sie die Position des virtuellen Monitors

### Docker im Development Desktop

Installation und Einrichtung von Docker:
```bash
sudo apt update
sudo apt install docker.io
sudo usermod -aG docker abc
# Neuanmeldung erforderlich nach Gruppenzuweisung

# Testen der Installation
docker run hello-world
```

## Fehlerbehebung

### Problem: Desktop startet nicht oder zeigt schwarzen Bildschirm

**Lösung**:
1. Überprüfen Sie den Pod-Status:
   ```bash
   kubectl -n $NAMESPACE get pods
   ```
2. Prüfen Sie die Logs:
   ```bash
   kubectl -n $NAMESPACE logs $POD_NAME
   ```
3. Versuchen Sie einen Neustart des Pods:
   ```bash
   kubectl -n $NAMESPACE delete pod $POD_NAME
   ```

### Problem: Tools wie VS Code starten nicht

**Lösung**:
1. Installation über Terminal überprüfen:
   ```bash
   which code
   dpkg -l | grep code
   ```
2. Manuell neu installieren:
   ```bash
   sudo apt update
   sudo apt install --reinstall code
   ```

### Problem: Langsame Verbindung oder Lags

**Lösung**:
1. Reduzieren Sie die Auflösung in den Einstellungen
2. Stellen Sie sicher, dass Sie eine stabile Internetverbindung haben
3. Versuchen Sie, einen nativen Client (VNC/RDP) statt des Browsers zu verwenden
4. Erhöhen Sie die Ressourcenlimits in der webtop-config.sh

### Problem: Persistenter Speicher ist voll

**Lösung**:
1. Speicherbelegung prüfen:
   ```bash
   df -h /config
   ```
2. Nicht benötigte Dateien entfernen:
   ```bash
   du -sh /config/* | sort -hr
   ```
3. In schweren Fällen: Vergrößern des PVC (erfordert Administrator-Eingriff)