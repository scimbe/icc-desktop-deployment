# Port-Forwarding für ICC Desktop
# PowerShell-Version des port-forward-webtop.sh Skripts

# Parameter für die direkte Ausführung
param(
    [Parameter()]
    [string]$Namespace = "",
    [Parameter()]
    [switch]$HTTPS = $false
)

# Skript-Verzeichnis ermitteln
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = (Get-Item $ScriptDir).Parent.FullName

# Farbdefinitionen für PowerShell
$Red = 'Red'
$Green = 'Green'
$Yellow = 'Yellow'
$Blue = 'Cyan'
$NC = 'White'

# Lese Konfiguration, wenn Namespace nicht angegeben wurde
if ([string]::IsNullOrEmpty($Namespace)) {
    $ConfigPath = Join-Path -Path $RootDir -ChildPath "configs\webtop-config.sh"
    
    if (Test-Path $ConfigPath) {
        $config = Get-Content $ConfigPath
        $NamespaceConfig = ($config | Where-Object { $_ -match "export NAMESPACE=" }) -replace 'export NAMESPACE="(.*)".*', '$1'
        
        if (![string]::IsNullOrEmpty($NamespaceConfig)) {
            $Namespace = $NamespaceConfig
        }
        else {
            Write-Host "Fehler: Konnte Namespace nicht aus Konfigurationsdatei lesen." -ForegroundColor $Red
            exit 1
        }
    }
    else {
        Write-Host "Fehler: Konfigurationsdatei nicht gefunden: $ConfigPath" -ForegroundColor $Red
        exit 1
    }
}

Write-Host "Überprüfe ob das Deployment existiert" -ForegroundColor $Blue
$DeploymentExists = kubectl -n $Namespace get deployment debian-xfce 2>$null
if (!$DeploymentExists) {
    Write-Host "Fehler: Webtop Deployment 'debian-xfce' nicht gefunden." -ForegroundColor $Red
    Write-Host "Bitte führen Sie zuerst deploy-webtop.ps1 aus."
    exit 1
}

Write-Host "Prüfe, ob ein Pod läuft" -ForegroundColor $Blue
$PodName = kubectl -n $Namespace get pods -l service=webtop -o jsonpath='{.items[0].metadata.name}' 2>$null
if ([string]::IsNullOrEmpty($PodName)) {
    Write-Host "Fehler: Kein laufender Pod für das Webtop Deployment gefunden." -ForegroundColor $Red
    exit 1
}

Write-Host "Prüfe Pod-Status" -ForegroundColor $Blue
$PodStatus = kubectl -n $Namespace get pod $PodName -o jsonpath='{.status.phase}'
if ($PodStatus -ne "Running") {
    Write-Host "Fehler: Pod ist nicht im Status 'Running', sondern im Status '$PodStatus'." -ForegroundColor $Red
    Write-Host "Bitte warten Sie, bis der Pod vollständig gestartet ist."
    exit 1
}

Write-Host "Starte Port-Forwarding in separaten Prozessen" -ForegroundColor $Green
Write-Host "Starte Port-Forwarding für debian XFCE Desktop:"

# Port-Forwarding für HTTP starten
$HttpProcess = $null
if (!$HTTPS) {
    Write-Host "- HTTP auf Port 3000" -ForegroundColor $Green
    $HttpProcess = Start-Process -FilePath "kubectl" -ArgumentList "-n $Namespace port-forward svc/debian-xfce 3000:3000" -NoNewWindow -PassThru
}
else {
    # Port-Forwarding für HTTPS starten
    Write-Host "- HTTPS auf Port 3001" -ForegroundColor $Green
    $HttpsProcess = Start-Process -FilePath "kubectl" -ArgumentList "-n $Namespace port-forward svc/debian-xfce 3001:3001" -NoNewWindow -PassThru
}

Write-Host
Write-Host "Port-Forwarding gestartet." -ForegroundColor $Green
Write-Host "Zugriffsmöglichkeiten für den Development Desktop:"
Write-Host "==================================================="
Write-Host "1. Webbrowser (empfohlen für einfachen Zugriff):"

if (!$HTTPS) {
    Write-Host "   HTTP: http://localhost:3000"
    # Browser öffnen
    Start-Process "http://localhost:3000"
}
else {
    Write-Host "   HTTPS: https://localhost:3001"
    # Browser öffnen
    Start-Process "https://localhost:3001"
}

Write-Host
Write-Host "Drücken Sie eine beliebige Taste, um das Port-Forwarding zu beenden..."
[void][System.Console]::ReadKey($true)

# Beende die Port-Forwarding-Prozesse
if ($HttpProcess) {
    Stop-Process -Id $HttpProcess.Id -Force -ErrorAction SilentlyContinue
}

if ($HttpsProcess) {
    Stop-Process -Id $HttpsProcess.Id -Force -ErrorAction SilentlyContinue
}

Write-Host "Port-Forwarding beendet." -ForegroundColor $Yellow
