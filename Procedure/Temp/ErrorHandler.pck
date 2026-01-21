CREATE_PACKAGE_HEADER(ErrorHandler)
authid definer
is
/*****************************************************************
* Package Info
* Author          : $Author: JOTHOR $
* Original Date   : $Date: 2006/01/09 12:02:18 $
* Last Modified   : $Modtime: 20.12.05 15:33 $
* Archive Name    : $Archive: /DB/ErrorHandler.pck $
* Description     : $Header: F:/Private/Repository/dbr/Procedure/ErrorHandler.pck,v 2.2 2006/01/09 12:02:18 JOTHOR Exp $
* Revision History: $Revision: 2.2 $
* Workfile        : $Workfile: ErrorHandler.pck $
* Copyright info  : Copyright (c), Statoil ASA,Norway. $Date: 2006/01/09 12:02:18 $
*****************************************************************
* Description
*
* getMessage can be used in two different ways:
*   supplying values for one or more lPara via addParam 
*   will imply ignoring whatever is supplied via the lPara1..n in the
*   procedures parameter list. All values added via addParam are removed
*   once the call has completed.
*   If no values have been added via the addParam, the parameter list
*   (lPara1..n) procedures parameter list will be used.
*  e.g using addParam
*	errorhandler.addParam('table name = well');
*	errorhandler.addParam('table name = wellbore');
*	lMessage := getMessage(1);
*  e.g using parameter list
*	lMessage := getMessage(1,'table name = well','table name = wellbore');
*
* Logging levels:
* logging_off
* level_high
* level_medium
* level_low
* level_info  - this is the standard debug level.
* level_trace
*
*****************************************************************
* Log
* Date  Description                                      Done by
*****************************************************************/
  PACKAGE_VARIABLE($Revision: 2.2 $);
  logging_off constant pls_integer := 0;
  level_high constant pls_integer := 1;
  level_medium constant pls_integer := 2;
  level_low constant pls_integer := 3;
  level_info constant pls_integer := 4;
  level_trace constant pls_integer := 5;

  STATEFUL;

  STD_PACKAGE_METHOD;

  /*********************************************
  * These methods are locked to schema owner
  *********************************************/
  function addMessage(lId varchar2,lMessage varchar2,lDescription varchar2 default null) return varchar2;
  function setMessage(lId varchar2,lMessage varchar2,lDescription varchar2 default null) return varchar2;

  /*********************************************
  * These are public methods for errorhandling services
  * setLevel: set the level at which logging shall occur. 
  *   Applies also to debug.
  *********************************************/
  procedure addParam(lParam varchar2);
  function getMessage(lId varchar2,lPara1 varchar2 default null,lPara2 varchar2 default null,lPara3 varchar2 default null,lPara4 varchar2 default null,lPara5 varchar2 default null) return varchar2;

  procedure logError(lLevel integer,lApplication varchar2,lVersion varchar2,lMessage varchar2,lHost varchar2 default 'NA');

  procedure setLevel(lLevel integer);
  function getLevel return integer;

  /*********************************************
  * These are for setting/getting warnings
  * Only one warning is present
  * It is possible to append to an existing warning
  * Max string length is the same as for the column
  * t_basis_clienterrorlog.MessageText
  *********************************************/
  function getWarning return varchar2;
  procedure setWarning(lMessage varchar2 default null);
  procedure appendWarning(lMessage varchar2);

  /*********************************************
  * These are public methods for debugging
  *********************************************/
  procedure debug(lLevel integer,lMessage varchar2);
END_CREATE_PACKAGE_HEADER;

