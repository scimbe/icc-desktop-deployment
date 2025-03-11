#!/bin/bash

# Skript zum Validieren der ICC Desktop Deployment-Konfiguration
set -e

# Pfad zum Skriptverzeichnis
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Farbdefinitionen
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Funktion zum Anzeigen von Fehlern
error() {
    echo -e "${RED}FEHLER:${NC} $1"
}

# Funktion zum Anzeigen von Warnungen
warning() {
    echo -e "${YELLOW}WARNUNG:${NC} $1"
}

# Funktion zum Anzeigen von Erfolgen
success() {
    echo -e "${GREEN}ERFOLG:${NC} $1"
}

# Prüfe, ob ein Konfigurationspfad als Parameter übergeben wurde
CONFIG_PATH=${1:-"$ROOT_DIR/configs/webtop-config.sh"}

# Prüfe, ob die Konfigurationsdatei existiert
if [ ! -f "$CONFIG_PATH" ]; then
    error "Konfigurationsdatei nicht gefunden: $CONFIG_PATH"
    exit 1
fi

# Lade die Konfiguration
source "$CONFIG_PATH"

# Validierung: Namespace
validate_namespace() {
    echo "Prüfe Namespace..."
    if [ -z "$NAMESPACE" ]; then
        error "NAMESPACE ist nicht definiert"
        return 1
    fi

    if [[ ! "$NAMESPACE" =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]]; then
        error "NAMESPACE muss ausschließlich Kleinbuchstaben, Zahlen und Bindestriche enthalten"
        error "Er muss mit einem Buchstaben oder einer Zahl beginnen und enden"
        return 1
    fi

    success "Namespace ist gültig: $NAMESPACE"
    return 0
}

# Validierung: Deployment-Namen
validate_deployment_names() {
    echo "Prüfe Deployment-Namen..."
    if [ -z "$WEBTOP_DEPLOYMENT_NAME" ]; then
        error "WEBTOP_DEPLOYMENT_NAME ist nicht definiert"
        return 1
    fi

    if [ -z "$WEBTOP_SERVICE_NAME" ]; then
        error "WEBTOP_SERVICE_NAME ist nicht definiert"
        return 1
    fi

    success "Deployment-Namen sind gültig"
    return 0
}

# Validierung: Ressourcenlimits
validate_resource_limits() {
    echo "Prüfe Ressourcenlimits..."
    if [ -z "$MEMORY_LIMIT" ]; then
        error "MEMORY_LIMIT ist nicht definiert"
        return 1
    fi

    if [ -z "$CPU_LIMIT" ]; then
        error "CPU_LIMIT ist nicht definiert"
        return 1
    fi

    # Prüfe, ob Memory-Limit im gültigen Format ist
    if [[ ! "$MEMORY_LIMIT" =~ ^[0-9]+[MmGg]i$ ]]; then
        error "MEMORY_LIMIT muss im Format <Zahl>Mi oder <Zahl>Gi sein"
        return 1
    fi

    # Prüfe, ob CPU-Limit im gültigen Format ist
    if [[ ! "$CPU_LIMIT" =~ ^[0-9]+m$ ]]; then
        error "CPU_LIMIT muss im Format <Zahl>m sein"
        return 1
    fi

    # Extrahiere numerischen Wert aus Memory-Limit
    local mem_value
    local mem_unit
    if [[ "$MEMORY_LIMIT" =~ ^([0-9]+)([MmGg]i)$ ]]; then
        mem_value=${BASH_REMATCH[1]}
        mem_unit=${BASH_REMATCH[2]}
        
        # Konvertiere in MB für Vergleich
        if [[ "$mem_unit" == "Gi" || "$mem_unit" == "gi" ]]; then
            mem_value=$((mem_value * 1024))
        fi
        
        # Prüfe, ob Memory-Limit innerhalb vernünftiger Grenzen ist
        if [ "$mem_value" -gt 16384 ]; then
            warning "MEMORY_LIMIT ist sehr hoch (>${mem_value}MB). Stellen Sie sicher, dass dies beabsichtigt ist."
        fi
        
        if [ "$mem_value" -lt 1024 ]; then
            warning "MEMORY_LIMIT ist sehr niedrig (${mem_value}MB). Mindestens 2Gi wird empfohlen."
        fi
    fi

    # Extrahiere numerischen Wert aus CPU-Limit
    local cpu_value
    if [[ "$CPU_LIMIT" =~ ^([0-9]+)m$ ]]; then
        cpu_value=${BASH_REMATCH[1]}
        
        # Prüfe, ob CPU-Limit innerhalb vernünftiger Grenzen ist
        if [ "$cpu_value" -gt 8000 ]; then
            warning "CPU_LIMIT ist sehr hoch (${cpu_value}m). Stellen Sie sicher, dass dies beabsichtigt ist."
        fi
        
        if [ "$cpu_value" -lt 500 ]; then
            warning "CPU_LIMIT ist sehr niedrig (${cpu_value}m). Mindestens 1000m wird empfohlen."
        fi
    fi

    success "Ressourcenlimits sind gültig"
    return 0
}

