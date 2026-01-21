#*************************************************
# Generates the job list whichs inserts keywords
# into powerbuilder code
# before indicates whether keyworks before or after
# synchronization point.
#*************************************************
BEGIN {
  before="false"
  dir="."
}

/./ {
  print "awk -f a.nawk before="before " " $0 " > " dir "\\" $0
}

END{
}
