// load the dataset
use "http://www.wrds.us/sample_dataset.dta"

// make time-series
destring  gvkey, replace
tsset gvkey fyear

// Generate dummy variables for fyear
tabulate fyear, gen(dfyear)
// ff12 is an industry classification (Fama French 12 industries)
// generating 12 dummy variables for those
tabulate ff12_, gen(dff12_)

// Summary statistics
sum ret beta // summary statistics
sum eps, d // detailed summary statistics
tab fyear // number of obs by year
tabstat ret roa beta size btm bve eps, stats (n mean min p25 p50 p75 max sd) col(stat) 

// difference-in-difference designs

// treatment firms only (each firm is its own control)
// for example: new regulation came out in 2012 for group audits (multiple auditors)
// putting more responsibility on the principal (main) auditor
// did some characteristic (earnings informativeness - EI) improve?
// sample: some years before 2012, some years after => POST = 1 for years >= 2012
// EI = a + b POST + c CONTROLS
// coefficient b tests if regulation affects the dependent variable

// treatment firms vs control firms
// problem: maybe something else made EI change for all firms after 2012, and that is what POST is picking up
// fix: include non-affected firms
// options:
// - include all non-affected firms
// - match each affected firm with a similar non-affected firm
//      - simple match: match on industry and size
//      - fancy match: propensity score matching 
// TREATMENT = 1 for treated firm, 0 for matched firm
// EI = a + b POST + c TREATMENT + d POST x TREATMENT + e CONTROLS
// coefficient d tests if regulation affected firms

// this setup is cleanest for exogenous shocks (firms didn't choose to make new regulation)
// endogeneity (self selection) would be present if you study CEO being fired, doing an acquisition, hiring expert intermediary, etc. 


// example: some new regulation becomes effective 2010 for firms with an odd gvkey
// which is expected to affect profitability (roa)
gen treatment = mod(gvkey,2)
gen post = 0
replace post = 1 if fyear >= 2010
gen treatment_post = treatment * post

// inspect
browse gvkey fyear treatment post treatment_post
tab post treatment

// OLS regressions
// using the treatment firms as their own control
reg roa post                          beta size btm bve eps dfyear* dff12_* if treatment == 1
// notice how treatment and treatment post are dropped (only using treatment firms)
reg roa post treatment treatment_post beta size btm bve eps dfyear* dff12_* if treatment == 1

// treatment and control firms
reg roa post treatment treatment_post beta size btm bve eps dfyear* dff12_* 

// multiple regressions in one table - use 'eststo' with 'esttab'

// To install:
findit eststo // click on the link for 'st0085_1', then 'click here to install'

// Example: results for two different models exported to a csv file (you can actually click on the link)

eststo clear
eststo: reg roa                               beta size btm bve eps dfyear* dff12_* 
eststo: reg roa post treatment                beta size btm bve eps dfyear* dff12_* 
eststo: reg roa post treatment treatment_post beta size btm bve eps dfyear* dff12_* 

esttab using M:\stata_output_table.csv, b(3) t(2) drop(dfyear*) star(* 0.10 ** 0.05 *** 0.01) r2

