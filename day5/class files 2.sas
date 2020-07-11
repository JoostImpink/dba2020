/*
	Dataset for restatements is on Canvas, file restatements.zip in datasets day 5

	I have unzipped it to E:\temp\
	So I have a libname statement using this folder

	UF Apps
	-------

	With M drive you can copy it to your M Drive 
	and use: libname r "M:\";
	or a folder if you placed it inside a folder, like: libname r "M:\dba\day5\"; 

	SAS Studio
	----------

	If you use SAS Studio, you can unzip and upload the .sas7bdat file as follows:
	- create a folder in SAS Studio, name it 'day5'
	- click the upload button (4th button, arrow pointing up) and save it in the 'day5' folder 
	- use: libname r '~/day5';
*/

libname r "E:\temp";

/* 	Variables on the dataset restatements:

	gvkey:			firm identifier
	fyear:			fiscal year
	sale:			sales revenue
	sich: 			4-digit industry code
	roa:			return on assets
	restatement:	dummy 1, if fiscal year is restated later on, 0 otherwise
	industry:		first 2 digits of sich
	
	There are 63503 firm-years (2010-2018), of which:
	restatement value 0:	61327 obs (pool of potential control firm-years)
	restatement value 1:	2176 obs (treatment firm-years)

*/


/* 	Logistic regression predicting having a restatement in a year
	So, the dependent variable is restatement
*/
proc logistic data=r.restatements descending  ;
  /* class will make dummies for the different values of industry and fyear */
  class industry fyear;
  /* we are using profitability, size, industry and year-effects to explain restatements */
  model restatement = roa sale industry fyear/ RSQUARE SCALE=none ;
  /* output out will make a new dataset (restate_prob) that has everything that is in the input dataset
  	and an extra variable predicted with the fitted value (wich is a probability of having a restatement) */
  output out = r.restate_prob PREDICTED=predicted ;
  /* if you want to capture coefficients, number of obs, etc, use ods output
  	the typical things to look at are spread over 7 datasets*/
  ods output
    ParameterEstimates  = _outp1
    OddsRatios = _outp2
    Association = _outp3
    RSquare = _outp4
    ResponseProfile = _outp5
    GlobalTests = _outp6			
    NObs = _outp7;
quit;

/* 2176 restatement firms that have a predicted value */
data z;
set r.restate_prob;
if restatement eq 1;
if predicted ne .;
run;


/* r.e_matched has 2175 matches 
	so there is one observation that didn't get matched
*/


/* 	Dataset restate_prob has the actual restatement (0, or 1), and the modeled probability of having a restatement 
	(variable predicted), so one dataset that has the treatment firms and the pool of all possible control firms

	The next thing is to pair each restatement firm -year(restatement = 1), with another firm-year with no restatement 
	(restatement = 0). We will require that the treatment and control firm are from the same industry, and have the same
	fiscal year.

	Since both treatment and potential control firms are on the same dataset we can use a self-join
*/
proc sql;
	create table r.e_matched as
	/* 'a' is restatement firm, 'b' is non-restate matched firm */
	select 
		a.fyear, a.industry, /* industry and year are the same for treatment and matched control firm */
		a.gvkey as gvkey_t, b.gvkey as gvkey_m, 
		a.roa as roa_t, b.roa as roa_m, 
		/* difference is the difference in predicted value, smaller values means more similar */
		a.predicted as predicted_t, b.predicted as predicted_m, abs(a.predicted -b.predicted) as difference
	/* self join */
	from r.restate_prob a, r.restate_prob b
	where
		a.restatement eq 1 /* table a will be treatment group (restatement) */
	and b.restatement eq 0 /* table b control group */
	/* same industry, same fyear */
	and a.industry = b.industry and a.fyear = b.fyear 
	/* we need to group by, because we want the closest match for each firm-year */
	group by a.gvkey, a.fyear
	/* keep closest match, use 'having' because difference is not on the input dataset, but computed in the select*/
	having difference = min(difference); 
quit;

/* 	It is possible multiple matches have the same minimum difference, keep the first */
proc sort data=r.e_matched nodupkey; by gvkey_t fyear;run;

/* 	With this setup it is possible that a single firm-year is the closes match to multiple restatement firm-years 
	If you want the matches to be unique, you will need to drop the second, third, etc match and redo the procedure,
	removing the treatment and control firm-years that are 'used' */


/* I have a dataset now for each restatement firm I have the gvkey for a control firm */

/* what if I want to do analyses like, match these observations back to Compustat, CRSP
and analyse any differences 

from what I have (2100 something rows), how can I make a dataset that looks like this:

	this should be 2 x 2100 something
	gvkey			gvkey (so that is gvkey_m or gvkey_t)
	fyear			fyear (already there)
	restatement		1 for records where gvkey is gvkey_t, 0 otherwise
	..

*/
/* let's make a dataset with gvkey, fyear, and restatement = 1 for gvkey_t firms (restatement firms) */
data new1 (keep = gvkey fyear restatement matched_with);
set r.e_matched;
gvkey = gvkey_t;
matched_with = gvkey_m;
restatement = 1;
run;

/* let's make a dataset with gvkey, fyear, and restatement = 0 for gvkey_m firms (control firms) */
data new2 (keep = gvkey fyear restatement matched_with);
set r.e_matched;
gvkey = gvkey_m;
matched_with = gvkey_t;
restatement = 0;
run;
/* glue together */
data new3;
set new1 new2;run;

/* another way using 'output' */
data new4 (keep = gvkey restatement fyear);
set r.e_matched;
/* treatment firms */
gvkey = gvkey_t;
restatement = 1;
output;
/* control firms */
gvkey = gvkey_m;
restatement = 0;
output;
run;
