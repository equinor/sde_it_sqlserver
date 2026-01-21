CREATE_PROCEDURE(SCHEMA.recompileAllSchemasInvalid)
  is
/*****************************************************************
*  Procedure Info
*   Author          : $Author: JOTHOR $
*   Original Date   : $Date: $
*   Last Modified   : $Modtime: $
*   Archive Name    : $Archive: $
*   Description     : $Header:  $
*   Revision History: $Revision:  $
*   Tag name        : $Name:  $
*   Workfile        : $Workfile: $
*****************************************************************
* Description
*
*
*****************************************************************
* Log
* Date  Description					Done by
*
*****************************************************************/
  DECLARE_VARIABLE;

  type rec_schemaData is record(
     name varchar2(255)
    ,comment varchar2(255)
  );  
  type tab_schemaData is table of rec_schemaData;
    
  lSchemaData tab_schemaData := tab_schemaData();

  PROCEDURE(addItem)(lTable in out nocopy tab_schemaData ,lName varchar2, lComment varchar2 default null)
  is 
  begin
      lTable.extend(1);
      lTable(lTable.last).name := lName;
      lTable(lTable.last).comment := lComment;
  END_PROCEDURE;;
begin 
  addItem(lSchemaData,'ST_ARC');
  addItem(lSchemaData,'ST_GPA');
  addItem(lSchemaData,'IRAPPL');
  addItem(lSchemaData,'IRDATA');

  for i in lSchemaData.first..lSchemaData.last
  loop
      DEBUG('sde_it.recompile_invalid_objects('||lSchemaData(i).name||')'); --, '%', '%', 'INVALID' )');
    begin
       sde_it.recompile_invalid_objects(lSchemaData(i).name, '%', '%', 'INVALID' );
    exception
     CONSUME_EXCEPTION;
     end;
  end loop; 
END_PROCEDURE;

