@echo off
REM ********************************************************************
REM Please adjust the paths JCUP_HOME and JAVA_HOME to suit your needs
REM (please do not add a trailing backslash)
REM ********************************************************************

if "x%1%" == "x" goto no_param

if not exist %1 goto no_file_exist

set JCUP_HOME=F:\Private\Java\Tools\YACC\Java_cup\cup
REM only needed for JDK 1.1.x:
set JAVA_HOME=C:\Java\java\jdk1.5.0_02

ECHO %JAVA_HOME%

REM ------------------------------------------------------------------- 

set CLPATH=%JAVA_HOME%\lib\classes.zip;%JCUP_HOME%\lib\JFlex.jar

REM for JDK 1.1.x
REM %JAVA_HOME%\bin\java -classpath %CLPATH% JFlex.Main %1 %2 %3 %4 %5 %6 %7 %8 %9

REM for JDK 1.2
%JAVA_HOME%\bin\java -classpath %JCUP_HOME% java_cup.Main < %1

goto end

:no_param
echo Must supply the CUP file to be processed
echo Example:
echo  jcup.bat c:\temp\myparser.cup
goto end

:no_file_exist
echo The file %1 does not exist.
goto end

:end
PAUSE
