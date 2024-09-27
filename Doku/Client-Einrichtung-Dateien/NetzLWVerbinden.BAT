NET USE N: /DEL
REM alte Variante:
REM   NET USE N: \\SERVER\EASY /User:easyNetz eyTest1#
REM
REM neue Variante:
REM   Server-Alias in \Windows\System32\drivers\etc\hosts setzen
REM   z. B.:
REM     # Alias für mehrere SMB-Verbindungen, hier Delapro
REM     192.168.178.38	Server-Alias
REM
REM   Benutzerdaten kommen von SaveCred: cmdkey /List:Server-Alias
REM   dazu einmalig NET USE N: \\Server-Alias\EASY /SAVECRED /PERSISTENT:YES aufrufen und die Daten eingeben
REM
REM   Oder mittels
REM   cmdkey /add:ServerHostname /user:easyTester /pass
REM   hinzufügen und dann 
REM   NET USE N: \\Server-Alias\EASY /user:easyTester die Verbindung aufbauen
REM
NET USE N: \\Server-Alias\EASY
