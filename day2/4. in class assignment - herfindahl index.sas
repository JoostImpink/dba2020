/*

	Create a dataset from Funda for the years 2012- (code given below), and append the 
	Herfindahl industry concentration index

	The index is computed as follows:
	- for each sich-fyear, compute total industry sales (sum of firm-year sales in that industry)
	- compute the market share of each company (company sales divided by total industry sales)
	- compute the square of the market share, and add these for all firms in the industry-year

	The Herfindahl index ranges between 0 (many small firms) to 1 (one firm in the industry)

*/

rsubmit;endrsubmit;
%let wrds = wrds-cloud.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

/* to locally view datasets on wrds 
when datasets have changed on wrds, you need to navigate out of the folder and back in to refresh
*/
Libname rwork slibref=work server=wrds;

/* 1 Compustat data */
rsubmit;
proc sql;	
	create table a_comp as		
		select gvkey, fyear, sich, sale 		
		from comp.funda		
		where fyear >= 2012 
		and missing (sich + sale) eq 0
		/* this is some boilerplate filtering (gets rid of doubles) */
		and indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C';
quit;

proc download data=a_comp out = a_comp;run;

endrsubmit;
