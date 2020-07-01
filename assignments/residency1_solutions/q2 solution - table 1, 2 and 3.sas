/* 	Table 1
	Left panel shows by year the #obs, and the #loss years
	Right panel shows the same, but for firms that were in the sample from 1968 
	through 1990 (23 years)
*/

/*	Left panel */

/* 	Using SQL */
proc sql;
	create table t1_left as
	select fyear, count(*) as numObs, sum(loss) as numLossFirms, 
	/* 'calculated' refers to a variable constructed in the query (as opposed to a variable on the dataset) */
	calculated numLossFirms / calculated numObs as percLoss
	from b_sample group by fyear;
quit;

proc print;run;

/*	Right panel */

/*	We need the subsample of firms that have 23 years of data over 1968-1990 */
proc sql;
	create table temp as 
		select gvkey, count(*) as numYears 
		from b_sample 
		where 1968 <= fyear <= 1990 
		group by gvkey 
		having numYears eq 23;
quit;

/* 	using gvkey IN ... gets gvkeys in that ( select gvkey from temp) */
proc sql;
	create table t1_right as
	select fyear, count(*) as numObs, sum(loss) as numLossFirms, 
	/* 'calculated' refers to a variable constructed in the query (as opposed to a variable on the dataset) */
	calculated numLossFirms / calculated numObs as percLoss
	from b_sample
	where 1968 <= fyear <= 1990 
	and gvkey IN (select gvkey from temp)
	group by fyear;
quit;

/* 	Table 2
	Use firms that have at least 8 years of data
	Count the number of loss-years
*/

/*	4402 firms with at least 8 years of data */
proc sql;
	create table temp as 
		select gvkey, count(*) as numYears 
		from b_sample 		
		group by gvkey 
		having numYears >= 8;
quit;

/* 	For each gvkey in the above table, count the #loss-years */
proc sql;
	create table t2_firms as
	select gvkey, sum(loss) as lossYears from b_sample	
	/* gvkey must be in the following table */
	where gvkey IN (select gvkey from temp )
	group by gvkey;
quit;

/* Tabulate the lossYears */
proc sql;
	create table t2 as select lossYears, count(*) as numFirms from t2_firms group by lossYears;
quit;


/*	Table 3 
	For each size decile: compute #firm-years and #losses 
*/

/*	Create size deciles */
proc rank data = b_sample out = t3_ranked groups = 10;
var size; 		
ranks size_d ; 
run;

/*	Add 1 to rank (0-9 => 1-10) */
data t3_ranked;
set t3_ranked;
size_d = size_d + 1;
run;

proc sort data=t3_ranked; by size_d; run;

/* get decile, count, #loss years, % loss years */
proc sql;
	create table t3 as
		select size_d, count(*) as numObs, sum(loss) as lossYears, sum(loss)/count(*) as percLoss
		from t3_ranked
		group by size_d;
quit;

