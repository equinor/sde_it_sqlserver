@echo off   
rem *****************************************************************
rem  Package Info
rem  Author          : $Author: jothor $
rem  Original Date   : $Date: 2009/01/14 12:32:03 $
rem  Last Modified   : $Modtime: $
rem  Archive Name    : $Archive: $
rem  Description     : $Header: f:\private\repository/dbr/Jobs/insertKeywork.cmd,v 1.4 2009/01/14 12:32:03 jothor Exp $
rem  Revision History: $Revision: 1.4 $
rem  Tag name        : $Name:  $
rem  Workfile        : $Workfile: $
rem  Copyright info  : Copyright (c), StatoilHydro ASA,Norway. $Date: 2009/01/14 12:32:03 $
rem *****************************************************************
rem  Description
rem 
rem 
rem *****************************************************************
rem  Log
rem  Date  Description                                      Done by
rem *****************************************************************/

set xStatus=0
setlocal

rem ***************************************
rem Variable declaration.
rem ***************************************
set xoutputDir=.\temp

if not exist %xoutputDir% md %xoutputDir%
if errorlevel 1 goto le_error
for %%i in (*) do (
  echo Processing: %%i
  nawk -f %~d0%~p0.\InsertKeywork.awk before=true doSync=false %%i > %xoutputDir%\%%i
)

rem ***************************************
rem End of program
rem ***************************************
goto le_end


:le_end
echo Output can be found in directory: %xoutputDir%
(date /t & time /t)
endlocal
exit /b %xStatus%
