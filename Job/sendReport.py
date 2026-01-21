#*****************************************************************
# Package Info
# Author          : $Author: JOTHOR $
# Original Date   : $Date: 26.04.2018 $
# Last Modified   : $Modtime: $
# Archive Name    : $Archive: $
# Description     : $Header:  $
# Revision History: $Revision: $
# Tag name        : $Name:  $
# Workfile        : $Workfile: $
#****************************************************************
# Description
# Reports are from within a week number (Monday 0000- Sunday 23:59:59
# Check is from the day before 1800 onwards. If the day before is
# before the week start, yesterday is set to week start.
#
# Parameters:
#   -t target CI in Service@Equinor. A valid CI must conform with the 
#      reg exp "^#.+#$". Only if this is fullfilled will the email
#      be sent to service now
#   -g mandatory the SDE connection files.
#   -s optional the (sub)system in question. This may not 
#      necessarialy be the same as the main system.
#   -v optional verbose/debug
#   -h optional provides help
#****************************************************************
# Log
# Date   Description                                        Done by
# 060520 Added xCurrentUser and program path	   		      JOTHOR
# 261022 Changed xSql_dict.iteritems() to xSql_dict.items() JOTHOR
#****************************************************************
import arcpy, getopt, csv, os, socket, re
import shutil, smtplib, subprocess, sys
import logging, time,datetime
import getpass

#http://www.oracle.com/technetwork/articles/dsl/python-091105.html
import cx_Oracle

xMailList=None
connectionFile  = ""
alertLevel = 0

xPrefixLocalWorkspace=r"Database Connections/"
xCurrentDate=None
xSql_dict=None
xLocalWorkspace=None
xDebug=False
xLogger=None
xLogFilename="sendReport.log"
xLogDir="."
xTargetCI=None
xDatabase="NA"
xSystem="NA"
xProgName="NA"
xProgPath="NA"
xHostName="NA"
xCurrentUser="NA"

#******************************************************
# Error handler
#******************************************************
class UserError(Exception):
   def __init__(self, value):
      self.value = value
   def __str__(self):
      return repr(self.value)
      
def debug(lStr):
   global xDebug
   global xLogger

   if (xDebug):
      xLogger.debug(lStr)
       
def printhelp():  
   print("Command line option")
   print(" -g sde connection file FQN.")
   print(" -t target CI in Service@Equinor. A valid CI msut conform with the")
   print("    reg exp '^#.+#$'. Only if this is fullfilled will the email")
   print("    be sent to service now")
   print(" -s optional the actual (sub)system in question.")
   print(" -h optional provides help.")
   print(" -v optional verbose.")
   print("")
   sys.exit(0)
   
def readCommandLineParamters():
   global xLocalWorkspace
   global xTargetCI
   global xDebug
   global xSystem
   lOption=None
   lArg=None
   
   try:
      myopts, args = getopt.getopt(sys.argv[1:],"hvs:g:t:")
      for lOption, lArg in myopts:
         if lOption == '-h':
            printhelp()
         elif lOption == '-g':  # ESRI sde connection file
            xLocalWorkspace=lArg
            #debug(xLocalWorkspace)
         elif lOption == '-s':    # system
            xSystem=lArg
         elif lOption == '-v':    # verbose modus
            xDebug=True
            debug("Debug modus activated")
         elif lOption == '-t':    # target CI
            xTargetCI=lArg
      debug("xSystem="+xSystem)
   except Exception as e:
      printhelp()
      raise UserError("Illegal option provided." )

