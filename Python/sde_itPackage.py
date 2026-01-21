__author__ = 'JOTHOR'
#*****************************************************************
# Package Info
# Author          : $Author: jothor $
# Original Date   : $Date:  22.06.16 $
# Last Modified   : $Modtime: $
# Archive Name    : $Archive: $
# Description     : $Header:  $
# Revision History: $Revision: $
# Tag name        : $Name:  $
# Workfile        : $Workfile: $
#****************************************************************
# Description
# SF_UpdateBatchStatus to be called immediately after job is finished.
# This since the end_date is set by the function.
#
# How to import the module
#    import sys
#    sys.path.append('f:/temp/test') # Note forward slash!
#    import <module name> # sde_itPackage
#
# From an Oracle connection use:
#   xDBConn=cx_Oracle.connect(xLocalDbConnStr)
# From a SDE connection use:
#   xDBConn=arcpy.ArcSDESQLExecute(xLocalWorkspace)
# Provide xDBConn to this package.
#
# To be executed as a module
#****************************************************************
#import platform
import cx_Oracle
import datetime
from socket import gethostname

def ping():
   print("received ping")

def getSqlExecutor(lDbConnection):
   if (lDbConnection == None):
      raise "Must supply a database connection"

#   print("--->"+str(type(lDbConnection)))
   lClass = str(type(lDbConnection))
   if (lClass == '<class \'arcpy.arcobjects.arcobjects.ArcSDESQLExecute\'>'):
      lCursor = lDbConnection
   elif  (lClass == '<class \'cx_Oracle.Connection\'>'):
      lCursor = lDbConnection.cursor()
   else:
      raise "Unknown database connector ("+lClass+")."
   return lCursor

#****************************************************************
# Logs error. 
# lDB_Connection the database connection to where to error is to be logged.
# lLevel between 1 (most serious) and 5
# lApplication the name of the application
# lVersion the application version if present
# lMessage the error message
#****************************************************************
def logError(lDB_Connection,lLevel,lApplication,lVersion,lMessage):
   lHostname = gethostname()
   
   lSql = "begin "
   lSql = lSql + "sde_it.errorhandler.logError("
   lSql = lSql + str(lLevel)
   lSql = lSql + ",'"+lApplication+"'"
   lSql = lSql + ",'"+lVersion+"'"
   lSql = lSql + ",'"+lMessage+"'"
   lSql = lSql + ",'"+lHostname+"'"
   lSql = lSql + ");"
   lSql = lSql + " end;"
#   print("Logerror: ="+lSql)
   getSqlExecutor(lDB_Connection).execute(lSql)

#****************************************************************
# pName - the name of the batch job or application monitored (hereafter task)
# pStartDate - the start time of task - datetime.datetime.now()
# pNrError  - the number of business transactions errors
# pNrBusinessTransaction - the total number of business transactions processed
# pMessage  - informative message
# pRetainHistory - default false. Should one desire to retain a history of
#    the previous lHistoryLimit entries, send in true and the system will
#    automatically maintain the history.
#****************************************************************
def updateBatchStatus(lDB_Connection,pApplication, pStartDate, pNrError, pNrBusinessTransaction, pMessage, pRetainHistory):
   lSql = ""
   lHostname = gethostname()

   lStartDate = pStartDate.strftime('%d.%m.%Y %H:%M:%S')
   lEndDate = datetime.datetime.now().strftime('%d.%m.%Y %H:%M:%S')
   lStartDate ="to_date('"+lStartDate+"','dd.mm.yyyy hh24:mi:ss')"
   lEndDate ="to_date('"+lEndDate+"','dd.mm.yyyy hh24:mi:ss')"

#   print("%s|%s|%s|%s|%s|%s|%s|%s",pApplication, lStartDate, lEndDate, pNrError, pNrBusinessTransaction, pMessage, pRetainHistory, lHostname)
   lSql = "begin "
   lSql = lSql +" sde_it.SF_UpdateBatchStatus('"+pApplication+"'"
   lSql = lSql +","+lStartDate
   lSql = lSql +","+lEndDate
   lSql = lSql +","+str(pNrError)
   lSql = lSql +","+str(pNrBusinessTransaction)
   lSql = lSql +",'"+pMessage+"'"
   if (pRetainHistory):
      lSql = lSql +",true"
   else:
      lSql = lSql +",false"
   lSql = lSql + ",'"+lHostname+"'"
   lSql = lSql +");"
   lSql = lSql + " end;"
#   print lSql

   getSqlExecutor(lDB_Connection).execute(lSql)
#   lCursor.callproc('sde_it.SF_UpdateBatchStatus', (pApplication, lStartDate, lEndDate, pNrError, pNrBusinessTransaction, pMessage, pRetainHistory, lHostname))
#   print("Leaving SF_UpdateBatchStatus "+lHostname+" "+lStartDate+" "+lEndDate)

#******************************************************
# Start of program.
#******************************************************
if __name__ == '__main__':
#   pStartDate=datetime.datetime.now()
#   print("12345"[3:5])
#   print(len("1234"))
#   SF_UpdateBatchStatus(None,"pName", pStartDate, "pNrError", "pNrBusinessTransaction", "pMessage", "pRetainHistory")
   raise "Not intended for standalone use."