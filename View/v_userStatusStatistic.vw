/*****************************************************************
*  Package Info
* Author          : $Author: jothor $
* Original Date   : $Date: 2021/12/06 08:21:56 $
* Last Modified   : $Modtime: $
* Archive Name    : $Archive: $
* Description     : $Header:  $
* Revision History: $Revision: 1.1 $
* Workfile        : $Workfile: $
* Copyright info  : Copyright (c), Equinor ASA,Norway. $Date: 2021/12/06 08:21:56 $
*****************************************************************
* Description
* Presents user creatation statistics
*
*****************************************************************
* Log
* Date  Description                                      Done by
*
*****************************************************************/
create or replace view v_userStatusStatistic
as
select 'created' as topic 
,extract(year from created) as year
      ,round(created,'MM') as month
      ,count(*) as created_this_month
   from dba_users u
   where u.oracle_maintained ='N'
   group by rollup (extract(year from created),round(created,'MM'))
union
select 'locked' as topic 
,extract(year from lock_date) as year
      ,round(lock_date,'MM') as month
      ,count(*) as locked_this_month
   from dba_users u
   where u.oracle_maintained ='N'
   and lock_date is not null
   group by rollup (extract(year from lock_date),round(lock_date,'MM')); 
