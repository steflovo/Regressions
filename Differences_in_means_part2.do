use http://www.stata-press.com/data/r10/bpwide.dta, clear

** Alternative method to get table with differences in means and statistical significance


**==============================================================================
**   Differences in means using Stata 17
**==============================================================================

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
