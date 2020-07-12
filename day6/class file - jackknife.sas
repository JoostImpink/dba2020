/*  Jackknife regression

Jackknife: repeat regressions with excluding one firm/industry/group at the time. This is helpful for robustnest checks (is some year, or some industry driving the results?).
*/

/* Good example is the crime paper, which tests if violent video game releases are associated with (short term) increases in crime 
This paper just uses 15 game releases. So, a natural question to ask is if a single one of these just happens to be correlated
with an unrelated event where crime increased.
The analysis on page 46 tabulates the regressions where 1 game at the time is left out of the sample. The results should remain stable (and these are).
*/

/* Let's run this regression: mtb = a + b GROWTH + c ROA + d SIZE + e
	but leave out one year at the time */

/* Remember that it is generally helpful to have the regression wrapped in a macro: */

%macro regRobust(dsin=, dep=, model=, outp=);
proc surveyreg data=&dsin;   
   	model  &dep = &model dyr2000-dyr2017;  
	ods output
      ParameterEstimates  = &outp._params 
      FitStatistics = &outp._fit
      DataSummary = &outp._summ;
quit;
%mend;

/* regression (surveyreg allows 'class' which will make dummies)*/
proc surveyreg data= p.deals;	
	class year industry;
	model deal = size treatment privateBuyer buyAssets year industry / solution;	
	ods output
      ParameterEstimates  = outp_params 
      FitStatistics = outp_fit
      DataSummary = outp_summ;
quit;

%macro regRobust(dsin=, dep=, model=, outp=);
proc surveyreg data= &dsin;	
	class year industry;
	model &dep = &model year industry / solution;	
	ods output
      ParameterEstimates  = &outp._params 
      FitStatistics = &outp._fit
      DataSummary = &outp._summ;
quit;
%mend;

filename mprint 'E:\temp\day6_sas_macrocode.sas';
options mfile mprint;

%regRobust(dsin=p.deals, dep=deal, model=size treatment privateBuyer buyAssets, outp=outp);

/*1990-2007*/
proc sql;
	create table years as select distinct year from p.deals;
quit;

/* I just want to test one line here:

*/
%let filter = 1990;
%regRobust(dsin=p.deals (where=(year ne &filter )), dep=deal, model=size treatment privateBuyer buyAssets, outp=_reg1);	

	data _reg1_params;
	set _reg1_params;
	filter= &filter;run;

%macro doJackknife(filter);
	/* run regression excluding fyear with value &filter */
	%regRobust(dsin=p.deals (where=(year ne &filter )), dep=deal, model=size treatment privateBuyer buyAssets, outp=_reg1);	

	/* set filter variable on regression output (to identify results)*/
	data _reg1_params;
	set _reg1_params;
	filter= &filter;run;

	/* keep all results in a single dataset work.jackknife*/
	%if %sysfunc(exist(jackknife)) %then %do;
		/* Add new obs to original data set */
		proc append base=jackknife data=_reg1_params; run;
  	%end;
  	%else %do;
		/* first regression: set jackknife */
		data jackknife; set _reg1_params;run;
	%end;
%mend;

/*  Include array function macros */
filename m1 url 'http://www.wrds.us/macros/array_functions.sas';
%include m1;


/* delete jackknife results (relevant if you run the code for a second time)*/
proc datasets; delete jackknife; quit;

/* repeat regression leaving out one industry at the time */
%do_over(values=1990-2007, macro=doJackknife);

/* is the coefficient for size robust across jackknife groups? */
data jackknife_treatment;
set jackknife;
if Parameter eq "treatment";
run;


/* question -- can you create a macro that makes the coefficient flexible
so, invoked as: 
%getCoefficientPerYear(coeff=growth);
%getCoefficientPerYear(coeff=roa);
%getCoefficientPerYear(coeff=size);
 */
