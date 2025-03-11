#!/bin/bash

# Hauptskript zur Vereinfachung des Deployments des debian XFCE Desktops auf der ICC
# Fasst die wichtigsten Funktionen in einem einzigen Skript zusammen

# Farbdefinitionen für bessere Lesbarkeit
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

# Pfad zum Skriptverzeichnis
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Banner anzeigen
echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}  ICC debian XFCE Desktop - Management Toolkit  ${NC}"
echo -e "${BLUE}=================================================${NC}"
echo

# Menüfunktion definieren
show_menu() {
    echo -e "${GREEN}Verfügbare Aktionen:${NC}"
    echo -e "${YELLOW}1)${NC} Vollständigen Desktop mit Entwicklungstools deployen (PVC)"
    echo -e "${YELLOW}2)${NC} Minimalen Desktop deployen (nur Basis-Desktop)"
    echo -e "${YELLOW}3)${NC} Desktop mit temporärem Speicher deployen (EmptyDir)"
    echo -e "${YELLOW}4)${NC} Port-Forwarding starten (für Browserzugriff)"
    echo -e "${YELLOW}5)${NC} RDP-Unterstützung einrichten"
    echo -e "${YELLOW}6)${NC} Installation überwachen (Monitor)"
    echo -e "${YELLOW}7)${NC} Deployment bereinigen (Alles löschen)"
    echo -e "${YELLOW}8)${NC} Konfiguration bearbeiten"
    echo -e "${YELLOW}9)${NC} Informationen zum Projekt"
    echo -e "${YELLOW}0)${NC} Beenden"
}

# Konfigurationsdatei überprüfen
check_config() {
    if [ ! -f "$SCRIPT_DIR/configs/webtop-config.sh" ]; then
        echo -e "${YELLOW}Konfigurationsdatei nicht gefunden.${NC}"
        echo -e "${YELLOW}Erstelle eine auf Basis der Beispielkonfiguration...${NC}"
        
        if [ ! -f "$SCRIPT_DIR/configs/webtop-config.example.sh" ]; then
            echo -e "${RED}Fehler: Beispielkonfigurationsdatei nicht gefunden.${NC}"
            exit 1
        fi
        
        # Erstelle Verzeichnis, falls es nicht existiert
        mkdir -p "$SCRIPT_DIR/configs"
        
        # Kopiere Beispielkonfiguration
        cp "$SCRIPT_DIR/configs/webtop-config.example.sh" "$SCRIPT_DIR/configs/webtop-config.sh"
        
        echo -e "${GREEN}Konfigurationsdatei erstellt: $SCRIPT_DIR/configs/webtop-config.sh${NC}"
        echo "Bitte passen Sie die Konfiguration an Ihre Anforderungen an."
        echo "Vor allem den Namespace müssen Sie anpassen!"
        
        # Konfiguration bearbeiten
        edit_config
    else
        # Lade Konfiguration
        source "$SCRIPT_DIR/configs/webtop-config.sh"
        echo -e "${GREEN}Verwende Konfiguration:${NC}"
        echo "  Namespace: $NAMESPACE"
        echo "  Ressourcen: $MEMORY_LIMIT RAM, $CPU_LIMIT CPU"
        echo "  Persistenter Speicher: $STORAGE_SIZE"
        echo
    fi
}

# Konfigurationsdatei bearbeiten
edit_config() {
    echo -e "${BLUE}Konfigurationsdatei bearbeiten...${NC}"
    
    # Öffne mit einem verfügbaren Editor
    if command -v nano &> /dev/null; then
        nano "$SCRIPT_DIR/configs/webtop-config.sh"
    elif command -v vim &> /dev/null; then
        vim "$SCRIPT_DIR/configs/webtop-config.sh"
    else
        echo -e "${RED}Kein Editor (nano/vim) gefunden.${NC}"
        echo "Bitte bearbeiten Sie die Datei manuell mit einem Text-Editor:"
        echo "$SCRIPT_DIR/configs/webtop-config.sh"
    fi
    
    # Lade die aktualisierte Konfiguration
    source "$SCRIPT_DIR/configs/webtop-config.sh"
    echo -e "${GREEN}Konfiguration aktualisiert.${NC}"
}

# Prüfe ICC-Verbindung
check_connection() {
    echo -e "${BLUE}Prüfe Verbindung zur ICC...${NC}"
    
    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${RED}Keine Verbindung zur ICC. Bitte stellen Sie sicher, dass Sie angemeldet sind.${NC}"
        echo "Führen Sie das Login-Skript aus oder stellen Sie die VPN-Verbindung her."
        return 1
    fi
    
    # Prüfe, ob Namespace existiert
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        echo -e "${RED}Fehler: Namespace $NAMESPACE existiert nicht.${NC}"
        echo "Bitte überprüfen Sie Ihre Konfiguration oder erstellen Sie den Namespace."
        return 1
    fi
    
    echo -e "${GREEN}Verbindung zur ICC hergestellt. Namespace $NAMESPACE existiert.${NC}"
    return 0
}

