


/* data step */

data newdata;
set olddata;
if fyear > 2000 ;
if at > 0;
/* there are records with missing roa , want to drop these */
/* missing function returns 1 if a variable is missing */
if missing(roa) eq 0;
/* the period is a shorthand for 'missing', and ne is not equal */
if roa ne . ; 
/* cmiss function for doing this for many variables in one go */
if cmiss (of roa) eq 0;


where tic eq "IBM";  /* uses index */
run;


/* proc sql */

/* left join */
	proc sql; 
		create table f_sample as select a.*, b.ret 
		from d_withpermno a left join f_ret b 
		on a.gvkey = b.gvkey and a.fyear = b.fyear;
	quit;

/* inner join */
	proc sql; 
		create table f_sample as select a.*, b.ret 
		from d_withpermno a , f_ret b 
		where a.gvkey = b.gvkey and a.fyear = b.fyear;
	quit;

/* outer join also exists (keep both unmatched records at 'left' and 'right' side) */

	
/* a dataset for 2 gvkeys, some 'x' variable */

data r;
gvkey = '001004'; x = 10; output;
gvkey = '001004'; x = 5; output;
gvkey = '001004';  x = 7; output;
gvkey = '001004';  x = 12; output;

gvkey = '001010';  x = 10; output;
gvkey = '001010'; x = 4; output;
gvkey = '001010';  x = 8; output;
gvkey = '001010'; x = 2; output;
run;

 proc sort data=r ; by gvkey; run;

/* lets compute a running sum */
 data r2 (drop = x);
 set r;
 by gvkey ;
 retain sum ; 

 if first.gvkey then sum = 0;
  sum = sum + x;
 if last.gvkey then output;
 /* it assumes not to create a record, when it is not the last.gvkey */
 run;

/* data step vs proc sql - does not have the retain */
proc sql;
	create table r3 as select gvkey, sum(x) as sum from r group by gvkey;
quit;


/* 	One of the assignments (following residency 1) will be using retain
	It will be something like: SICH is often missing for companies (about 20%) of the time 
	you can either throw these away (if you need industry) 
	Or, you could use SICH code from an earlier year.
	So if SICH for some company is missing in 2010, 2011, and 2012
	but it is there in 2009, then you can assume it didn't change 
	forward-fill that missing SICH (by gvkey) */
 
