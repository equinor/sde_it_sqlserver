@echo off
cd %~dp0
echo %~dp0
rem Note target is without #'s so report should not go to service-now if errors uncovered.
echo Correct paths and target should be "-t #IRIS21#" for production.
c:\appl\Python27\ArcGIS10.2\python.exe sendReport.py -s IRIS21 -t "IRIS21" -g c:/users/%USERNAME%/appdata/roaming/esri/desktop10.2/arccatalog/Test_IRIS21_sde_it.sde