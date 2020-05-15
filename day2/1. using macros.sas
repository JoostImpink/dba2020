/* macro variables */

/* note: when SAS sees the ampersand (&), it will replace that with the value of the variable */


/* define */
%let myname = 'Joost';
%let myname2 = Impink;

/* usage &myname will be replaced by 'Joost' (with the quotes) */
%put Hello &myname --  &myname2;

/* single quotes vs double quotes */
%put double quotes: "&myname &myname2";
%put single quotes: '&myname &myname2';




/* get a dataset to work with */
rsubmit;endrsubmit;
%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

rsubmit;

libname myfiles "~"; /* ~ is home directory in Linux, e.g. /home/ufl/imp */
proc sql;
	create table myfiles.a_funda as
		select gvkey, fyear, datadate, sich, sale, ni
	  	from comp.funda 
  	where 		
		2010 <= fyear <= 2016	
	and indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
quit;

proc download data=myfiles.a_funda out=a_funda;run;
endrsubmit;


/* use in queries */
%let startyr = 2010;
%let endyr = 2015;

proc sql;
  create table a_comp as select fyear, median(ni/sale) from comp.funda 
	where &startyr <= fyear <= &endyr 
	group by fyear;
quit;


/* using proc sql to dynamically set a macro variable */

/* figure out first and last fyear */
proc sql; select min(fyear), max(fyear) into :minYr, :maxYr from a_comp;quit;

/* Print the values of minYr and maxYr */
%put start year: &minYr ending year: &maxYr;


/*  A first macro (one that doesn't do much) */
%macro myFirst(); /* define a new macro with the name 'myFirst' */

	/* create a dataset with some variable */
	data myData;
	x = 1;  
	run;

%mend; /* mend=macro end */

/* invoke (run) the macro and inspect generated text file with code generated */
%myFirst();

/* turn on macro debugging (choose one) */

/* UF Apps */
filename mprint 'M:\tempSAScode.txt';
options mprint mfile;

/* SAS Studio */
filename mprint '~/tempSAScode.txt';
options mprint mfile;

/* pc */
filename mprint 'C:\git\dba2020\day2\tempSAScode.txt';
options mprint mfile;


/* passing arguments into macro 
   ---------------------------- */
%macro mySecond(val); 
  data myData;
  x = &val;  
  run;
%mend;

%mySecond(5);

/* Explicit Multiple macro arguments */

* require variable names to be specified;
%macro myThird(val=); 
  data myData;
  x = &val;  
  run;
%mend;

/* invoking the macro */
%myThird(val=5);

/* multiple vars */
%macro myFourth(dsout=, val=); 
  data &dsout;
  x = &val;  
  run;
%mend;

/* all macro variables are specified */
%myFourth(dsout=myData2, val=5);

/* the order can be different -- this is identical */
%myFourth(val=5, dsout=myData2);

/* Optional/default macro variables */
/* val will be set to 7 if it is not passed */
%macro myFifth(dsout=, val=7); 
  data &dsout;
  x = &val;  
  run;
%mend;

%myFifth(dsout=myData2);

/* Accessing macro variables  defined 'outside' the macro; */
/* define some variable */
%let something = 1;

/* macro definition */
%macro mySixth(dsout=, val=7); 
  data &dsout;
  x = &val;  
  y = &something;
  run;
%mend;

%mySixth(val=5, dsout=myData2);

%macro myThird(dsin=, dsout=, datevar=, name=year); 
  data &dsout;
  set &dsin;
  &name = year(&datevar);
  /* the macro accesses the variable */
  somevar = &something;
  run;
%mend;

%myThird(dsin=myData, dsout=myData2, datevar=date1);

/* Include statement */

/* Include the macro file `example_macro.sas` in the `data_management\macros` folder
  this will read and run the file (helpful for macro definitions)
*/
/* just for illustration */
%include "M:\dba-master\residency_1\data_management\macros\example_macro.sas";

/* include all sas files in some folder */
filename mymacros "M:\dba-master\residency_1\data_management\macros";
%include mymacros('*.sas');

/* Instead of reading a file from disk, you can read from a url*/
/* this url is actually valid */
filename m1 url 'http://www.wrds.us/macros/runquit.sas';
%include m1;

/* the runquit macro (loaded above) will stop execution when an error occurs */

/* without runquit -- SAS will continue after the error */

proc go_gators!; quit;
data myData2; x=1; run;

/* with runquit it will stop */
proc go_gators!; %runquit; /* %runquit instead of quit */
data myData2; set myData; year = year(date); %runquit; /* %runquit instead of run */

