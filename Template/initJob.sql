/********************************************************
* Written by: Johan Thorsen
* Company: Statoil ASA
* Date : 1600816
********************************************************
* Description
* All jobs must start with a lJobPrefix. It is a grouping identifier.
* This so as they can be identified and removed prior to recreating the jobs. 
*
* See for details: http://docs.oracle.com/cd/B28359_01/appdev.111/b28419/d_sched.htm#i1013037 
* frequency_clause = "FREQ" "=" ( predefined_frequency | user_defined_frequency )
* predefined_frequency = "YEARLY" | "MONTHLY" | "WEEKLY" | "DAILY" | 
*   "HOURLY" | "MINUTELY" | "SECONDLY"
* Initiate jobs 
*   to_date('04.11.2008 18:00:00','dd.mm.yyyy hh24:mi:ss')
********************************************************
* Log
* Date   Description                            Done by
********************************************************/
set define on
set feed on

---------------------------------------
-- Remove all jobs starting with lJobPrefix
-- This is to be done prior to creating the jobs.
---------------------------------------
declare
  cursor cur_job(lJobPrefix varchar2)
  is 
    select job
      from all_jobs
      where what like lJobPrefix||'%';
  x number;
  lHour integer := 1; 
  lJobPrefix varchar2(50) := '/*Cleanup logs */'; 
begin
  for i in cur_job(lJobPrefix(
  loop
    dbms_output.put_line('Removing job nr'||i.job||' prefix=<'||lJobPrefix||'>');
    dbms_job.remove(i.job);
  end loop;
--  
  sys.dbms_job.submit
    ( job       => x 
     ,what      => lJobPrefix
	       || ' begin'
		   || '  cleanUpTransitTable;'
		   || ' end;'
     ,next_date => trunc(sysdate+1)+20/24
     ,interval  => 'trunc(sysdate+1)+20/24'
     ,no_parse  => true
    );
--  sys.dbms_output.put_line('Job prefix is: <'||lJobPrefix||'>');
  sys.dbms_output.put_line('Job cleanUpTransitTable, number is: ' || to_char(x));
  commit;
end;

