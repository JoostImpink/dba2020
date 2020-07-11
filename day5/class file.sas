

data ken;
cusip = "004567105"; output;
cusip = "124117205"; output;
cusip = "124467105"; output;
run;

data ken2;
cusip =   4567; output;
cusip = 124117; output;
run;

/* if you want to match ken with
ken2:
- ken: take the first 6
- and turn it numeric
then match
*/
data ken3;
set ken;
cusip6 = substr(cusip,1,6);run;

/* sometimes you need to match variables across datasets
and they are not in the same format
 industry codes sich
 firm identifiers like CIK (central index key)
*/

/* convert a text to number
	cusip can have text in real life, but in this example
it doesn't so we can use it as an example
*/

data ken_num;
set ken;
/* 6.0 is a format */
cusip_num = input(cusip,10.0);
cusip_num2 = input(cusip,10.2);
cusip_cheat = 1 * cusip;
run;

/* convert number to text*/
data ken_char;
set ken2;
new_num = INPUT(cusip, best.);
run;

/* need to match -- what is the best
so from best to worst 

best: gvkey, permno, cusip, cik

compromise: ticker symbol + date
			(match crsp.dsenames)

compromise: name + date
			(match crsp.dsenames)

worst: name, ticker symbol

*/

data ken_sim;
simil_0 = spedis("IBM", "IBM");
simil_1 = spedis("IBM", "ibm");
simil_2 = spedis("IBM, Inc.", "IBM");
simil_3 = spedis("IBM, Inc.", "International Business Machines, Inc.");
run;
