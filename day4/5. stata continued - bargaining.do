/*

Example: interaction variable

When is an interaction variable appropriate, how to set up the hypothesis, regression model, and how to test/interpret.

Suppose we are conducting a study relating to bargaining power. Let's say our first hypothesis tests if large firms have more bargaining power (in alternative format):

H1: Bargaining power increases with firm size

So to test this hypothesis, we use performance (return on assets) and a measure of competition as the dependent variable, and firm size and other (control) variables as the independent variables.

Next, Assume that we have theory suggesting that the bargaining power depends on the type of industry in terms of contract intensity:
- low contract intensity (CI) industries: inputs are purchased on markets, like oil, chicken legs, etc
- high contract intensity (CI) industries: firms have to contract with suppliers, like airplane manufacturing, car manufacturing

So, contract intensity could moderate the relation between size and bargaining power. When any firm can purchase inputs on a market (low CI), bargaining power means less compared to the setting where firms negotiate one-on-one (high CI).

H2: Bargaining power of large firms increases with industry contract intensity 


The following variables are on the dataset (years 1998-2009)
	
	gvkey: firm identifier
	fyear: fiscal year
	industry: Fama French industry code (12 industries)
	roce: return on capital employed 
	ci: contract intensity (between 0 - lowest and 1 - hightes) (online available by prior research by Nunn)
	ln_sales: natural log of firm salesgr_1y
	firmage: number of years the firm has been listed
	lev: leverage (debt as a percentage of assets)
	salesgr_1y: percentage sales growth (current sales/previous year sales - 1)
	pctcomp: captures usage of competition-related words in the 10-K, provided by Feng Li (2012)
	
*/

// the dataset is online, and can be loaded:
use http://www.wrds.us/day4_bargaining.dta , clear

// make time-series
// turn gvkey (which is text) into a number (needed for next command)
destring  gvkey, replace
// set this dataset as timeseries: gvkey identifies firm, fyear identifies year
tsset gvkey fyear

// lagged, differences, leading variables
// for this to work, the dataset needs to be defined as a timeseries with tsset (see above)
gen ln_sales_lag = L.ln_sales
gen ln_sales_diff = D.ln_sales
gen ln_sales_lead = F.ln_sales

// * is a wildcard and will match all variation (variables that start with ln_sales)
browse gvkey fyear ln_sales*

// interaction term
gen ci_ln_sales = ci * ln_sales

// Summary statistics
sum roce ci ln_sales // summary statistics
sum roce, d // detailed summary statistics
tab fyear // number of obs by year
tabstat ci ln_sales roce pctcomp, stats (n mean min p25 p50 p75 max sd) col(stat) 

// OLS regression
reg roce    ln_sales ci             firmage lev salesgr_1y i.fyear i.industry 

// what is the median value of ci?  .6691962  
sum ci, d

// split the sample into low vs high ci (based on median)
// low ci (oil, chicken legs, etc)
// coefficient ln_sales: 0.0137376
reg roce    ln_sales ci             firmage lev salesgr_1y i.fyear i.industry if ci < 0.6691962 
// high ci (aircraft, car manufacturing)
// coefficient ln_sales: 0.017314  
reg roce    ln_sales ci             firmage lev salesgr_1y i.fyear i.industry  if ci >= 0.6691962 

// compare the coefficient on ln_sales: in which subsample is it stronger?
// you could test h2 comparing these coefficients (using a t-test), but it is better to use a single
// regression for the full sample with the interaction effect (below)


// L., D., F. can be used in a regression (no need to create new variables)
// say you want previous year's sales growth
reg roce    ln_sales ci             firmage lev L.salesgr_1y i.fyear i.industry  if ci >= 0.6691962 

// use eststo-esttab to make tables with multiple regressions output (one column for each regression)
// To install eststo:
// findit eststo // click on the link for 'st0085_1', then 'click here to install'

// Example: results for two different models exported to a csv file (you can actually click on the link)

// test of hypothesis 1 -- coefficient of ln_sales

eststo clear
eststo: reg roce    ln_sales ci             firmage lev salesgr_1y i.fyear i.industry 
eststo: reg pctcomp ln_sales ci             firmage lev salesgr_1y i.fyear i.industry  

// test of hypothesis 2 -- coefficient of ci_ln_sales
eststo: reg roce    ln_sales ci ci_ln_sales firmage lev salesgr_1y i.fyear i.industry 
eststo: reg pctcomp ln_sales ci ci_ln_sales firmage lev salesgr_1y i.fyear i.industry  


// UF Apps
esttab using M:\stata_day4_output_table.csv, b(3) t(2) drop(dfyear*) star(* 0.10 ** 0.05 *** 0.01) r2

// PC
esttab using C:\git\dba2020\day4\stata_day4_output_table.csv, b(3) t(2) drop(dfyear*) star(* 0.10 ** 0.05 *** 0.01) r2



