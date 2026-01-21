CREATE_PACKAGE_HEADER(SDE_Utility)
 authid current_user
--authid definer
is
/*****************************************************************
*  Package Info
* Author          : $Author: jothor $
* Original Date   : $Date: 2011/03/01 13:35:52 $
* Last Modified   : $Modtime: $
* Archive Name    : $Archive: $
* Description     : $Header: F:\Private\Repository/ITOPP-UBA/Gis/Procedure/SDE_Utility.pck,v 1.4 2011/03/01 13:35:52 jothor Exp $
* Revision History: $Revision: 1.4 $
* Tag name        : $Name:  $
* Workfile        : $Workfile: $
* Copyright info  : Copyright (c), Statoil ASA,Norway. $Date: 2011/03/01 13:35:52 $
*****************************************************************
* Description
* Execute privilege to be granted to public.
*
*****************************************************************
* Log
* Date  Description                                      Done by
*****************************************************************/
  PACKAGE_VARIABLE($Revision: 1.4 $);

  STD_PACKAGE_METHOD;

  function isInitialized return boolean;

/*****************************************************************
* Given the feature class, it finds the associated A-table
* If it does not exist, null is returned.
*****************************************************************/
   FUNCTION(sdeFind_A_table)(lFeatureClass sde.table_registry.table_name%type)
      return sde.table_registry.table_name%type;

/*****************************************************************
* These methods are to be executed as user SDE.
* if lDryRun = true, no action taken but all intended actions will be logged.
*****************************************************************/
   PROCEDURE(removeOrphanedKeyset) (lDryRun boolean default false);
   PROCEDURE(removeSDEOrphanes) (lDryRun boolean default false);
   PROCEDURE(removeOrphanedTableLock) (lDryRun boolean default false);
   PROCEDURE(removeOrphanedProcess) (lDryRun boolean default false);
   PROCEDURE(removeOrphanedProcess) (lStartDate date, lEndDate date,lDryRun boolean default false);
   PROCEDURE(removeOrphanedProcess) (lNodeName varchar2,lDryRun boolean default false);
END_CREATE_PACKAGE_HEADER;
