# Windows-Unterstützung für ICC Desktop Deployment

## Überblick

Diese Dokumentation erklärt die Nutzung des ICC Ubuntu Desktop Deployment-Toolkits unter Windows. Das Toolkit wurde erweitert, um neben Linux und macOS auch unter Windows nutzbar zu sein.

## Voraussetzungen

Um das Toolkit unter Windows zu nutzen, benötigen Sie:

1. **Windows 10/11** mit PowerShell 5.1 oder höher
2. **kubectl** muss installiert und konfiguriert sein (siehe [Kubernetes Dokumentation](https://kubernetes.io/docs/tasks/tools/))
3. **Optionale Voraussetzungen** für erweiterte Funktionalität:
   - Git Bash oder WSL (Windows Subsystem for Linux) für vollständige Bash-Unterstützung
   - Ein RDP-Client (z.B. der eingebaute Windows Remote Desktop Client)

## Installationsoptionen

Es gibt zwei Hauptmethoden, um das Toolkit unter Windows zu nutzen:

### Option 1: Native Windows-Unterstützung (PowerShell)

Diese Option nutzt die PowerShell-Skripte direkt und benötigt keine Bash-Shell.

1. Verwenden Sie die `.bat` oder `.ps1`-Dateien direkt:
   ```
   .\deploy-webtop.bat
   ```
   oder
   ```
   .\deploy-webtop.ps1
   ```

2. Wählen Sie die gewünschte Funktion aus dem interaktiven Menü

### Option 2: Windows mit Bash-Unterstützung (Git Bash oder WSL)

Diese Option bietet die vollständigste Funktionalität und arbeitet am zuverlässigsten.

1. Installieren Sie Git Bash (als Teil von [Git for Windows](https://git-scm.com/download/win)) oder WSL
2. Öffnen Sie Git Bash/WSL und navigieren Sie zum Projektverzeichnis
3. Führen Sie die Bash-Skripte direkt aus:
   ```bash
   ./deploy-webtop.sh
   ```

## Verfügbare Windows-Skripte

Das Toolkit enthält folgende Windows-spezifische Skripte:

- `deploy-webtop.bat` - Windows-Batch-Datei zum Starten des PowerShell-Wrappers
- `deploy-webtop.ps1` - PowerShell-Hauptskript mit Menü und Deployment-Funktionen
- `icc-desktop-manager.bat` - Windows-Batch-Datei zum Starten des Desktop-Managers
- `scripts/port-forward-webtop.ps1` - PowerShell-Skript für Port-Forwarding

## Funktionsunterstützung unter Windows

| Funktion | PowerShell-Unterstützung | Hinweise |
|----------|--------------------------|----------|
| Vollständiges Deployment | ✅ | Vollständig unterstützt |
| Minimales Deployment | ✅ | Vollständig unterstützt |
| Einfaches Deployment (EmptyDir) | ✅ | Vollständig unterstützt |
| Port-Forwarding | ✅ | Vollständig unterstützt |
| RDP-Unterstützung | ⚠️ | Grundlegende Unterstützung |
| Installation überwachen | ✅ | Vollständig unterstützt |
| Deployment bereinigen | ✅ | Vollständig unterstützt |
| Konfiguration bearbeiten | ✅ | Öffnet mit Notepad |

## Bekannte Einschränkungen

1. Einige erweiterte Funktionen sind nur mit Git Bash oder WSL vollständig nutzbar
2. Die RDP-Unterstützung ist unter PowerShell vereinfacht
3. Windows-Pfadkonventionen können bei komplexeren Skripten Probleme verursachen

## Fehlerbehebung

### Problem: "kubectl wird nicht erkannt"

**Lösung:**
- Stellen Sie sicher, dass kubectl installiert ist
- Fügen Sie den Pfad zu kubectl zu Ihrer PATH-Umgebungsvariablen hinzu
- Starten Sie Ihr Terminal oder PowerShell neu

### Problem: "PowerShell-Skripte können nicht ausgeführt werden"

**Lösung:**
```powershell
# Führen Sie PowerShell als Administrator aus und setzen Sie die Execution Policy:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Problem: "Bash wird nicht erkannt"

**Lösung:**
- Installieren Sie Git Bash oder WSL
- Oder verwenden Sie stattdessen die PowerShell-Skripte

## Unterstützung

Bei Problemen oder Fragen zur Windows-Unterstützung:
1. Konsultieren Sie die allgemeine Fehlerbehebungsdokumentation
2. Öffnen Sie ein Issue im Projekt-Repository

## Mitwirkende

Die Windows-Unterstützung wurde zum Projekt beigetragen, um eine breitere Nutzerbasis zu unterstützen und die Zugänglichkeit des Toolkits zu verbessern.
