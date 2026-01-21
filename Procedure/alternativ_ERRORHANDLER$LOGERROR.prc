CREATE PROCEDURE SDE_IT.errorhandler$logerror  
   @llevel int,
   @lapplication varchar(max),
   @lversion varchar(max),
   @lmessage varchar(max)
as 
   begin

      declare
         @active_spid int, 
         @login_time datetime, 
         @db_name nvarchar(128)

      set @active_spid = @@SPID; -- ssma_oracle.get_active_spid()

      set @login_time = ssma_oracle.get_active_login_time()

      set @db_name = db_name()

      execute master.dbo.xp_ora2ms_exec2_ex 
         @active_spid, 
         @login_time, 
         @db_name, 
         n'sde_it', 
         n'errorhandler$logerror$impl', 
         n'false', 
         @llevel, 
         @lapplication, 
         @lversion, 
         @lmessage

   end
go

CREATE PROCEDURE SDE_IT.ERRORHANDLER$LOGERROR$IMPL  
   @LLEVEL int,
   @LAPPLICATION varchar(max),
   @LVERSION varchar(max),
   @LMESSAGE varchar(max)
AS 
   BEGIN

      SET  IMPLICIT_TRANSACTIONS  ON

      DECLARE
         @LSTR varchar(4000), 
         @LVER varchar(50)

      BEGIN TRY

         EXECUTE ssma_oracle.db_check_init_package 'SDE_IT', 'ERRORHANDLER'

         IF (@LLEVEL != SDE_IT.ERRORHANDLER$C$LEVEL_HIGH() AND @LLEVEL > ssma_oracle.get_pv_int('SDE_IT', 'ERRORHANDLER', 'XLEVEL'))
            RETURN 

         IF (@LMESSAGE IS NULL OR @LMESSAGE = '')
            SET @LSTR = 'N/A'
         ELSE 
            IF (ssma_oracle.length_varchar(@LMESSAGE) > SDE_IT.ERRORHANDLER$GETMAXMESSAGELENGTH())
               /*
               *   SSMA warning messages:
               *   O2SS0273: Oracle SUBSTR function and SQL Server SUBSTRING function may give different results.
               */

               SET @LSTR = substring(@LMESSAGE, 1, SDE_IT.ERRORHANDLER$GETMAXMESSAGELENGTH())
            ELSE 
               SET @LSTR = @LMESSAGE

         IF (@LVERSION IS NULL OR @LVERSION = '')
            SET @LVER = 'N/A'
         ELSE 
            SET @LVER = @LVERSION

         BEGIN

            BEGIN TRY

               INSERT SDE_IT.T_BASIS_CLIENTERRORLOG(
                  APPLICATIONNAME, 
                  APPLICATIONVERSION, 
                  USERREGISTERED, 
                  MESSAGECODE, 
                  MESSAGETEXT)
                  VALUES (
                     @LAPPLICATION, 
                     @LVER, 
                     session_user, 
                     @LLEVEL, 
                     @LSTR)

               GOTO LE_END_GOTO

               LE_FINISH_GOTO:

               DECLARE
                  @db_null_statement int

               LE_END_GOTO:

               DECLARE
                  @db_null_statement$2 int

            END TRY

            BEGIN CATCH

               DECLARE
                  @errornumber int

               SET @errornumber = ERROR_NUMBER()

               DECLARE
                  @errormessage nvarchar(4000)

               SET @errormessage = ERROR_MESSAGE()

               DECLARE
                  @exceptionidentifier nvarchar(4000)

               SELECT @exceptionidentifier = ssma_oracle.db_error_get_oracle_exception_id(@errormessage, @errornumber)

               BEGIN/* l_consume_exception_handler*/

                  IF (ssma_oracle.db_error_sqlcode(@exceptionidentifier, @errornumber) NOT IN ( -20003, -20002, -20001 ))
                     BEGIN

                        DECLARE
                           @temp integer

                        SET @temp = ssma_oracle.db_error_sqlcode(@exceptionidentifier, @errornumber)

                        EXECUTE ssma_oracle.set_pv_float 'SDE_IT', 'ERRORHANDLER', 'Z_STATUS', @temp

                        IF (ssma_oracle.get_pv_varchar('SDE_IT', 'ERRORHANDLER', 'Z_ERRORTEXT') IS NULL)
                           BEGIN

                              DECLARE
                                 @temp$2 varchar(8000)

                              SET @temp$2 = substring('logError: ' + ISNULL(ssma_oracle.db_error_sqlerrm_0(@exceptionidentifier, @errornumber), ''), 1, 255)

                              EXECUTE ssma_oracle.set_pv_varchar 'SDE_IT', 'ERRORHANDLER', 'Z_ERRORTEXT', @temp$2

                           END

                     END

                  EXECUTE ssma_oracle.set_pv_int 'SDE_IT', 'ERRORHANDLER', 'Z_ISLOGGED', 0/*LO G(1,SQLERRM)*/

               END

            END CATCH

         END

         IF @@TRANCOUNT > 0
            COMMIT TRANSACTION 

         GOTO LE_END_GOTO$2

         LE_FINISH_GOTO$2:

         DECLARE
            @db_null_statement$3 int

         LE_END_GOTO$2:

         DECLARE
            @db_null_statement$4 int

      END TRY

      BEGIN CATCH

         DECLARE
            @errornumber$2 int

         SET @errornumber$2 = ERROR_NUMBER()

         DECLARE
            @errormessage$2 nvarchar(4000)

         SET @errormessage$2 = ERROR_MESSAGE()

         DECLARE
            @exceptionidentifier$2 nvarchar(4000)

         SELECT @exceptionidentifier$2 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$2, @errornumber$2)

         BEGIN/* l_consume_exception_handler*/

            IF (ssma_oracle.db_error_sqlcode(@exceptionidentifier$2, @errornumber$2) NOT IN ( -20003, -20002, -20001 ))
               BEGIN

                  DECLARE
                     @temp$3 integer

                  SET @temp$3 = ssma_oracle.db_error_sqlcode(@exceptionidentifier$2, @errornumber$2)

                  EXECUTE ssma_oracle.set_pv_float 'SDE_IT', 'ERRORHANDLER', 'Z_STATUS', @temp$3

                  IF (ssma_oracle.get_pv_varchar('SDE_IT', 'ERRORHANDLER', 'Z_ERRORTEXT') IS NULL)
                     BEGIN

                        DECLARE
                           @temp$4 varchar(8000)

                        SET @temp$4 = substring('logError: ' + ISNULL(ssma_oracle.db_error_sqlerrm_0(@exceptionidentifier$2, @errornumber$2), ''), 1, 255)

                        EXECUTE ssma_oracle.set_pv_varchar 'SDE_IT', 'ERRORHANDLER', 'Z_ERRORTEXT', @temp$4

                     END

               END

            EXECUTE ssma_oracle.set_pv_int 'SDE_IT', 'ERRORHANDLER', 'Z_ISLOGGED', 0/*LO G(1,SQLERRM)*/

         END

      END CATCH

   END
GO



