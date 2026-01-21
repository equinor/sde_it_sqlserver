/*********************************************************
 * Author: JOTHORTestGeoX
 * Date: 300323
 * Source: https://techcommunity.microsoft.com/t5/sql-server-blog/how-to-create-an-autonomous-transaction-in-sql-server-2008/ba-p/383471
 *********************************************************/

CREATE TABLE geox_cache.ErrorLogging (id integer identity, logTime DATETIME, msg VARCHAR(255));
CREATE TABLE geox_cache.TestAT (id INT identity PRIMARY KEY,ltext nvarchar(30));

/*
truncate TABLE geox_cache.TestAT;
truncate TABLE geox_cache.ErrorLogging;

drop TABLE geox_cache.TestAT;
drop TABLE geox_cache.ErrorLogging;
*/
alter TABLE geox_cache.[TestAT] alter column [id] integer  not null

alter TABLE geox_cache.TestAT add primary key (id);

CREATE or alter PROCEDURE geox_cache.usp_ErrorLogging
@errNumber INT
AS
begin
	BEGIN  TRAN AutonomousErrorlog
	INSERT INTO geox_cache.ErrorLogging VALUES (GETDATE(), 'Error ' + CAST(@errNumber AS VARCHAR(8)) +' occurred.');
	COMMIT  TRAN AutonomousErrorlog;
end;


create or alter  PROCEDURE geox_cache.testAutonomous as
begin
	DECLARE @ERROR AS INT;
	INSERT INTO geox_cache.TestAT(id,ltext) VALUES (1,'a');
	BEGIN TRAN a
		begin try
		INSERT INTO geox_cache.TestAT(id,ltext) VALUES (1,'should not be here.'); -- This will raise primary key constraint violation error
--		
		end try begin catch
		SELECT @ERROR = @@ERROR;
		IF @ERROR <> 0
		BEGIN
			print('In innertran reporting error.')
			EXEC geox_cache.usp_ErrorLogging @ERROR;
		END;
	    end catch;
  ROLLBACK TRAN a;
   IF @@TRANCOUNT > 0 COMMIT TRAN a;
end;

exec  geox_cache.testAutonomous;

begin
	exec  geox_cache.testAutonomous;
	print 'Trancount '+ cast(@@TRANCOUNT as nvarchar)+'.';
	IF @@TRANCOUNT > 0 
	begin
		rollback;
		print 'Roling back';
	end;
	else 
		print 'NO Rolling back ****';
end;


SELECT * FROM geox_cache.TestAT;

SELECT * FROM geox_c
ache.ErrorLogging order by id desc;

delete FROM geox_cache.TestAT;
delete FROM geox_cache.ErrorLogging;
