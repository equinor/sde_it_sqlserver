#************************************************************
# Author          : $Author: jothor $
# Original Date   : $Date: 2010/03/16 13:38:14 $
# Last Modified   : $Modtime:  $
# Archive Name    : $Archive:  $
# Description     : $Header: f:\private\repository/dbr/Jobs/AuditSdeTable/addAuditInfo.awk,v 1.1 2010/03/16 13:38:14 jothor Exp $
# Revision History: $Revision: 1.1 $
# Workfile        : $Workfile:  $
# Copyright info  : Copyright (c), StatoilHydro ASA,Norway. $Date: 2010/03/16 13:38:14 $
#
#***********************************************************
# Description:
# Generates scripts/alter table scripts to add audit info.
# Usage
# nawk -f addAuditInfo.awk {lOnlyDelta=true} {filename containing list of tables} 
#   lOnlyDelta=true processes only the delta tables including parent
#   lOnlyDelta=false default processes tables including delta
#
# See http://forums.esri.com/Thread.asp?c=2&f=1719&t=193025
# I don't believe there is any way to do this using only the SDE command line tools.
# IF your layer is not versioned AND the layer does not participate in geodatbase functionality you can add the column using SQL (e.g. alter table hospital add column dlc varchar(30)). You could issue this type of command using osql from a batch script.
# If you want to execute the alter table statement using a sde command line tool style interface you can use the sdesql tool from Vince's se_toolkit (ftp://ftp.esri.com/pub/staff/vangelo/se_toolkit/index.html ) to modify the table (same precautions still apply, but the syntax is similar to the sde command line tools).
#
# Entry in SDE.COLUMN_REGISTRY
# TABLE_NAME	OWNER	COLUMN_NAME	SDE_TYPE	COLUMN_SIZE	DECIMAL_DIGITS	DESCRIPTION	OBJECT_FLAGS	OBJECT_ID
# AUDIT_CITIES	SDE_ADM	ST_ROW_CREATE_DATE	7	0	null	null	4	null	
# AUDIT_CITIES	SDE_ADM	ST_ROW_CREATE_USER	5	100	null	null	4	null	
# AUDIT_CITIES	SDE_ADM	ST_ROW_UPDATE_DATE	7	0	null	null	4	null	
# AUDIT_CITIES	SDE_ADM	ST_ROW_UPDATE_USER	5	100	null	null	4	null	
#
#
# Find Table and corresponding A-table. 
# select sde_reg.table_name,sde_reg.a_table_name,u.table_name
#  from  user_tables u
#      ,(select 'A'||registration_id as a_table_name,table_name from sde.table_registry where owner = user) sde_reg
#  where u.table_name = sde_reg.a_table_name
#  and regexp_instr(u.table_name,'^A[0-9]+')> 0
#  order by 1
# 
#
# Picks out all tables and any corresponding layers (layer_id <> null).
#
# select u.owner
#       ,u.table_name
#       ,tr.REGISTRATION_ID
#       ,tr.rowid_column
#       ,l.layer_id
# --      ,decode(u.table_name,'A'||tr.registration_id,'true','false') as DeltaTableExist
# --      ,decode(regexp_instr(u.table_name,'^[AD][0-9]+'),0,'false','true') as DeltaTableExist
#       ,decode(tr.registration_id,null
#              ,'false'
#              ,(select 'true' from dual 
#                  where exists (select * from user_tables  
#                     where table_name = 'A'||tr.registration_id
#                     or table_name = 'D'||tr.registration_id
#                     )
#               )
#              ) as DeltaTableExist
# --      (select 'yes' from user_tables where table_name ='A'||tr.registration_id) as DeltaTableExist
#  from (select 'SDE_ADM' as owner,ut.table_name from user_tables ut) u 
#  left join  sde.table_registry tr
#     on tr.owner = u.owner
#     and u.table_name = tr.table_name 
#  left join sde.layers l
#      on tr.owner = l.owner
#      and tr.table_name = l.table_name
#  where u.table_name not like '%$'
#  and not regexp_instr(u.table_name,'^[SF][0-9]+')> 0  -- exclude the potential S and F support feature tables.
#  and not regexp_instr(u.table_name,'^KEYSET_[0-9]+')> 0
#  and u.table_name not like 'SDE_%'
#  and not regexp_instr(u.table_name,'^[AD][0-9]+')> 0  -- select only potential delta tables
#  order by tr.owner,tr.table_name
#***********************************************************
# Log    Description                                        Done by
#
#***********************************************************
BEGIN {
  FS=";";
  lCount=0;
  if (1==2) {
    lAlterTable = "c:\\temp\\alterTable.sql";
    lSedTrigger = "c:\\temp\\sedTableTrigger.cmd";
    lTriggerMal = "c:\\temp\\TriggerMaintainCreateUpdateInfo.mal";
    lTriggerDeltaMal="c:\\temp\\TriggerMaintainDeltaUpdateInfo.mal";
    lTriggerDir = "c:\\temp"
    lAlterColReg ="c:\\temp\\alterColReg.sql";
  }
  else {
    lAlterTable = "alterTable.sql";
    lSedTrigger = "sedTableTrigger.cmd";
    lTriggerMal = "TriggerMaintainUpdateInfo.mal";
    lTriggerA_DeltaMal = "TriggerMaintainCreateUpdateInfo.mal";
    lTriggerD_DeltaMal="TriggerMaintainDeltaUpdateInfo.mal";
    lTriggerDir = "."
    lAlterColReg ="alterColReg.sql";
  }

  lOnlyDelta="false";
  lTriggerName= ""
  lTrigerTable = ""
  lTriggerInnh = "trigger.innh"
  lSchema = ""   # suffixed with a dot later on
  lSchemaName = ""  # the schema name.
  lMaxLengthTrigName=30;
}
#************************
# Expected file format
# All fields separated by ";" and line terminated by ";\n"
# ----------------------------------------------------------
# 1  schema
# 2  table
# 3  registration id, used to identify/name A/D tables
# 4  rowid_column
# 5  layer_id. If null then ordinary SDE table.
#************************
/./ {
#print "ONlydelta="lOnlyDelta" $6"$6
  if ("$1" != "") {
    if ( (lOnlyDelta ~/true/ && $6 ~/true/) || lOnlyDelta ~/false/) {
#print "  --- adding "$2
      lTabList[lCount".schema"] = $1;
      lTabList[lCount".table"] = $2;
      lTabList[lCount".registration_id"] = $3;
      lTabList[lCount".rowid_column"] = $4;
      lTabList[lCount".layer_id"] = $5;
      lTabList[lCount".DeltaTableExist"] = $6;
#print ">>>"$1" "$2 "---"lTabList[lCount".table"];
      lCount++;
    }
  }
}

