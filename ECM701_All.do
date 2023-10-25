
**==============================================================================
**==============================================================================
**==============================================================================
**==============================================================================
**   Differences in means
**==============================================================================

sysuse auto.dta, clear

tabstat mpg, by(foreign)
reg mpg foreign
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


use ECM701data_final, clear

*==============================================================
xtset districtid year
xtdes
ge after = year>2004
*==============================================================

*==============================================================
*===== Plotting the data ======================================
*==============================================================

preserve
	collapse (mean) outcome, by(treated year)
	reshape wide outcome, i(year) j(treated)
	twoway (connected outcome0 year) (connected outcome1 year) , ylabel(0(100)600) xline(2004.5) ///
			xlabel(2001(1)2008) ytitle("Average outcome") xtitle("") ///
			legend(order(1 "Control" 2 "Treatment") position(11) ring(0)) name(overview, replace)
restore

binscatter outcome year, by(treated) linetype(connect) ///
			xline(2004.5) xlabel(2001(1)2008) ylabel(0(100)600)  ///
			legend(order(1 "Control" 2 "Treated") ring(0) position(11))
			
*if you including controls, binscatter2 is preferred			

*==============================================================
*========================= 2X2 DID ============================		
*==============================================================
		
table treated after , stat(mean outcome) nototal nformat(%5.2f)
	
cibar outcome  ///
	, over(treated after)  level(95) ///
	graphopts(ylabel(0(100)500) xlabel(1.5 "Before" 4 "After" , ///
	nogrid) ytitle(Outcome)  legend(order (1 "Control" 2 "Treated") position(11) ring(0)) name(neobar, replace))

	
** baseline	
reg outcome treated treated##after , cluster(district)
estimates store reg1

** baseline	
reg outcome treated treated##after i.year, cluster(district)
reghdfe outcome treated treated##after , absorb(year) cluster(district)
estimates store reg2

** Stafe FE	
reghdfe outcome treated treated##after, absorb(year state)  cluster(district)
estimates store reg3

** District FE	
reg outcome treated treated##after i.year,  cluster(district)
reghdfe outcome treated treated##after, absorb(year district) cluster(district)
estimates store reg4

** Collapsed data at treatment level == balanced panel
preserve
	collapse (mean) outcome , by(treated year after)
	reg outcome treated treated##after i.year,  robust
	reghdfe outcome treated treated##after, absorb(year ) res(robust)
	estimates store reg5
restore

esttab reg* , star(* 0.1 ** 0.05 *** 0.01) noomitted se  nogaps scalar(N N_clust) sfmt(0) b(%9.3f)    mtitle(None Year State District Collapse) drop(0.* _cons) 	

** Making the panel unbalanced
ge outcome_mod = outcome
replace outcome_mod = . if _n>500 & _n<900
	
** baseline	
reg outcome_mod treated treated##after , cluster(district)
estimates store mod1

** baseline	
reghdfe outcome_mod treated treated##after , absorb(year) cluster(district)
estimates store mod2

** Stafe FE	
reghdfe outcome_mod treated treated##after, absorb(year state)  cluster(district)
estimates store mod3

** District FE	
reghdfe outcome_mod treated treated##after, absorb(year district) cluster(district)
estimates store mod4

** Collapsed data at treatment level == balanced panel
preserve
	collapse (mean) outcome_mod , by(treated year after)
	reghdfe outcome_mod treated treated##after, absorb(year ) res(robust)
	estimates store mod5
restore

esttab mod* , star(* 0.1 ** 0.05 *** 0.01) noomitted se  nogaps scalar(N N_clust) sfmt(0) b(%9.3f)    mtitle(None Year State District Collapse) drop(0.* _cons)	

	
*==============================================================	
*================ Event study =================================	
*==============================================================

table  year treated , stat(mean outcome) nototal nformat(%5.2f)

egen time = group(year)
tabstat time, by(year) nototal
tab time, ge(d_time)
sum time
global numyearmax = r(max)
global numyearmin = r(min)	

forvalues i = $numyearmin(1)$numyearmax{
	ge id_treated_`i' = treated * d_time`i'	
		}

** dropping the last pre-treatment year		
drop id_treated_4

