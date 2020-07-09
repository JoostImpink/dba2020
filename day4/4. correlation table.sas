/*
	Code to make a correlation table (with p-values):
		- lower left panel: Pearson
		- upper right panel: Spearman (rank correlations)        
*/

/*	Let's use Hayn dataset 
 	----------------------
*/

/* UF Apps */
%let wrds = wrds-cloud.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;
rsubmit;
filename hayn4 url 'http://www.wrds.us/Hayn_table_4.sas';
%include hayn4;
proc download data=t4_firms_wins out=t4_firms_wins;run;
endrsubmit;

/*	SAS Studio */
filename hayn4 url 'http://www.wrds.us/Hayn_table_4.sas';
%include hayn4;


/*	Load macro (from web) 
	---------------------
*/

filename mcorr url 'http://www.wrds.us/macro_correlation.sas';
%include mcorr;

/*  Invoke macro to create corrCoeff and corrProb*/
 
%correlationMatrix(dsin=t4_firms_wins, vars=ret e_p ch_e_p, mCoeff=corrCoeff, mPValues=corrProb);

/*	Export these to existing Excel sheet, and beautify there. Worksheets need to exist */
proc export data= corrCoeff outfile= "C:\git\dba2020\day4\Hayn_correlation.xlsx" dbms=xlsx replace; sheet="correlations"; run;
proc export data= corrProb outfile= "C:\git\dba2020\day4\Hayn_correlation.xlsx" dbms=xlsx replace; sheet="pvalues"; run;
