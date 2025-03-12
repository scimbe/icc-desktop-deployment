#!/bin/bash

# Dieses Skript wird im Container ausgeführt, um das richtige Repository zu klonen
set -e

# Wechsle ins Home-Verzeichnis des Benutzers abc
cd /config

# Clone das Repository mit dem spezifischen Branch
echo "Clone ansible-basic Repository (Branch: icc)..."
if [ -d "ansible-basic" ]; then
    echo "Repository existiert bereits, update wird durchgeführt..."
    cd ansible-basic
    git fetch
    git checkout icc
    git pull
else
    git clone -b icc https://github.com/scimbe/ansible-basic.git
    cd ansible-basic
fi

# Erstelle localhost Inventar-Datei falls nicht vorhanden
if [ ! -f "localhost" ]; then
    echo "Erstelle localhost Inventar-Datei..."
    echo "localhost ansible_connection=local" > localhost
fi

# Setze Berechtigungen
cd ..
chown -R abc:abc ansible-basic

echo "Ansible-Repository wurde ausgecheckt."

# Repository-Auswahl aus Umgebungsvariable
echo -e "Repository-Auswahl aus Umgebungsvariable: $DESKTOP_INSTALLATION"
REPO_CHOICE=${DESKTOP_INSTALLATION}

# Wenn die Wahl leer ist, Standard auf "Nichts" setzen
if [ -z "$REPO_CHOICE" ]; then
    REPO_CHOICE="Nichts"
    echo "Keine Repository-Auswahl angegeben, verwende Standard-Option: $REPO_CHOICE"
fi

echo "Repository-Auswahl: $REPO_CHOICE"

# Behandlung der verschiedenen Optionen
case "$REPO_CHOICE" in
    "Nichts")
        echo "Keine Repositories werden ausgecheckt."
        ;;
        
    "VS_Pattern")
        echo "Clone VS_Pattern Repository..."
        if [ -d "VS_Pattern_By_KI" ]; then
            echo "Repository existiert bereits, update wird durchgeführt..."
            cd VS_Pattern_By_KI
            git fetch
            git pull
            cd ..
        else
            git clone https://github.com/scimbe/VS_Pattern_By_KI.git
        fi
        ;;
        
    "VS_Script")
        echo "Clone VS_Script Repository..."
        if [ -d "vs_script" ]; then
            echo "Repository existiert bereits, update wird durchgeführt..."
            cd vs_script
            git fetch
            git pull
            cd ..
        else
            git clone https://github.com/scimbe/vs_script.git
        fi
        ;;
        
    "Alles")
        echo "Clone VS_Pattern Repository..."
        if [ -d "VS_Pattern_By_KI" ]; then
            echo "Repository existiert bereits, update wird durchgeführt..."
            cd VS_Pattern_By_KI
            git fetch
            git pull
            cd ..
        else
            git clone https://github.com/scimbe/VS_Pattern_By_KI.git
        fi
        
        echo "Clone VS_Script Repository..."
        if [ -d "vs_script" ]; then
            echo "Repository existiert bereits, update wird durchgeführt..."
            cd vs_script
            git fetch
            git pull
            cd ..
        else
            git clone https://github.com/scimbe/vs_script.git
        fi
        ;;

    *)
        echo "Ungültige Repository-Auswahl: $REPO_CHOICE"
        echo "Gültige Optionen sind: Nichts, VS_Pattern, VS_Script, Alles"
        exit 1
        ;;
esac

# Setze Berechtigungen
chown -R abc:abc /config/home/abc

echo "Repository-Auschecken abgeschlossen."