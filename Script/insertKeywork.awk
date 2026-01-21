#*************************************************
# Inserts keywords into powerbuilder code
# before indicates whether keyworks before or after
# synchronization point.
# /* $NoKeywords: $ */
#*************************************************
BEGIN {
  doSync="false"
  dump=0
  headerDone="false"
}

function heading() {
  if (headerDone == "true") return
  print "/************************************************************"
  print "* Author          : $Author: jothor $"
  print "* Original Date   : $Date: 2009/01/07 14:39:42 $"
  print "* Last Modified   : $Modtime:  $"
  print "* Archive Name    : $Archive:  $"
  print "* Description     : $Header: f:\private\repository/dbr/Jobs/insertKeywork.awk,v 1.4 2009/01/07 14:39:42 jothor Exp $"
  print "* Revision History: $Revision: 1.4 $"
  print "* Workfile        : $Workfile:  $"
  print "* Copyright info  : Copyright (c), StatoilHydro ASA,Norway. $Date: 2009/01/07 14:39:42 $"
  print "*"
  print "************************************************************"
  print "* Description:"
  print "*"
  print "************************************************************/"
  print "/* $NoKeywords: $ */"
  headerDone="true"

  headerDone="true"

  dump=dump+1
}
#Synchronization point. doSync must be set to true
/select/ {
  dump=dump+1
}

/./ {
  if (doSync=="false") {
    heading()
  }
  if (doSync=="true" && before=="true" && dump==1) {
    heading()
  }

  printf "%s\n",$0

  if (doSync=="true" && before!="true" && dump==1) {
    heading()
  }
}

END {

}

