CREATE_PACKAGE_HEADER(Common)
authid current_user
is
/*****************************************************************
*  Package Info
* Author          : $Author: JOTHOR $
* Original Date   : $Date: 2006/08/08 13:00:29 $
* Last Modified   : $Modtime: 20.12.05 15:27 $
* Archive Name    : $Archive: /DB/Utility.pck $
* Description     : $Header: f:\private\repository/dbr/Procedure/utility.pck,v 2.9 2006/08/08 13:00:29 JOTHOR Exp $
* Revision History: $Revision: 2.9 $
* Workfile        : $Workfile: Utility.pck $
* Copyright info  : Copyright (c), Statoil ASA,Norway. $Date: 2006/08/08 13:00:29 $
*****************************************************************
* Description
*  This is a support package. Just throw exceptions, do not rollback.
*
*****************************************************************
* Log
* Date   Description                                        Done by
* 080806 Added new method getTable                          JOTHOR
*****************************************************************/
  PACKAGE_VARIABLE($Revision: 2.9 $);

  -----------------------------------------------------
  -- Type and variable
  -- t_cursor
  -- Choose type of sort
  -----------------------------------------------------
  type t_cursor is ref cursor;
  type type_SortList is table of integer; -- for use with sort
  USE_QSORT integer;  -- default

  STD_PACKAGE_METHOD;

  function isInitialized return boolean;

  procedure executeStatement (lStatement varchar2,lDryRun boolean default false);
  --procedure executeProcedure (lProcedure varchar2,lDryRun boolean default false);

END_CREATE_PACKAGE_HEADER;


