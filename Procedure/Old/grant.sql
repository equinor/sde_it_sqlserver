/*****************************************************************
* SQL Info
* Author          : $Author: jothor $
* Original Date   : $Date: 2009/04/07 07:21:47 $
* Last Modified   : $Modtime: 20.12.05 15:26 $
* Archive Name    : $Archive: /DB/Utility.pcb $
* Description     : $Header: F:\Private\Repository/ITOPP-UBA/Development/Procedure/grant.sql,v 1.3 2009/04/07 07:21:47 jothor Exp $
* Revision History: $Revision: 1.3 $
* Workfile        : $Workfile: Utility.pcb $
* Copyright info  : Copyright (c), Statoil ASA,Norway. $Date: 2009/04/07 07:21:47 $
*****************************************************************
* Description
*  Grants access to common objects
* Required grants:
* drop/create sequence
* grant select,insert,delete,update,execute to user/role
* drop/create/alter trigger,view,table,procedure,package,function,type,view
* drop/create databaselink
* drop/create index,synonym
*****************************************************************/
grant execute on ErrorHandler to public;
grant execute on Utility to public;
grant execute on IT_Constant to public;
grant execute on SF_updateBatchStatus to public;
grant execute on SDE_Utility to public;
grant execute on manage_mail to public;
grant execute on grantToRbac to public;
grant execute on checkEpsilon to public;

GRANT insert,update,select ON TABLE_LOCK_HISTORY TO SDE;
grant insert,update,select on process_information_history to SDE;
GRANT insert,update,select ON compress_log TO SDE;

grant select on r_table_def to public;

----------------------------------------------
--Synonyms
----------------------------------------------
CREATE PUBLIC SYNONYM ERRORHANDLER FOR FRAMEWORK_SCHEMA.ERRORHANDLER;
CREATE PUBLIC SYNONYM IT_CONSTANT FOR FRAMEWORK_SCHEMA.IT_CONSTANT;
CREATE PUBLIC SYNONYM UTILITY FOR FRAMEWORK_SCHEMA.UTILITY;
CREATE PUBLIC SYNONYM SF_updateBatchStatus for FRAMEWORK_SCHEMA.SF_updateBatchStatus;
CREATE PUBLIC SYNONYM SDE_Utility for FRAMEWORK_SCHEMA.SDE_Utility;

