
#CDRs import script

The script imports CDRs produced by a service application. 
* It may run for example once per day through "cron".
* Gets all "CDR" files produced on the day before (if any) and 
* converts them into "iso8859-7" as they (may) contain Greek text in "UTF8". 
* The converted CDRs are being appended into a single (daily) file. 
* It also moves each original "CDR" file under the proper "archive" directory.
* Then it executes "SQL loader" Oracle utility, uploading the data onto the proper db table. 
* In case where an "Oracle" exception has been thrown, it catches this error, submits the proper 
  email notification and exits. 
* Else, it retrieves the number of "successfully loaded" and the number of "total read" records, 
  verifying whether the two numbers match or not submitting the proper email notification per case.