function addAuditColum(lSchema,lTable) {
#print "in addAuditColum(lSchema,lTable)",lSchema,lTable;
    printf "alter table %s.%s\n",lSchema,lTable >> lAlterTable;
    printf "add (\n" >> lAlterTable;
    printf "  st_row_create_date date null\n" >> lAlterTable;
    printf " ,st_row_create_user varchar2(100) null\n" >> lAlterTable;
    printf " ,st_row_update_date date null\n" >> lAlterTable;
    printf " ,st_row_update_user varchar2(100) null\n" >> lAlterTable;
    printf ");\n" >> lAlterTable;

# Start: This can change, so do not use
#    if (lTabList[i".DeltaTableExist"] != "") {
#      lStr = ". Associated delta table [AD]"lTabList[i".registration_id"];
#    }
# End: This can change, so do not use

    printf "COMMENT ON COLUMN %s.%s.st_row_create_date IS 'This is the datetime the row was created';\n",lSchema,lTable >> lAlterTable;
    printf "COMMENT ON COLUMN %s.%s.st_row_create_user IS 'This is the name of the user who created the row';\n",lSchema,lTable >> lAlterTable;
    printf "COMMENT ON COLUMN %s.%s.st_row_update_date IS 'This is the datetime the row was updated';\n",lSchema,lTable >> lAlterTable;
    printf "COMMENT ON COLUMN %s.%s.st_row_update_user IS 'This is the name of the user who updated the row';\n",lSchema,lTable >> lAlterTable;
    print "\n" >> lAlterTable;
}

