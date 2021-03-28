sysuse auto.dta, clear

**==============================================================================
**   Differences in means
**==============================================================================

reg mpg foreign
tabstat mpg, by(foreign)

**==============================================================================
**   Multiple variables
**==============================================================================

foreach i of varlist price mpg weight  length {
	reg `i' foreign
	estadd scalar Domestic = _b[_cons] 
	estadd scalar Foreign = _b[_cons]  + _b[foreign] 
	estadd scalar Difference =  _b[foreign] 	
	estimates store `i'	
}

** display results
esttab price mpg weight  length,  nose nogaps b(%9.3f) star(* 0.1 ** 0.05 *** 0.01) scalar( Domestic Foreign Difference N)

** export table
esttab price mpg weight  length using ttest, csv replace nose nogaps b(%9.3f) star(* 0.1 ** 0.05 *** 0.01) scalar(Domestic Foreign Difference N)


