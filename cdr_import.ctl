--
-- "SQL Loader" control file.
--
-- Contains the configuration necessary for "SQL Loader" utility. 
-- Uploads CDRs data on the proper db table for a service application.  
--
LOAD DATA
APPEND
INTO TABLE "<table_name>"
FIELDS TERMINATED BY '|'
TRAILING NULLCOLS
(
  "<column-1>" 	DATE "DDMMYYYY HH24:MI:SS",
  "<column-2>" 	CHAR,  
  "<column-3>" 	CHAR,
  "<column-4>" 	CHAR,
	:
	:
  "<column-n>" 	CHAR
)
