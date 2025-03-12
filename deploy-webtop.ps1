function Monitor-Installation {
    if (Test-Bash) {
        # Wenn Bash verfügbar ist, führe das originale Skript aus
        $MonitorScript = Join-Path -Path $RootDir -ChildPath "scripts\monitor-installation.sh"
        bash -c "cd '$RootDir' && bash '$MonitorScript'"
    }
    else {
        # Wenn Bash nicht verfügbar ist, übersetze die wichtigsten Befehle in PowerShell
        if (!(Test-Kubectl)) { return }
        if (!(Get-WTConfig)) { return }
        
        # Lese Konfiguration
        $ConfigPath = Join-Path -Path $RootDir -ChildPath "configs\webtop-config.sh"
        $config = Get-Content $ConfigPath
        $Namespace = ($config | Where-Object { $_ -match "export NAMESPACE=" }) -replace 'export NAMESPACE="(.*)".*', '$1'
        
        # Pod-Namen holen
        $PodName = kubectl -n $Namespace get pods -l service=webtop -o jsonpath='{.items[0].metadata.name}' 2>$null
        if (!$PodName) {
            Write-Host "Fehler: Kein laufender Pod für das Webtop Deployment gefunden." -ForegroundColor $Red
            Write-Host "Überprüfen Sie den Status des Deployments mit:"
            Write-Host "kubectl -n $Namespace get pods"
            return
        }
        
        Write-Host "=== Überwache Installationsprozess für debian XFCE Desktop ===" -ForegroundColor $Green
        Write-Host "Pod: $PodName"
        Write-Host "Namespace: $Namespace"
        Write-Host
        Write-Host "Drücken Sie Ctrl+C, um die Überwachung zu beenden."
        Write-Host "-----------------------------------------------------------"
        
        try {
            while ($true) {
                Clear-Host
                Write-Host "=== debian XFCE Desktop Installationsmonitor ===" -ForegroundColor $Green
                Write-Host "Zeitstempel: $(Get-Date)"
                Write-Host "Pod: $PodName"
                Write-Host "Namespace: $Namespace"
                Write-Host "-----------------------------------------------------------"
                
                # Zeige Pod-Informationen
                Write-Host "`nPod Status:" -ForegroundColor $Yellow
                kubectl -n $Namespace get pod $PodName -o wide
                
                # Zeige Ereignisse
                Write-Host "`nNeueste Ereignisse:" -ForegroundColor $Yellow
                kubectl -n $Namespace get events --sort-by=.metadata.creationTimestamp | Select-String $PodName | Select-Object -Last 5
                
                # Zeige Logs
                Write-Host "`nContainer Logs (letzte 30 Zeilen):" -ForegroundColor $Yellow
                kubectl -n $Namespace logs $PodName --tail=30
                
                Write-Host "`nDrücken Sie Ctrl+C zum Beenden der Überwachung." -ForegroundColor $Yellow
                Write-Host "Nächste Aktualisierung in 10 Sekunden..."
                
                # Warte 10 Sekunden
                Start-Sleep -Seconds 10
            }
        }
        catch {
            Write-Host "Überwachung beendet."
        }
    }
}

