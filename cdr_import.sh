#!/bin/bash
#
# CDRs import script.
#
# The script imports CDRs produced by a service application. 
# * It may run for example once per day through "cron".
# * Gets all "CDR" files produced on the day before (if any) and 
# * converts them into "iso8859-7" as they (may) contain Greek text in "UTF8". 
# * The converted CDRs are being appended into a single (daily) file. 
# * It also moves each original "CDR" file under the proper "archive" directory.
# * Then it executes "SQL loader" Oracle utility, uploading the data onto the proper db table. 
# * In case where an "Oracle" exception has been thrown, it catches this error, submits the proper 
#   email notification and exits. 
# * Else, it retrieves the number of "successfully loaded" and the number of "total read" records, 
#   verifying whether the two numbers match or not submitting the proper email notification per case.
#

# Set the email of service "admin". Any notification will be sent to this email.
adminEmail=someone@somewhere.com

# Set the necessary db connection configurations.
dbport=<port>
dbsid=<id>
dbpwd=<pwd>
dbuser=<user>
dbname=<name>

# Calculate the date of the day before.
yesterday=`perl \-e '@y=localtime(time()-86400); printf "\%04d\%02d\%02d",$y[5]+1900,$y[4]+1,$y[3];'`

# Set the name "template" of the "CDR" files we are looking for; for example: 
filename=cdr_$yesterday

# Check if there are files for processing, which reside under for example "cdr" directory:
files=`ls cdr/$filename*.cdr | wc -l | sed 's/^[ ]*//g'`

# If no files found then submit the proper email notification and terminate.
if [ $files -eq 0 ] 
then
	subject="No CDRs for $yesterday..."
	message="No CDR files found..."
	(echo "$message") | mailx -s "$subject" $adminEmail

	exit 0
fi

# Get "CDR" files, convert their encoding, appending their data into a single file under the proper path 
# and finally move them into the proper "archive" dir.
for file in $(ls cdr/$filename*.cdr)
do
	iconv -c -f utf8 -t iso8859-7 $file >> cdr/closed/$filename.cdr
	mv $file cdr/archived/
done

# Execute "SQL loader" utility, uploading the "encoded" data file onto the proper db table.
sqlldr $dbuser/$dbpwd@"(DESCRIPTION\=(ADDRESS\=(PROTOCOL\=TCP)(HOST\=$dbname)(PORT\=$dbport))(CONNECT_DATA\=(SERVICE_NAME\=$dbsid)))" control=cdr_import.ctl log=cdr/log/$filename.log bad=cdr/log/$filename.bad data=cdr/closed/$filename.cdr rows=5000

# Check if an "Oracle" exception has been thrown. Submit the proper notification email and terminate.
if grep -q -i "ORA-" cdr/log/$filename.log 
then
	subject="CAUTION: error uploading CDRs for $yesterday..."
	message=`grep -i "ORA-" cdr/log/$filename.log`
    (echo "$message") | mailx -s "$subject" $adminEmail
        
	exit 0
fi

# Get number of "successfully loaded" and "total read CDR" rows.
cdrLoaded=`grep "successfully loaded" cdr/log/$filename.log | sed 's/^[ ]*//g' | cut -f 1 -d " "`
cdrRead=`grep "Total logical records read" cdr/log/$filename.log | cut -d " " -f 5- | cut -f 5- | sed 's/^[ ]*//g'`

# Check if both numbers are equal and submit the proper notification email.
if [ $cdrLoaded != $cdrRead ]
then
	subject="CAUTION: error uploading CDRs for $yesterday..."
	message="Total logical records read : $cdrRead, while successfully loaded : $cdrLoaded"
	(echo "$message") | mailx -s "$subject" $adminEmail
else
	subject="Success: CDRs uploaded for $yesterday..."
	message="Total logical records read and successfully loaded : $cdrLoaded"
	(echo "$message") | mailx -s "$subject" $adminEmail
fi

exit 0 
