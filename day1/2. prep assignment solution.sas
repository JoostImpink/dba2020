
%let wrds = wrds-cloud.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

* this allows us to browse the remote work folder ;
Libname rwork slibref=work server=wrds;

rsubmit;
/* Keep relevant variables -- SICH is the industry code */
data mynames2 (keep = gvkey fyear tic conm sich);
set comp.funda;
/* tic is the variable name for ticker symbol */
where tic eq "INTC"; 
/* year after 2000 */
if fyear > 2000;
/* prevent double records */
if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
run;
proc download data=mynames2 out=mynames2;run;
endrsubmit;

/* so Intel is in sich 3674 */

/* Let's get the ratios for Intel, notice how we compute the ratios in the 'select'  */
rsubmit;
proc sql;
	create table myData as
		select conm, fyear, ni / at as roa, ni / sale as ros, sale / at as asset_turn		
		from comp.funda		
		where TIC eq "INTC" and fyear > 2000
		/* this is some boilerplate filtering (gets rid of doubles) */
		and indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C';
quit;

/* Median firm in the industry  3674(SEMICONDUCTORS & RELATED DEVICES), 
for SIC codes see https://www.sec.gov/info/edgar/siccodes.htm */

/* all firms in the industry */
proc sql;
	create table myData2 as
			select fyear, ni / at as roa, ni / sale as ros, sale / at as asset_turn
			from comp.funda
			/* filter: get all firms in industry 3674 after 2000 */
			where SICH eq 3674 and fyear > 2000
			/* this is some boilerplate filtering (gets rid of doubles) */
			and indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C';
quit;

/* median values of the industry -- 1 record for each year (because 'by fyear') */
proc sql;
	create table myData3 as
		select fyear, count(*) as numFirms, median(roa) as median_roa, median(ros) as median_ros, median(asset_turn) as median_asset_turn
		/* where to get it from: a subquery */
		from myData2
		/* compute it for each year => GROUP BY */
		group by fyear;
quit;

/* nested query -- combines previous 2 queries into 1 */
/*
proc sql;	
	create table myData3 as		
		select fyear, count(*) as numFirms, median(roa) as median_roa, median(ros) as median_ros, median(asset_turn) as median_asset_turn
		from (
			select fyear, ni / at as roa, ni / sale as ros, sale / at as asset_turn
			from comp.funda
			where SICH eq 3674 and fyear > 2000
			and indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C'
			)
		group by fyear;
quit;
*/
/* lets combine the two tables (match on year) */
proc sql;
	create table myData4 as 
	/* get everything ('*') from both tables */
	select a.*, b.* 
	from myData a, myData3 b 
	/* join on fiscal year */
	where a.fyear = b.fyear;
quit;

proc print;run;
endrsubmit;

/* why the industry median and not industry mean as a benchmark? */
