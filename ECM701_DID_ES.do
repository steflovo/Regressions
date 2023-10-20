
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
		headings(id_treated_5 = "", nogap) /// *This add an empty space on the last pre-treatment period
		yaxis("") xline(4.5) yline(0) vertical  name(method1, replace)  ///
		msymbol(circle) mcolor(blue) xtitle("Time") ///
		xlabel (1 "-4"  2 "-3"  3 "-2"  4 "-1"  5 "0"  6 "1"  7 "2"  8 "3" ) ///
		ytitle(Coefficients) legend(off) ciopts(color(black)) p) 


		
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
	