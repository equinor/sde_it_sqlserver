/*****************************************************************
*  Package Info
*   Author          : $Author: JOTHOR $
*   Original Date   : $Date: 2026-03-18 $
*   Last Modified   : $Modtime: $
*   Archive Name    : $Archive: $
*   Description     : $Header:  $
*   Revision History: $Revision: $
*   Tag name        : $Name:  $
*   Workfile        : $Workfile: $
*   Copyright       : $Equinor ASA: $
*****************************************************************
* Description
* Displays 
*****************************************************************
* Log
* Date   Description                                     Done by
* 
*****************************************************************/
CREATE_VIEW(SCHEMA.v_rbac_permission)
as
select ob.db_name
      ,ob.schema_name
      ,r.name as role_name
      ,ob.name as object_name
      ,ob.xtype as object_type
      ,perm.xselect
      ,perm.xupdate
      ,perm.xinsert
      ,perm.xdelete
      ,perm.xexecute
      ,perm.xcreate
      ,perm.xdrop
      ,perm.xenable
      ,perm.xdisable
      -- primary keys
      ,ob.db_st_id
      ,ob.schema_st_id
      ,perm.rbac_role_st_id 
      ,ob.st_id as rbac_object_st_id
      ,perm.st_id as rbac_permission_st_id
   from SCHEMA.rbac_permission perm
   inner join SCHEMA.v_rbac_object ob
       on perm.rbac_object_st_id =ob.st_id
   inner join SCHEMA.rbac_role r
       on r.st_id = perm.rbac_role_st_id;