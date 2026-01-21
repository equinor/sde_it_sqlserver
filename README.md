# SDE_IT
SDE_IT provides procedures for errorhandling/reporting in a consistent manner. This is through the package "ERRORHANDLER"
All error messages are standardised, though additional can be entered. These are to be numbered from 100 and onwards. Avoid using freetext (code 20).

Epsilon is used in conjuction with batch jobs. When dataloading, one can use the previous reported handled numbers to trigger a message should the current executed exceed an upper/lower limit (epsilon).

For those who have knowledeg of the macro processor M4 (see GNU for details), there are macro libraries for various systems (e.g. Oracle, etc). Using the Oracle.mcr simplifies programming for stored procedures in Oracle.

Additional procedures are available, examine if it provides benefits.

Macro libraries can be found in repository: GitHub\compile2database
Tools to ease compiliation also found here.