CREATE_PROCEDURE(maintainUser)(lDesiredAction varchar2
   ,lUserName varchar2
   ,lRole varchar2 default null
   ,lProfile varchar2 default null
   ,lPw varchar2 default null
   ,lGrantQuota varchar2 default null
   ,lDryRun boolean default false
   )
--authid current_user
authid definer   
is
/*****************************************************************
* Package Info
* Author          : $Author: JOTHOR $
* Original Date   : $Date: 10.03.2022 $
* Last Modified   : $Modtime: $
* Archive Name    : $Archive: $
* Description     : $Header:  $
* Revision History: $Revision:  $
* Workfile        : $Workfile: $
* Copyright info  : Copyright (c), EQUINOR ASA,Norway. $Date:  $
*****************************************************************
* Description
* Prefix all table names with schema owner.
* See "processing_script.sql" for table and data setup 
*
* NOTE: Even all normal users are to be registered in AccessIT, there is the problem of A_KEYS.
* To solve this, all users wishing to have A_KEYS must registered the normal key first.
* This has to be renewed yearly. If not renewed, the job can drop/lock the normal key AND
* will also lock the A_KEY if present.
*
* NOTE: if "lDryRun" is true, no commits are performed. Remember to rollback afterwards.
*
* Requirements:
*   User must have: grant connect to {e.g FRAMEWORK_SCHEMA} with grant option;
*     create/drop user
*     create any table
*     create any view
*     create any index
*     create any sequence
*     select any dictionary
*     any roles to be managed by FRAMEWORK_SCHEMA (apart from CONNECT and those created 
*        by FRAMEWORK_SCHEMA itself) must be granted with admin option.
*        e.g.: grant xxrole to FRAMEWORK_SCHEMA with admin option;
*
*   All roles must be granted by one (1) user and one user only, 
*   otherwise revoking can not be done by this user.
*
* select username,account_status,created,lock_date,expiry_date 
*   from dba_users u where u.username like 'SVAZ%';
* select * from sys.dba_role_privs where grantee like 'SVAZ%';
*
* Permitted actions:
*  drop   drop user. errormessage giver is user does not exist.
*  lock   - lock user. errormessage giver is user does not exist.
*  open   - unlock user. errormessage giver is user does not exist.
*  add    - add user. if exists, creatation ignored and role,quota may be done
*  revoke - revoke role from user. user and role must exist.
*  grant  - grant role to user. user and role must exist.
*
* If lPw given, pw user created otherwise SSO user.
* If lGrantQuota provided, quota (may be - see code if active) given to user.
*        K is kilobytes
*        M is megabytes
*        G is gigabytes -- verify abbreviation
*        T  is terabytes (max 2TB)  -- verify abbreviation
*        unlimited  - avoid this.* 
* User is corrected to uppercase.
* 
* NOTE: Scripts must adhere to the following requirements:
* All scripts to end with "/" on a new line in the first column
* All comments must start with "--"  in the first column
* Not permitted to use double quotes
* 
* https://stackoverflow.com/questions/14328621/splitting-string-into-multiple-rows-in-oracle
*
* Testing:
  begin
   FRAMEWORK_SCHEMA.errorhandler.setlevel(5);
   ---- SSO user: Remember enclose name in double quotes e.g. "SHORTNAME@STATOIL.NET"
--   FRAMEWORK_SCHEMA.maintainUser('add',:lUser
--      ,lRole=>:lRolename
--      ,lProfile=>:lProfile,lPw=>:lPw
--      ,lGrantQuota=>:lQuota
--      ,lDryRun=>:lDryRun
--      );
--   FRAMEWORK_SCHEMA.maintainUser('add',:lUser,:lRolename,:lProfile,:lPw,:lQuota);
--   FRAMEWORK_SCHEMA.maintainUser('add',:lUser);
--   FRAMEWORK_SCHEMA.maintainUser('add',:lUser,:lRolename);
--   FRAMEWORK_SCHEMA.maintainUser('add',:lUser,lRole=>:lRolename,lGrantQuota=>:lQuota);
--   FRAMEWORK_SCHEMA.maintainUser('drop',:lUser);
--   FRAMEWORK_SCHEMA.maintainUser('grant',:lUser,:lRolename);
--   FRAMEWORK_SCHEMA.maintainUser('revoke',:lUser,:lRolename);
--   FRAMEWORK_SCHEMA.maintainUser('lock',:lUser);
--   FRAMEWORK_SCHEMA.maintainUser('open',:lUser);
   FRAMEWORK_SCHEMA.errorhandler.setlevel(1);
 exception
   when others then 
   FRAMEWORK_SCHEMA.errorhandler.setlevel(1);
   raise;  
 end;
*
* Check A-KEY and associated SSO-KEY
   select username as a_key,a_key_account_status
   ,(select username from dba_users x where x.username =substr(u.username,3)) as sso_key
   ,(select account_status from dba_users x where x.username =substr(u.username,3)) as sso_key_account_status
          from dba_users u
          where username like 'A\_%' escape '\'
          and account_status='OPEN'

* -- Username without the double quotes.
* select * from dba_users where username like 'TEST%'
* select * from dba_tables where owner like  'TEST%'
* select * from SYS.dba_role_privs where grantee like 'TEST%'
*
* Grant object to role:
* SDE database:
*  Check type (Dataset, Feature class, Feature class view, etc)
   select GT.NAME, g.* from SDE.GDB_ITEMS g
    inner join SDE.GDB_ITEMTYPES gt
    on g.type = GT.UUID
    where G.PHYSICALNAME like '%GLI_4326%'
    order by g.path
*****************************************************************
* Log
* Date   Description                                     Done by
* 171022 Upgraded handling of Lock/Drop code.            JOTHOR
* 181022 create user: Password now enclosed in double    JOTHOR
*  quotes.
* 171112 Now "authid definer". Added check to ensure     JOTHOR
*  the value "lSystem" has been set correctly.
*  Now performing a "commit" if lDryRun = false.
* 190123 Added consumer_exception for pre/post processing JOTHOR
* 070223 Checking username now modified to match exactly  JOTHOR
*  the search pattern using "^" and "$" to encase it.
*****************************************************************/
   STANDARD_VARIABLE;
   lSystem constant varchar2(10) := 'xxx';
   lAction varchar2(40) := null;
   lCount integer := 0;
   lGlobalName varchar2(50) := null;
   lSql varchar2(1000) := null;
   lUser varchar2(50) := null;
   lUser2 varchar2(50) := null;
   lUserStripped varchar2(50) := null;  -- username without the double quotes
   lUserExist boolean := false;
   lNrUsersIdentified integer := 0;
   
   lUserTablespace constant varchar2(50) := 'users';
   lDefaultUserProfile varchar2(50) :=  'EQ_END_USER_PROFILE';
   
   cursor cur_user(lUser varchar2) is
      select lUser as submitted_username
