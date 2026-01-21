CREATE_PACKAGE_HEADER(treeManipulation)
authid current_user
is
/*****************************************************************
* Package Info
* Author        : $Author: JOTHOR $
* Original Date   : $Date: 2006/07/11 06:15:58 $
* Last Modified   : $Modtime: $
* Archive Name    : $Archive: $
* Description     : $Header: f:\private\repository/dbr/Procedure/treeManipulation.pck,v 2.1 2006/07/11 06:15:58 JOTHOR Exp $
* Revision History  : $Revision: 2.1 $
* Workfile      : $Workfile: $
* Copyright info  : Copyright (c), Statoil ASA,Norway. $Date: 2006/07/11 06:15:58 $
*****************************************************************
* Description
*
*
*****************************************************************
* Log
* Date  Description                                      Done by
*****************************************************************/
  subtype type_Name is varchar2(50);
  type t_cursor is ref cursor;

  PACKAGE_VARIABLE($Revision: 2.1 $);

  STD_PACKAGE_METHOD;

  function isInitialized return boolean;

/*****************************************************************
* Data access and manipulation methods 
*****************************************************************/
  FUNCTION(getTable) return type_Name;
  FUNCTION(getColumn) return type_Name;
  FUNCTION(getParent) return type_Name;
  PROCEDURE(setTable)(lTable varchar2);
  PROCEDURE(setColumn)(lColumn varchar2);
  PROCEDURE(setParent)(lParent varchar2);
  PROCEDURE(setConnectBy)(lConnectBy varchar2);

  PROCEDURE(setDetail)(lTable varchar2,lColumn varchar2, lParent varchar2);
  PROCEDURE(displayDetail);
  
  PROCEDURE(selectSet)(lCursor out t_cursor);

  PROCEDURE(deleteBranch)(lRoot varchar2,lElement varchar2);
END_CREATE_PACKAGE_HEADER;
