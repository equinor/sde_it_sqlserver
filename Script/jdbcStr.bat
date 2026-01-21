echo off
rem ********************************************************
rem Written by : Johan Thorsen
rem Dept : IT-EH
rem Date : 01.01.2001
rem SCCS : this is under source code control
rem ********************************************************
rem Log
rem 01062001 : Upgraded due to NextStep
rem ********************************************************
echo Getting oracle connect string :
g:\appl\ocd\perl\bin\perl g:\appl\ocd\priv\johan\Jobs\getJDBC_DBprops.exe %1 %2 %3 %4 %5 %6 %7 %8
