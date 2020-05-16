
rsubmit;endrsubmit;
%let wrds = wrds-cloud.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

/* to locally view datasets on wrds 
when datasets have changed on wrds, you need to navigate out of the folder and back in to refresh
*/
Libname rwork slibref=work server=wrds;

rsubmit;

	/* 	This code runs remotely on WRDS 
	   	libraries (comp, crsp) have been assigned with the sign on
		You will not be able to access libraries/folders on your pc (unless using 'proc upload')
		*/

	/*	Make key variables of Compustat Funda */
	data a_comp (keep = gvkey fyear datadate conm sich sale ib at ni ceq prcc_f csho mcap roa mtb boy sic2);
	set comp.funda;
	/* data is for fiscal years 2010-219, but we need one extra year to compute sales growth */
	if 2009 <= fyear <= 2019;
	/* no financial firms, so sich either < 6000 or >= 7000 */
	if sich < 6000 or sich >= 7000;
	/* none of these should be missing */
	if cmiss (of prcc_f csho ib at ceq sale) eq 0; 
	/* positive assets, positive equity */
	if at >0 and ceq > 0; 
	/* compute size (MCAP) */
	mcap = csho * prcc_f;
	/* return on assets (ROA) */
	roa = ib / at;
	/* market to book ratio (MTB) */
	mtb = mcap / ceq;
	/* this will set boy to the first day of 11 months before datadate */
	boy = intnx('month', datadate, -11, 'b');
	/* sich is 4-digit industry code, floor function rounds down */
	sic2 = floor (sich / 100);
	/* boilerplate filtering (gets rid of doubles) */
	if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C';
	format boy date9.;
	run;

	/* Sales growth requires sales from the previous year */
	proc sql;
		create table b_growth as
		select 
			/* a.* -> everything on a_comp */
			a.*, 
			/* sale from dataset 'a' (which is a_comp)
				and sale from 'b' (which is also a_comp)
				however: fyear from 'b' is fyear-1 from 'a' 
				in other words, b.sale will be sales of the previous year
				*/
			a.sale / b.sale - 1  as growth
		from
			/* notice how a_comp is used twice */ 
			a_comp a, a_comp b
		where 
			/* you need where =.. otherwise any record will match against any other record */
			/* same gvkey */
			a.gvkey = b.gvkey 
			/* but different years */
			and a.fyear - 1 = b.fyear;
	quit;

	/*create a decile rank variable for market cap (mcap) */
	proc rank data = b_growth out=c_ranked groups = 10;
	var mcap  ; 		
	ranks mcap_d  ; 
	run;

	/* Drop any observation with any missing of the variables above  */
	data c_ranked;
	set c_ranked;
	if cmiss (of roa mtb boy sic2 growth mcap mcap_d ) eq 0;
	run;

	/*	Get permno using the CCM merge lookup table
	    This is very boilerplate-like, the relevant thing is that this match gives
	    the correct permno at date 'boy' (in this case) for a given gvkey */      	
	proc sql;
	    	create table d_withpermno as
	    	select a.* , b.lpermno as permno
	    	from c_ranked a
	    	left join
	              crsp.ccmxpf_lnkhist b
	    	on a.gvkey = b.gvkey
	    	and b.linktype in ("LC" "LN" "LU" "LX" "LD" "LS")
	    	and b.linkprim in ("C", "P")   
	    	and ((a.boy >= b.LINKDT) or b.LINKDT = .B) and
	  	  ((a.boy <= b.LINKENDDT) or b.LINKENDDT = .E);
	quit;

	/*    Get stock return */
	proc sql;
	    create table e_ret (keep = gvkey fyear permno boy datadate date ret) as
	    select a.*, b.date, b.ret
	    from   d_withpermno a, crsp.msf b
	    where a.boy <= b.date <= a.datadate
	    and a.permno = b.permno
	    and missing(b.ret) ne 1;
	quit;

	/*    Compute compound return  -- yes, the exp(sum(log(1+ret))) is very compact!
	        Thanks to Lin, one of our graduated finance PhD students! */
	proc sql;
	        create table f_ret as
	        select gvkey, fyear, exp(sum(log(1+ret)))-1 as ret
	        from e_ret
	        /* compound for each firm year */
	        group by gvkey, fyear;
	quit;

	/* alternative to the above, using 'retain'
		Retain allows you to 'remember' something in a data step
		from one record to the next
		'.first' and '.last' can detect a new firm-year (when using by gvkey fyear) 
		retain a sum of compounded returns
		output will trigger a record
	*/
	/* requires sorting by gvkey fyear */
	proc sort data=e_ret ; by gvkey fyear; run;

