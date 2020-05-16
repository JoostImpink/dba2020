
// the dataset is online, and can be loaded:
use http://www.wrds.us/day1_sample.dta , clear

// to run a line, select it, and press 'control D'
// you can also select the line, then in top menu, select 'Tools', and 'Execute (do)'

// see all variables
browse

// see some variables
browse gvkey fyear ret growth mcap_d

// see some variables with some condition (== means condition/filter)
browse gvkey fyear ret growth mcap_d if mcap_d == 3

// how many obs
count

// how many obs for condition/filter
count if mcap_d == 3

// obs by year
tab fyear

// obs by sic2
tab sic2

// descriptive statistics
// descriptive statistics
tabstat ret roa mcap mtb growth , stats (n mean min p10 p25 p50 p75 p90 max sd) col(stat)

// exporting descriptive statistics
estpost tabstat ret roa mcap mtb growth , stats (n mean min p10 p25 p50 p75 p90 max sd) col(stat) 
// export: make sure path/folder exists
esttab . using C:\git\dba2020\day1\sample_descriptives.csv ,  replace cells(" min p50 mean max sd ")

// correlation table
pwcorr ret roa mcap mtb growth 
pwcorr ret roa mcap mtb growth ,sig

// regression
reg ret roa mcap mtb growth 

// with year dummies
reg ret roa mcap mtb growth i.fyear

// winsorize variables

// installing winsor
// findit winsor  
// select: winsor from http://fmwww.bc.edu/RePEc/bocode/w
// help for winsor: http://fmwww.bc.edu/repec/bocode/w/winsor.html

winsor ret, gen(ret_w) p(0.01)
winsor roa, gen(roa_w) p(0.01)
winsor mcap, gen(mcap_w) p(0.01)
winsor mtb, gen(mtb_w) p(0.01)
winsor growth, gen(growth_w) p(0.01)

// compare; sum (summarize) ', d' for details 
sum ret
sum ret, d
sum ret_w, d

// sort by ret
sort ret
browse ret ret_w

// descriptive statistics (winsorized variables)
tabstat ret_w roa_w mcap_w mtb_w growth_w , stats (n mean min p10 p25 p50 p75 p90 max) col(stat) 

// regression winsorized variables
reg ret_w roa_w mcap_w mtb_w growth_w 
reg ret_w roa_w mcap_w mtb_w growth_w i.fyear
reg ret_w roa_w        mtb_w growth_w i.mcap_d i.fyear

// by the way, the regression is not set up very clean as there is some circularity
// if return is high, then mcap and mbt are also higher
