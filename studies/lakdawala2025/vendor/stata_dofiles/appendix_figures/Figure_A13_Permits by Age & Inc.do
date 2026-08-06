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
				Permits by Age & Inc
==================================================*/

clear all

*Child Labor Survey
use 	"${relabeled_dataCS}/RW_child_labor_survey.dta", clear

keep if year==2016 & c_age>=10

/*Replace don't know with missing*/
replace 	c_wrk_permission = . if c_wrk_permission==99
tab 		c_age c_wrk_permission if d_worked==1, m
tab 		c_age c_wrk_permission if d_worked==1, row
table 		c_age  if d_worked==1,stat(mean c_wrk_permission)

gen 		contract = 1 if  c_wrk_contract_h ~=.
replace 	contract = 0 if c_wrk_contract_h==. & d_worked==1

gen 		agegroup = 1 if (c_age>=10 & c_age<=13)
replace 	agegroup = 2 if (c_age>=14 & c_age<=17)
replace 	agegroup = . if (c_age==.)

label def 	agegr 1 "Age 10-13" 2 "Age 14-17"
label val 	agegroup agegr

table 		agegroup  if d_worked==1, stat(mean c_wrk_permission) stat(count c_wrk_permission)

graph bar 	c_wrk_permission if d_worked==1, over(agegroup) ///
			ytitle(Proportion of working children with permits, size(large)) ///
			blabel(bar, format(%4.3f) size(large)) 
			
graph export 	"${figuredir}/permits_agegroup.png", replace

table 		agegroup  if d_worked==1, stat(mean contract) stat(count contract)

graph bar 	contract if d_worked==1, over(agegroup) ///
			ytitle(Proportion of working children with contracts, size(large)) ///
			blabel(bar, format(%4.3f) size(large))
 
graph export 	"${figuredir}/contracts_agegroup.png", replace


sum 		income_adults_pc, det
local 		med = r(p50)
gen 		incgroup = 1 if (income_adults_pc<`med')
replace 	incgroup = 2 if (income_adults_pc>=`med')
replace 	incgroup = . if (income_q==.)
label def 	incgr 1 "Poorer 50%" 2 "Richer 50%" 
label val 	incgroup incgr

table 		incgroup  if d_worked==1, stat(mean c_wrk_permission) stat(count c_wrk_permission)

graph bar 	c_wrk_permission if d_worked==1, over(incgroup) ///
			ytitle(Proportion of working children with permits, size(large)) ///
			blabel(bar, format(%4.3f) size(large))
 
graph export 	"${figuredir}/permits_incgroup.png", replace

table 		incgroup  if d_worked==1, stat(mean contract) stat(count contract)

graph bar 	contract if d_worked==1, over(incgroup) ///
			ytitle(Proportion of working children with contract, size(large)) ///
			blabel(bar, format(%4.3f) size(large))
 
graph export 	"${figuredir}/contracts_incgroup.png", replace
