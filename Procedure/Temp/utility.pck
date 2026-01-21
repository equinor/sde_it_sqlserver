CREATE_PACKAGE_HEADER(Utility)
authid definer
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

  /***************************************************************
  * Bitwise functions
  * bitand - is a standard function in Oracle
  ***************************************************************/
  FUNCTION(bitor)( x in number, y in number ) return number;
  FUNCTION(bitxor)( x in number, y in number ) return number;

  /***************************************************************
  * Unit conversion function
  ***************************************************************/
  PROCEDURE(append)(lColumn in out varchar2,lStr varchar2);
  PROCEDURE(appendToList)(lColumn in out varchar2,lStr varchar2,lSeparator varchar2 default ',');
  PROCEDURE(appendToUniqueList)(lColumn in out varchar2,lStr varchar2,lSeparator varchar2 default ',');

  /***************************************************************
  * Unit conversion function
  ***************************************************************/
  FUNCTION(convertMetreToFeet)(lLength number) return number;
  FUNCTION(convertFeetToMetre)(lLength number) return number;
  FUNCTION(convertGPrCMToPSI)(lPressure number) return number;
  FUNCTION(convertCelsiusToFahrenheit)(lTemp number) return number;
  FUNCTION(convertFahrenheitToCelsius)(lTemp number) return number;

  /***************************************************************
  * Type conversion.
  * strToNumber  Converts the following strings to number
  *     -- 3 3/4  search for a space, split and calculate
  *     -- 3,75   substitute the comma with decimal point and calculate
  *     -- 3.75   normal conversion
  ***************************************************************/
  FUNCTION(strToNumber)(lStrNum varchar2) return number;

  /***************************************************************
  * Database function
  ***************************************************************/
  function hasChanged(
          lEntity varchar2
         ,lKey varchar2
         ,lSuid SUID_TYPE
         ,lTimestamp TIMESTAMP_TYPE
         ) return boolean;

  procedure deleteEntity(
          lEntity varchar2
         ,lSuidName varchar2
         ,lSuid SUID_TYPE
         ,lTimestamp TIMESTAMP_TYPE
         ,lRowcount out integer
         );

   function keyExist(
          lEntity varchar2
         ,lSuidName varchar2
         ,lSuid SUID_TYPE
         )
         return boolean;

-------------------------------------------------
-- Gets the next suid
-------------------------------------------------
--  function getNextSuid return pls_integer;

  /***************************************************************
  * Database schema information
  ***************************************************************/
  function getColumnSize(lSchema varchar2,lTable varchar2,lColumn varchar2) return integer;
  function getNrColumn(lSchema varchar2,lTable varchar2) return integer;
  function getNrTable(lSchema varchar2) return integer;

  function existColumn(lSchema varchar2,lTable varchar2,lColumn varchar2) return boolean;
  function existTable(lSchema varchar2,lTable varchar2) return boolean;


  function getDatabaseName return varchar2;
  function isProduction return char;
  function isTest return char;
  function isDevelopment return char;

  PROCEDURE(disableIndex)(lSchema varchar2,lTableName varchar2);
  PROCEDURE(rebuildIndex)(lSchema varchar2,lTableName varchar2);

  PROCEDURE(truncateTable)(lSchema varchar2,lTable varchar2);
  FUNCTION(existTable)(lSchema varchar2, lTableName varchar2) return boolean;
  PROCEDURE(executeStatement)(lSql varchar2);
  procedure createShadowTable(lSchema varchar2,lTableName varchar2,lShadowTableName varchar2,lDrop boolean default false);
  procedure getTable(lSchema varchar2,lTable varchar2,lCursor out t_cursor);

  /***************************************************************
  * The system may be deployed in various sites around the globe.
  * This function should return the site name.
  ***************************************************************/
  function getSite return varchar2;

  /***************************************************************
  * Sorting
  ***************************************************************/
   PROCEDURE(sort)(lList in out type_SortList,sortType integer default USE_QSORT);
   PROCEDURE(testSort);

END_CREATE_PACKAGE_HEADER;


