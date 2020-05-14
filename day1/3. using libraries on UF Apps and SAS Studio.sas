/* 	Using libraries 

 	By default, datasets are placed in the 'work' folder, and are deleted when SAS restarts 

	To keep datasets more 'permanently' (like any other file), you can use libraries

	To specify a dataset in some library, use LIBRRARY.DATASETNAME (library name, period, followed by dataset name)

	To specify a dataset in the work (default) library, just use DATASETNAME (no library)

	Every time you start SAS, you need to assign the libraries (give the library name, and the folder name).
	(When you sign on WRDS (using SAS), you will see many library assignments in the log.)

	Example (UF Apps), assign library 's' with path "M:\myDBA" (only works if this folder exists):
		libname s "M:\myDBA";

	After the library assignment you can start placing datasets in the s library (these will appear in the folder) 
*/

/* 	UF Apps 
 	First use, UF Apps 'M Drive' to create a folder 
	You can also use this SAS command to create the folder: 
	systask command "mkdir M:\myDBA" ;
*/
libname s "M:\myDBA";

/* 	SAS Studio 
	First create the folder, click 'Folder Shortcuts', right-click 'Home', select 'New -> Folder', name it accordingly */
libname s "~/myDBA";

/* 	PC  - make sure path/folder exists/is correct */
libname s "C:\git\dba2020\day1";


/* Example */

/* makes a dataset named data1, in the s library */
data s.data1;
x = 1;
run;

/* versus */

/* same dataset, in the work libary (will be deleted) */
data data1;
x = 1;
run;