# Setze Ausführungsberechtigungen für Skripte
set_permissions() {
    echo -e "${BLUE}Setze Ausführungsberechtigungen für Skripte...${NC}"
    chmod +x "$SCRIPT_DIR/scripts/"*.sh
    chmod +x "$SCRIPT_DIR/deploy-webtop.sh"
    echo -e "${GREEN}Ausführungsberechtigungen gesetzt.${NC}"
}

# Zeige Projektinformationen
show_info() {
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${BLUE}  ICC debian XFCE Desktop - Projektinformation  ${NC}"
    echo -e "${BLUE}=================================================${NC}"
    echo
    echo "Dieses Toolkit ermöglicht die einfache Bereitstellung eines"
    echo "debian XFCE Desktops mit Entwicklungswerkzeugen auf der"
    echo "Informatik Compute Cloud (ICC) der HAW Hamburg."
    echo
    echo "Das System bietet einen vollständigen Linux-Desktop mit:"
    echo "- Visual Studio Code"
    echo "- Sublime Text"
    echo "- Ansible"
    echo "- und weiteren Entwicklungstools"
    echo
    echo "Der Zugriff ist möglich über:"
    echo "- Webbrowser (HTTP/HTTPS)"
    echo "- VNC-Clients"
    echo "- RDP-Clients (nach Einrichtung)"
    echo
    echo "Weitere Informationen finden Sie in der README.md und"
    echo "in der FEHLERBEHEBUNG.md im Projektverzeichnis."
    echo
    echo -e "${YELLOW}Drücken Sie eine Taste, um fortzufahren...${NC}"
    read -n 1
}

# Hauptfunktion
main() {
    set_permissions
    check_config
    
    while true; do
        clear
        echo -e "${BLUE}=================================================${NC}"
        echo -e "${BLUE}  ICC debian XFCE Desktop - Management Toolkit  ${NC}"
        echo -e "${BLUE}=================================================${NC}"
        echo
        show_menu
        echo
        read -p "Wählen Sie eine Option (0-9): " choice
        echo
        
        case $choice in
            1) # Vollständigen Desktop deployen
                if check_connection; then
                    echo -e "${BLUE}Starte Deployment des vollständigen Desktops...${NC}"
                    "$SCRIPT_DIR/deploy-webtop.sh"
                fi
                ;;
            2) # Minimalen Desktop deployen
                if check_connection; then
                    echo -e "${BLUE}Starte Deployment des minimalen Desktops...${NC}"
                    "$SCRIPT_DIR/scripts/deploy-webtop-minimal.sh"
                fi
                ;;
            3) # Desktop mit temporärem Speicher
                if check_connection; then
                    echo -e "${BLUE}Starte Deployment mit temporärem Speicher...${NC}"
                    "$SCRIPT_DIR/scripts/deploy-webtop-simple.sh"
                fi
                ;;
            4) # Port-Forwarding starten
                if check_connection; then
                    echo -e "${BLUE}Starte Port-Forwarding...${NC}"
                    "$SCRIPT_DIR/scripts/port-forward-webtop.sh"
                fi
                ;;
            5) # RDP-Unterstützung einrichten
                if check_connection; then
                    echo -e "${BLUE}Richte RDP-Unterstützung ein...${NC}"
                    "$SCRIPT_DIR/scripts/setup-rdp.sh"
                fi
                ;;
            6) # Installation überwachen
                if check_connection; then
                    echo -e "${BLUE}Starte Überwachung der Installation...${NC}"
                    "$SCRIPT_DIR/scripts/monitor-installation.sh"
                fi
                ;;
            7) # Deployment bereinigen
                if check_connection; then
                    echo -e "${BLUE}Bereinige das Deployment...${NC}"
                    "$SCRIPT_DIR/scripts/cleanup-webtop.sh"
                fi
                ;;
            8) # Konfiguration bearbeiten
                edit_config
                ;;
            9) # Informationen zum Projekt
                show_info
                ;;
            0) # Beenden
                echo -e "${GREEN}Auf Wiedersehen!${NC}"
                exit 0
                ;;
            *) # Ungültige Eingabe
                echo -e "${RED}Ungültige Option. Bitte wählen Sie eine Zahl zwischen 0 und 9.${NC}"
                echo -e "${YELLOW}Drücken Sie eine Taste, um fortzufahren...${NC}"
                read -n 1
                ;;
        esac
    done
}

# Starte die Hauptfunktion
main
