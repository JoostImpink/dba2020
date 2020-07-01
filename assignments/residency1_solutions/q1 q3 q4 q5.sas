/* 1. Missing SICH */
%let wrds = wrds-cloud.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_; Libname rwork slibref=work server=wrds;

rsubmit;
data a_funda (keep = gvkey fyear datadate at sale ceq sich missSich);
set comp.funda;
/* require fyear to be within 2015-2019 */
if 2015 <=fyear <= 2019;
/* create variable that captures whether or not the sich is missing */
missSich = missing(sich);
/* prevent double records */
if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
run;

/* group by year */
proc sql;
	create table q1 as 
		select fyear, sum(missSich) / count(*) as percMiss 
		from a_funda 
		group by fyear;
quit;

/* we want to forward fill missing industry codes, so first sort by gvkey and fyear */
proc sort data=a_funda; by gvkey fyear; run;

/* forward-fill any missing sich codes */
data q1b;
set a_funda;
retain tempSich;
/* with 'by' the first. command will work */
by gvkey;
/* first year of any firm - set tempSich to missing (don't want to use sich of another gvkey) */
if first.gvkey then tempSich = .;
/* now it is safe to replace any missing sich with tempSich
this will not do anything if tempSich is missing, but will fix missing sich if tempSich is a valid SIC code */
if missing(sich) then sich = tempSich;
/* update tempSich to most recent number */
tempSich = sich;
run;
proc download data=q1 out=q1;run;
proc download data=q1b out=q1b;run;
endrsubmit;

/* 2. Hayn tables, see separate q2 solution SAS file*/


/* 3. Macro stock return */

/* create a dataset to work with */
%let wrds = wrds-cloud.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_; Libname rwork slibref=work server=wrds;

rsubmit;
data a_funda (keep = gvkey fyear datadate ni at sale ceq prcc_f csho sich);
set comp.funda;
/* require fyear to be within 2015-2019 */
if 2015 <=fyear <= 2019;
/* require assets, etc to be non-missing */
if cmiss (of at sale ceq ni) eq 0;
/* prevent double records */
if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
run;

/* append permno */
proc sql; 
  create table b_permno as 
  select a.*, b.lpermno as permno
  from a_funda a , crsp.ccmxpf_linktable b 
    where a.gvkey eq b.gvkey 
    and b.lpermno ne . 
    and b.linktype in ("LC" "LN" "LU" "LX" "LD" "LS") 
    and b.linkprim IN ("C", "P")  
    and ((a.datadate >= b.LINKDT) or b.LINKDT eq .B) and  
       ((a.datadate <= b.LINKENDDT) or b.LINKENDDT eq .E)   ; 
  quit; 

/* add beginning and end of year variables */
data c_dates;
set b_permno;
startdate = intnx('month' , datadate, -11, 'B'); /* if datadate is dec 31, then startdate is jan 1 */
enddate = datadate; /* same as datadate */
format startdate enddate date9.;
run;

/* code without using a macro */

/* 	The next two proc sql statement get the monthly returns, and then compound it.
	This is the code we will wrap inside a macro so it can be reused across projects*/

/* get monthly stock return */
proc sql;
	create table e_msf as
	select a.*, b.ret, b.date
	from c_dates a, crsp.msf b
	where a.permno = b.permno
	and a.startdate <= b.date <= a.enddate	
	and missing(b.ret) ne 1 ; /* could be missing if firm on pinksheet/otc for 1 month */
quit;

/* compound it */
proc sql; 
	create table f_car as select 
		gvkey, fyear, exp(sum(log(1+ret))) as car, count(ret) as n
	from e_msf 
	group by gvkey, fyear;
quit;

/* create dataset with car appended */
proc sql;
	create table g_car as select a.*, b.car from c_dates a left join f_car b on a.gvkey = b.gvkey and a.fyear = b.fyear;
quit;	

proc download data=g_car out=g_car;run;

endrsubmit;

/* Macro stock return
Turn the code for part 1 into a macro. The macro needs to be invoked with the following arguments: 
%getReturn(dsin=a_funda, dsout=b_ret, start=startdate, end=enddate) where dsin already holds the firms and their permnos 
(gvkey, fyear, permno, sich, datadate, enddate) (make sure to generate startdate; for enddate you can use datadate).
*/

rsubmit;

%macro getReturn(dsin=, dsout=, start=, end=);

