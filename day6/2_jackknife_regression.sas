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

/* You could manually invoke the `regRobust` macro and 'hardcode' leaving out one industry at the time: */


%regRobust(dsin=c_mydata_wins(where=(fyear ne 2000)), dep=mtb, model=growth roa size, outp=_reg1);
%regRobust(dsin=c_mydata_wins(where=(fyear ne 2001)), dep=mtb, model=growth roa size, outp=_reg2);
%regRobust(dsin=c_mydata_wins(where=(fyear ne 2002)), dep=mtb, model=growth roa size, outp=_reg3);

/* 
This is a good setting to use Clay's macros; we can use `%do_over` with `values=1-12`. 

If you want to combine the output of 12 regressions, you will need to have a condition to know whether some regression is the first regression, or if it the results need to be appended.

In the following code we test if the output dataset 'jackknife' exists with: `%if %sysfunc(exist(jackknife))`. If it doesn't exist, we can set 'jackknife' to the first regression output (`data jackknife; set _reg1_params;run;`).

If it does exist, we can append the regression output to 'jackknife': `proc append base=jackknife data=_reg1_params;run;`
*/


%macro doJackknife(filter);
	/* run regression excluding fyear with value &filter */
	%regRobust(dsin=c_mydata_wins (where=(fyear ne &filter )), dep=mtb, model=growth roa size, outp=_reg1);

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

/* delete jackknife results (relevant if you run the code for a second time)*/
proc datasets; delete jackknife; quit;

/* repeat regression leaving out one industry at the time */
%do_over(values=2000-2017, macro=doJackknife);

/* is the coefficient for size robust across jackknife groups? */
data jackknife_size;
set jackknife;
if Parameter eq "size";
run;


/* question -- can you create a macro that makes the coefficient flexible
so, invoked as: 
%getCoefficientPerYear(coeff=growth);
%getCoefficientPerYear(coeff=roa);
%getCoefficientPerYear(coeff=size);
 */