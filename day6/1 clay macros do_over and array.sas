
/* start with a dataset from funda: gvkey, fyear, roa and roe */

%let wrds = wrds-cloud.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;
rsubmit;
data a_funda (keep = gvkey fyear sich roa roe ros);
set comp.funda;
if at > 0;
if ceq > 0;
if fyear >= 2010;
roa = ni / at;
roe = ni / ceq;
ros = ni / sale;
if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
run;
proc download data=a_funda out=a_funda;run;
endrsubmit;


/*  Include array function macros */
filename m1 url 'http://www.wrds.us/macros/array_functions.sas';
%include m1;

/* turn on macro debugging */
filename mprint 'E:\temp\tempSAScode.sas';
options mprint mfile;

/* turn on macro debugging - SAS UF Appst */
filename mprint 'M:\tempSAScode.sas';
options mprint mfile;

/* turn on macro debugging - SAS Studio */
filename mprint '~/tempSAScode.sas';
options mprint mfile;



/* lets make year-indicator variables */

/* simple way */
data b_indicators;
set a_funda;
d2010 = (fyear eq 2010);
d2011 = (fyear eq 2011);
d2012 = (fyear eq 2012);
d2013 = (fyear eq 2013);
run;

/* using Ted Clay's %do_over */
data b_indicators;
set a_funda;
%do_over(values=2010-2013, phrase=d? = (fyear eq ?););
run;

/* replace missings with zero for these variables */
%let varlist = roa roe ros;

data c_misreplaced;
set b_indicators;
%do_over(values=&varlist, phrase=if missing(?) then ? = 0;);
run;


/* fancy way */
/* figure out first and last fyear */
proc sql; select min(fyear), max(fyear) into :minYr, :maxYr from a_funda;quit;

%put start year: &minYr ending year: &maxYr;
/* create dummies */
data b_indicators;
set a_funda;
%do_over(values=&minYr - &maxYr, phrase=d? = (fyear eq ?););
run;

/* another way -- just in case there are jumps in the years , if 2012 would be missing */
proc sql;
	create table myYears as select distinct fyear from a_funda ;
quit;

%array(kangaroo, data=myYears, var=fyear);
%put kangarooN: &kangarooN;
%put kangaroo1: &kangaroo1;
%put kangaroo2: &kangaroo2;


data b_indicators;
set a_funda;
%do_over(kangaroo, phrase=d? = (fyear eq ?););
run;

/* In a query 

Use `%do_over` in sql query: `select a.*, %do_over(values=at sale ceq, phrase=b.?) 
from dset1 a, dset2 b where a.key=b.key` 

which generates `select a.*, b.at, b.sale, b.ceq from dset1 a, dset2 b where a.key=b.key`.

*/

/* 
Instead of filling in a phrase, %do_over can also call a macro. So, for each value in the 
'values=' list (or in the array that is passed), the macro will be called and the value 
is passed as an argument. 

> Note: in the macro definition (first line of the macro), do not include the '=' sign, 
but instead use `%macro myMacro(myVar);`

*/
%macro myMacro(var);
	/* do something with &var; */
	%put myMacro called with &var;
%mend;

/* for each value in array theYears, call the macro myMacro */
%do_over(kangaroo, macro=myMacro);