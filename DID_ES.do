

use /Users/stefania/Dropbox/Econometrics/Event_study, clear

xtset districtid time_reg
*=========================

sum time_reg
global toadd = r(min)
sum time_reg
global numyearmax = r(max)
global numyearmin = r(min)	


forvalues i = $numyearmin(1)$numyearmax{
	ge d_time`i'  = time_reg==`i'
	ge id_treated_`i' = $treatment * d_time`i'	
		}
		
	** dropping the treatment year		
	drop id_treated_7

ge first_treat = $treatment* 8
ge first_treatSA = first_treat
recode first_treatSA (0 = .)
gen ry = time_reg - first_treatSA
gen never_treat = (first_treatSA == .)
tab ry
tab time_reg $treatment

gen K = time_reg-first_treatSA // "relative time", i.e. the number periods since treated (could be missing if never-treated)
gen D = K>=0 & first_treatSA!=. 

tab K
ge Kcont = time_reg - 8

sum first_treatSA
gen lastcohort = first_treatSA==r(max) // dummy for the latest- or never-treated cohort

forvalues l = 0/2 {
	gen L`l'event = K==`l' 
}
forvalues l = 1/5 {
	gen F`l'event = K==-`l' 
}

drop F1event
*==============================================================

*==============================================================

xtdes
drop if mining==.

table time_reg mining  , stat(count length) nototal
table time_reg mining  , stat(mean length) nototal


*==============================================================
* DID
*==============================================================
table after mining  , stat(mean length) nototal
reg length mining##after , cluster(state)    // without time dummies


*==============================================================
* Event study
*==============================================================
table time_reg mining  , stat(mean length) nototal
reg length id_treated_* b7.time_reg mining,  cluster(state)

table time_reg mining  , stat(mean length) nototal
reg length F*event L*event b7.time_reg mining,  cluster(state)


*==============================================================
* Event study
*==============================================================

reg length F*event L*event b7.time_reg mining i.districtid,  cluster(state)
xtreg length F*event L*event b7.time_reg mining , fe cluster(state)
xtreg length id_treated_* b7.time_reg mining , fe cluster(state)