# Validierung: Persistenz-Einstellungen
validate_persistence() {
    echo "Prüfe Persistenz-Einstellungen..."
    if [ "$ENABLE_PERSISTENCE" = "true" ]; then
        if [ -z "$STORAGE_SIZE" ]; then
            error "STORAGE_SIZE ist nicht definiert, obwohl ENABLE_PERSISTENCE=true"
            return 1
        fi
        
        # Prüfe, ob Storage-Size im gültigen Format ist
        if [[ ! "$STORAGE_SIZE" =~ ^[0-9]+[MmGg]i$ ]]; then
            error "STORAGE_SIZE muss im Format <Zahl>Mi oder <Zahl>Gi sein"
            return 1
        fi
        
        # Extrahiere numerischen Wert aus Storage-Size
        local storage_value
        local storage_unit
        if [[ "$STORAGE_SIZE" =~ ^([0-9]+)([MmGg]i)$ ]]; then
            storage_value=${BASH_REMATCH[1]}
            storage_unit=${BASH_REMATCH[2]}
            
            # Konvertiere in MB für Vergleich
            if [[ "$storage_unit" == "Gi" || "$storage_unit" == "gi" ]]; then
                storage_value=$((storage_value * 1024))
            fi
            
            # Prüfe, ob Storage-Size innerhalb vernünftiger Grenzen ist
            if [ "$storage_value" -gt 20480 ]; then
                warning "STORAGE_SIZE ist sehr hoch (>${storage_value}MB). Stellen Sie sicher, dass dies beabsichtigt ist."
            fi
            
            if [ "$storage_value" -lt 1024 ]; then
                warning "STORAGE_SIZE ist sehr niedrig (${storage_value}MB). Mindestens 5Gi wird empfohlen."
            fi
        fi
    else
        warning "Persistenz ist deaktiviert (ENABLE_PERSISTENCE=${ENABLE_PERSISTENCE}). Daten gehen bei Pod-Neustarts verloren."
    fi

    success "Persistenz-Einstellungen sind gültig"
    return 0
}

# Validierung: VNC-Passwort
validate_password() {
    echo "Prüfe VNC-Passwort..."
    if [ -z "$VNC_PASSWORD" ]; then
        error "VNC_PASSWORD ist nicht definiert"
        return 1
    fi
    
    if [ ${#VNC_PASSWORD} -lt 8 ]; then
        warning "VNC_PASSWORD ist sehr kurz (${#VNC_PASSWORD} Zeichen). Ein längeres Passwort wird empfohlen."
    fi
    
    if [ "$VNC_PASSWORD" = "haw-password" ]; then
        warning "VNC_PASSWORD ist das Standardpasswort. Aus Sicherheitsgründen sollten Sie es ändern."
    fi

    success "VNC-Passwort ist gesetzt"
    return 0
}

# Hauptvalidierungsfunktion
validate_config() {
    echo "=== Validiere Konfiguration: $CONFIG_PATH ==="
    
    local exit_code=0
    
    validate_namespace || exit_code=1
    echo
    validate_deployment_names || exit_code=1
    echo
    validate_resource_limits || exit_code=1
    echo
    validate_persistence || exit_code=1
    echo
    validate_password || exit_code=1
    
    echo
    if [ $exit_code -eq 0 ]; then
        success "Alle Validierungen bestanden!"
        echo "Die Konfigurationsdatei ist gültig und kann für das Deployment verwendet werden."
    else
        error "Validierung fehlgeschlagen. Bitte korrigieren Sie die Fehler."
    fi
    
    return $exit_code
}

# Führe die Validierung aus
validate_config
exit $?
