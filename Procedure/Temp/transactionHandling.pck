CREATE_PACKAGE_HEADER(TransactionHandling)
authid current_user
is
/***************************************************************************
  Package Info
*   Author          : $Author: JOTHOR $
*   Original Date   : $Date: 2006/08/15 07:56:49 $
*   Last Modified   : $Modtime: 13.12.05 15:15 $
*   Archive Name    : $Archive: /DB/transactionHandling.pck $
*   Description     : $Header: f:\private\repository/dbr/Procedure/transactionHandling.pck,v 2.5 2006/08/15 07:56:49 JOTHOR Exp $
*   Revision History: $Revision: 2.5 $
*   Workfile        : $Workfile: transactionHandling.pck $
*   Copyright info  : Copyright (c), Statoil ASA,Norway. $Date: 2006/08/15 07:56:49 $
* 
* Description
* Recommended usage: The controller loops through all
* the business cases and delegates the work to others.
* The commit is within the inner exception block and
* will not result in the loop stopping (since in this case,
* this is what is desired).
*
* -- Controlling transaction procedure
*  procedure myController(inPara1 in varchar2)
*  is
*  begin
*      TransactionHandling.starttransaction;
*      begin  -- start of business block
*        for i in cur_Well
*         loop
*           begin
*              myTest(i.well_id);
*              TransactionHandling.performCommit;
*           exception
*           when others then
*              -- do your error handling here
*             TransactionHandling.performrollback;
*           end;
*         end loop;
*      exception
*        when others then
*           -- do your error handling here
*          TransactionHandling.performrollback;
*      end;
*
*      TransactionHandling.endtransaction;
*  exception
*      when others then
*         -- do your error handling here
*  end myController;
* 
*
*  procedure myTest(inPara1 in varchar2)
*  is
*  begin
*      TransactionHandling.starttransaction;
*
*      begin -- start of business block
*         -- perform your business code here
*         TransactionHandling.performCommit;
*      exception
*      when others then
*         -- do your error handling here
*         TransactionHandling.performrollback;
*      end;
*
*      TransactionHandling.endtransaction;
*  exception
*      when others then
*         -- do your error handling here
*  end myTest;
*
* or if you are using the macro library
*
* -- Controlling transaction procedure
*  PROCEDURE(myController)(inPara1 in varchar2)
*  is
*  begin
*      START_TRANSACTION; -- automatically sets up an inner block.
*
*      for i in cur_Well
*      loop
*        begin -- start of business block
*           myTest(i.well_id);
*           COMMIT;
*        EXCEPTION_BLOCK
*           STD_EXCEPTION_HANDLER;
         end;
*      end loop;
*
*      END_TRANSACTION;
*  EXCEPTION_BLOCK
*     STD_EXCEPTION_HANDLER;
*  END_PROCEDURE;
* 
*  procedure myTest(inPara1 in varchar2)
*  is
*  begin
*      START_TRANSACTION; -- automatically sets up an inner block.
*
*      begin -- start of business block
*         -- perform your business code here
*         COMMIT;
*      EXCEPTION_BLOCK
*         STD_EXCEPTION_HANDLER;
*      end;
*
*      END_TRANSACTION;
*  EXCEPTION_BLOCK
*     STD_EXCEPTION_HANDLER;
*  END_PROCEDURE;
*
* NOTE: It is important (extremely important) that start and end transaction
* are outside the business block. Failure to respect this will cause synchronization
* problems with respect to the transaction nest level.
*
* Issue:
* How does this work with autonomous transactions?
*****************************************************************************
* Log
* Date   Description						                              Done by
* 150806 Changed to authid current_user                           JOTHOR
****************************************************************************/

   /*Global variables */
   PACKAGE_VARIABLE($Revision: 2.5 $);

   STD_PACKAGE_METHOD;

/*******************************************************************************
* Transaction strategy procedures
*******************************************************************************/
   function  getCommitRate return number;
   procedure setCommitRate(pCommitRate IN INTEGER);
   procedure ForceCommit;
   procedure PerformCommit;
   procedure performRollback;
   procedure performRollback(pName in varchar2);
   procedure setSavepoint(pName in varchar2);

/*******************************************************************************
* Transaction
*******************************************************************************/
  procedure startTransaction;
  procedure endTransaction;
  function getTransactionLevel return number;

/*******************************************************************************
* Support methods
*******************************************************************************/
  function getStartDate return date;
  function getEndDate return date;
  function getNrBizTransaction return integer;

/*******************************************************************************
* This will force a reset of the package. 
* Do not use unless absolutely necessary.
*******************************************************************************/
   procedure reset;

/*******************************************************************************
* To be called to set procedure identificator. The procedure id
* is the first procedure to  start the transaction.
* Can only be used outside of a transaction.
*******************************************************************************/
   procedure setMethodName(pName in varchar2);
END_CREATE_PACKAGE_HEADER;

