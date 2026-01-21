@echo off
setlocal
rem *********************************
rem Prepares Oracle table script for
rem loading into erwin
rem *********************************

set xstatus=0
if "x%1" == "x" goto le_errParam

set xSedDir=f:\appl\utility\gnu\bin
set xTemp=deleteMe.temp
echo s/REPLACE FORCE//g > %xTemp%
echo s/CREATE OR REPLACE/CREATE/g >> %xTemp%
echo s/BYTE)/)/g >> %xTemp%
echo s/DISABLE//g >> %xTemp%
echo s/GLOBAL TEMPORARY/\/*GLOBAL TEMPORARY*\//g >> %xTemp%
echo s/ON COMMIT PRESERVE ROWS/\/*ON COMMIT PRESERVE ROWS*\//g >> %xTemp%
sed -f %xTemp% %1
if errorlevel 1 goto le_Error

goto le_end
rem *********************************
rem end of program
rem *********************************
:le_error
rem echo Error occurred
set xstatus=1
goto le_end

:le_errParam
echo Must supply filename
set xstatus=1
goto le_end

:le_end
del %xTemp%
endlocal
exit /b %xstatus%


