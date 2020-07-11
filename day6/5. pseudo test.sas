/* 	See canvas datasets for 'deals.zip'.  */

/* variables:

	deal			log of the deal (price for which a company was sold)
	treatment		indicator, 1 if treatment, 0 otherwise 
	size			log of NetSales, Net Sales Annual gross sales, net of returns and discounts allowed, if any.
	privateBuyer	1 if private company , 0 if acquirer is public
	buyAssets		1 if transaction type is assets purchased, 0 if stock purchased
	year 			year of transaction
	industry		2-digit SIC code of industry company sold
*/

/*	I have the dataset locally 
	Change this to fit your setup; copy it into M: drive for SAS UF Apps, or upload into SAS Studio
*/
libname p "E:\temp";

/* summary statistics */
proc means data=p.deals n min mean median max stddev;
	var deal size treatment privateBuyer buyAssets;
run;

/* correlations */
proc corr data = p.deals ;
	var deal size treatment privateBuyer buyAssets;
run;

/* regression (surveyreg allows 'class' which will make dummies)*/
proc surveyreg data= p.deals;	
	class year industry;
	model deal = size treatment privateBuyer buyAssets year industry / solution;	
quit;


/* pseudo test */

/* 	A pseudo test is a test that is intended to give us confidence about the specification.
	It is set up in such a way that it should not give results.

	Example: you are doing an event study and find that certain events lead to stock price increases.
	A pseudo test would be to replace the 'real' dates with random dates. The positive relation should go away
	when rerunning the regression with the random dates.

	In the regression, it could be that 'treatment' just happens to occur more often at higher or lower prices, and
	not related with a higher deal value. (The correlation between deal and treatment is negative; a positive coefficient
	would be most problematic as it may be driving the results.)

	A pseudo test could be:
	- for each treatment observation (treatment = 1), find a control observation (treatment = 0) with similar size,
	and set 'treat_fake' to 1 for that observation (this is a fake treatment, not a real one)
	- drop all real treatment observations
	- drop all 'real' treatment observations from the sample and rerun the regression testing treat_fake 
	(the sample now will have only 'fake' treatment observations and control observations)

*/

proc sql;
	create table d_pseudo as
	/* 'a' is the regular sample, 'b' will hold the id of the 'fake' restatement observations */
	select 
		a.*, b.id as fake_id,
		/* difference is the difference in predicted value, smaller values means more similar */
		abs(a.size -b.size) as difference
	/* left self join, we want to keep all observations, not just what matches */
	from p.deals a left join p.deals b
	on
		a.treatment eq 1 /* table a will be treatment group */
	and b.treatment eq 0 /* table b control group */
	/* same fyear */
	/* note: also requiring same industry gave too few matches */
	and a.year = b.year 
	/* we need to group by, because we want the closest match for each transaction */
	group by a.id
	/* keep closest match, use 'having' because difference is not on the input dataset, but computed in the select*/
	having difference = min(difference) and difference < 0.01; 
quit;


/* 	It is possible multiple matches have the same minimum difference, keep the first */
proc sort data=d_pseudo nodupkey; by id;run;

/* 	Inspect the dataset: for treatment firms only we have a variable 'fake_id' with the deal of some control observations

	Next steps: 
	- set a fake treatment variable to 1 for these obs 
	- drop all observations with treatment = 1 (real treatments)
*/

proc sql;
	create table e_pseudo2 as 
		select a.*, ( b.fake_id > 0) as treat_fake
		from d_pseudo a left join d_pseudo b
		on a.id = b.fake_id;
quit;

/* some fake treatment firms were 'closest' to multiple real treatment obs; nodupkey will drop these */
proc sort data=e_pseudo2 nodupkey; by id;run;

/* correlations 
	notice that treatment is negatively correlated with deal value (but positive coefficient in earlier regression)
*/
proc corr data =e_pseudo2;
var deal treatment treat_fake size;
run;

data f_only_fake;
set e_pseudo2;
/* git rid of real treatment obs */
if treatment eq 0;
run;

/* summary statistics  */
proc means data=f_only_fake n min mean  median max stddev;  
  var deal size treatment treat_fake privateBuyer buyAssets;
run;

/* pseudo test regression */
proc surveyreg data= f_only_fake;	
	class year industry;
	model deal = size treat_fake privateBuyer buyAssets year industry / solution;	
quit;
