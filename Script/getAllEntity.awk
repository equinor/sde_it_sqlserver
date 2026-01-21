#************************************************
#   Author          : $Author: jothor $
#   Original Date   : $Date: 2006/07/06 10:35:15 $
#   Last Modified   : $Modtime: 22.11.05 17:25 $
#   Archive Name    : $Archive: $
#   Description     : $Header: f:\private\repository/dbr/Jobs/getAllEntity.awk,v 1.1 2006/07/06 10:35:15 jothor Exp $
#   Revision History: $Revision: 1.1 $
#   Workfile        : $Workfile: generateRushmoreData.pcb $
#   Copyright info  : Copyright (c), Statoil ASA,Norway. $Date: 2006/07/06 10:35:15 $
# 
# Description
#  Picks out all the table names
#************************************************
BEGIN {
  inSel = 0
  inFrom = 0
  inWhere = 0
  lDone = 0;
  noPrint = 0
}

function reset() {
    inSel = 0;
    inFrom = 0;
    inWhere = 0;
    lDone = 0;
}

function output(lStr) {
  printf "%d(%d/%d):%s\n",NR,inSel,inFrom,lStr;
}

function checkSchema(lStr) {
  if (lStr !~ /[a-zA-Z]+\.[a-zA-Z]+/) {
    output("Schema NOT OK!!!!1 : "lStr"  ("substr($0,1,70)")");
  }

  return 0;
}

/^\*/ , /[ \t]*--/ {  
  noPrint = 1;
}
/(update[ \t]+|insert[ \t]+|delete[ \t]+)/ {
  if (noPrint == 0) {
    if ($1 ~ /insert/ && $2 ~/into/)
      lVal = $3;
    else if ($1 ~ /delete/ && $2 ~/from/)
      lVal = $3;
    else if ($1 ~ /update/)
      lVal = $2;
    else
      lVal = $2;
 
#    output($0);
    checkSchema(lVal);
  }
}

/select[ \t]+/ {
  if (noPrint == 0) {
    inSel++;
  }
}
/from[ \t]+/ {
  if (inSel > 0) {
    inFrom++;
  }
}

/./ { 
  if (noPrint == 0 && inFrom > 0) {
    lDone = 1;
#    output($0);
    if ($1 ~/from/) {
#output("from.-..");
       checkSchema($2);
    }
    else if ($1 ~/,[a-zA-Z]+/) {
#output("looking for comma");
       checkSchema(substr($1,2)); # start at 2 to ignore the comma
    }
    else {
#output("no go");
    }
  }
  if (noPrint > 0) {
    noPrint = 0;
  }
}

/where[ \t]+/ {
  if (inSel > 0) {
    inSel--;
    inFrom--;
  }
}

/;/ {
  if (lDone > 0) {
    reset();
  }
}


END {
  output("\n\nProcessed filename : "FILENAME);
}

