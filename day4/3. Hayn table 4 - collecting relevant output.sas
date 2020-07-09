/*
	Create dataset SAS UF Apps.

	The code at http://www.wrds.us/Hayn_table_4.sas (you can open this page in a browser)
	creates the dataset (t4_firms_wins). It is not a macro, so there is no macro call. 
	The %include will load and run the page.

*/
%let wrds = wrds-cloud.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

rsubmit;

filename hayn4 url 'http://www.wrds.us/Hayn_table_4.sas';
%include hayn4;

proc download data=t4_firms_wins out=t4_firms_wins;run;

endrsubmit;

/*
	Create dataset SAS Studio

*/

filename hayn4 url 'http://www.wrds.us/Hayn_table_4.sas';
%include hayn4;

/*	After you run the above code, inspect to see the work library and make sure t4_firms_wins is there (69,000 obs) */


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

/* So, 6 regressions give us 6 x 3 output datasets:
	from _params we need: Variable (e_p vs ch_e_p) and Estimate from row 2 
	from _r2 we need: nValue2 from row 1
	from _obs we need: NObsUsed from row 1 
*/

/* Mechanism to 'pull' something into a macro variable with SYMPUT */

/* _null_ means no output dataset */
data _null_;
set up_full_level_params;
/* what we need is in the second row, _N_ is an internal row counter */
if _N_ eq 2 then do ;
	/* the value of Variable is copied into macro variable var */
	call symput ('var', Variable);
	/* the value of Estimate is copied into macro variable value */
	call symput ('value', Estimate);
end;
run;

%put The variable of this regression was: &var with value: &value;

/*	Get this info in a new dataset */
data newInfo;
panel = "upper";
vars = "&var"; /* need quotes here */
value = &value; /* no need for quotes as value is a number */
run;

/*	Remember there is also proc sql 'select into', which can also be used*/

/*	How do we automate this? 
	The macro %table4_upper would be a natural place to include this code to 'collect' the things we need.
	We also would not need to have 6 x 3 output datasets, but just create 3 output datasets, collect, and
	overwrite it when it is called again

	There is a proc append, which allows us to 'paste' a dataset onto another dataset. (So that sounds great.)
	The problem is that the first dataset cannot be appended (nothing to append it to)
	So we need to somehow figure out if we are dealing with the first time we run the macro or not

	One way to deal with this is to use code to detect if a dataset exists.
	Say, we want to collect all our output in a new dataset 't4'.
	The logic in the macro would be:
	- run the regression (create 3 output files)
	- does t4 exist?
		- yes: then append the new info to t4
		- no: make t4

	We need to remember to delete t4 if we rerun the code (otherwise it will just get longer)
	*/

/* We will bring this piece into the macro
	The %if is macro if, and won't run unless it is inside a macro
	It is used for the macro which code to generate.
	If it is 'true', the code within runs, otherwise it doesn't.	
	Check the mprint file to see the code that actually runs. After the first macro call
	you will see 'data t4; set newInfo; run;'. Subsequent macro calls will have the proc append.
*/

/* does t4 exist? */
%if %sysfunc(exist(t4)) %then %do;
	/* Yes, glue newInfo to it */
	proc append base=t4 data=newInfo; run;
  %end;
  %else %do;
	/* No, just copy newInfo */
	data t4; set newInfo;run;
%end;


/* 	Updated macro 

 	Removed outp=, as the output will be collected into t4
	Added message so that we can add something to help remember which model it was */
%macro table4_upperFancy( dsin=, vars=, message=);

proc reg data= &dsin  ;		
	model ret = &vars ;
	ods output	ParameterEstimates  = temp_params
	            FitStatistics 		= temp_r2
				NObs				= temp_obs;
quit;

	/* grab what we need (we don't need to get variable, as it is passed as &vars )*/	
	/* grab coefficient of variable */
	data _null_;
	set temp_params;	
	if _N_ eq 2 then call symput ('value', Estimate);	
	run;

	/* from _r2 we need: nValue2 from row 1 */
	data _null_;
	set temp_r2;	
	if _N_ eq 1 then call symput ('r2', nValue2);	
	run;

	/* NObsUsed from row 1 (let's get that) */
	data _null_;
	set temp_obs;	
	if _N_ eq 1 then call symput ('obs', NObsUsed);	
	run;

	/*	Get this info in a new dataset.
		This will be overwritten each time the macro runs.
		That is fine, because we are appending it to t4 each time 
	*/
	data newInfo;
	/* length keyword needed to prevent that these variables are 'too short'
		for example, message for first model is 'all', then length is set to 3
		but then message 'loss' will be cut to 'los'.
		Length keyword sets this to 20 characters (the $ indicates text)
	*/
	length message $20 vars $10 dsin $100; 
	
	vars = "&vars"; /* need quotes here */
	value = &value; /* no need for quotes as value is a number */
	rsq = &r2; /* rsquared */
	obsUsed = &obs; /* Number of observations */
	/* will help in Excel (VLOOKUP) to have message and vars in a single column */
	/* easiest to put the quotes around message here, around &message and &vars */
	message = "&message &vars"; 
	/* dataset used (why not..) */
	dsin = "&dsin";
	run;

	/* Does t4 exist? */
	%if %sysfunc(exist(t4)) %then %do;
		/* Yes: glue newInfo to it */
		proc append base=t4 data=newInfo; run;
	%end;
	%else %do;
		/* No: set newInfo as t4*/
		data t4; set newInfo;run;
	%end;

%mend;

/* delete t4 (relevant if you run the code for a second time)*/
proc datasets; delete t4; quit;

/* same as before, invoke it 6 times */
%table4_upperFancy( dsin= t4_firms_wins                       , vars= e_p , message = all);
%table4_upperFancy( dsin= t4_firms_wins (where =(loss eq 1 )) , vars= e_p , message = loss);
%table4_upperFancy( dsin= t4_firms_wins (where =(loss eq 0 )) , vars= e_p , message = profit);

%table4_upperFancy( dsin= t4_firms_wins                       , vars= ch_e_p , message = all););
%table4_upperFancy( dsin= t4_firms_wins (where =(loss eq 1 )) , vars= ch_e_p , message = loss););
%table4_upperFancy( dsin= t4_firms_wins (where =(loss eq 0 )) , vars= ch_e_p , message = profit););

/*	We have exported SAS datasets to csv files before. Now we will export to a specific worksheet
	on an existing Excel (.xlsx) file; make sure it exists (and has the worksheet we export into) */

/*	Export t4 to existing Excel sheet, and beautify there. Worksheet 'rawUpper' needs to exist */
proc export data= t4 outfile= "C:\git\dba2020\day4\Hayn_t4_beautify.xlsx"
dbms=xlsx replace; sheet="rawUpper"; run;


