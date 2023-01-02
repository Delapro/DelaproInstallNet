# DLPInstallClient.PS1
#

# PeerClient einrichten
Function Install-easyPeerClient {

	# Einstellungen von Internet Explorer Intranet Settings prüfen und
	# das verwendete Netzwerklaufwerk bei den Ausnahmen hinzufügen
	If (-Not (Test-NetworkDiscoveryFirewall)) {
		Enable-NetworkDiscoveryFirewallPorts
	}

	# easy Benutzergruppe einrichten

	# Benutzer einrichten

	Set-SmbClientConfiguration -OplocksDisabled $true -Force
	Set-SmbClientConfiguration -UseOpportunisticLocking $false -Force

	# zusätzlich vielleicht, wird für Suchserver benötigt:
	Set-SmbClientConfiguration -DirectoryCacheLifetime 0 -Force
	Set-SmbClientConfiguration -FileInfoCacheLifetime 0 -Force
	Set-SmbClientConfiguration -FileNotFoundCacheLifetime 0 -Force

	# um sicher zu gehen, dass obige Konfiguration angewendet werden noch den Dienst neu starten
	# Allerdings zieht der Neustart des Dienstes eine Smartscreen-Meldung nach sich: https://github.com/Delapro/DelaproInstallNet/blob/master/Doku/SmartScreen-Problem.md
	Restart-Service LanmanWorkstation -Force -Verbose

	# Mapping einrichten
}