/* assignment will be something like: SICH is often missing for companies (about 20%) of the time */
/* you can either throw these away (if you need industry) */
	/* use SICH code from an earlier year; so if SICH for some company is missing in 2010, 2011, and 2012
	but it is there in 2009, then you can assume it didn't change */
	/* forward-fill that missing SICH (by gvkey) */

rsubmit;
data f_ret_alt;
	set e_ret;
	retain ret_alt;
	by gvkey fyear;
	/* start with 1 if it is the first observation for a year */
	if first.fyear then ret_alt = 1;
	/* compound the return */
	ret_alt = ret_alt * ( 1 + ret);

	if last.fyear then ret_alt = ret_alt - 1; /* subtract 1 */
	/* when you remove the line below, you will get 12 records for each year */
	if last.fyear then output; 
	run;
endrsubmit;
	/*	Append return to our dataset with Compustat variables 
		This is a typical workflow: upload some dataset, construct some variables,
		and then append the newly created variables onto the uploaded dataset.
		Then download the resulting dataset.
		Left join will keep all original firm-years from the uploaded dataset.
	*/
	proc sql; 
		create table f_sample as select a.*, b.ret 
		from d_withpermno a left join f_ret b 
		on a.gvkey = b.gvkey and a.fyear = b.fyear;
	quit;
	/* append ret_alt */
	proc sql; 
		create table f_sample2 as select a.*, b.ret_alt
		from f_sample a left join f_ret_alt b 
		on a.gvkey = b.gvkey and a.fyear = b.fyear;
	quit;
	/*	Download to local work library */  
	proc download data=f_sample2 out=f_sample2;run;
 			
endrsubmit;

/* f_sample may have missing returns? why? */

data g_sample;
set f_sample2;
if missing(ret) eq 0;
run;


/* observations by year */

/* proc means */

/* summary statistics for full sample */
proc means data=work.g_sample n mean  median stddev ;
  OUTPUT OUT=work.h_count_alt n= /*mean= median= stddev= */ /autoname;
  var ret ;
run;


/* proc freq -- personally I don't use this */


/* proc sql */
	proc sql;
		create table h_count as 
			select fyear, count(*) as numObs from g_sample group by fyear;	
	quit;
	


/* observations by 2-digit SIC */
/* .. */

/* What is median and mean roa by mcap deciles */
/* .. */

/* Get sample descriptives (mean, median, min, max, standard deviation)	*/
/* .. */

/* How about these descriptives for each mcap decile? */
/* .. */

/* Export in dta format (for Stata) */

/* here we need to provide a folder where to export, this will depend on what you are using
	UF Apps: M:\ drive
	SAS Studio: "~" is the home folder 
	SAS installed on your pc: C:\ etc
*/


/* Export g_sample as Stata dataset */

/* Depending on your setup, pick one of the below  

	I have also uploaded the dataset online, so you can load the dataset in Stata from the web 
	http://www.wrds.us/day1_sample.dta
	For your dissertation you will need to find a way to 'push' files through your pipeline
*/

/* UF Apps, this will put it in the root of M, not in a folder (if you want to place it in a folder, create it first) */
proc export data=g_sample outfile="M:\day1_sample.dta" replace; run; /* Stata format */
proc export data=g_sample outfile="M:\day1_sample.csv" replace; run; /* Excel format */

/* SAS Studio, '~' means home folder */
proc export data=g_sample outfile="~/day1_sample.dta" replace; run; /* Stata format */
proc export data=g_sample outfile="~/day1_sample.csv" replace; run; /* Excel format */

/* PC, make sure folder exists */
proc export data=g_sample outfile="C:\git\dba2020\day1\day1_sample.dta" replace; run; /* Stata format */
proc export data=g_sample outfile="C:\git\dba2020\day1\day1_sample.csv" replace; run; /* Excel format */

