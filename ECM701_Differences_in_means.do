sysuse auto.dta, clear

**==============================================================================
**   Differences in means
**==============================================================================
sysuse auto.dta, clear
reg mpg foreign
tabstat mpg, by(foreign)
dtable mpg, by(foreign)
ttest mpg, by(foreign)

**==============================================================================
**   Differences in means 
**==============================================================================

reg mpg foreign 
predict yhat, xb
reg mpg foreign weight length
predict yhat2, xb
tabstat mpg yhat, by(foreign)

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

**==============================================================================
**   Multiple categories
**==============================================================================

use http://www.stata-press.com/data/r10/bpwide.dta, clear
table agegrp sex, stat(mean bp_before) nototal

reg bp_before i.agegrp if sex==1 // women
nlcom (g30_45: _b[_cons]) ///
	  (g46_59 : _b[_cons] + _b[2.agegrp]) ///
	  (g60plus: _b[_cons] + _b[3.agegrp]) ///
	  (diff1: _b[2.agegrp]) ///
	  (diff2: _b[3.agegrp]) ///
	  (diff3: _b[3.agegrp] - _b[2.agegrp]), ///	  
	  post
estimates store ttestf  

reg bp_before i.agegrp if sex==0 // men
nlcom (g30_45: _b[_cons]) ///
	  (g46_59: _b[_cons] + _b[2.agegrp]) ///
	  (g60plus: _b[_cons] + _b[3.agegrp]) ///
	  (diff1: _b[2.agegrp]) ///
	  (diff2: _b[3.agegrp]) ///
	  (diff3: _b[3.agegrp] - _b[2.agegrp]), ///	  
	  post
estimates store ttestm

esttab ttest* , star(* 0.1 ** 0.05 *** 0.01) noomitt not  nogaps scalar(  )  b(%9.3f)  nocons   mtitle("Women" "Men")

esttab ttest*  using  ttest_part2 , csv replace star(* 0.1 ** 0.05 *** 0.01) noomitt not  nogaps scalar(  )  b(%9.3f)  nocons   mtitle("Women" "Men")  
