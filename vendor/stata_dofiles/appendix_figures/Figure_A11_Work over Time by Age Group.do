/*==================================================
Project:       The effects of expanding worker rights to children
Authors:       Leah K. Lakdawala
               Diana Martínez Heredia        
               Diego Vera-Cossio
----------------------------------------------------
Creation Date:    Apr 2025
Modification Date:   
Do-file version:    01
References:          
Output:             
==================================================*/

/*==================================================
            0: Program set up
==================================================*/
*Written on STATA 17
drop _all

/*==================================================
            Work over time by Age group
==================================================*/

clear all

use "${relabeled_data}/HHsurvey.dta", clear

* Age Groups
gen gr13 = (age_dob_m>=156 & age_dob_m<168)
gen gr14 = (age_dob_m>=168 & age_dob_m<180)
gen gr1517 = (age_dob_m>=180 & age_dob_m<216)
gen agegr = 1 if gr13==1
replace agegr = 2 if gr14==1
replace agegr = 3 if gr1517==1
label def ageg 1 "Age 13" 2 "Age 14" 3 "Age 15-17"
label val agegr ageg

*Time Periods
gen timegr = 1 if year==2012|year==2013
replace timegr = 2 if year>2013 & year<=2017
replace timegr = 3 if year>2017
label define timegr 1 "Pre-Law" 2 "During Law" 3 "Post-Reversal"
label values timegr timegr

table (agegr) (timegr), stat(mean works)



keep if agegr~=.

collapse (mean) works , by(timegr agegr)

twoway (connected works timegr if agegr==1 , ms(X) mcolor(gray) msize(large) lcolor(gray) lp(-))( connected works timegr if agegr==2, ms(O) mcolor(black) lcolor(black) )( connected works timegr if agegr==3 , ms(diamond) mcolor(blue) lcolor(blue) lp(dot)) ( connected works timegr if agegr==4 , ms(diamond) mcolor(red) lcolor(red) lp(dot)), legend(order(1 "Age 13" 2 "Age 14" 3 "Age 15-17" ) )  ylabel(#10,labsize(small)) ytitle("Work Probabilities") xlabel(#3, valuelabel labsize(small))  graphregion(color(white)) xtitle(Time period)

graph export 	"${figuredir}/work_time_age.png", replace








