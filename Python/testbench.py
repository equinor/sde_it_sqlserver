# python createFeatureClass.py -t "user/pw@sid" -g "sdeconnection"
# Import system modules
import arcpy
from arcpy import env
import datetime
import traceback
import sys
import getopt
import datetime
import socket
import os

#http://www.oracle.com/technetwork/articles/dsl/python-091105.html
import cx_Oracle

xPrefixLocalWorkspace=r"Database Connections/"
xLocalWorkspace = "NA"
xLocalDbConnStr = "NA"
xLocalWorkspace = "NA"
xSDEserver = "NA"
xSDEinstance = "NA"
xSDEdatabase = "NA"
xSDEuser = "NA"
xSDEpw = "NA"
xConnProvided = False
xDebug = True

def debug(lStr):
    global xDebug
    if (xDebug):
       print "Debug:"+str(lStr).encode('utf-8', 'ignore')
       
def readCommandLineParamters():
   global xRbacConnStr
   global xLocalDbConnStr
   global xLocalWorkspace
   global xConnProvided
   global xDebug
   global xSDEserver
   global xSDEinstance
   global xSDEdatabase
   global xSDEuser
   global xSDEpw
   global xXmlFile

   # Read command line args
   xConnProvided=False
#   if (len(sys.argv) > 1):
#     xConnProvided=True

# deprecated   myopts, args = getopt.getopt(sys.argv[1:],"hvr:t:g:s:i:d:u:p:f:")
   myopts, args = getopt.getopt(sys.argv[1:],"vt:g:")
   for o, a in myopts:
     if o == '-h':
         printhelp()
     elif o == '-v':    # verbose modus
         xDebug=True
         debug("Debug modus activated")
     elif o == '-t':  # target database
         xLocalDbConnStr=a
         xConnProvided = True
     elif o == '-g':
         xLocalWorkspace=xPrefixLocalWorkspace+a
     else:
         logError(3,"Illegal commnand line argument: " + o)

def getSourceStore():
    global xLocalDbConn
    return xLocalDbConn

def getConnectionStr(lStr):
   if not lStr:
      raise SysError('getConnection requires an string parameter')

   lCount=0;
   lMaxAttempt=3
   lTempStr=''
   while True:
      if (lCount > 0):
         lTempStr='Attempt ({0}/{1}), {2}'.format(lCount,lMaxAttempt,lStr)
         targetDb=raw_input(lTempStr)
      else:
         targetDb=raw_input(lStr)

      if  targetDb :
         break
      if lCount > 2:
         raise UserError('No connection string provided')
      lCount +=1
   return unicode(targetDb, "utf-8")         
 
def initialise():
   global xHostName
   global xLocalDbConnStr
   global xLocalDbVersion
   global xLocal_version_sde_actual
   global xLocalDbServiceName
   global xIsSDEenabled
   global xTimestamp
   global xConnProvided
   global xTargetDb
   global xSchemaExclude

   global xLocalWorkspace
   global xSDEserver
   global xSDEinstance
   global xSDEdatabase
   global xSDEuser
   global xSDEpw
   global xXmlFile
   
   global xSdeConn
   global xLocalDbConn

   global xSystem
   global xSite

   lSDE_DbServiceName = 'NA'
   xHostName = socket.getfqdn()
#   xTimestamp=datetime.datetime.utcnow()

#xxxx
#   xRbacConnStr = r"/@U.statoil.no"
#   xLocalDbConnStr = r"@T.statoil.no"
#   xLocalWorkspace = r"Database Connections/Test_Iris21_sde.sde"  -- the Database Connections/ if prefixed now
#   xRbacConnStr = r"rbac_transit/xxx@T775.statoil.no"
#   xLocalDbConnStr = r"irdba/xxx@P080.statoil.no"
#   xLocalWorkspace = r"Database Connections/Test_Iris21_sde.sde"  -- the Database Connections/ if prefixed now
#   print "Using hardcoded connection settings"

   try:
      readCommandLineParamters()
      print("xxxx")
      if(xConnProvided == False):
         xLocalDbConnStr=getConnectionStr('Oracle: Source connection(user/pw@SID):')
         raise "Please supply a db connection"

      xTargetDb = xLocalDbConnStr.rsplit("@",1)[1]

      #Oracle connection information
      xLocalDbConn=cx_Oracle.connect(xLocalDbConnStr)
      xLocalDbVersion = getSourceStore().version
      lLocalDbCur = getSourceStore().cursor()

      lSql = "select global_name from global_name"  # gives as e.g. t123.statoil.no
      debug(lSql)
      lLocalDbCur.execute(lSql)
      for lResult in lLocalDbCur:
         xLocalDbServiceName = lResult[0]
         debug("Result db connection: "+xLocalDbServiceName)

      try:
       debug("Selecting username from all_users")
       lLocalDbCur.execute("select username from all_users where username='SDE'")
       for lResult in lLocalDbCur:
           if (lResult[0] == "SDE"):
              xIsSDEenabled=True

              if(xConnProvided == False):
                debug("Example of SDE connection to be provided: Test_Iris21_sde.sde")
                xLocalWorkspace = xPrefixLocalWorkspace + xLocalWorkspace

              if (xLocalWorkspace != "NA"):
                 debug("SDE - using connection file")
                 xSdeConn=arcpy.ArcSDESQLExecute(xLocalWorkspace)
                 lResult = xSdeConn.execute("select global_name from global_name")
                 lSDE_DbServiceName = lResult
              elif (xSDEserver != "NA"):
                debug("SDE - using direct connect")
                xSdeConn=arcpy.ArcSDESQLExecute(xSDEserver,xSDEinstance,xSDEdatabase,xSDEuser,xSDEpw)
                lResult = xSdeConn.execute("select global_name from global_name")
                lSDE_DbServiceName = lResult
                debug("Result sde connection: "+lSDE_DbServiceName)
              else:
                 xIsSDEenabled=False

       #--------------------------------------------------------------------------
       # If SDE provided, ensure both connections are to the same database.
       #--------------------------------------------------------------------------
       if(xIsSDEenabled):
           debug("lSDE_dbname "+lSDE_DbServiceName+"/"+xLocalDbServiceName)
           if (lSDE_DbServiceName != xLocalDbServiceName):
              raise Exception("Local database does not match the SDE database provided "+xLocalDbServiceName+"/"+lSDE_DbServiceName)

           debug("SDE - picking up the sde version")
           lLocalDbCur.execute("select major||'.'||minor||'.'||bugfix from sde.version where rownum=1")
           for i in lLocalDbCur:
              xLocal_version_sde_actual = i[0]
              debug("SDE connection: "+xLocal_version_sde_actual)

      except Exception as e:
       raise

   except Exception as e:
      print("Does the source connection have access to dba_users and dba_objects?")
      raise
      return
   return
   
import sys
sys.path.append('f:/temp/test')
import sde_itPackage

   
def testBench():
   print("In testBench")
   lStartDate = datetime.datetime.now()
   initialise()
#   print("instance xSdeConn: "+str(type(xSdeConn)))
#   print("instance xLocalDbConn: "+str(type(xLocalDbConn)))  
   sde_itPackage.ping()
   sde_itPackage.logError(xSdeConn,1,"sde_itPackagetestBench22","1.0","sde_itPackageTest message")
   sde_itPackage.updateBatchStatus(xSdeConn,"sde_itPackagex22xx",lStartDate,1,2,"sde_itPackagebatchstatsu test",False)
   print("Done in testBench")
      
testBench()