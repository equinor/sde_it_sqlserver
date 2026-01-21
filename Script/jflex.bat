REM @echo off
REM ********************************************************************
REM Please adjust the paths JFLEX_HOME and JAVA_HOME to suit your needs
REM (please do not add a trailing backslash)
REM ********************************************************************

set JFLEX_HOME=F:\Private\Java\Tools\YACC\Jflex\JFlex
REM only needed for JDK 1.1.x:
set JAVA_HOME=C:\Java\java\jdk1.5.0_02

ECHO %JAVA_HOME%

REM ------------------------------------------------------------------- 

set CLPATH=%JAVA_HOME%\lib\classes.zip;%JFLEX_HOME%\lib\JFlex.jar

REM for JDK 1.1.x
REM %JAVA_HOME%\bin\java -classpath %CLPATH% JFlex.Main %1 %2 %3 %4 %5 %6 %7 %8 %9

REM for JDK 1.2
%JAVA_HOME%\bin\java -cp %JFLEX_HOME%\lib\JFlex.jar JFlex.Main %1 %2 %3 %4 %5 %6 %7 %8 %9

goto end

:no_param
echo Must supply the FLEX file to be processed
echo Example:
echo  jflex.bat
goto end

:no_file_exist
echo The file %1 does not exist.
goto end

:end
PAUSE
