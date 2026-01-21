@echo off
rem **************************************************
rem written by: Johan Thorsen
rem Date: 290908
rem Description
rem  For use with sde 9.1 oracle 9i
rem Parameters
rem 1) program to be executed
rem 2-9) parameters to be passed on
rem **************************************************

rem *************************************
rem Initialize
rem *************************************

if "%1" == "" goto le_Parameter
if not exist %1 goto le_NonExist

rem *************************************
rem End of program
rem *************************************
goto le_end

:le_NonExist
echo Error: The file %1 does not exist.
goto le_end

:le_Parameter
echo Enter command to execute including parameters to be passed on
echo Example:
echo To run the "manage_service" job with parameter "status":
echo runJob manage_service status
echo 
echo ----------------------------------------------------
echo ----------------------------------------------------
goto le_end

:le_error
echo Error has occurred %errorlevel%
goto le_end

:le_end
exit /b %errorlevel%

