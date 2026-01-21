@echo off
setlocal
rem ********************************************************
rem Author          : $Author: jothor $
rem Original Date   : $Date: 2008/12/18 15:15:35 $
rem Last Modified   : $Modtime: $
rem Archive Name    : $Archive: $
rem Description     : $Header: f:\private\repository/dbr/Jobs/prepModel4Mysql.cmd,v 1.2 2008/12/18 15:15:35 jothor Exp $
rem Revision History: $Revision: 1.2 $
rem Workfile        : $Workfile: $
rem Copyright info  : Copyright (c), Statoil ASA,Norway. $Date: 2008/12/18 15:15:35 $
rem ********************************************************
rem Description
rem Copies files to destination directory
rem ********************************************************

if "x%1" == "x" goto leParameter

set xdir=%~d0%~p0
set xfileDir=%~d1%~p1
set xtemp=1234.temp
set xresFile=res.sql

echo s/ BYTE)/)/g > %xtemp%
echo s/\(VARCHAR2([0-9]*\)\([ ]*\)\(CHAR\)/\1/g >>%xtemp%
echo s/VARCHAR2/VARCHAR/g >>%xtemp%
echo s/LONG RAW/BLOB/g >> %xtemp%
echo s/CLOB/BLOB/g >> %xtemp%
echo s/LONG/BIGINT/g >> %xtemp%
echo s/ON COMMIT DELETE ROWS//g >> %xtemp%
echo s/GLOBAL TEMPORARY //g  >> %xtemp%
echo s/ NUMBER(/ NUMERIC(/g  >> %xtemp%
echo s/ NUMBER / NUMERIC /g  >> %xtemp%
echo s/ON COMMIT PRESERVE ROWS//g  >> %xtemp%
echo s/OR REPLACE FORCE//g  >> %xtemp%
rem echo s/@[a-zA-Z0-9_]*/\/\*&\*\//g  >> %xtemp%
echo s/@[a-zA-Z0-9_]*//g  >> %xtemp%
echo s/\//;/ >>%xtemp%
echo s/CREATE UNIQUE INDEX /CREATE INDEX /g >> %xtemp%


rem cat %xtemp%
sed -f %xtemp% %1 > %xresFile%

goto le_end

:leParameter
echo Please enter filename to be processed
goto le_end

:le_end

echo Job completed
echo Result in %xfileDir%%xresFile%
(date /t & time /t) 
echo ===============================  
del /Q /F %xtemp%

endlocal
exit /b %xStatus%
