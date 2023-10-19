
**==============================================================================
**==============================================================================
**==============================================================================
**==============================================================================
**   Differences in means
**==============================================================================

sysuse auto.dta, clear

sysuse auto.dta, clear
reg mpg foreign
tabstat mpg, by(foreign)
dtable mpg, by(foreign)
ttest mpg, by(foreign)

**==============================================================================
**   One variable 
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

**==============================================================================
**==============================================================================
**==============================================================================
**==============================================================================
**   Interactions
**==============================================================================


sysuse auto.dta, clear

*overall
reg price mpg 

*subsamples
reg price mpg if foreign==0
reg price mpg if foreign==1

tabstat price, by(foreign)

*generate an interaction term manually
ge i_mpg_for = mpg*foreign

*interaction 1
reg price mpg i_mpg_for

*interaction 2
reg price c.mpg##foreign

*interaction 3
reg price foreign c.mpg#foreign
test 1.foreign#c.mpg = 0.foreign#c.mpg

*==============================================================
*============= Control variables ==============================

*subsamples 2
reg price mpg length if foreign==0
reg price mpg length if foreign==1

*interaction 4 (ONLY DO THIS WHEN INTERACTING A CONTINOUS VARIABLE WITH A DUMMY)
reg price foreign c.mpg#foreign length 

*interaction 5 (ONLY DO THIS WHEN INTERACTING A CONTINOUS VARIABLE WITH A DUMMY)
reg price foreign c.mpg#foreign c.length#foreign 

*==============================================================
*============= Panel data======================================

use http://www.stata.com/data/jwooldridge/eacsap/wagepan.dta, clear

xtset nr year
xtdes

xtsum educ
ge postgraduate = educ>12

* baseline
xtreg lwage fin i.year, fe

ge i_fin_postgr = fin*postgraduate 

* baseline 2
xtreg lwage fin  i.year , fe
reghdfe lwage fin , absorb(year nr)

*subsamples 2
reghdfe lwage fin  if postgraduate==0, absorb(year nr)
reghdfe lwage fin  if postgraduate==1, absorb(year nr)
di .2025657 - .1391845

* interaction 6
reghdfe lwage fin postgraduate i_fin_postgr , absorb(year nr)

* interaction 7
reghdfe lwage fin##postgraduate, absorb(year nr)

* interaction 8 --- NO (Be careful!!)
reghdfe lwage postgraduate fin#postgraduate , absorb(year nr)

* interaction 9
reghdfe lwage fin##postgraduate, absorb(year##postgraduate nr##postgraduate)

**==============================================================================
**==============================================================================
**==============================================================================
**==============================================================================
**   Difference in differences
**==============================================================================
