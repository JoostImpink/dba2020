/*

Example of the use of 'having' (using Hayn dataset)

*/


%let wrds = wrds-cloud.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

rsubmit;

filename hayn4 url 'http://www.wrds.us/Hayn_table_4.sas';
%include hayn4;

proc download data=t4_firms_wins out=t4_firms_wins;run;

endrsubmit;

/* we have: gvkey, datadate, fyear, ret, e_p, ch_e_p */

proc sql;
	create table new1 as
		select gvkey, e_p, ( e_p < 0 ) as loss, ret from t4_firms_wins;
quit; 

/* only keep if newloss is 0 */
proc sql;
	create table new1 as
		select gvkey, e_p, ( e_p < 0 ) as newloss, ret
		from t4_firms_wins
		having newloss eq 0;
quit; 

/* I want firms that e_p went up by at least 10% from the previous year
	in select create e_p_growth, in having filter on it
*/
proc sql;
	create table new2 as
		select a.*, a.e_p / b.e_p -1 as e_p_growth
		from t4_firms_wins a left join t4_firms_wins b
		on a.gvkey = b.gvkey
		and a.fyear -1 = b.fyear
		having e_p_growth > 0.1;
quit; 

/* find another firm that has similar e_p */
proc sql;
	create table new2 as
		select a.gvkey, a.e_p, a.fyear, b.gvkey as gvkey_m, b.e_p as e_p_m,
			/* compute the difference in e_p */
			abs( a.e_p  - b.e_p) as difference

		from t4_firms_wins a , t4_firms_wins b
		where a.fyear eq b.fyear
		/* not have the firm itself be its best match */
		and a.gvkey ne b.gvkey
		/* this needs a group by because we need to find the minimum difference for each
			firm year */
		group by a.gvkey, a.fyear
		having min(difference) = difference; 
quit; 

/* multiple firms can be the best match (same difference), keep one */
proc sort data=new2 nodupkey; by gvkey fyear;run;

