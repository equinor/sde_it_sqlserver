#**********************************************************************
# SCCS ver : %W%
# SCCS rev : %R%
# SCCS date: %G%
#
# Author          : Johan Thorsen
# Consultantfirm  : IT-UB
# Telephonenumber : (+47) 5199000 (Stavanger, Norway)
# Date            : 11 Nov 1998
# 
# Warning
#   This code is administered by SCCS. Please do not make alterations
# unless you extract the code from SCCS for editing.  
# If in doubt, please contact Statoil IT-UB.
#
# Description
#   Gets the properties needed to establish a jdbc connection string.
# Performs a tnsping to the database. For use with oracle.
#
# Parameters
#   -d {database}   use database other than default $ORACLE_SID
#
# Usage
#  ./getJDBC_DBprop.exe
#**********************************************************************
# Log 
# Date   Description								Done by
# 090299 Altered sychronization in returned tnsping string	JOTHOR
#	to synchronize on lower case. Tnsping sometimes varies eg:
#	returning Host or HOST!
#**********************************************************************
INITIATION

use FileHandle;
require 'getopts.pl';


#**********************************************************************
# Declaration of global variables
# 
#**********************************************************************
DECL($xoracleDir)="c:\oracle\ora81";
DECL($xtnsPing)="${xoracleDir}\bin\tnsping";
DECL($xdatabase);
DECL(%xdbInfo);

#**********************************************************************
# Initiation
# Check for minimum number of required parameters in ARGV
#**********************************************************************
SUB(init)
  PARAMETER();

  CHECK_NR_ARGV(0);

  if (! -x "$xtnsPing") {
    ERROR_SHOW(MSG_FILE_NONEXISTENT($xtnsPing));
    EXIT(ERR);
  }

  CALL(&Getopts)("d:");
  
  if (defined($opt_d)) {
    $xdatabase = $opt_d;
  }
  elsif (defined($ENV{'ORACLE_SID'})) {
    $xdatabase = "$ENV{'ORACLE_SID'}";   
  }
  else {
    ERROR_SHOW(Database not defined);
    EXIT(ERR);
  }

ENDSUB

#**********************************************************************
# The returned string from tnsping is reduced to lower case on the
# sychronization points only. The value is not altered!
#**********************************************************************
SUB(getProperty)
  PARAMETER();
  DECL($lconnectStr) = '';
  DECL($lfh);
  DECL(@larr);
  DECL(@larr2);
  DECL($lPrimaryKey);
  DECL($lAddr);
  $lfh = new FileHandle("$xtnsPing $xdatabase |");
  while (<$lfh>) {
    $lAddr = uc($_);
    if ($lAddr =~ /ADDRESS/) {
      (@larr) = split("=",$_,2);
      if (defined($larr[1])) {
	   $larr[1] =~ s/[(]//g;
        (@larr) = split("[)]",$larr[1]);
        foreach $i (@larr) {
          (@larr2 ) = split("=",$i,2);
          $lPrimaryKey = lc($larr2[0]);
          $xdbInfo{$lPrimaryKey} = $larr2[1] if (defined($larr2[1]));
        }
        last;
      }
    }
  }
  
  $lfh->close();

  $lconnectStr = "jdbc:oracle:thin:@";
  $lconnectStr .= $xdbInfo{"host"}.":".$xdbInfo{"port"}. ":" . $xdatabase;
  			 
  printf "$lconnectStr";
ENDSUB

#**********************************************************************
# Main program
#**********************************************************************
SUB(main)
  CALL(init);
  TESTRETURN;

  CALL(getProperty);
  TESTRETURN;

ENDSUB


CALL(main);
TESTEXIT;
