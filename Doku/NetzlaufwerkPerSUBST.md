# Netzlaufwerk N: bei Peer-Server per SUBST einrichten für mehr Performance

Als <Code>C:\easy\Install-DelaproSubstTask.ps1</Code> anlegen und dann einmal ausführen.

```Powershell
# Install-DelaproSubstTask.ps1
# Erstellt eine Login-Aufgabe, die N: => C:\easy per SUBST setzt.

$TaskName   = 'Delapro - SUBST N'
$ScriptDir  = Join-Path $env:LOCALAPPDATA 'Delapro'
$ScriptPath = Join-Path $ScriptDir 'Set-DelaproSubstN.ps1'
$TargetPath = 'C:\easy'
$Drive      = 'N:'

New-Item -ItemType Directory -Path $ScriptDir -Force | Out-Null

$MapScript = @'
$Drive      = 'N:'
$TargetPath = 'C:\easy'
$LogDir     = Join-Path $env:LOCALAPPDATA 'Delapro'
$LogFile    = Join-Path $LogDir 'Subst-N.log'

New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -LiteralPath $LogFile -Value "$timestamp $Message"
}

function Get-SubstTarget {
    param([string]$Drive)

    $lines = (& cmd.exe /c subst) 2>$null
    $pattern = '^{0}\\:\s*=>\s*(.+)$' -f [regex]::Escape($Drive)

    foreach ($line in $lines) {
        if ($line -match $pattern) {
            return $Matches[1].Trim()
        }
    }

    return $null
}

try {
    if (-not (Test-Path -LiteralPath $TargetPath -PathType Container)) {
        Write-Log "FEHLER: Zielpfad existiert nicht: $TargetPath"
        exit 1
    }

    $currentSubstTarget = Get-SubstTarget -Drive $Drive

    if ($currentSubstTarget) {
        if ($currentSubstTarget.TrimEnd('\') -ieq $TargetPath.TrimEnd('\')) {
            Write-Log "OK: $Drive ist bereits auf $TargetPath gesetzt."
            exit 0
        }

        Write-Log "INFO: Entferne vorhandenes SUBST $Drive => $currentSubstTarget"
        & cmd.exe /c "subst $Drive /D" | Out-Null
    }
    else {
        $logicalDisk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$Drive'" -ErrorAction SilentlyContinue

        if ($logicalDisk) {
            Write-Log "FEHLER: $Drive existiert bereits, ist aber keine SUBST-Verbindung. DriveType=$($logicalDisk.DriveType), ProviderName=$($logicalDisk.ProviderName)"
            exit 2
        }
    }

    & cmd.exe /c "subst $Drive `"$TargetPath`""

    if ($LASTEXITCODE -ne 0) {
        Write-Log "FEHLER: subst meldete ExitCode $LASTEXITCODE"
        exit $LASTEXITCODE
    }

    $newTarget = Get-SubstTarget -Drive $Drive

    if ($newTarget -and ($newTarget.TrimEnd('\') -ieq $TargetPath.TrimEnd('\'))) {
        Write-Log "OK: $Drive wurde auf $TargetPath gesetzt."
        exit 0
    }

    Write-Log "FEHLER: $Drive konnte nicht verifiziert werden."
    exit 3
}
catch {
    Write-Log "FEHLER: $($_.Exception.Message)"
    exit 99
}
'@

Set-Content -LiteralPath $ScriptPath -Value $MapScript -Encoding UTF8 -Force

$PowerShellExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$UserId        = "$env:USERDOMAIN\$env:USERNAME"

$Action = New-ScheduledTaskAction `
    -Execute $PowerShellExe `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""

$Trigger = New-ScheduledTaskTrigger `
    -AtLogOn `
    -User $UserId

$Principal = New-ScheduledTaskPrincipal `
    -UserId $UserId `
    -LogonType Interactive `
    -RunLevel LeastPrivilege

$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Principal $Principal `
    -Settings $Settings `
    -Description 'Setzt beim Benutzer-Login N: per SUBST auf C:\easy.' `
    -Force | Out-Null

Start-ScheduledTask -TaskName $TaskName

Write-Host "Geplante Aufgabe wurde erstellt: $TaskName"
Write-Host "SUBST-Script: $ScriptPath"
Write-Host "Logdatei: $env:LOCALAPPDATA\Delapro\Subst-N.log"
```

Zum Prüfen:
```Powershell
cmd /c subst

Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='N:'" |
    Select-Object DeviceID, DriveType, ProviderName
```

müsste

```
N:\: => C:\easy

DeviceID DriveType ProviderName
-------- --------- ------------
N:              3
```
ergeben

Zum Entfernen:

```Powershell
Unregister-ScheduledTask -TaskName 'Delapro - SUBST N' -Confirm:$false
cmd /c "subst N: /D"
```
