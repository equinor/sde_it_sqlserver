divert(-1)
#**********************************************************************
# Author          : $Author: JOTHOR $
# Original Date   : $Date: 2007/03/01 08:13:19 $
# Last Modified   : $Modtime: 6.01.06 13:00 $
# Archive Name    : $Archive: /Macro/oracle.mcr $
# Description     : $Header: f:\private\repository/dbr/Macro/oracle.mcr,v 1.28 2007/03/01 08:13:19 JOTHOR Exp $
# Revision History: $Revision: 1.28 $
# Workfile        : $Workfile: oracle.mcr $
# Copyright info  : Copyright (c), Statoil ASA,Norway. $Date: 2007/03/01 08:13:19 $#
# Date            : 02.02.2001
# 
# Warning
#   This code is administered by SCCS. Please do not make alterations
# unless you extract the code from SCCS for editing.  
# If in doubt, please contact Statoil IT-OPP UBA
#
# Description
#**********************************************************************
# Contains the schema name
#**********************************************************************
#changequote(`',`')
#changequote(<&>,<%>)
define(SCHEMA,<&>SDE_IT<%>)
define(FRAMEWORK_SCHEMA,<&>SDE_IT<%>)
define(SUID_TYPE,<&>varchar2<%>)   # e.g dbr.well.well_s%type
define(SUID_TYPE_DEF,<&>varchar2(19)<%>)   # e.g dbr.well.well_s%type
define(TIMESTAMP_TYPE,<&>number<%>)   # e.g. dbr.casing_cutting.time_stamp%type
divert

