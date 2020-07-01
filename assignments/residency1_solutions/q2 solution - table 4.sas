/*	Regressions */

/* 	regressions are done on sample of firms with at least 8 years of data 
	(4,148 firms in table 4 corresponds with 4,148 firms in table 2)
*/

/*	firms with at least 8 years of data */
proc sql;
	create table temp as 
		select gvkey, count(*) as numYears 
		from b_sample 		
		group by gvkey 
		having numYears >= 8;
quit;

/* 	For each gvkey in the above table, count the #loss-years */
proc sql;
	create table t4_firms as
	select *, sum(loss) as lossYears from b_sample	
	/* gvkey must be in the following table */
	where gvkey IN (select gvkey from temp )
	group by gvkey
	;	
quit;

/*	Winsorize outliers ('dampens' first and last percentile) */

/*	Import winsorize macro */
filename m1 url 'https://gist.githubusercontent.com/JoostImpink/497d4852c49d26f164f5/raw/11efba42a13f24f67b5f037e884f4960560a2166/winsorize.sas';
%include m1;

/*	Invoke winsorize */
%winsor(dsetin=t4_firms, byvar=fyear, dsetout=t4_firms_wins, vars=e_p ch_e_p ret, type=winsor, pctl=1 99);


/*	Upper panel 
	These are pooled regressions: all firms, loss firm-years, profit-firmyears, both levels and changes

	See ODS options
	https://documentation.sas.com/?docsetId=statug&docsetTarget=statug_reg_details52.htm&docsetVersion=15.1&locale=en
*/
%macro table4_upper( dsin=, vars=, outp=);

proc reg data= &dsin  ;		
	model ret = &vars ;
	ods output	ParameterEstimates  = &outp._params
	            FitStatistics 		= &outp._r2
				NObs				= &outp._obs;
quit;
%mend;

%table4_upper( dsin= t4_firms_wins                       , vars= e_p , outp= up_full_level);
%table4_upper( dsin= t4_firms_wins (where =(loss eq 1 )) , vars= e_p , outp= up_loss_level);
%table4_upper( dsin= t4_firms_wins (where =(loss eq 0 )) , vars= e_p , outp= up_profit_level);

%table4_upper( dsin= t4_firms_wins                       , vars= ch_e_p , outp= up_full_ch);
%table4_upper( dsin= t4_firms_wins (where =(loss eq 1 )) , vars= ch_e_p , outp= up_loss_ch);
%table4_upper( dsin= t4_firms_wins (where =(loss eq 0 )) , vars= ch_e_p , outp= up_profit_ch);



/* 	Lower panel 
	These are time series regressions: one regression for each firm, and the beta, R-squared are reported
	(levels and regressions)
*/

/* example -- this is the first line, levels regression */
proc sort data=t4_firms_wins; by gvkey ;run;

proc reg data=t4_firms_wins noprint edf outest=h_parms2; /* edf means degrees of freedom */
model ret = e_p  ; 
by gvkey;
run;

/* median e_p and median r-squared */
proc sql;
	create table t4_low_all_lev as
		select count(*) as numFirms, median(e_p) as e_p_median, median(_RSQ_) as r_squared from h_parms2 ;
quit;


/*	Let's turn it into a macro */
%macro t4_lower(dsin=, var=, outp=);

proc reg data=&dsin noprint edf outest=t4_params; /* edf means degrees of freedom */
model ret = &var  ; 
by gvkey;
run;

/* median e_p and median r-squared */
proc sql;
	create table &outp as
		/* &vars only works in this case because it is one variable */
		select count(*) as numFirms, median(&var) as var_median, median(_RSQ_) as r_squared from t4_params ;
quit;

%mend;

/* levels */
/* use where= to filter the observations you want to use */ 
%t4_lower(dsin=t4_firms_wins,                               var=e_p, outp=t4_low_all_lev);
%t4_lower(dsin=t4_firms_wins (where=(lossYears eq 0)),      var=e_p, outp=t4_low_0_lev);
%t4_lower(dsin=t4_firms_wins (where=(lossYears eq 1)),      var=e_p, outp=t4_low_1_lev);
%t4_lower(dsin=t4_firms_wins (where=(2 <= lossYears <= 3)), var=e_p, outp=t4_low_2to3_lev);
%t4_lower(dsin=t4_firms_wins (where=(4 <= lossYears <= 5)), var=e_p, outp=t4_low_4to5_lev);
%t4_lower(dsin=t4_firms_wins (where=(lossYears > 5)),       var=e_p, outp=t4_low_5up_lev);

/* changes */
%t4_lower(dsin=t4_firms_wins,                               var=ch_e_p, outp=t4_low_all_ch);
%t4_lower(dsin=t4_firms_wins (where=(lossYears eq 0)),      var=ch_e_p, outp=t4_low_0_ch);
%t4_lower(dsin=t4_firms_wins (where=(lossYears eq 1)),      var=ch_e_p, outp=t4_low_1_ch);
%t4_lower(dsin=t4_firms_wins (where=(2 <= lossYears <= 3)), var=ch_e_p, outp=t4_low_2to3_ch);
%t4_lower(dsin=t4_firms_wins (where=(4 <= lossYears <= 5)), var=ch_e_p, outp=t4_low_4to5_ch);
%t4_lower(dsin=t4_firms_wins (where=(lossYears > 5)),       var=ch_e_p, outp=t4_low_5up_ch);



