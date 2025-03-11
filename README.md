# ICC Ubuntu Desktop Deployment

Ein Deployment-Werkzeug zur einfachen Installation und Konfiguration eines debian XFCE Desktop-Systems mit Entwicklungswerkzeugen auf der Informatik Compute Cloud (ICC) der HAW Hamburg.

## Überblick

Dieses Projekt bietet Skripte und Konfigurationsdateien zur Bereitstellung einer vollständigen Entwicklungsumgebung als Container auf der ICC-Kubernetes-Plattform. Die Umgebung basiert auf einem debian XFCE Desktop und enthält vorinstallierte Entwicklungswerkzeuge wie Visual Studio Code, Sublime Text und Ansible.

### Hauptmerkmale

- **Desktop-Zugriff**: Fernzugriff auf einen vollständigen Linux-Desktop über Browser, VNC oder RDP
- **Persistenter Speicher**: Dauerhafte Speicherung von Daten und Konfigurationen auch nach Neustarts
- **Vorinstallierte Entwicklungswerkzeuge**: VS Code, Sublime Text, Ansible und weitere Tools
- **Plattformübergreifend**: Nutzbar von Windows, macOS oder Linux aus
- **Automatisierte Installation**: Einfache Bereitstellung durch Skripte

## Voraussetzungen

- Zugang zur ICC (Informatik Compute Cloud) der HAW Hamburg
- Konfigurierter `kubectl`-Zugriff auf die ICC
- Bash-kompatible Shell (Linux, macOS oder Windows mit Git Bash/WSL)

## Schnellanleitung

1. **Repository klonen**:
   ```bash
   git clone https://github.com/yourusername/icc-desktop-deployment.git
   cd icc-desktop-deployment
   ```

2. **Ausführungsberechtigungen setzen**:
   ```bash
   chmod +x deploy-webtop.sh
   chmod +x scripts/*.sh
   ```

3. **Konfiguration anpassen**:
   ```bash
   cp configs/webtop-config.example.sh configs/webtop-config.sh
   # Bearbeiten Sie die Datei und setzen Sie insbesondere den NAMESPACE
   nano configs/webtop-config.sh
   ```

4. **Deployment starten**:
   ```bash
   ./deploy-webtop.sh
   ```

5. **Auf den Desktop zugreifen**:
   ```bash
   ./scripts/port-forward-webtop.sh
   ```
   Öffnen Sie dann einen Browser und navigieren Sie zu:
   - http://localhost:3000

## Installationsoptionen

### Persistente Installation (empfohlen)
```bash
./deploy-webtop.sh
```
Diese Option verwendet einen PersistentVolumeClaim (PVC), der sicherstellt, dass Ihre Daten nach Neustarts erhalten bleiben.

### Einfache Installation (für Tests)
```bash
./scripts/deploy-webtop-simple.sh
```
Diese Option verwendet temporären Speicher (EmptyDir). Daten gehen bei Pod-Neustarts verloren.

### Minimale Installation (für Stabilitätsprobleme)
```bash
./scripts/deploy-webtop-minimal.sh
```
Diese Option installiert nur die Basis-Desktop-Umgebung ohne Entwicklungswerkzeuge.

## Zugriffsmöglichkeiten

- **Webbrowser**: http://localhost:3000 (HTTP) oder https://localhost:3001 (HTTPS)
- **VNC-Clients**: Verbindung zu localhost:5900 (nach Konfiguration)
- **RDP-Clients**: Verbindung zu localhost:3389 (nach Ausführung von `./scripts/setup-rdp.sh`)

## Problembehebung

Falls Probleme auftreten, konsultieren Sie bitte die Datei `FEHLERBEHEBUNG.md` für ausführliche Anleitungen zur Fehlerbehebung.

## Beitragen

Beiträge zu diesem Projekt sind willkommen! Bitte forken Sie das Repository und erstellen Sie einen Pull Request mit Ihren Änderungen.

## Lizenz

Dieses Projekt steht unter einer modifizierten MIT-Lizenz, die nur für akademische Zwecke frei nutzbar ist. Siehe die [LICENSE](LICENSE) Datei für Details.

**Hinweis**: Dieses Projekt ist für die Verwendung an der HAW Hamburg konzipiert und darf nur für Bildungs- und Forschungszwecke frei verwendet werden. Kommerzielle Nutzung bedarf der expliziten Genehmigung.
