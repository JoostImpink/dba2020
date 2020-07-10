# Endogeneity

## Sources of endogeneity

An endogeneity problem occurs when an explanatory variable is correlated with the error term:
- Omitted (correlated) variable
- Measurement error in the independent variables
- Simultaneity (bi-directionality)
- Selection bias (self-selection)

## Regression 

`Y = b0 + b1 X1 + b2 X2 + e`

Endogeneity exists when X2 and the error term are correlated. This correlation violates the assumptions of OLS (see technical discussion here: [https://en.wikipedia.org/wiki/Endogeneity_(econometrics)](https://en.wikipedia.org/wiki/Endogeneity_(econometrics)))


## Omitted correlated variables

A variable is not included in the model, but should have been. It is most problematic if the variable that tests your hypothesis is correlated with the omitted variable.

The remedy/approach is to use regression specifications of prior literature.

More details: [https://en.wikipedia.org/wiki/Omitted-variable_bias](https://en.wikipedia.org/wiki/Omitted-variable_bias)

## Measurement error

Say you want to compute the earnings response coefficient (ERC), that is, for each 'unit' of unexpected earnings, how much does the stock market react? In other words: for each $0.01 higher-than-expected earnings per share, how much percent does the stock price go up? 

Model:

`Y = b0 + b1 X + e`

Where Y is the stock return around the earnings announcement (1 or 2 day return), and X is the earnings surprise (reported EPS - analyst forecast EPS, typically scaled by stock price). The coefficient b is the ERC estimate.

The ERC is an often used measure as it reflects a dimension of reporting quality. (If quality is higher, then reported earnings influence stock prices more.)

In archival settings, researchers use the analyst forecast as the expected earnings number, and subtract that from the reported number to get to the earnings surprise.

Where is the measurement error? The analyst forecast is not updated frequent enough, so the forecast is typically a few weeks old. So, there is measurement error in X (there is information reflected in stock return, which is not reflected in the earnings surprise).

> In this specific setting the bias as a result of measurement error can be mitigated by including an extra independent variable of the stock return over the period between the date of the analyst forecast and prior the earnings announcement. This return is correlated with the measurement error, but not with the dependent variable, so it reduces the downward bias in the ERC.

## Simultaneity (bi-directionality)

In accounting research, this issue is recognized, but it is too hard to deal with that it is ignored. 

### Examples

Firm size and profitability. Does profitability lead to larger firms? Or do larger firms make higher profits? Probably both: firms start out small (from the garage), and at some point there is success (or failure). In case of success, 'good things' happen (new deals/more customers, exposure, etc), where profit and size grow hand in hand.

Measures of performance. Both accounting information and the stock market can be seen as performance measures (earnings vs stock return), and have overlapping underlying source of events. Firms make journal entries of transactions, aggregate/report these, and the stock market learns and incorporates new information from whatever source (including the firm). In accounting research, stock market performance is often linked to accounting performance (typically stock return as the dependent), while the 'true' relation is probably simultaneous.

### Sample study

See [https://link.springer.com/content/pdf/10.1007/s11116-017-9791-1.pdf](https://link.springer.com/content/pdf/10.1007/s11116-017-9791-1.pdf) for a study that looks at car ownership and enrolling (or not) in car-sharing programs. "The effect of carsharing on vehicle ownership is a dynamic process that plays out over a period of time—past ownership influences enrollment decisions, which in turn influence holdings in a later period."

In other words, both car ownership and enrollment are dependent variables. (But, a regression can only have 1 dependent variable. The study uses a system of equations, meaning multiple regressions estimated in one go.)

### Intuitive example

Say you work at Designer Shoe Warehouse and you want to evaluate the profitability of sending out coupons for discounts to customers. 

`Y = b0 + b1 Coupon + e`

Where Y is customer sales over some period, and Coupon is 1 if the customer received a coupon.

This regression can be estimated without issues when coupons are sent out randomly. But, what if coupons are sent out based on past customer orders? Then it is no longer random (sales => coupon => more sales => another coupon etc). Example comes from [here](Introduction to Endogeneity - Towards Data Science.pdf)


## Selection bias (self-selection)

### Examples

The classic example in econometrics is the wage offer of married women (yes, this sounds old-fashioned). In entering the labor market, people only participate if the wage exceeds their 'reservation' pay. We do not observe pay data non-participating people. (The idea being if you have children to take care for you probably have a higher 'reservation' pay then if you don't have children. Not sure if this is currently still true, but at the time that Heckman wrote his paper, women were more likely to take care of children than men, hence 'wage offer of married women'). 

Why do firms voluntary disclose bad news? Bad news disclosures reduce the stock price. However, we do not observe the counterfactual (what would stock price do if the firms did not disclose)? Potentially there is information (unobservable to researchers), but available to (some) market participants that make managers do this. For example, a class action lawsuit can be successful if it can be shown that management had information and did not disclose it. 

Firms that diversity (conglomerates) are found to be trading at a discount relative to 'pure' play (undiversified) firms (Berger and Ofek 1995). Is diversification the cause of the discount? Not necessarily, possibly poor performing pure play firms are more likely to diversify and diversification may have created value.


### Instrumental variables

Instrumental variables, also called two-stage least squares, is an attempt to reduce the problems of endogeneity.

Say you have this model:

`Y = a + b X + c Z + e`

where Z is correlated with e (endogeneity problem).

With two stage least squares you do two regressions (hence two-stage). In the first step, you regress the 'problematic' variable (Z in this case) on 'instruments', which are variables that explain Z, but not Y.

Step 1: `Z = a + bX + cV +dW + e`

The fitted value of Z is Z*

Then, in the second stage, the fitted value of Z is included in the regression on Y.

Step 2: `Y = a + bX + cZ* + e`

For this to work well, the instruments need to explain Z well (called the 'strong first stage assumption'), and the instruments explain Y through , but not directly (called 'exclusion restriction').

Interesting read: https://medium.com/teconomics-blog/machine-learning-meets-instrumental-variables-c8eecf5cec95

### Instumental variables using Stata

Stata has a command [rivregress] (https://www.stata.com/manuals/rivregress.pdf)

2SLS estimation of a linear regression of y1 on x1 and endogenous regressor y2 that is instrumented
by z1:

`ivregress 2sls y1 x1 (y2 = z1)`

This is shorthand for the following steps:

`regress y2 x1 z1`

// fitted value of y2, see predict command https://www.stata.com/manuals13/rpredict.pdf
`predict y2hat`

// use fitted value instead of y
`regress y1 y2hat x1`

Try it yourself:

```
// 1978 Automobile Data, comes with Stata
sysuse auto 
// rename variables
rename price y1
rename mpg y2
rename displacement z1
rename turn x1 

ivregress 2sls y1 x1 (y2 = z1)

// vs

// it is common practice to include all independent variables in the first stage
// ivregress does that by default 
regress y2 x1 z1 
predict y2hat
regress y1 y2hat x1
```

### Heckman test

See [further reading - Heckman selection](further reading - Heckman selection.md)