@echo off
rem ************************************
rem  Package Info
rem  Author          : jothor
rem  Original Date   : 2012
rem ************************************
rem Description
rem Creates triggers based on templates.
rem NOTE: Some trigger must be maintained manually due to problems with mutating triggers
rem Entities to be handled manually- see below
rem ********************************************
rem Logg
rem Date   Description												Done by
rem 261113 Add ACTIVE_DIRECTORY to trigger ID and Audit				JOTHOR
rem ************************************
echo The following entities are to be handled manually due to problems
echo with mutating triggers:
rem pause

setlocal
set xSystem=XXX
set xhomeDir=C:\Appl\Job\CreateTrigger
set xtemplateDir=%xhomeDir%
set xschemaFile==%xhomeDir%\schema.mcr
set xoutputDir=c:\temp\%xSystem%
set xcompileDir=c:\temp\%xSystem%\rr

set xsedfileDir=%xhomeDir%
set xsedfile=sedfile.sed

rem This is for the specific non-generated triggers here.
set xtriggerDir=%xoutputDir%\Trigger_source
set xbigfile=%xtriggerDir%\Trigger.sql
set xsed=f:\appl\utility\gnu\bin\sed
rem set xTrigggerFile=

rem Should the system require an additional macro file.
set xspecificMacro=%xhomeDir%\Macro\xxx.mcr
set xspecificMacro=

rem ************************************
rem Make directory
rem ************************************
md %xoutputDir%
md %xcompileDir%
md %xtriggerDir%

rem ************************************
rem Clean out directory
rem ************************************
echo Cleaning out directory
echo -
del /Q %xoutputDir%\t*_*.sql
del /Q %xcompileDir%\*.*

rem ************************************
echo Creating separat triggers for flag,audit and id.

rem ************************************
rem Create flag triggers
rem select ut.table_name
rem from user_tables ut
rem  inner join user_tab_columns utc 
rem  on ut.table_name = utc.table_name
rem  and utc.column_name='DEPLOYED_DATE'
rem  order by ut.table_name
rem ************************************
echo Creating FLAG triggers ...
REM select  DISTINCT TABLE_NAME from user_TAB_COLUMNS where column_name in('DEPLOYED_DATE') order by 1;
set tableList=
for %%i in (%tableList%) do (
  echo Flags - Processing table: %%i
  sed -e "s/{table_name}/%%i/g" %xtemplateDir%\Trigger_flag.mal > %xoutputDir%\tflag_%%i.sql
)
echo Done creating FLAG triggers

rem ************************************
rem Create ID triggers
rem select string_agg(ut.table_name,' ') within group(order by ut.table_name) 
rem   from user_tables ut
rem   inner join user_tab_columns utc 
rem     on ut.table_name = utc.table_name
rem     and utc.column_name='ST_ID'
rem  --where ut.table_name != 'CONTAINER_TYPE'
rem  order by ut.table_name
rem ************************************
echo Creating ID triggers ...
REM select  string_agg(table_name||' ') within group (order by table_name) from user_TAB_COLUMNS where column_name in('ST_ID') order by 1;
set tableList=
for %%i in (%tableList%) do (
  echo ID - Processing table: %%i
  sed -e "s/{table_name}/%%i/g" %xtemplateDir%\Trigger_id.mal > %xoutputDir%\t_id%%i.sql
)
echo Done creating ID triggers

rem ************************************
rem Create Audit triggers
rem ************************************
echo Creating AUDIT triggers ...
rem select  string_agg(table_name||' ') within group (order by table_name) from user_TAB_COLUMNS where column_name in('ST_CREATED_BY') order by 1;
set tableList=actor
for %%i in (%tableList%) do (
  echo Audit - Processing table: %%i
  sed -e "s/{table_name}/%%i/g" %xtemplateDir%\taud_audit.mal > %xoutputDir%\taud_%%i.sql
)
echo Done creating Audit triggers
goto le_end 

:le_test
rem ************************************
rem Put triggers into one file
rem Create triggerinnh file
rem Expand code
rem Strip off superfluous info and merge to one big file.
rem ************************************
echo Create triggerinnh file
echo First: This copies specific non-generated triggers here.
cd %xoutputDir%
rem This copies specific non-generated triggers here.
copy %xtriggerDir%\t*_*.sql .
dir /B t*_*.sql > %xoutputDir%\trig_all.innh
echo Output triggers found in directory %xoutputDir%

echo Expanding code ....
echo > %xbigfile%
echo Put triggers into one file - %xbigfile%
copy %xschemaFile% .
call f:\appl\jobs\comp -ped %xcompileDir% noLoginInfo trig_all.innh
echo Done expanding code

echo Creating one big file
echo ------------------------------------------------ >> %xbigfile%
echo -- %xSystem% complete set of triggers >> %xbigfile%
echo ------------------------------------------------ >> %xbigfile%
echo -- >> %xbigfile%

if exist %xsedfileDir%\%xsedfile% (
  cd %xcompileDir%
  copy %xsedfileDir%\%xsedfile% .
  for %%i in (t*.sql) do (
    %xsed% -f %xsedfile% %%i >> %xbigfile%
    echo /  >> %xbigfile%
  )
  del /Q %xsedfile%
)

echo --
echo --
echo Done create the big file. Result in  %xbigFile%

rem done create the big file

rem ************************************
rem Clean out directory
rem ************************************
echo Cleaning out directory
echo -
del /Q %xoutputDir%\t*_*.sql
del /Q %xcompileDir%\*.*


rem END: Area below is errorhandling and wrap up. Code to be executed to be placed above.
goto le_end
rem --------------------------------------

:le_end

echo Task completed.
echo Is the file %xbigfile% writable?
echo otherwise you will get "Access Denied"
echo Check out the file from TFS.
echo 
echo Ensure exist: %xoutputDir% and %xcompileDir%
echo
endlocal
exit /b 0


rem --------------------------------------
rem --------------------------------------
rem --------------------------------------
rem --------------------------------------
rem --------------------------------------





rem ************************************
rem Create new triggers
rem ************************************
rem set tableList=
rem for %%i in (%tableList%) do (
rem   echo InsertUpdate - Processing table: %%i
rem   sed -e "s/{trigger_name}/%%i/g" %xtemplateDir%\TriggerInsertUpdate.mal > %xoutputDir%\tiu_%%i.sql
rem )

