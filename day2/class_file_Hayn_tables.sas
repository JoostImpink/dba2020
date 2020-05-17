/* class file day 3 */

data test;
x = 1; output;
x = -2;output;
x = .;output;
run;

data test2;
set test;
loss = ( x < 0 );
run;

data test3;
set test;
loss = 0 ;
if x < 0 then loss = 1;
run;

/* what if you need to do something with 5 years of sales */
	proc sql;
		create table b_growth as
		select a.*, b.sale , b.fyear
		from a_comp a, a_comp b
		where a.gvkey = b.gvkey 
			/* get 5 years of sales */
		and a.year - 5 <  b.fyear  <= a.fyear;
	quit;
/* if the measure you need is the standard deviation of ROA */

	proc sql;
		create table b_growth as
		select a.*, b.roa , b.fyear
		from a_comp a, a_comp b
		where a.gvkey = b.gvkey 
			/* get 5 years of sales */
		and a.year - 5 <  b.fyear  <= a.fyear;
	quit;
/*	proc means; where you compute the standard deviation of roa BY gvkey fyear */


/* table 1; for each year we want to know #firms, #loss firms, % of loss firms */
/* left side */
proc sql;
	create table t1 as
		select fyear, 
			/* count the #firms */
			count(*) as numFirms, 
			/* count the #loss firms */
			sum(loss) as loss_fyear,
			/* percentage */
			sum(loss) / count(*) as percentage,
			mean(loss) as perc_alt,
			calculated loss_fyear / calculated numFirms as perc_alt2
		from b_sample
		group by fyear;
quit;

proc export data=t1 outfile="C:\git\dba2020\day2\Hayn tables\table1_left.csv" replace; run;

/* same stuff for firms that are in each of the years 1968-1990 */
/* extra step -- get the firms that are in the sample 23 years (1968-1990) */
proc sql;
	create table t1_right as
		select key, fyear, loss , count(*) as howOften
		from b_sample
		where 1968 <= fyear <= 1990 /* where filters on the input dataset */		
		group by gvkey
		having howOften eq 23; /* having filters on the output dataset */
quit;
proc sql;
	create table t1_right2 as
		select fyear, count(*) as numFirms, sum(loss) as loss_fyear, mean(loss) as perc_alt
		from t1_right
		group by fyear;
quit;

proc export data=t1_right2 outfile="C:\git\dba2020\day2\Hayn tables\table1_right.csv" replace; run;

/* table 4 */

proc means data=b_sample mean median min max N;
  var e_p ch_e_p ret;  
run;

/*	Import winsorize macro */
filename m1 url 'https://gist.githubusercontent.com/JoostImpink/497d4852c49d26f164f5/raw/11efba42a13f24f67b5f037e884f4960560a2166/winsorize.sas';
%include m1;

/*	Invoke winsorize */
%winsor(dsetin=b_sample, byvar=fyear, dsetout=b_sample_wins, vars=e_p ch_e_p ret, type=winsor, pctl=1 99);

/* descriptives after winsorizing */
proc means data=b_sample_wins mean median min max N;
  var e_p ch_e_p ret;  
run;


/* For table 4 only use observations with at least 8 years of data */

proc sql;
	create table b_sample_wins_8more as
		select * , count(*) as howOften
		from b_sample_wins		
		group by gvkey
		having howOften >= 8 ; /* having filters on the output dataset */
quit;

/* how many unique gvkeys I have - 4402  (Hayn 4148) */
proc sql; create table test as select distinct gvkey from b_sample_wins_8more; quit;

/* upper panel - pooled regression (everything, all the observations in one regression) */
/* full sample, levels (e_p in the model) */
/*	Pooled, levels */
proc reg data= b_sample_wins_8more;		
	model ret = e_p ;
	ods output	ParameterEstimates  = up_full_level_params
	            FitStatistics 		= up_full_level_r2;
quit;
/* full sample, but only loss firms, still e_p */
proc reg data= b_sample_wins_8more (where =(loss eq 1 )) ;		
	model ret = e_p ;
	ods output	ParameterEstimates  = up_loss_level_params
	            FitStatistics 		= up_loss_level_r2;
quit;

/* pc */
filename mprint 'C:\git\dba2020\day2\tempSAScode.txt';
options mprint mfile;

%macro table4_upper( dsin=, vars=, outp=);

proc reg data= &dsin  ;		
	model ret = &vars ;
	ods output	ParameterEstimates  = &outp._params
	            FitStatistics 		= &outp._r2;
quit;
%mend;

%table4_upper( dsin= b_sample_wins_8more                       , vars= e_p , outp= up_full_level);
%table4_upper( dsin= b_sample_wins_8more (where =(loss eq 1 )) , vars= e_p , outp= up_loss_level);
%table4_upper( dsin= b_sample_wins_8more (where =(loss eq 0 )) , vars= e_p , outp= up_profit_level);

%table4_upper( dsin= b_sample_wins_8more                       , vars= ch_e_p , outp= up_full_ch);
%table4_upper( dsin= b_sample_wins_8more (where =(loss eq 1 )) , vars= ch_e_p , outp= up_loss_ch);
%table4_upper( dsin= b_sample_wins_8more (where =(loss eq 0 )) , vars= ch_e_p , outp= up_profit_ch);


/* lower panel - time series -> one regression for each firm 4,000 or so regressions */

proc sort data=b_sample_wins_8more; by gvkey ;run;

proc reg data=b_sample_wins_8more noprint edf outest=h_parms2; /* edf means degrees of freedom */
model ret = e_p  ; 
by gvkey;
run;

/* median e_p and median r-squared */
proc sql;
	create table table4_lower as
		select count(*) as numFirms, median(e_p) as e_p_median, median(_RSQ_) as r_squared from h_parms2 ;
quit;
