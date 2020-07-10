// load the dataset
use "http://www.wrds.us/sample_dataset.dta", clear

// make time-series
destring  gvkey, replace
tsset gvkey fyear

// Generate dummy variables for fyear
tabulate fyear, gen(dfyear)
// ff12 is an industry classification (Fama French 12 industries)
// generating 12 dummy variables for those
tabulate ff12_, gen(dff12_)


// Multicollinearity
// -----------------
// From wikipedia: https://en.wikipedia.org/wiki/Multicollinearity
//    In statistics, multicollinearity (also collinearity) is a phenomenon 
//    in which two or more predictor variables in a multiple regression model 
//    are highly correlated, meaning that one can be linearly predicted from 
//    the others with a substantial degree of accuracy.

// including both total assets (at) and equity (ceq) 
reg ret beta size btm bve eps at ceq 
// a vif score above 10 is deemed to be too 'high'
vif
// including both total assets (at) and lagged assets (L.at), this is going to be problematic because total assets don't change that much over time
reg ret beta size btm bve eps at ceq L.at
// a vif score above 10 is deemed to be too 'high'
// at and lagged at are problematic to include at the same time 
vif
// correlations
corr at L.at ceq

//Not all types of regressions support the vif command. 
//For example,  'xtreg' doesn't, but you can first run a 'reg' equivalent 
//of the regression, and see if multicollinearity is an issue for that 
//specification.


// Dealing with outliers

// Winsorizing is a variable-by-variable approach 
// In a regression, you can still have leverage points (data points with
// a high influence) even if the data is winsorized
// For example, for 2 variables the values are in the 98th percentile

// Cook's distance, see Wikipedia https://en.wikipedia.org/wiki/Cook%27s_distance

// to detect outliers/leverage points you can utilize Cook's Distance in Stata.


// initial regression
reg ret beta size btm bve eps at ceq 
// compute cook's distance
predict cook, cooksd, if e(sample)
// rerun regression without leverage points
// cutoff: 4 / n-k, where n is number of observations and k is #independent variables (including intercept)
// number of observations in sample dataset
count
// rerun regression without leverage points
reg ret beta size btm bve eps at ceq if cook < 4/ (46805-8)
// browse leverage points that were excluded
browse if cook > 4/ (46805-8)

// Ranked regression

// Another way to deal with outliers is to use ranked regression. For each variable, all values are sorted from low to high, and the ranks (1, 2, 3, ...) are assigned in that order. Indicator variables do not need to be ranked.
// The rank transformation results in a variable that has a uniform distribution (it removes distance information).

egen ret_r = rank(ret)
egen beta_r = rank(beta)
egen size_r = rank(size)

sort ret
browse ret ret_r

reg ret_r beta_r size_r