function Cleanup-Deployment {
    if (Test-Bash) {
        # Wenn Bash verfügbar ist, führe das originale Skript aus
        $CleanupScript = Join-Path -Path $RootDir -ChildPath "scripts\cleanup-webtop.sh"
        bash -c "cd '$RootDir' && bash '$CleanupScript'"
    }
    else {
        # Wenn Bash nicht verfügbar ist, übersetze die wichtigsten Befehle in PowerShell
        if (!(Test-Kubectl)) { return }
        if (!(Get-WTConfig)) { return }
        
        # Lese Konfiguration
        $ConfigPath = Join-Path -Path $RootDir -ChildPath "configs\webtop-config.sh"
        $config = Get-Content $ConfigPath
        $Namespace = ($config | Where-Object { $_ -match "export NAMESPACE=" }) -replace 'export NAMESPACE="(.*)".*', '$1'
        
        Write-Host "=== Löschen aller debian XFCE Desktop Ressourcen ===" -ForegroundColor $Yellow
        Write-Host "Namespace: $Namespace"
        Write-Host "Diese Aktion wird alle Ressourcen des debian XFCE Desktops löschen,"
        Write-Host "einschließlich des persistenten Speichers und aller darin enthaltenen Daten!"
        Write-Host
        
        # Bestätigung einholen
        $Confirm = Read-Host "Sind Sie sicher, dass Sie alle Ressourcen löschen möchten? (j/N)"
        if ($Confirm -ne "j" -and $Confirm -ne "J") {
            Write-Host "Abbruch"
            return
        }
        
        # Doppelte Bestätigung für Datenverlust
        $ConfirmData = Read-Host "Warnung: Alle gespeicherten Daten werden unwiderruflich gelöscht! Fortfahren? (j/N)"
        if ($ConfirmData -ne "j" -and $ConfirmData -ne "J") {
            Write-Host "Abbruch"
            return
        }
        
        Write-Host "`nLösche Service..." -ForegroundColor $Yellow
        kubectl delete service debian-xfce --namespace=$Namespace --ignore-not-found
        Write-Host "Service gelöscht oder nicht gefunden." -ForegroundColor $Green
        
        Write-Host "`nLösche Deployment..." -ForegroundColor $Yellow
        kubectl delete deployment debian-xfce --namespace=$Namespace --ignore-not-found
        Write-Host "Deployment gelöscht oder nicht gefunden." -ForegroundColor $Green
        
        # Warte kurz, damit Pods beendet werden können
        Write-Host "`nWarte auf Beendigung der Pods..." -ForegroundColor $Yellow
        Start-Sleep -Seconds 5
        
        # Überprüfe, ob noch Pods mit dem Label "app=webtop" laufen
        $Pods = kubectl get pods --namespace=$Namespace -l app=webtop -o name 2>$null
        if ($Pods) {
            Write-Host "Es laufen noch einige Pods. Lösche diese..." -ForegroundColor $Yellow
            kubectl delete pods --namespace=$Namespace -l app=webtop --force --grace-period=0
            Write-Host "Pods gelöscht." -ForegroundColor $Green
            
            # Warte nochmal kurz
            Start-Sleep -Seconds 2
        }
        
        Write-Host "`nLösche PersistentVolumeClaim..." -ForegroundColor $Yellow
        kubectl delete pvc webtop-pvc --namespace=$Namespace --ignore-not-found
        Write-Host "PersistentVolumeClaim gelöscht oder nicht gefunden." -ForegroundColor $Green
        
        Write-Host "`nBereinigung abgeschlossen." -ForegroundColor $Green
        Write-Host "Alle Ressourcen des debian XFCE Desktops wurden gelöscht."
    }
}

function Edit-Config {
    $ConfigPath = Join-Path -Path $RootDir -ChildPath "configs\webtop-config.sh"
    
    if (!(Test-Path $ConfigPath)) {
        Write-Host "Konfigurationsdatei nicht gefunden: $ConfigPath" -ForegroundColor $Red
        return
    }
    
    Write-Host "Öffne Konfigurationsdatei zur Bearbeitung..." -ForegroundColor $Blue
    Start-Process notepad.exe $ConfigPath -Wait
    
    Write-Host "Konfiguration aktualisiert." -ForegroundColor $Green
}

function Show-ProjectInfo {
    Write-Host "=================================================" -ForegroundColor $Blue
    Write-Host "  ICC debian XFCE Desktop - Projektinformation   " -ForegroundColor $Blue
    Write-Host "=================================================" -ForegroundColor $Blue
    Write-Host
    Write-Host "Dieses Toolkit ermöglicht die einfache Bereitstellung eines"
    Write-Host "debian XFCE Desktops mit Entwicklungswerkzeugen auf der"
    Write-Host "Informatik Compute Cloud (ICC) der HAW Hamburg."
    Write-Host
    Write-Host "Das System bietet einen vollständigen Linux-Desktop mit:"
    Write-Host "- Visual Studio Code"
    Write-Host "- Sublime Text"
    Write-Host "- Ansible"
    Write-Host "- und weiteren Entwicklungstools"
    Write-Host
    Write-Host "Der Zugriff ist möglich über:"
    Write-Host "- Webbrowser (HTTP/HTTPS)"
    Write-Host "- VNC-Clients"
    Write-Host "- RDP-Clients (nach Einrichtung)"
    Write-Host
    Write-Host "Weitere Informationen finden Sie in der README.md und"
    Write-Host "in der FEHLERBEHEBUNG.md im Projektverzeichnis."
    Write-Host
    Write-Host "Drücken Sie eine beliebige Taste, um fortzufahren..." -ForegroundColor $Yellow
    [void][System.Console]::ReadKey($true)
}

