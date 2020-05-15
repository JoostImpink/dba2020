// load the dataset

// you can load a local file, e.g. (if you are on UF Apps you can read from M:)
// use "M:\day2_hayn.dta", clear

// the Hayn dataset is online, and can be loaded:
use http://www.wrds.us/day2_hayn.dta , clear

// make time-series
destring  gvkey, replace
tsset gvkey fyear

// Summary statistics
sum ret e_p // summary statistics
sum e_p, d // detailed summary statistics
tab fyear // number of obs by year
tabstat ret e_p ch_e_p, stats (n mean min p25 p50 p75 max sd) col(stat) 

// OLS regression
reg ret e_p
reg ret e_p ch_e_p

reg ret e_p if loss == 0
reg ret e_p if loss == 1

reg ret e_p ch_e_p if loss == 0
reg ret e_p ch_e_p if loss == 1


// Generate dummy variables
tabulate fyear, gen(dfyear)

// including year indicator variables
reg ret e_p ch_e_p dfyear* if loss == 0

// same as
reg ret e_p ch_e_p i.fyear if loss == 0

// lagged, differences, leading variables
gen size_lag = L.size
gen size_diff = D.size
gen size_lead = F.size

browse gvkey fyear size size_lag size_diff size_lead

// L., D., F. can be used in a regression (no need to create new variables)
reg ret e_p ch_e_p i.fyear L.size D.size

// use eststo-esttab to make tables with multiple regressions output (one column for each regression)
// To install eststo:
// findit eststo // click on the link for 'st0085_1', then 'click here to install'

// Example: results for two different models exported to a csv file (you can actually click on the link)

eststo clear
eststo: reg e_p 
eststo: reg e_p ch_e_p 
eststo: reg e_p ch_e_p dfyear* 
// UF Apps
esttab using M:\stata_output_table.csv, b(3) t(2) drop(dfyear*) star(* 0.10 ** 0.05 *** 0.01) r2

// PC
esttab using C:\git\dba2020\day2\stata_output_table.csv, b(3) t(2) drop(dfyear*) star(* 0.10 ** 0.05 *** 0.01) r2