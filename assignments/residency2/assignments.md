# Assignments (following Residency 2) 

## 1. Matching most recent record

Suppose you have a dataset with monthly returns, which you need to match with yearly accounting data (for example, to add a market to book control variable).

Use the following datasets for the monthly and yearly data:

```SAS
data returns;
  input @01 id       
  	@03 date  MMDDYY10.
        @14 return;
format date date9.;
datalines;
1 10/31/2013 0.01
1 11/30/2013 0.02
1 12/31/2013 0.03
1 01/31/2014 -0.01
1 02/28/2014 0.01
2 10/31/2013 -0.01
2 11/30/2013 0.02
2 12/31/2013 0.01
2 01/31/2014 -0.02
2 02/28/2014 -0.03
2 03/31/2014 0.02 
run;

data yearly;
  input @01 id        
  	@03 date  MMDDYY10.
        @14 equity;
format date date9.;
datalines;
1 12/31/2011 8
1 12/31/2012 10
1 12/31/2013 11
2 12/31/2012 30
2 12/31/2013 28
run;
```

## 2. Macros

Extend the macro of problem 4 (residency 1 assignments), such that the macro is able to use crsp.dsf (daily stock file) or crsp.msf (monthly stock file), using an additional argument passed when invoking the macro ('granularity=daily' or 'granularity=monthly'). So, if you want returns for a short window (few days), you would call the macro with 'granularity=daily', for long windows (fiscal year or longer), you would call it with 'granularity=monthly'. Also, add an argument ('varname=') to name the newly created return variable. 

Then, use this macro to compute return for several windows (note variable 'rdq' - earnings announcement date - is on Compustat Funda):

```SAS
%getReturn(dsin=a_funda, dsout=b_ret1, start=rdq-1, end=rdq+1, granularity=daily, adjustMarket=yes, varname=rdq_ret1);
%getReturn(dsin=b_ret1,   dsout=b_ret2, start=rdq-1, end=rdq+1, granularity=daily, adjustMarket=no, varname=rdq_ret2);
%getReturn(dsin=b_ret2, dsout=b_ret3, start=datadate-365, end=datadate, granularity=monthly, adjustMarket=no, varname=rdq_ret2);
```

## 3. Pseudo test

Describe the main regression equation for your dissertation. Then, describe how you can set up a (meaningful) pseudo test.

## 4. Industry leaders

Write SAS code that uses Compustat and retrieves firm-quarters for 2004-2013 of firms with fiscal year end in December (fyr is 12). Additionally, there need to be at least 10 active firms in each 4-digit SICH industry-quarter for firms to be included. Determine industry-quarter median firm size (using sales), and flag each observation whether or not its sales are above/below the industry median. Wrap this code in a macro that can be invoked as %getFirmYears(dsout=)

For firms in Compustat Fundamental Annual (Funda) retrieve gvkey, fyear, sale, sich and rdq for the years 2010-2019. Then, determine the industry leader for each 4-digit SICH industry-years. The industry leader has above-median sales, and is the first one to report earnings (variable rdq in Compustat Funda holds the earnings announcement date). Also compute the number of days the firms report later relative to the industry leader. Use proc rank to create delay deciles, where the quickest filers are in decile 1 and the slowest filers in decile 10 (do this by year, as filing requirements changed over time). Wrap the code in a macro that can be invoked as %industryLeaders(dsin=,dsout=) which adds delay_rank to the input dataset.