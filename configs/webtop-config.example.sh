#!/bin/bash

# ICC Namespace (wird automatisch erstellt, normalerweise ist es Ihre w-Kennung + "-default")
# Beispiel: Wenn Ihr Login infwaa123 ist, dann ist Ihr Namespace waa123-default
export NAMESPACE="wXYZ123-default"  # Ersetzen Sie dies mit Ihrem Namespace

# Deployment-Namen
export WEBTOP_DEPLOYMENT_NAME="debian-xfce"
export WEBTOP_SERVICE_NAME="debian-xfce"

# Ressourcenlimits
export MEMORY_LIMIT="2Gi"  # 8GB RAM für Entwicklungsarbeit
export CPU_LIMIT="2000m"   # 4 CPU-Kerne

# VNC-Passwort (für sicheren Zugriff)
export VNC_PASSWORD="haw-password"  # Bitte ändern Sie dies in ein sicheres Passwort

# Persistenter Speicher einrichten
export ENABLE_PERSISTENCE=false
export STORAGE_SIZE="10Gi"  # max 10GB für Entwicklungsprojekte

# Nichts         - Keine Repositories auschecken"
# VS_Pattern    - Nur das VS_Pattern Repository auschecken"
# VS_Script     - Nur das VS_Script Repository auschecken"
# Alles         - Beide Repositories auschecken"
export DESKTOP_INSTALLATION="VS_Pattern"
