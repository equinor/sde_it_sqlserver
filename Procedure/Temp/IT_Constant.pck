CREATE_PACKAGE_HEADER(IT_Constant)
authid current_user
-- authid definer
is
/*****************************************************************
*  Package Info
* Author          : $Author: JOTHOR $
* Original Date   : $Date: 2007/03/08 10:32:57 $
* Last Modified   : $Modtime: $
* Archive Name    : $Archive: $
* Description     : $Header: f:\private\repository/dbr/Template/package_header.mal,v 1.5 2007/03/08 10:32:57 JOTHOR Exp $
* Revision History: $Revision: 1.5 $
* Tag name        : $Name:  $
* Workfile        : $Workfile: $
* Copyright info  : Copyright (c), Statoil ASA,Norway. $Date: 2007/03/08 10:32:57 $
*****************************************************************
* Description
*
*
*****************************************************************
* Log
* Date  Description                                      Done by
*****************************************************************/
  PACKAGE_VARIABLE($Revision: 1.5 $);

  type t_cursor is ref cursor;
  type list_string is table of varchar2(100);
  type list_integer is table of integer;
  type list_float is table of float;
  type list_number is table of number;

/*****************************************************************
* Enumeration for the various elements in a schema
*****************************************************************/
  subtype schemaElement is integer;

  X_SCHEMA constant integer := 0;
  X_TABLE constant integer := 1;
  X_COLUMN constant integer := 2;
  X_TYPE constant integer := 3;
  X_PROCEDURE constant integer := 4;
  X_FUNCTION constant integer := 5;
  X_PACKAGE_HEADER constant integer := 6;
  X_PACKAGE_BODY constant integer := 7;
  X_TRIGGER constant integer := 8;
  X_VIEW constant integer := 9;
  X_MATERIALIZED_VIEW constant integer := 10;
  X_DATABASE_LINK constant integer := 11;
  X_INDEX constant integer := 12;
  X_LOB constant integer := 13;
  X_SEQUENCE constant integer := 14;

/*****************************************************************
* General constants
*****************************************************************/
  xNotApplicable constant varchar2(10) := 'NA';
  xYes constant char(1) := 'Y';
  xNo constant char(1) := 'N';
  xTrue constant char(1) := 'Y';
  xFalse constant char(1) := 'N';

/*****************************************************************
* Databases in use
*****************************************************************/
  xDBProd constant varchar2(20) := 'P080';
  xDBTest constant varchar2(20) := 'T080';
  xDBDev  constant varchar2(20) := 'U080';

/*****************************************************************
* Sites where the system is deployed
*****************************************************************/
  xSiteStavanger constant varchar2(50) := 'Stavanger';
  xSiteHouston constant varchar2(50) := 'Houston';

  xSiteName constant varchar2(50) := xSiteStavanger;
--  xSiteName constant varchar2(50) := xSiteHouston;

/*****************************************************************
* Edin related constants
*****************************************************************/
  xEdinRootProd constant varchar2(200) := 'http://edin.statoil.no:7777';
  xEdinRootTest constant varchar2(200) := 'http://edintest.statoil.no:7777';
  xEdinRootDev  constant varchar2(200) := 'http://edindev.statoil.no:7777';

  xEdinProd constant varchar2(200) := xEdinRootProd||'/pls/edinprod';
  xEdinTest constant varchar2(200) := xEdinRootTest||'/pls/edintest';
  xEdinDev  constant varchar2(200) := xEdinRootDev||'/pls/edindev';

END_CREATE_PACKAGE_HEADER;