/* append monthly stock return*/
proc sql;
	create table temp1 as
	select a.*, b.ret, b.date
	/* notice how &dsin is used */
	from &dsin a, crsp.msf b
	where a.permno = b.permno
	/* &start and &end are variables on &dsin */
	and a.&start <= b.date <= a.&end	
	and missing(b.ret) ne 1 ; /* could be missing if firm on pinksheet/otc for 1 month */
quit;

proc sql; 
	create table temp2 as select 
		gvkey, fyear, exp(sum(log(1+ret))) as car
	from temp1 
	group by gvkey, fyear;
quit;

/* create &dsout as &dsin with car appended */
proc sql;
	create table &dsout as select a.*, b.car from &dsin a left join temp2 b on a.gvkey = b.gvkey and a.fyear = b.fyear;
quit;	

%mend;

/* invoke, c_dates has gvkey, fyear, startdate, enddate, permno*/
%getReturn(dsin=c_dates, dsout=g_car_2, start=startdate, end=enddate);

proc download data=g_car_2 out=g_car_2;run;

endrsubmit;

/* 4. Abnormal return */

/* be sure to run this code while the WRDS session is still running 
	otherwise, rerun the code for problem 3 */

rsubmit;
%macro getReturn(dsin=, dsout=, start=, end=, adjustMarket=);

/* append monthly stock return and index return*/
proc sql;
	create table temp1 as
	select a.*, b.ret, b.date, c.vwretd 
	/* join with 3 tables */
	from &dsin a, crsp.msf b, crsp.msix c
	where a.permno = b.permno
	and a.&start <= b.date <= a.&end
	/* match msf and msix on end of month */
	and b.date = c.caldt
	and missing(b.ret) ne 1 ; /* could be missing if firm on pinksheet/otc for 1 month */
quit;

/* note: using macro %if, which is for the macro engine to decide which code to generate
In this case, we want to include '- exp(sum(log(1+vwretd)))' in the calculation of variable car
but only if adjustMarket has the value yes; if adjustMarket has another value, then
'- exp(sum(log(1+vwretd)))' is not part of the generated code.
*/
proc sql; 
	create table temp2 as select 		
		gvkey, fyear, exp(sum(log(1+ret))) 
		/*  You can also compound log(1+ret-vwretd) 
		    If macro variable adjustMarket has the value yes (no quotes), 
			then subtract compound market return 
		 	If this is confusing, look at the code that is generated/executed */
		%if &adjustMarket eq yes %then %do;
			- exp(sum(log(1+vwretd))) 
		%end;		
		as car
	from temp1 
	group by gvkey, fyear;
quit;

/* create &dsout as &dsin with car appended */
proc sql;
	create table &dsout as select a.*, b.car from &dsin a left join temp2 b on a.gvkey = b.gvkey and a.fyear = b.fyear;
quit;	

%mend;

/* invoke, c_dates has gvkey, fyear, startdate, enddate, permno*/
%getReturn(dsin=c_dates, dsout=q4, start=startdate, end=enddate, adjustMarket=yes);

proc download data=q4 out=q4;run;

endrsubmit;

/* 5. Relative industry ROA */
%let wrds = wrds-cloud.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_; Libname rwork slibref=work server=wrds;

rsubmit;
data myComp (keep = gvkey fyear datadate ni at sale sich roa );
set comp.funda;
/* require fyear to be within 2015-2019 */
if 2015 <=fyear <= 2019;
/* require assets, etc to be non-missing */
if cmiss (of at ni) eq 0;
/* positive assets */
if at > 0;
/* construct roa */
roa = ni / at;
/* prevent double records */
if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
/* require roa to be nonmissing */
if missing(roa) eq 0;
run;

/* group by industry-year, compute count, industry roa and industry roa excluding firmyear */
proc sql; 
	create table q5 as 
	/* the * means the query will return all observations and variables myComp */
	select *, 
	/* count, sum are aggregates and will do this by sich, fyear */
	count(*) as numFirms, sum(roa)/count(*) as roa_ind, 
	/* nice how sum(roa) and roa can be used at the same time, you don't need a separate proc sql 
		to first sum(roa) */
		(sum(roa)-roa)/( count(*) - 1) as roa_ind_excl_firmyear
	from myComp 
	group by sich, fyear;
quit;
	
proc download data=q5 out=q5;run;

endrsubmit;