def init():
   global xCurrentDate
   global xLogger
   global xLogDir
   global xLogFilename
   global xHostName
   global xDebug
   global xCurrentUser
   
   lLogLevel=logging.WARNING

   # Log File
   ts = time.time()
   lLogfilename = "{0}/{1}".format(xLogDir,xLogFilename)
   logging.basicConfig(filename=lLogfilename,filemode='w',level=lLogLevel, format='%(asctime)s %(levelname)s: %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
   xLogger = logging.getLogger()
   xLogger.log(xLogger.getEffectiveLevel(),"Logfile set to: {0}.".format(lLogfilename))
   xLogger.log(xLogger.getEffectiveLevel(),"Logging set to level: {0}.".format(xLogger.getEffectiveLevel()))

   #--------------------------------------------------------------------------------------
   # create formatter
   # add formatter to ch
   # add ch to xLogger. If this is done, the logger will stream to standard output also.
   #--------------------------------------------------------------------------------------
   '''
   ch = logging.StreamHandler()
   formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
   ch.setFormatter(formatter)
   xLogger.addHandler(ch)
   '''
   
   readCommandLineParamters()
   if xDebug:
      lLogLevel=logging.DEBUG
      xLogger.setLevel(lLogLevel)
      #print("logging level: "+str(xLogger.getEffectiveLevel()))
      debug("Setting logger level to DEBUG")

   xCurrentDate=datetime.datetime.now().strftime('%d.%m.%Y')

   if (xLocalWorkspace == None):
      raise UserError("No SDE connection file supplied")
   elif (xTargetCI == None):
      raise UserError("No target CI supplied for Service@Equinor")

   # Alternatively platform.node() may be used.
   xHostName =socket.gethostname()
   
   xCurrentUser = getpass.getuser()
   
#-----------------------------------------      
# Send mail function
#-----------------------------------------      
def sendReport(lMsg,lMailinglist,lStatus):
   global xDatabase
   global xSystem
   global xTargetCI
   
   lSubject = ""
   lBody = ""
   lFromaddr = ""
   lToaddr = ""
   lStrStatus = "OK"
   try:
      lFromaddr = 'no-reply@equinor.com'
      lToaddr = lMailinglist
      
      if lStatus != 0:
         lStrStatus="Error"

      #NOTE: extremely important to have a space after the first word i.e xTargetCI
      lSubject = "{0} Sys={1} Db={2}: Status={3}".format(xTargetCI,xSystem,xDatabase,lStrStatus)
         
      lBody = lMsg
      #lMsg = 'Subject: %s\n\n%s' % (lSubject, lBody)
      lMsg =  """From: no-reply@equinor.com <%s>
To: <%s>
MIME-Version: 1.0
Content-type: text/html
Subject: %s

<html>
%s
</html>
""" % (lFromaddr,lToaddr, lSubject, lBody)

      server = smtplib.SMTP("mailhost.statoil.no")
      server.sendmail(lFromaddr,lToaddr,lMsg.encode('utf-8'))
      server.quit()
   except Exception as e:
      debug("Error: unable to send email %s %s %s" % (lMsg,lMailinglist, e))
      xLogger.error("Error: unable to send email %s %s %s" % (lMsg,lMailinglist, e))


def createSql():
   global xSql_dict
   xSql_dict = None
   
   #-----------------------------------------------------------
   #-- Checks only for messages from yesterday 1800 and till weeksend.
   #-- Only messages belonging to week number are examined
   #-- If changing yesterdayAfternoon, then fix mail content too.
   #-----------------------------------------------------------
   lWeek = "select to_char(sysdate,'IW') as weeknum \
       ,trunc(sysdate, 'iw') as weekstart \
       ,trunc(sysdate, 'iw') + 7 - 1/86400 as weekend \
       ,case when (trunc(sysdate) - 1 + 18/24) >= to_date(trunc(sysdate, 'iw')) then \
         trunc(sysdate) - 1 + 18/24 \
        else \
         trunc(sysdate, 'iw') \
        end as yesterdayAfternoon \
      from dual"
   #-----------------------------------------------------------
   # NOTE: Several FDUs may be attempted downloaded. Only pickup
   # the first one in the week - therefore start_date between xw.weekstart and xw.weekend
   # and use "weekstart".
   # All other checks are to be for after the value in lWeek.yesterdayAfternoon.
   #-----------------------------------------------------------
   xSql_dict = dict(batch_status="with xweek as ("+lWeek+") \
      ,xres as (select b.* from SDE_IT.BATCH_STATUS b,xweek xw \
      where name ='new_auto_get.sh' \
      and start_date between xw.weekstart and xw.weekend \
      order by b.start_date asc \
      ) \
      ,xdata as (select b.*  \
       from SDE_IT.BATCH_STATUS b \
       where b.version = 1 \
       and b.name <> 'new_auto_get.sh' \
      union \
      select x.* from xres x \
      where rownum = 1 \
      ) \
      select name \
         ,to_char(start_date,'dd.mm.yyyy hh24:mi:ss') as start_date  \
         ,to_char(end_date,'dd.mm.yyyy hh24:mi:ss') as end_date  \
         ,nr_of_error \
         ,message \
         ,host \
        /*xw.weeknum,xw.yesterdayAfternoon,xw.weekstart,xw.weekend,xd.* */ \
        from xdata xd ,xweek xw \
      where nr_of_error > 0 \
      and to_char(start_date,'IW') = xw.weeknum \
      and start_date between xw.yesterdayAfternoon and xw.weekend \
      order by name,start_date desc"
   ,clienterrorlog="with xweek as ("+lWeek+") \
      select applicationname as name\
         ,to_char(dateregistered,'dd.mm.yyyy hh24:mi:ss') as dateregistered \
         ,messagecode \
         ,messagetext \
         /* xw.weeknum,xw.weekstart,xw.yesterdayAfternoon,xw.weekend,b.* */\
      from SDE_IT.T_BASIS_CLIENTERRORLOG b \
          ,xweek xw \
      where to_char(b.dateregistered,'IW') = xw.weeknum \
      and b.dateregistered  between xw.yesterdayAfternoon and xw.weekend \
      order by b.dateregistered desc"
   )  

def cleanUp():
   # if necessary
   if xIsSDEenabled:
        del xSdeConn

def createRowStr(lKey,lRow):
   lName=str(lRow[0])
   if lKey == "batch_status":
      lStr = "Name=\"{0}\" date=\"{1}\" host=\"{2}\". Message={3}".format(lName,lRow[1],lRow[5],lRow[4])
   elif lKey == "clienterrorlog":
      lStr = "Name=\"{0}\" date=\"{1}\" code=\"{2}\". Message={3}".format(lName,lRow[1],lRow[2],lRow[3])
   return lStr

#----------------------------------------------------------------------------
#  lNrNewline is the number of newlines before lLine. A default is in place.  
#----------------------------------------------------------------------------
def addLine(lMsg,lLine,lNrNewline=1):
   for i in range(1,lNrNewline+1):
      lMsg=lMsg+"<br>"
   return lMsg+lLine
   
def main():
   global xCurrentDate
   global xSql_dict
   global xMailList
   global xLocalWorkspace
   global xDatabase
   global xTargetCI
   global xCurrentUser
   
   lMsg=""
   lMsgBody=""
   lStatus = 0  # Used for exceptions encountered
   lErrCount = 0 # The number of errors registered in the database
   lPattern=None
   lRegExpr = "^#.+#$"  # pattern used to check if valid target CI
   
   init()
   
   lMsg = addLine(lMsg,"Report generated on computer: '{0}' by program: {1}\\{2}.".format(xHostName,xProgPath,xProgName))
   lMsg = addLine(lMsg,"Report generated by: '{0}'.".format(xCurrentUser))
   lMsg = addLine(lMsg,"Report generated: {0} UTC.".format(datetime.datetime.utcnow()))
   lMsg = addLine(lMsg,"This report is limited to this week only.")
   lMsg = addLine(lMsg,"Messages searched are between 1800 yesterday and till weeksend.")      
   lMsg = addLine(lMsg,"Date = " + xCurrentDate)

   try:
       # Read workspace path from arguments
      arcpy.env.workspace = xLocalWorkspace
      
      # connection to the enterprise geodatabase.
      lConn = arcpy.ArcSDESQLExecute(xLocalWorkspace)
      xDatabase = lConn.execute("select global_name from global_name")
      lMsg = addLine(lMsg,"Database = " + xDatabase)

      # Check FDU delivery. Consume exception.
      try:
         #IRIS21 specific
         lFDU = lConn.execute("select max(fdu_id) from irdata.data_frequent_delivery")
         lMsgBody = addLine(lMsgBody,"Current FDU in db = {0:.0f} (may not be the same as what may be available at IHS)".format(lFDU))
      except Exception as err:
         lMsgBody = addLine(lMsgBody,"Failed to pickup fdu")
         #lMsgBody = addLine(lMsgBody,err)
         None
      lMsgBody = addLine(lMsgBody,"")

      # For each SQL statement passed in, execute it.
      createSql()
      for lKey,lSql in xSql_dict.items():
         debug("Key = "+lKey)
         debug("Execute SQL Statement: {0}".format(lSql))
         try:
               # Pass the SQL statement to the database.
               lResult = lConn.execute(lSql)
         except Exception as err:
            #print(err)
            xLogger.error(err)
            lMsgBody = addLine(lMsgBody,"---------------------------------------------------",2)
            lMsgBody = addLine(lMsgBody,"Failed to process: "+lKey)
            lMsgBody = addLine(lMsgBody,"---------------------------------------------------")
            lErrCount = lErrCount + 1
            continue
            
         lMsgBody=addLine(lMsgBody,"---------------------------------------------------",2)
         lMsgBody=addLine(lMsgBody,"Processing: "+lKey)
         lMsgBody=addLine(lMsgBody,"---------------------------------------------------")
            
         # If the return value is a list (a list of lists), display
         # each list as a row from the table being queried.
         if isinstance(lResult, list):
            for lRow in lResult:
               lErrCount = lErrCount + 1
               lMsgBody=addLine(lMsgBody,createRowStr(lKey,lRow))

            debug("Number of rows returned by query: {0} rows".format(len(lResult)))
         else:
            lMsgBody=addLine(lMsgBody,"  No rows of interest found.")
            
         #xLogger.info('Check End.')
      if lConn:
         del lConn
      debug("lMsgBody={0}".format(lMsgBody))
      lMsg = addLine(lMsg,lMsgBody)
   except Exception as err:
      lStatus = 1
      debug(err)
      lMsg = addLine(lMsg,"Using ESRI connection {0}".format(xLocalWorkspace))
      lMsg = addLine(lMsg,str(err))
      xLogger.error(err)

   #Send a report if more than one row has been observed.
   xMailList=["jothor@equinor.com","grmoper@equinor.com","kuaa@equinor.com","ohsa@equinor.com"]

   #--------------------------------------------------------------
   # Only add service now if errors and the target CI is valid.
   #--------------------------------------------------------------
   if lErrCount > 0 or lStatus != 0:
      lStatus = 1
      lPattern=re.compile(lRegExpr)
      if lPattern.match(xTargetCI):
         debug("Valid target CI. Adding recipient to service now.")
         xMailList.append("scapp@equinor.com")
      # -- xMailList.append("scmail9@equinor.com") #  Service now test system

   debug("lErrCount="+str(lErrCount)+" lStatus="+str(lStatus) )
   sendReport(lMsg,xMailList,lStatus)
       
if __name__ == "__main__":
   xProgName = os.path.basename(__file__)
   xProgPath = os.path.dirname(__file__)
   main()