/*      ,case when regexp_like(lUser,'^A_'||lName.lShortname||'@STATOIL.NET') then 'A-KEY'
         when regexp_like(lUser,lName.lShortname||'@STATOIL.NET$') then 'SSO-KEY'
         else 'PW-KEY'
         end as submitted_type 
*/         
      ,case when lUser = 'A_'||lName.lShortname||'@STATOIL.NET' then 'A-KEY'
         when lUser = lName.lShortname||'@STATOIL.NET' then 'SSO-KEY'
         else 'PW-KEY'
         end as submitted_type         
      ,x.username as registered_name
      ,case when regexp_like(username,'^A_.+@STATOIL.NET') then 'A-KEY'
         when regexp_like(username,'.+@STATOIL.NET') then 'SSO-KEY'
         else 'PW-KEY'
         end as registered_type
      ,lName.lShortname
       --,x.*
      from all_users x
         ,(SELECT regexp_replace(lUser,'(^A_|@STATOIL.NET$)') as lShortname 
            from dual
          )  lName
      where regexp_like(username,'^A_'||lName.lShortname||'@STATOIL.NET$') -- checking for A key
      or regexp_like(username,'^'||lName.lShortname||'@STATOIL.NET$')      -- checking for SSO key
      or regexp_like(username,'^'||lName.lShortname||'$'); -- checking a PW key
  
   cursor cur_precreate(lSystem varchar2,lContainer varchar2)
      is select system_name,container_name,
          trim(column_value) sqlcode
         from FRAMEWORK_SCHEMA.processing_script,
      xmltable(('"'|| replace(pre_create, '/', '","')   || '"'))    
      where system_name = lSystem
      --and upper(pre_create_type) = 'SQL'
      and container_name = lContainer; 

   cursor cur_predelete(lSystem varchar2,lContainer varchar2)
      is select system_name,container_name,
          trim(column_value) sqlcode
         from FRAMEWORK_SCHEMA.processing_script,
      xmltable(('"'|| replace(pre_delete, '/', '","')   || '"'))    
      where system_name = lSystem
      --and upper(pre_create_type) = 'SQL'
      and container_name = lContainer; 
      
   cursor cur_postcreate(lSystem varchar2,lContainer varchar2)
      is select system_name,container_name,
          trim(column_value) sqlcode
         from FRAMEWORK_SCHEMA.processing_script,
      xmltable(('"'|| replace(post_create, '/', '","')   || '"'))    
      where system_name = lSystem
      --and upper(pre_create_type) = 'SQL'
      and container_name = lContainer; 

   cursor cur_postdelete(lSystem varchar2,lContainer varchar2)
      is select system_name,container_name,
          trim(column_value) sqlcode
         from FRAMEWORK_SCHEMA.processing_script,
      xmltable(('"'|| replace(post_delete, '/', '","')   || '"'))    
      where system_name = lSystem
      --and upper(pre_create_type) = 'SQL'
      and container_name = lContainer;      

   PROCEDURE(output)(lStr varchar2)
   is
   begin
      DEBUG('Sql: >'||lStr||'<.');
      if (lSql is null ) then
         DEBUG('lSql is null.');
         return;
      end if;
      dbms_output.put_line(lStr);
   END_PROCEDURE;        
   
   ------------------------------------------------------
   -- Outputs details about the user.
   ------------------------------------------------------
   PROCEDURE(listDetail)(lUser varchar2)
   is
   begin
      return;
   END_PROCEDURE;
      
   ------------------------------------------------------
   -- No sql command is less than 5 characters.
   ------------------------------------------------------
   PROCEDURE(executeSql)(lSql varchar2)
   is
   begin
      
      if (lSql is null or length(lSql) < 5) then
         DEBUG('lSql is null or length < 5.');
         return;
      end if;

      DEBUG('Sql: >'||lSql||'<.');
      if (lDryRun = false) then  
         execute immediate lSql;
      end if;
   END_PROCEDURE;  
   
   PROCEDURE(associateRoleUser)(lAction varchar2,lUser varchar2,lRole varchar2)
   is
     lCount integer := 0;
   begin
      if (lAction is null or lUser is null or lRole is null) then
         USERERROR(11,'action user or role');
      end if;
      
      select count(*) into lCount
         from sys.dba_roles
         where role=upper(lRole);
      
      if (lCount != 0) then
         if (lAction = 'grant') then 
            executeSql('grant '||lRole||' to '||lUser);
         elsif (lAction = 'revoke') then 
            executeSql('revoke '||lRole||' from '||lUser);
         else
             USERERROR(9,lAction,'grant,revoke');
         end if;
      else
         USERERROR(12,'role='||lRole);
      end if;
   END_PROCEDURE;
   
   --------------------------------------------------
   -- Not supplying "lUser" since more substitutes may
   -- come in the future. Simplifies things, but a bit
   -- stupid. Breaks the transfer of values across 
   -- procedures.
   --------------------------------------------------
   FUNCTION(preProcessSql)(lSql varchar2)
      return varchar2
   is
   begin
      return regexp_replace(lSql,'{username}',lUser);
   END_FUNCTION;
   
   PROCEDURE(preCreate)(lSystem varchar2,lContainer varchar2)
   is 
   begin
      DEBUG_ENTER;
      for i in cur_precreate(lSystem,lContainer)
      loop
         begin
            executeSql(i.sqlcode);
         EXCEPTION
            CONSUME_EXCEPTION_HANDLER;
         end;

      end loop;
      DEBUG_EXIT;
   END_PROCEDURE;
   
   PROCEDURE(preDelete)(lSystem varchar2,lContainer varchar2)
   is 
   begin
      DEBUG_ENTER;
      for i in cur_predelete(lSystem,lContainer)
      loop
         begin
            executeSql(i.sqlcode);
         EXCEPTION
            CONSUME_EXCEPTION_HANDLER;
         end;
      end loop;
      DEBUG_EXIT;
   END_PROCEDURE;
   
   PROCEDURE(postCreate)(lSystem varchar2,lContainer varchar2)
   is 
      lSql varchar2(4000);
   begin
      DEBUG_ENTER;
      for i in cur_postcreate(lSystem,lContainer)
      loop
         begin
            lSql := preProcessSql(i.sqlcode);
            executeSql(lSql);
         EXCEPTION
            CONSUME_EXCEPTION_HANDLER;
         end;
      end loop;
      DEBUG_EXIT;
   END_PROCEDURE;
   
   PROCEDURE(postDelete)(lSystem varchar2,lContainer varchar2)
   is 
   begin
      DEBUG_ENTER;
      for i in cur_postdelete(lSystem,lContainer)
      loop
         begin
            executeSql(i.sqlcode);
         EXCEPTION
            CONSUME_EXCEPTION_HANDLER;
         end;
      end loop;
      DEBUG_EXIT;
   END_PROCEDURE;

   PROCEDURE(updateUserInfo)(lAction varchar2,lUser varchar2)
   is
      lOpenDate date := current_date;
      lLockDate date := current_date;
      lCount integer := 0;
      lCleanUsername varchar2(100);
   begin
      if(lAction in ('add','open')) then
         lLockDate := null;
      elsif (lAction = 'lock') then
         lOpenDate := null;
      elsif (lAction = 'drop') then
         null;
      else 
         USERERROR(9,lAction,'add|drop|lock|open');
      end if;
      
      lCleanUsername := regexp_replace(lUser,'"');
      
      select count(*) into lCount
         from FRAMEWORK_SCHEMA.user_administration
         where username = lCleanUsername;
         
      if (lCount = 0) then
         insert into FRAMEWORK_SCHEMA.user_administration(username,open_date,lock_date)
            values(lCleanUsername,lOpenDate,lLockDate);
      elsif (lAction in ('lock','open')) then
         update FRAMEWORK_SCHEMA.user_administration
            set open_date = lOpenDate
               ,lock_date = lLockDate
            where username = lCleanUsername;
      elsif  (lAction in ('drop')) then
         delete from FRAMEWORK_SCHEMA.user_administration
            where username = lCleanUsername;
      end if;
      
      if (lDryRun = false) then
         commit;
      end if;
   END_PROCEDURE;
