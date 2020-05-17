# Assignments (following Residency 1)

## 1. Missing SICH

For the observations in Funda, compute by year how often SICH is missing. (You can start with fiscal year 2000.) The missing function in SAS returns a 1 if a variable has a missing value:

```
data mydataOut;
set mydataIn;
missSich = missing(sich);
run;
```

The output should show the percentage missing SICH for each year.

Then, forward-fill any missing SICHs (by gvkey). So, if for any year the SICH is not missing, then use this SICH instead of any missing SICH.

> Hint: use a datastep with `retain`.

## 2. Hayn tables

Create tables 2, 3 and 4 (lower panel). Use the class code to generate the dataset (b_sample_wins and b_sample_wins_8more). Use macros when you notice code is duplicate.

> For table 2 and 4 you will need how many losses each firm has. Use proc sql with group by gvkey to sum the loss variable.

## 3. Macro stock return

Write a macro that computes (compound) stock return for a period. The macro needs to be invoked with the following arguments: `%getReturn(dsin=a_funda, dsout=b_ret, start=startdate, end=enddate)` where dsin already holds the firms and their permnos (gvkey, fyear, permno, sich, startdate, enddate). So these variables need to exist already (and are not made inside the macro). You may assume that the macro can use the monthly stock file (monthly returns).

Use your macro on data from Compustat Funda to compute return over the fiscal year, where startdate is the beginning of the fiscal year (first date of the month, 11 months prior to datadate).

## 4. Abnormal return

As above, but computing the cumulative abnormal return, by subtracting 'vwretd' from CRSP.MSIX (value weighted return). Make your macro flexible, so that people can specify if they want raw return (not adjusted, `adjustMarket=no`) or market adjusted return (`adjustMarket=yes`):

```SAS
%getReturn(dsin=a_funda, dsout=b_ret, start=startdate, end=enddate, adjustMarket=)
```

> Instead of multiplying (1 + firm return), you would multiply (1 + firm return - vwretd ) to take the market-wide return into account to get to the 'excess' or 'abnormal' part.


## 5. Relative industry ROA

Create a dataset from Funda with gvkey, fyear, sich, and return on assets for fiscal years 2010-2019. Construct a measure that is the average return on assets of the other firms in the industry-year, excluding the firm itself.

> Example: Firm A is in the same industry as firms B and C. For fiscal 2019, the ROA for firm A is 10%, firm B: 8% and firm C 6%. For firm A, the average ROA for the other firms (B and C) is 7%. But for firm B, the average ROA for the other firms (A and C) is 8%, etc.

> Hint: if you know the average age of a group of 12 people is 40 (including yourself), you can then multiply 12 people x 40 minus your own age and divide by 11 to get the average age of the other people. (In a similar way you can 'undo' the effect of a firm's ROA on the average ROA.)