


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
filename mprint 'E:\temp\day5_tempSAScode.sas';
options mprint mfile;

/* turn on macro debugging - SAS UF Apps */
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
%put kangaroo10: &kangaroo10;



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

	data newds ;
	set realds;
	if game ne var;
	run;

	%macro doAnalyses(dsin=newds);
	%macro tabulateResults();
	
%mend;

/* for each value in array theYears, call the macro myMacro */
%do_over(games, macro=myMacro);


significant results (for your hypothesis)
dataset with 10 years, for 20 industries
and your chair asks if you can repeat the analyses 
- 10 times excluding 1 year at the time (to see if any particular year is driving all the results)
- 20 times -- same for industry

%arry -- holds 10 years -> do_over -> macro call where I do something like this

%table4_upper( dsin= mydataset , vars= e_p , outp= up_full_level);


%macro sensitivityYear(var);

  %table4_upper( dsin= mydataset (where=(fyear ne &var) ) , vars= e_p , outp= out&var);

%mend;
%macro sensitivityInd(var);

  %table4_upper( dsin= mydataset (where=(industry ne &var) ) , vars= e_p , outp= out&var);

%mend;

%do_over(yearsDs, macro=sensitivityYear);
%do_over(indDs, macro=sensitivityInd);

the macro has: proc reg data= &dsin  ;	



data test;
x=1;
run;

%macro horrible();
test;
%mend;

%macro toohorrible();
data test2;
set %horrible();
y = 5 * 1;
run;
%mend;

%toohorrible;


/* task: use do_over to make a variable that computes how many variables are non-missing for funda 
	there are 1000 or so variables in Compustat Funda

	gvkey, fyear, nonMissVars = ...


	proc datasets - has a way to make a table with all the variables in any dataset
	we can use that to make a dataset that has: 1000 records, gvkey, fyear, datadate, sich, sale, ceq

	

*/

/* by hand */
data myDs;
set comp.funda;
nonMissVars = 0;
if missing(ceq) eq 0 then nonMissVars = nonMissVars +1;
if missing(at) eq 0 then nonMissVars = nonMissVars +1;
if missing(sale)eq 0 then nonMissVars = nonMissVars +1;
...
1000 times
...
run;

assume we have dataset named fundaVars with a variable name, 
has 1000 records with name holding all variablenames

/* take the names from fundaVars and make it into an array with the name vars */
%array(vars, data=fundaVars, var=name);
data myDs;
set comp.funda;
nonMissVars = 0;
%do_over(vars, phrase=if missing(?) eq 0 then nonMissVars = nonMissVars +1;);
run;