# Hauptmenü anzeigen
function Show-Menu {
    Clear-Host
    Show-Banner
    
    Write-Host "Verfügbare Aktionen:" -ForegroundColor $Green
    Write-Host "1) Vollständigen Desktop mit Entwicklungstools deployen (PVC)" -ForegroundColor $Yellow
    Write-Host "2) Minimalen Desktop deployen (nur Basis-Desktop)" -ForegroundColor $Yellow
    Write-Host "3) Desktop mit temporärem Speicher deployen (EmptyDir)" -ForegroundColor $Yellow
    Write-Host "4) Port-Forwarding starten (für Browserzugriff)" -ForegroundColor $Yellow
    Write-Host "5) RDP-Unterstützung einrichten" -ForegroundColor $Yellow
    Write-Host "6) Installation überwachen (Monitor)" -ForegroundColor $Yellow
    Write-Host "7) Deployment bereinigen (Alles löschen)" -ForegroundColor $Yellow
    Write-Host "8) Konfiguration bearbeiten" -ForegroundColor $Yellow
    Write-Host "9) Informationen zum Projekt" -ForegroundColor $Yellow
    Write-Host "0) Beenden" -ForegroundColor $Yellow
    Write-Host
    
    [int]$choice = Read-Host "Wählen Sie eine Option (0-9)"
    
    switch ($choice) {
        1 { Deploy-FullDesktop }
        2 { Deploy-MinimalDesktop }
        3 { Deploy-SimpleDesktop }
        4 { Start-PortForwarding }
        5 { Setup-Rdp }
        6 { Monitor-Installation }
        7 { Cleanup-Deployment }
        8 { Edit-Config }
        9 { Show-ProjectInfo }
        0 { 
            Write-Host "Auf Wiedersehen!" -ForegroundColor $Green
            exit 
        }
        default {
            Write-Host "Ungültige Option. Bitte wählen Sie eine Zahl zwischen 0 und 9." -ForegroundColor $Red
            Write-Host "Drücken Sie eine beliebige Taste, um fortzufahren..." -ForegroundColor $Yellow
            [void][System.Console]::ReadKey($true)
            Show-Menu
        }
    }
    
    # Nach der Aktion zurück ins Menü, außer bei Beenden
    if ($choice -ne 0) {
        Write-Host
        Write-Host "Drücken Sie eine beliebige Taste, um zum Hauptmenü zurückzukehren..." -ForegroundColor $Yellow
        [void][System.Console]::ReadKey($true)
        Show-Menu
    }
}

# Prüfe Bash-Verfügbarkeit und zeige passende Hinweise
if (Test-Bash) {
    Write-Host "Bash wurde gefunden. Volle Unterstützung für alle Skripte ist verfügbar." -ForegroundColor $Green
    Write-Host "Windows PowerShell wird als Wrapper für die Bash-Skripte verwendet." -ForegroundColor $Green
}
else {
    Write-Host "Bash wurde nicht gefunden. Einige Funktionen sind möglicherweise eingeschränkt." -ForegroundColor $Yellow
    Write-Host "Für volle Funktionalität empfehlen wir die Installation von Git Bash oder WSL." -ForegroundColor $Yellow
}

# Hauptfunktion basierend auf übergebenem Parameter
switch ($Action) {
    "deploy" { Deploy-FullDesktop }
    "minimal" { Deploy-MinimalDesktop }
    "simple" { Deploy-SimpleDesktop }
    "port-forward" { Start-PortForwarding }
    "rdp" { Setup-Rdp }
    "monitor" { Monitor-Installation }
    "cleanup" { Cleanup-Deployment }
    "edit-config" { Edit-Config }
    "info" { Show-ProjectInfo }
    default { Show-Menu }
}
