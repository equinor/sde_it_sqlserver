CREATE_PACKAGE_HEADER(AuditTrigger_helper)
authid current_user
-- authid definer
is
/*****************************************************************
* Package Info
* Author          : $Author: jothor $
* Original Date   : $Date: 2010/10/22 12:00:43 $
* Last Modified   : $Modtime: $
* Archive Name    : $Archive: $
* Description     : $Header: f:\private\repository/dbr/Jobs/AuditSdeTable/AuditTrigger_helper_rowidversion.pck,v 1.1 2010/10/22 12:00:43 jothor Exp $
* Revision History: $Revision: 1.1 $
* Tag name        : $Name:  $
* Workfile        : $Workfile: $
* Copyright info  : Copyright (c), Statoil ASA,Norway. $Date: 2010/10/22 12:00:43 $
*****************************************************************
* Description
*
* Ref: http://asktom.oracle.com/pls/asktom/ASKTOM.download_file?p_file=6551198119097816936
* We must set the state of the above package to some known, consistent state
* before we being processing the row triggers.  This trigger is mandatory,
* we *cannot* rely on the AFTER trigger to reset the package state.  This
* is because during a multi-row insert or update, the ROW trigger may fire
* but the AFTER tirgger does not have to fire -- if the second row in an update
* fails due to some constraint error -- the row trigger will have fired 2 times
* but the AFTER trigger (which we relied on to reset the package) will never fire.
* That would leave 2 erroneous rowids in the newRows array for the next insert/update
* to see.   Therefore, before the insert / update takes place, we 'reset'
*
* NOTE on Exceptions
* ------------------
* Since this package is to be used by triggers, it will only throw exceptions. 
*****************************************************************
* Log
* Date  Description                                      Done by
*****************************************************************/

/*****************************************************************
* Variable
*****************************************************************/
  PACKAGE_VARIABLE($Revision: 1.1 $);
  subtype type_sdeStateId is number;
  subtype type_ObjectId is number;

  STD_PACKAGE_METHOD;

  function isInitialized return boolean;

/*****************************************************************
* Data access and manipulation methods 
* reset - releases the resources and sets up for new use.
* addKey - collection of keys to identify rows.
* performUpdate - performs the actual update.
* display - displays info in stored via the addKey procedure
*     and other information of interest.
*****************************************************************/
  PROCEDURE(reset)(lParentTable varchar2 default '',lDeltaTableName varchar2 default '',lPrimaryKeyName varchar2 default 'objectid');
  PROCEDURE(addKey)(lSdeStateId type_sdeStateId,lObjectId type_ObjectId,isInsert boolean default true);
  PROCEDURE(performUpdate);
  PROCEDURE(display);
END_CREATE_PACKAGE_HEADER;
