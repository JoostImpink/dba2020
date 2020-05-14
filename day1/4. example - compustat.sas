/*
	Example pipeline
	----------------

	Create a dataset using Compustat Funda (financial statements data) and CRSP (returns):

	- For the fiscal years 2010 - 2019
	- Dropping financial firms (with SICH between 6000 and 6999)
	- Variables Compustat:
		- size (MCAP): csho * prcc_f (=shares outstanding x stock price)
		- return on assets (ROA): IB / AT 
		- market to book ratio (MTB): csho * prcc_f / ceq 
			(=shares outstanding x stock price / book equity)
		- sales growth (GROWTH) (sale / sale of previous year - 1)
		- beginning of year (BOY): date of first day of month, 11 months before datadate 
			(if datadate is dec 31, 2015, then boy is jan 1, 2015)
		- 2-digit SIC (SIC2), take first 2 digits of SICH, for example 3411 -> 34
		- create decile ranks based on size (MCAP_D) (use proc rank)		
	- Drop any observation with any missing of the variables above 
	- Variable CRSP
		- return (RET): stock return over the fiscal year, using the crsp-compustat link 
			table, get permno, then get 12 monthly returns over the fiscal year and compound these
	
	In SAS:
	- Count the observations by year
	- Count the observations by 2-digit industry
	- What is median and mean roa by mcap deciles
	- Get sample descriptives (mean, median, min, max, standard deviation)	
		- How about these descriptives for each mcap decile?	
	
	Export tables to Excel (csv), export dataset to Stata

	In Stata:
	- Create a table with descriptive statistics
	- Create a correlation table	
	- Do a regression:
		- Dependent variable: stock return
		- Independent variables: return on assets, market cap, market to book ratio, growth
	- Winsorize the variables (in Stata)
	- Redo the tables

	In-class assignments (SAS):
	- Explain 'missing' function, then explore how many firm-years are missing
	- Explain 'retain', then look into how we can forward fill a prior year's SICH 
	- Create a variable 'big', 1 if sales for the firm-year exceeds the median 
		industry sales (for that year), 0 otherwise

*/
