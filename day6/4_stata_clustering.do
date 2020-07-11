// load dataset either from disk, or from url

// load dataset from disk (make sure path is correct)
use "M:\dataset_resid2_day1.dta", clear
use "E:\teaching\dba\2019\residency 2 - day 1\datasets\dataset_resid2_day1.dta", clear

// load dataset from url
use http://www.wrds.us/dataset_resid2_day1.dta , clear

// turn gvkey into a number, and set as timeseries
destring  gvkey, replace
tsset gvkey fyear

// simple OLS
reg mtb growth roa size dyr2000-dyr2017

// OLS with robust standard errors
reg mtb growth roa size dyr2000-dyr2017, robust

// OLS with robust standard errors clustering by firm
reg mtb growth roa size dyr2000-dyr2017, robust cluster(gvkey)

// Fixed Effects regression
xtreg mtb growth roa size dyr2000-dyr2017 , fe 

// Fixed firm effects regression with clustering of standard errors by firm.
xtreg mtb growth roa size dyr2000-dyr2017 , fe vce(cluster gvkey)

// 2-way clustering

// In the above examples we have seen a few instances where standard errors were clustered. 
// For OLS there is also the cluster2 package, where you specify the firm identifier with 'fcluster'
// and time clustering with 'tcluster'.

// The package can be downloaded from Petersen's website, the direct link is 
// http://www.kellogg.northwestern.edu/faculty/petersen/htm/papers/se/cluster2.ado.

// See here for instructions on installing: https://www.stata.com/manuals13/u17.pdf

// type 'sysdir' in Stata command window to see all the places where Stata will look for packages
// with the UF Apps File manager, copy the downloaded 'cluster2.ado' file to 'M:\Documents\StataAdo\Plus'

cluster2 mtb growth roa size dyr2000-dyr2017, fcluster(gvkey) tcluster(fyear)