
/* import dataset */

filename csvFile url "http://www.wrds.us/graph_data.csv" termstr=crlf;

proc import datafile=csvFile out=myData replace dbms=csv; run;

/* scatter plot, x and y are already named x and y */
proc sgplot data = myData; 
scatter x = x y = y; 
run;

/* let's make a quintile ranked variable: first 20% obs: 0, next 20%: 1, etc */

/* proc rank does not give same #obs in each group */
proc rank data=mydata out=mydata2 groups=5;
Var x;
Ranks x_rank; 
run;

/* count #obs for each x_rank */
proc sql; select x_rank, count(*) as numobs from mydata2 group by x_rank; quit;

/* instead of using proc rank, let's construct it ourselves using _N_ /

/* first: the order of observations may not be random -- let's add a random variable*/

data myData3;
set myData;
randomVar = rand("Uniform");
run;

/* now obs with same value of x are in random order */
proc sort data=myData3; by x randomVar;run;

/* let's make bins -- first get number of observations */
proc sql;
	select count(*) into :numObs from mydata3;
quit;

/* how many observations per bin? */
%let nrBins = 5; 
%let binSize =  %sysevalf(&numObs/&nrBins) ; /* sysevalf can hold fraction, %eval would round it */
%put If we want &nrBins buckets, we need &binSize obs per bucket (for &numObs observations);

/* determine the bin */
data mydata4;
set mydata3;
x_rank  = floor( ( _N_ - 1 ) / &binSize);
run;

/* check: count #obs for each x_rank */
proc sql; select x_rank, count(*) as numobs from mydata4 group by x_rank; quit;

/* median values by rank */
proc sql;
	create table mydata5 as 
		select x_rank, median(y) as y_median
		from mydata4
		group by x_rank;
quit;

/* barchart */
proc sgplot data = mydata5;
 vbar x_rank / response = y_median; 
RUN; 

/* more dramatic */
proc sgplot data = mydata5;
 vbar x_rank / response = y_median; 
 yaxis min=3000;
RUN; 