begin
   DEBUG_ENTER;
   DEBUG('lAction='||lDesiredAction||'; lUser='||lUserName||'; lRole='||coalesce(lRole,'null')||'; lPw=xxxx.');
   if (lDryRun) then
      DEBUG('Dry run. Remember to rollback or commit afterwards.');
   end if;

   -- Can be checked as this is executed as definer.
   if (user != 'FRAMEWORK_SCHEMA') then
      USERERROR(20,'Must be executed as FRAMEWORK_SCHEMA or procedure set as "authid definer".');
   end if;

   if (lSystem = 'xxx') then
      SYSTEMERROR(20,'Please set "lSystem" to the name as registered and to be used in PROCESSING_SCRIPT table.');
   end if;
   
   lUser := upper(lUserName);
   lAction := lower(lDesiredAction);
   
   -- Override default profile.
   if (lProfile is not null) then
      lDefaultUserProfile := lProfile;
   end if;
   
   ----------------------------------------------
   -- Remove double quotes (") when checking existence.
   -- Check if A-key is in focus or not.
   ----------------------------------------------
   lUserExist := false;
   lUserStripped := regexp_replace(lUser,'"');
   select count(*) into lNrUsersIdentified
      from all_users
      where username = lUserStripped;
   if (lNrUsersIdentified = 1) then
      lUserExist := true;
      DEBUG('User '||lUserStripped||' exists.');
   end if;
  
   if (lAction in ('drop','lock','open')) then
      if (lUserExist = false) then
         USERERROR(12,'user='||lUser);
      end if;
      
      if (lAction in ('drop','lock') ) then
         for i in cur_user(lUserStripped)
         loop
            if (i.registered_type in ('A-KEY','SSO-KEY') ) then
               lUser2 := '"'||i.registered_name||'"';
            else
               lUser2 := i.registered_name;
            end if;
            DEBUG(i.registered_type||' lUser2 = '||lUser2||'.');
            
            if (lAction = 'drop') then
               lSql := 'drop user '||lUser2|| ' cascade';
            elsif (lAction = 'lock') then
               lSql := 'alter user '||lUser2||' account lock';
            else
               SYSTEMERROR(9,lAction,'drop or lock');
            end if;

            DEBUG(lAction||': (submitted_type: '||i.submitted_type||') Checking '||i.registered_name||' type: '||i.registered_type||'.');
            DEBUG(lSql);
            if (i.submitted_type = 'SSO-KEY') then
               executeSql(lSql);
            elsif (i.submitted_type = 'A-KEY' and i.registered_type = 'A-KEY') then
               executeSql(lSql);
            elsif (i.submitted_type = 'PW-KEY' and i.registered_type = 'PW-KEY') then
               executeSql(lSql);
            end if;
         end loop;
      elsif (lAction = 'open') then
         executeSql('alter user '||lUser||' account unlock');
      else
          SYSTEMERROR(9,lAction,'drop or lock or open');
      end if;
      updateUserInfo(lAction,lUser);

      if (lDryRun = false) then
         commit;
      end if;
   elsif (lAction in ('add','revoke','grant') ) then
      -------------------------------------------------------
      -- Establish user and associate with role if supplied.
      -- Should supply "connect" role.
      -- Create user only if non-existent, but otherwise perform
      -- subsequent tasks associated with the adding.
      -------------------------------------------------------
      if (lAction in ('add') ) then
         if (lUserExist = false) then
            select global_name into lGlobalName 
               from global_name;
            
            preCreate(lSystem,lGlobalName);
            
            if (lPw is null) then
               lSql := 'create user '||lUser||' identified externally';
            else
               lSql := 'create user '||lUser||' identified by "'||lPw||'"';
            end if;
            lSql := lSql || ' default tablespace '||lUserTablespace
                    ||' temporary tablespace temp'
                    ||' profile '||lDefaultUserProfile
                    ||' account unlock';
            executeSql(lSql);
            lUserExist := true;
            
            -- Should one grant quota to user?
            -- D EBUG('Granting quota currently deactivated: '||lSql||'.');
            if (lGrantQuota is not null) then
               DEBUG('Granting quota : '||lGrantQuota||'.');
               lSql := 'alter user '||lUser||' quota '||lGrantQuota||' on '||lUserTablespace;
               executeSql(lSql);
            end if;
            
            -- Should one grant connect role to user? yes!
            DEBUG('Default granting of "connect" role.');
            associateRoleUser('grant',lUser,'connect');
            
            if (lRole is  not null) then
               associateRoleUser('grant',lUser,lRole);
            end if;
            postCreate(lSystem,lGlobalName);
            
            updateUserInfo(lAction,lUser);
            if (lDryRun = false) then
               commit;
            end if;
         end if;
         
         if (lRole is not null) then
            executeSql('grant '||lRole||' to '||lUser);
         end if;
      elsif (lAction in ('grant','revoke') and lRole is not null and lUserExist = true) then
         associateRoleUser(lAction,lUser,lRole);
      end if;
   else
      USERERROR(9,lAction,'drop|lock|open|add|grant|revoke');
   end if;

   if (lDryRun) then
      DEBUG('Dry run.');
   else
      commit;
   end if;
   DEBUG_EXIT;
EXCEPTION_BLOCK
   THROW_EXCEPTION_HANDLER;
END_PROCEDURE;  


/*************
-- Test maintainUser
declare 
  laction varchar2(32767);
  -- Note usage of double quotes in username (SSO user)!
  lusername varchar2(32767) := '"XXX@STATOIL.NET"';
  lrole varchar2(32767) := 'R_PUBLIC_INTERNAL';
  lpw varchar2(32767):= null;
  lgrantquota varchar2(32767):= null;
begin 
--
  FRAMEWORK_SCHEMA.errorhandler.setlevel(5);
  -- Create user
--  begin
--    FRAMEWORK_SCHEMA.maintainuser ( 'add',lusername,lrole );
--  exception when others then null;
--  end;
    -- Options on existing user.
--  FRAMEWORK_SCHEMA.maintainuser ( 'open',  lusername);
--  FRAMEWORK_SCHEMA.maintainuser ( 'lock',  lusername);
--  FRAMEWORK_SCHEMA.maintainuser ( 'grant', lusername,lrole );
--  FRAMEWORK_SCHEMA.maintainuser ( 'revoke',lusername,lrole );
--  FRAMEWORK_SCHEMA.maintainuser ( 'drop',  lusername);
  commit; 
  FRAMEWORK_SCHEMA.errorhandler.setlevel(1);
exception when others then
  FRAMEWORK_SCHEMA.errorhandler.setlevel(1);
  raise;  
end; 

select * from dba_users where username ='XXX@STATOIL.NET';
select * from FRAMEWORK_SCHEMA.user_administration where username like 'XXX%'
select * from dba_role_privs where grantee ='XXX@STATOIL.NET';
select * from dba_objects where owner ='XXX@STATOIL.NET';

--==========================================================================

---------------------------------------------------
-- Preload user_administration with current setup
---------------------------------------------------
insert into FRAMEWORK_SCHEMA.user_administration(username,open_date,lock_date)
select username
  ,case when account_status = 'OPEN' then current_date else null end  as opendate
  ,case when account_status LIKE  '%LOCKED' then LOCK_DATE else null end  as lockdate
  from dba_users
  where username like '%@STATOIL.NET';


---------------------------------------------------
-- As "F_RBAC_MGR@STATOIL.NET"
-- All roles created by the above user must be "transferred"
-- to target user. This is done by using the below 
-- generated grants.
---------------------------------------------------
   select 'grant '||role||' to FRAMEWORK_SCHEMA with admin option;' 
     from dba_roles where regexp_like(role,'^R_')
  
---------------------------------------------------
-- Grant privileges to FRAMEWORK_SCHEMA with grant option in each schema
---------------------------------------------------
--------------------------------------------
-- Generic – generates grants the set of objects
-- for any given schema (taken from RBAC document
-- "How to insert a new system - the hard way.docx")
--------------------------------------------
   with xobj as (select owner,object_name,object_type
       from all_objects
       where object_type in ('TABLE','VIEW','PACKAGE','FUNCTION','PROCEDURE')
       and object_name not like 'BIN$%$0'
       and owner = upper(:schema)
   )
   ,sde_versioned_view as (select to_char(owner) as owner,to_char(imv_view_name) as object_name,'SDE_VERSIONED_VIEW' as object_type
       from sde.table_registry tr
       where tr.imv_view_name is not null 
       --and tr.imv_view_name like '%5340%1'
       and owner = upper(:schema)
   )
   ,xsdeSpecific as (select tr.owner,table_name,tr.registration_id,x.object_type
      from sde.table_registry tr
        inner join xobj x
          on x.object_name = tr.table_name
          and x.owner = tr.owner 
      where exists (select 1 from all_objects 
         where owner=tr.owner
         and regexp_like(object_name,'(A|D|S)'||tr.registration_id||'(_IDX$){0,1}')
         )
   )
   ,xAtable as (select to_char(owner) as owner,'A'||registration_id as object_name,object_type from xsdeSpecific)
   ,xDtable as (select to_char(owner) as owner,'D'||registration_id as object_name,object_type from xsdeSpecific)
   ,xset as (select owner,object_name,object_type
       from xobj
       where owner||'.'||object_name  not in (select owner||'.'||object_name from sde_versioned_view)
       union
       select owner,object_name,object_type from sde_versioned_view
       union
       select  owner,object_name,object_type from xAtable
       union
       select  owner,object_name,object_type from xDtable
   )
   ,xIndextable as (select x.owner,'S'||gu.index_id||'_IDX$' as object_name,x.object_type
      from sde.st_geometry_index gu
            inner join xset x
           on x.object_name = gu.table_name
           and x.owner= gu.owner
   )
   ,xres as (    select  owner,object_name,object_type from xset
       union
       select  owner,object_name,object_type from xIndextable
   )            
   select 'grant '||
       case when object_type in ('TABLE','SDE_VERSIONED_VIEW') then 
       'SELECT,INSERT,UPDATE,DELETE'
       when object_type in ('VIEW') then 
       'SELECT'
       -- 'SELECT,INSERT,UPDATE,DELETE'
       ELSE
       'EXECUTE'
       END
       || ' ON '||owner||'.'||OBJECT_NAME||' TO '||:targetUser||' with grant option;'
   from xres
   order by owner,object_type,object_name;

---------------------------------------------------
-- As FRAMEWORK_SCHEMA: Identify owner,role,object,privilege
-- Transfer grants to role(s) to FRAMEWORK_SCHEMA
-- Revoke grants from original grantor.
---------------------------------------------------
   with roles as
     (select distinct granted_role
      from (select granted_role, grantee
            from dba_role_privs
            connect by grantee = prior granted_role
            start with regexp_like(grantee,:own)
            --start with grantee =:own
            )
     )
   ,xpriv as (select  distinct dtp.privilege, dtp.grantable, dtp.grantee,
          dtp.grantor, dtp.owner, dtp.type as object_type, dtp.table_name as object_name, null as column_name
      from   sys.dba_tab_privs dtp, roles
      where dtp.grantee = roles.granted_role
      union all
      select  distinct dcp.privilege, dcp.grantable, dcp.grantee, dcp.grantor,
             dbo.owner, dbo.object_type, dbo.object_name, dcp.column_name
      from  dba_col_privs dcp, dba_objects dbo, roles
      where dcp.owner = dbo.owner
      and   dcp.table_name = dbo.object_name
      and   dcp.grantee = roles.granted_role
      and   dbo.object_type in ('TABLE', 'VIEW', 'PROCEDURE','FUNCTION','PACKAGE') --'SNAPSHOT', 'MATERIALIZED VIEW')
      union all
      select  distinct dtp.privilege, dtp.grantable, dtp.grantee,
             dtp.grantor, dtp.owner, dtp.type as object_type, dtp.table_name as object_name, null as column_name
      from   sys.dba_tab_privs dtp
      where regexp_like(dtp.grantee,:own) 
            --dtp.grantee = :own
      union all
      select  distinct dcp.privilege, dcp.grantable, dcp.grantee, dcp.grantor,
             dbo.owner, dbo.object_type, dbo.object_name, dcp.column_name
      from  dba_col_privs dcp, dba_objects dbo
      where dcp.owner = dbo.owner
      and   dcp.table_name = dbo.object_name
      and   regexp_like(dcp.grantee,:own)
      --and   dcp.grantee = :own
      and   dbo.object_type in ('TABLE', 'VIEW', 'PROCEDURE','FUNCTION','PACKAGE') --'SNAPSHOT', 'MATERIALIZED VIEW')
   )
   select
       'grant '||privilege||' on '||owner||'.'||object_name||' to '||grantee||';' as  gra
      -- ,'revoke '||privilege||' on '||owner||'.'||object_name||' from '||grantor||';' as rev
       ,x.*
     from xpriv x
     where object_name not like 'BIN$%$0' 
     and grantor = 'F_RBAC_MGR@STATOIL.NET'
     and object_name like '%' --'EPDS_COMPANY'
     order by grantee,owner,object_name,grantor

*************/
