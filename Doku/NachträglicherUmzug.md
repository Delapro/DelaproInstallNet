Beim nachträglichen Umzug zu beachten:

* BILDER-Verzeichnis abklären (Anpassung von DLP_MAIN.INI und BILDER.DBF)
* Verweise von GHOSTPDF*.BAT abklären, PDFFile sollte auf Netzlaufwerk verweisen:
```
IF %CD% == N:\DELAGAME (
  SET PDFFILE=N:\DELAGAME\EXPORT\PDF\DELAPRO.PDF
) ELSE (
  SET PDFFILE=N:\DELAPRO\EXPORT\PDF\DELAPRO.PDF
)
```
* evtl. Netzwerkmodus im Programmverteiler aktivieren

