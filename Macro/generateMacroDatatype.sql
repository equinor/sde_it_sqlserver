/*****************************************************************
*  Program Info
*   Author          : $Author: JOTHOR $
*   Original Date   : $Date: 12.04.2023 $
*   Last Modified   : $Modtime: $
*   Archive Name    : $Archive: $
*   Description     : $Header:  $
*   Revision History: $Revision: 1.0 $
*   Tag name        : $Name:  $
*   Workfile        : $Workfile: $
*   Copyright       : $Equinor ASA: $
*****************************************************************
* Description
* Sql to generate a M4 macro library. Intended use is to 
* immitate Oracle "table.column%type", i.e should datatype change
* regenerate macro library and recompile procedures etc.
* E.g: For column in table, the macro is PLA_RES_DIAG.X_UNIT.
*	create function mytest (lName PLA_RES_DIAG.X_UNIT) ..
* expands to: create function mytest (lName varchar(256)) ..
*****************************************************************
* Log
* Date   Description                                        Done by
*
*****************************************************************/

SELECT 
'define(TYPE_'+table_name+'.'+column_name+',<&>'+data_type+
case when DATA_TYPE = 'numeric' then '('+cast(x.numeric_precision as nvarchar)+','+cast(x.numeric_scale as nvarchar) 
when DATA_TYPE = 'float' then ''
when DATA_TYPE in ('char','nchar','varchar','nvarchar') then '('+cast(	x.CHARACTER_MAXIMUM_LENGTH as nvarchar) +')'
when DATA_TYPE = 'bit' then ''
when DATA_TYPE = 'tinyint' then '('+cast(x.numeric_precision as nvarchar) +')'
when DATA_TYPE = 'smallint' then '('+cast(x.numeric_precision as nvarchar) +')'
when DATA_TYPE = 'int' then '('+cast(x.numeric_precision as nvarchar) +')'
when DATA_TYPE = 'integer' then ''
when DATA_TYPE = 'date' then ''
when DATA_TYPE = 'datetime' then '('+cast(x.datetime_precision as nvarchar) +')'
when DATA_TYPE = 'datetime2' then '('+cast(x.datetime_precision as nvarchar) +')'
when DATA_TYPE = 'varbinary' then '('+cast(x.CHARACTER_MAXIMUM_LENGTH as nvarchar) +')'
end +'<%>)' ,
column_name, data_type,*
FROM INFORMATION_SCHEMA.COLUMNS x
where TABLE_CATALOG ='TestGeoX' and TABLE_SCHEMA ='GEOX47';

/*

select   data_type,*
FROM INFORMATION_SCHEMA.COLUMNS x
--where DATA_TYPE ='bit'
--where TABLE_CATALOG ='TestGeoX' 
--and TABLE_SCHEMA ='GEOX47'
--and DATA_TYPE ='bit' And numeric_scale>0

*/