*** TWFE: year and district FE
xtreg outcome  id_treated_* i.time ,  fe cluster(district)
estimates store ev1

*** DID = difference between average of pre and post coefficients
nlcom (post:(_b[id_treated_1]+_b[id_treated_2] +_b[id_treated_3]+ 0)/4) ///
	  (pre:(_b[id_treated_5]+_b[id_treated_6] +_b[id_treated_7] +_b[id_treated_8])/4) ///
	  (DID: (_b[id_treated_1]+_b[id_treated_2] +_b[id_treated_3]+0)/4 - ///
	  (_b[id_treated_5]+_b[id_treated_6] +_b[id_treated_7] +_b[id_treated_8] )/4)   ///  
	  , post
estimates store ev2

** Collapsed data at treatment level == balanced panel
preserve
	collapse (mean) outcome , by(treated time id_treated_*)
	reghdfe outcome treated id_treated_* treated, absorb(time ) res(robust)
	estimates store other1
restore** TWFE: year and district FE
xtreg outcome  id_treated_* i.time ,  fe cluster(district)
estimates store ev1

*** DID = difference between average of pre and post coefficients
nlcom (post:(_b[id_treated_1]+_b[id_treated_2] +_b[id_treated_3]+ 0)/4) ///
	  (pre:(_b[id_treated_5]+_b[id_treated_6] +_b[id_treated_7] +_b[id_treated_8])/4) ///
	  (DID: (_b[id_treated_1]+_b[id_treated_2] +_b[id_treated_3]+0)/4 - ///
	  (_b[id_treated_5]+_b[id_treated_6] +_b[id_treated_7] +_b[id_treated_8] )/4)   ///  
	  , post
estimates store ev2

** Collapsed data at treatment level == balanced panel
preserve
	collapse (mean) outcome , by(treated time id_treated_*)
	reghdfe outcome treated id_treated_* treated, absorb(time ) res(robust)
	estimates store other1
restore


coefplot  ev1,  keep(id_treated_*) ///
		headings(id_treated_5 = "", nogap) /// *This add an empty space for the last pre-treatment period
		yaxis("") xline(4.5) yline(0) vertical  name(method1, replace)  ///
		msymbol(circle) mcolor(blue) xtitle("Time") ///
		xlabel (1 "-4"  2 "-3"  3 "-2"  4 "-1"  5 "0"  6 "1"  7 "2"  8 "3" ) ///
		ytitle(Coefficients) legend(off) ciopts(color(black))  

		
esttab ev* , star(* 0.1 ** 0.05 *** 0.01) noomitted se  nogaps scalar(N N_clust) sfmt(0) b(%9.3f) ///
	mtitle(Balanced Comparison Unbalanced Comparison) indicate("Time FE = *time")	nocons	
		
*==============================================================
*================== Alternative way ===========================
*==============================================================

ge first_treat = treated * 5
recode first_treat (0 = .)
gen K = time-first_treat // "relative time", i.e. the number periods since treated 

forvalues l = 0/3 {
	gen L`l'event = K==`l' 
}
forvalues l = 1/4 {
	gen F`l'event = K==-`l' 
}

drop F1event

reghdfe outcome F*event L*event i.time,  absorb(district)  cluster(district)
estimates store ev4

event_plot  ev4 , ///
	stub_lag(  L#event   ) stub_lead(  F#event  ) plottype(scatter) ciplottype(rcap)  alpha(0.01) ///
	together perturb(-0(0.0)0.0) trimlead(5) noautolegend ///
	graph_opt(title("" ) name(method2, replace) xtitle("Time", size(medlarge) ) ///
	legend(off) ylabel(-400(100)400)  ///
	ytitle("Coefficient") xlabel(-4(1)3)  ///
	xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
	graphregion(color(white)) bgcolor(white) ylabel(, angle(horizontal))) ///
	lag_opt1(msymbol(O) ) lag_ci_opt1(color(black)) 

esttab ev* , star(* 0.1 ** 0.05 *** 0.01) noomitted se  nogaps scalar(N N_clust) sfmt(0) b(%9.3f) ///
			 mtitle(Method1 DID Collapse Method2) indicate("Time FE = *time")
	
