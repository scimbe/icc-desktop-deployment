#!/bin/bash

# ICC Namespace (wird automatisch erstellt, normalerweise ist es Ihre w-Kennung + "-default")
# Beispiel: Wenn Ihr Login infwaa123 ist, dann ist Ihr Namespace waa123-default
export NAMESPACE="wXYZ123-default"  # Ersetzen Sie dies mit Ihrem Namespace

# Deployment-Namen
export WEBTOP_DEPLOYMENT_NAME="ubuntu-xfce"
export WEBTOP_SERVICE_NAME="ubuntu-xfce"

# Ressourcenlimits
export MEMORY_LIMIT="8Gi"  # 8GB RAM für Entwicklungsarbeit
export CPU_LIMIT="4000m"   # 4 CPU-Kerne

# VNC-Passwort (für sicheren Zugriff)
export VNC_PASSWORD="haw-password"  # Bitte ändern Sie dies in ein sicheres Passwort

# Persistenter Speicher einrichten
export ENABLE_PERSISTENCE=true
export STORAGE_SIZE="20Gi"  # 20GB für Entwicklungsprojekte