Function Save-NetDriveRefresh {
	[CmdletBinding()]
	Param(
		[String]$ScriptName='RefreshNetDrive.PS1',
		[String]$DlpDrive='N:',
		[String]$RemotePath="\\$($env:COMPUTERNAME)\easy"
	)

	$script = @"
	# Netzwerkverknüpfung von Delapro-Verknüpfung prüfen

	# zuerst drei Helper Routinen definieren
	Function Get-FileShortcut {
		[CmdletBinding()]
		Param (
			[String]`$LinkFilename,
			[String]`$Folder=(Get-DesktopFolder -AllUsers)
		)
	
		`$Shell = New-Object -ComObject Wscript.Shell
		Write-Verbose "Pfad: `$folder"
		If (-Not `$LinkFilename.ToUpper().EndsWith(".LNK")) {
			`$LinkFilename = `$LinkFilename + ".LNK"
		}
		Write-Verbose "Shortcutpfad: `$LinkFilename"
		`$link = `$Shell.CreateShortcut("`$(`$folder)\`$(`$LinkFilename)")  # Windowslogik: Create ist auch zum Lesen da!
		If (`$null -ne `$link) {
			`$Properties = @{
				ShortcutName = `$link.Name;
				FullName = `$link.FullName;
				DirectoryName = `$link.DirectoryName
				WorkingDirectory = `$link.WorkingDirectory
				Description = `$link.Description
				Arguments = `$link.Arguments
				TargetPath = `$link.targetpath
				Hotkey = `$link.Hotkey
				IconLocation = `$link.IconLocation
			}
			New-Object PSObject -Property `$Properties
		}
	}
	
	Function Set-FileShortcut {
		[CmdletBinding()]
		Param (
			[PSObject]`$Shortcut,
			[String]`$TargetPath,
			[String]`$WorkingDirectory
		)
	
		`$Shell = New-Object -ComObject Wscript.Shell
		`$link = `$Shell.CreateShortcut("`$(`$Shortcut.Fullname)")  # Windowslogik: Create ist auch zum Lesen da!
		If (`$null -ne `$link) {
			If (`$TargetPath.Length -gt 0) {
				`$link.targetPath = `$TargetPath
			}
			If (`$WorkingDirectory.Length -gt 0) {
				`$link.WorkingDirectory = `$WorkingDirectory
			}
			`$link.Save()
		}
	}
	
	Function Get-DesktopFolder {
		[CmdletBinding()]
		Param(
			[Switch]`$AllUsers,
			[Switch]`$CurrentUser
		)
	
		If (`$AllUsers) {
			`$folder = [System.Environment]::GetFolderPath("CommonDesktop")
		} else {
			`$folder = [System.Environment]::GetFolderPath("Desktop")
		}
	
		`$folder
	}

	`$DlpLink = "`$(Get-DesktopFolder -CurrentUser)\Delapro.LNK"
	If (-Not (Test-Path `$DlpLink)) {
		`$DlpLink = "`$(Get-DesktopFolder -AllUsers)\Delapro.LNK"
	} 
	If (Test-Path `$DlpLink) {
		`$DlpLinkSet = Get-FileShortCut -LinkFilename `'Delapro.Lnk`' -Folder (Get-ChildItem `$DlpLink).Directory
		If (`$DlpLinkSet) {
			If (`$DlpLinkSet.WorkingDirectory.Substring(0, 2) -ne `'$DLPDrive`') {
				Set-FileShortcut -Shortcut `$DlpLinkSet.Fullname -WorkingDirectory `$DlpLinkSet.WorkingDirectory.Replace("`$DlpLinkSet.WorkingDirectory.Substring(0, 2)\", "`$DLPDrive\")
				Write-Host -ForegroundColor Green "Delapro.Lnk WorkingDirectory gesetzt!"
			}
			If (`$DlpLinkSet.TargetPath.Substring(0, 2) -ne `'$DLPDrive`') {
				Set-FileShortcut -Shortcut `$DlpLinkSet.Fullname -TargetPath `$DlpLinkSet.TargetPath.Replace("`$DlpLinkSet.TargetPath.Substring(0, 2)\", "`$DLPDrive\")
				Write-Host -ForegroundColor Green "Delapro.Lnk TargetPath gesetzt!"
			}
		} else {
			Write-Error "Problem: `$DlpLinkSet nicht gefunden!"
		}
	} else {
		Write-Error "Problem: `$DlpLink konnte nicht gefunden werden!"
	} 

	# Netzwerkverbindung prüfen und gegebenenfalls wiederherstellen, sollte auf jedem Client lokal gespeichert und mittels Verknüpfung aufrufbar sein.
	# es sollte für die Netzwerkeinrichtung ein NetSetup Unterverzeichnis im Delapro angelegt werden, damit darüber die nötigen Scripte erzeugt werden können und dann am einzelnen Client ausgeführt werden, damit die Einrichtung darüber schneller von statten geht.
	`$localPath = `'$DLPDrive`'
	`$remotePath = `'$RemotePath`'
	If (((Get-SmbMapping -LocalPath `$localPath -ea SilentlyContinue).Status) -eq `$null) {
	  # es existiert noch kein lokales Laufwerk, also neu anlegen
	  New-SmbMapping -LocalPath `$localPath -RemotePath `$remotePath
	}
	If (((Get-SmbMapping -LocalPath `$localPath -ea SilentlyContinue).Status) -eq 'Unavailable') {
	  # Laufwerk wurde getrennt, also Verbindung neu aufbauen
	  New-SmbMapping -LocalPath `$localPath -RemotePath `$remotePath
	}
	If (((Get-SmbMapping -LocalPath `$localPath -ea SilentlyContinue).Status) -ne 'OK') {
	  # wenn noch nicht erfolgreich, zunächst versuchen die Verbindung zu entfernen und dann neu aufzubauen
	  Remove-SmbMapping -LocalPath `$localPath -Confirm:`$False -Force
	  New-SmbMapping -LocalPath `$localPath -RemotePath `$remotePath
	}
	If (((Get-SmbMapping -LocalPath `$localPath -ea SilentlyContinue).Status) -eq 'OK') {
	  Write-Host -ForegroundColor Green "Verbindung sollte jetzt verfügbar sein!"
	  Start-Sleep -Seconds 1
	} else {
	  Write-Error "Probleme Verbindung zwischen `$localPath und `$remotePath aufzubauen."
	  "Fehler wurden in die Windows Zwischenablage kopiert."
	  `$error | Set-Clipboard
	  Start-Sleep -Seconds 30
	}
	
"@

	$script | Set-Content -Path $ScriptName
}


<#


#>

# EOF: DLPInstallClient.PS1