END {
#-----------------------------------------------
# Open the exit below, remove the 1==2 condition
# and this will print the contents of lTabList.
#-----------------------------------------------
  if (1==2) {
    for (i=0;i<lCount;i++) {
      print "schema:", lTabList[i".schema"];
      print "table:" lTabList[i".table"];
      print "regid:",lTabList[i".registration_id"];
      print "rowid:",lTabList[i".rowid_column"];
      print "layid:",lTabList[i".layer_id"];
      print "delta:",lTabList[i".DeltaTableExist"];
    }
   exit 1
  }

#-----------------------------------------
# Prepare the files.
#-----------------------------------------
  printf "" > lAlterTable;
  printf "" > lSedTrigger;
  printf "" > lAlterColReg;
  printf "" > lTriggerInnh

#-----------------------------------------
# Create the alter tables and the SDE
# column registry files
#-----------------------------------------
  print "-- Alter table, add audit columns" >> lAlterTable;
  print "-- Alter column registy in SDE schema" >> lAlterColReg

  printf "@echo off\n" >> lSedTrigger;
  print "rem  Alter table, sed script for trigger" >> lSedTrigger;
  printf "if not exist %s (\n",lTriggerMal >> lSedTrigger;
  printf "  echo The file %s does not exist. Exiting\n",lTriggerMal >> lSedTrigger;
  printf "  exit /b 1\n" >> lSedTrigger;
  printf ")\n\n" >> lSedTrigger;
  printf "echo Job in progress ...\n" >> lSedTrigger;

  for (i=0;i<lCount;i++) {
    # ------------------------------------------------
    # Update all tables with audit columns.
    # ------------------------------------------------
    addAuditColum(lTabList[i".schema"],lTabList[i".table"]);

    # ------------------------------------------------
    # Update SDE column registry where Delta tables exist
    # ------------------------------------------------
    if (lTabList[i".DeltaTableExist"] ~/true/) {
      printf "-- Delta table parent: %s\n",lTabList[i".table"] >> lAlterTable;
      addAuditColum(lTabList[i".schema"],"A"lTabList[i".registration_id"]);

      printf "-- To be executed as SDE user in the SDE schema\n" >> lAlterColReg;
      printf "begin\n" >> lAlterColReg;
      printf "  insert into sde.column_registry (TABLE_NAME,OWNER,COLUMN_NAME,SDE_TYPE,COLUMN_SIZE,DECIMAL_DIGITS,DESCRIPTION,OBJECT_FLAGS,OBJECT_ID)\n",lSchema,lTabList[i] >> lAlterColReg;
      printf "    values ('%s','%s','ST_ROW_CREATE_DATE', 7, 0,   null, null, 4, null);\n",lTabList[i".table"],lTabList[i".schema"] >> lAlterColReg;
      printf "  insert into sde.column_registry (TABLE_NAME,OWNER,COLUMN_NAME,SDE_TYPE,COLUMN_SIZE,DECIMAL_DIGITS,DESCRIPTION,OBJECT_FLAGS,OBJECT_ID)\n",lSchema,lTabList[i] >> lAlterColReg;
      printf "    values ('%s','%s','ST_ROW_CREATE_USER', 5, 100, null, null, 4, null);\n",lTabList[i".table"],lTabList[i".schema"] >> lAlterColReg;
      printf "  insert into sde.column_registry (TABLE_NAME,OWNER,COLUMN_NAME,SDE_TYPE,COLUMN_SIZE,DECIMAL_DIGITS,DESCRIPTION,OBJECT_FLAGS,OBJECT_ID)\n",lSchema,lTabList[i] >> lAlterColReg;
      printf "    values ('%s','%s','ST_ROW_UPDATE_DATE', 7, 0,   null, null, 4, null);\n",lTabList[i".table"],lTabList[i".schema"] >> lAlterColReg;
      printf "  insert into sde.column_registry (TABLE_NAME,OWNER,COLUMN_NAME,SDE_TYPE,COLUMN_SIZE,DECIMAL_DIGITS,DESCRIPTION,OBJECT_FLAGS,OBJECT_ID)\n",lSchema,lTabList[i] >> lAlterColReg;
      printf "    values ('%s','%s','ST_ROW_UPDATE_USER', 5, 100, null, null, 4, null);\n",lTabList[i".table"],lTabList[i".schema"] >> lAlterColReg;
      printf "  commit;\n" >> lAlterColReg;
      printf "end;\n" >> lAlterColReg;
      printf "\n" >> lAlterColReg;
    }

    # ------------------------------------------------
    # Create the A delta table triggers
    # If total length of name exceeds name limits, truncate.
    # ------------------------------------------------
    if (lTabList[i".DeltaTableExist"] ~/true/) {
      # ------------------------------------------------
      # Prepare for the A-delta table
      # ------------------------------------------------
      lTriggerName = "tiuA" lTabList[i".registration_id"] "_audit";
      if (length(lTriggerName) > lMaxLengthTrigName) {
        lTriggerName = substr(lTriggerName,1,lMaxLengthTrigName);
      }
      lTriggerFile = lTriggerName".sql"
      lTriggerTable = lTabList[i".schema"]".A"lTabList[i".registration_id"];
      printf "sed -e s/\\{triggerName\\}/%s.%s/g -e s/\\{triggerTable\\}/%s/g ",lTabList[i".schema"],lTriggerName,lTriggerTable >> lSedTrigger;
      printf " -e s/\\{parentTable\\}/%s.%s/g  -e s/\\{parentKey\\}/%s/g",lTabList[i".schema"],lTabList[i".table"],lTabList[i".rowid_column"] >> lSedTrigger;
      printf " %s > %s\\%s\n",lTriggerA_DeltaMal,lTriggerDir,lTriggerFile >> lSedTrigger;
      printf "%s\n",lTriggerFile >> lTriggerInnh


       # ------------------------------------------------
       # Prepare for the D-delta table
       # ------------------------------------------------
#      lTriggerName = "tiuD" lTabList[i".registration_id"] "_audit";
#      if (length(lTriggerName) > lMaxLengthTrigName) {
#        lTriggerName = substr(lTriggerName,1,lMaxLengthTrigName);
#      }
#
#      lTriggerFile = lTriggerName".sql"
#      lTriggerTable = lTabList[i".schema"]".A"lTabList[i".registration_id"];
#      printf "sed -e s/\\{triggerName\\}/%s.%s/g -e s/\\{triggerTable\\}/%s/g ",lTabList[i".schema"],lTriggerName,lTriggerTable >> lSedTrigger;
#      printf " -e s/\\{parentTable\\}/%s.%s/g -e s/\\{parentKey\\}/%s/g",lTabList[i".schema"],lTabList[i".table"],lTabList[i".rowid_column"] >> lSedTrigger;
#      printf " %s > %s\\%s\n",lTriggerD_DeltaMal,lTriggerDir,lTriggerFile >> lSedTrigger;
#      printf "%s\n",lTriggerFile >> lTriggerInnh
    }

    # ------------------------------------------------
    # Parent table.
    # ------------------------------------------------
    lTriggerName = "tiu" lTabList[i".table"] "_audit";
    if (length(lTriggerName) > lMaxLengthTrigName) {
      lTriggerName = substr(lTriggerName,1,lMaxLengthTrigName);
    }
    lTriggerFile = lTriggerName".sql"
    lTriggerTable = lTabList[i".schema"]"."lTabList[i".table"];
    printf "sed -e s/\\{triggerName\\}/%s.%s/g -e s/\\{triggerTable\\}/%s/g %s > %s\\%s\n",lTabList[i".schema"],lTriggerName,lTriggerTable,lTriggerMal,lTriggerDir,lTriggerFile >> lSedTrigger;
    printf "%s\n",lTriggerFile >> lTriggerInnh
  }

  printf "echo Done\n" >> lSedTrigger;
  printf "(date /t & time /t)\n" >> lSedTrigger;

  print "Add columns sql in file: ",lAlterTable
  print "Sed script to create triggers in file: ",lSedTrigger
  print "Insert rows into sde.column_registry: ",lAlterColReg
  print "Trigger innh file : "lTriggerInnh
}
