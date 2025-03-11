#!/bin/bash

# Hauptskript für das Deployment eines Ubuntu XFCE Desktops mit Entwicklungstools
set -e

# Pfad zum Skriptverzeichnis
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Prüfe, ob Konfigurationsdatei existiert
if [ ! -f "$SCRIPT_DIR/configs/webtop-config.sh" ]; then
  echo "Konfigurationsdatei nicht gefunden."
  echo "Erstelle eine auf Basis der Beispielkonfiguration..."
  
  if [ ! -f "$SCRIPT_DIR/configs/webtop-config.example.sh" ]; then
    echo "Fehler: Beispielkonfigurationsdatei nicht gefunden."
    exit 1
  fi
  
  # Erstelle Verzeichnis, falls es nicht existiert
  mkdir -p "$SCRIPT_DIR/configs"
  
  # Kopiere Beispielkonfiguration
  cp "$SCRIPT_DIR/configs/webtop-config.example.sh" "$SCRIPT_DIR/configs/webtop-config.sh"
  
  echo "Konfigurationsdatei erstellt: $SCRIPT_DIR/configs/webtop-config.sh"
  echo "Bitte passen Sie die Konfiguration an Ihre Anforderungen an."
  echo "Vor allem den Namespace müssen Sie anpassen!"
  echo
  
  # Frage nach Bearbeitung
  read -p "Möchten Sie die Konfigurationsdatei jetzt bearbeiten? (j/N) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Jj]$ ]]; then
    # Öffne mit einem verfügbaren Editor
    if command -v nano &> /dev/null; then
      nano "$SCRIPT_DIR/configs/webtop-config.sh"
    elif command -v vim &> /dev/null; then
      vim "$SCRIPT_DIR/configs/webtop-config.sh"
    else
      echo "Bitte bearbeiten Sie die Datei manuell mit einem Text-Editor."
      exit 0
    fi
  else
    echo "Bitte bearbeiten Sie die Datei, bevor Sie fortfahren."
    exit 0
  fi
fi

# Setze Ausführungsberechtigungen für Skripte
chmod +x "$SCRIPT_DIR/scripts/deploy-webtop-icc.sh"
chmod +x "$SCRIPT_DIR/scripts/port-forward-webtop.sh"
chmod +x "$SCRIPT_DIR/scripts/setup-rdp.sh"

# Prüfe ICC-Verbindung
CURRENT_NS=$(kubectl config view --minify -o jsonpath='{..namespace}')

if ! kubectl cluster-info -n $CURRENT_NS  &> /dev/null; then
  echo "Keine Verbindung zur ICC. Bitte stellen Sie sicher, dass Sie angemeldet sind."
  echo "Führen Sie das Login-Skript aus oder stellen Sie die VPN-Verbindung her."
  exit 1
fi

echo "=== Ubuntu XFCE Desktop mit Entwicklungstools Deployment ==="
echo "Dieser Prozess wird:"
echo "1. Ein Ubuntu XFCE Desktop-System auf der ICC bereitstellen"
echo "2. Visual Studio Code, Sublime Text und Ansible installieren"
echo "3. Persistenten Speicher für Ihre Daten konfigurieren"
echo "4. Port-Forwarding für den Browser-Zugriff einrichten"
echo
echo "Unterstützte Remote-Clients: Webbrowser, VNC-Clients, RDP-Clients, NoMachine"
echo "Unterstützte Plattformen: Windows, macOS, Linux"
echo

# Fortsetzungsbestätigung
read -p "Möchten Sie fortfahren? (j/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Jj]$ ]]; then
  echo "Abbruch."
  exit 0
fi

# Führe Deployment-Skript aus
"$SCRIPT_DIR/scripts/deploy-webtop-icc.sh"
