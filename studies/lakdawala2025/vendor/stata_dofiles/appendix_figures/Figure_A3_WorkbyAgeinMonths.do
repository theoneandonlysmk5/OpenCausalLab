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
           Work by age in months
==================================================*/

clear all

use "${relabeled_data}/HHsurvey.dta", clear

local color1="89 172 203"
local color2="16 120 149"
local color3="0 71 98"
graph set print fontface "Garamond"
graph set window fontface "Garamond"

capture drop s_date_approx
gen s_date_approx=mdy(10, 16, 2012) if year==2012
replace s_date_approx=mdy(10, 19, 2015) if year==2015
replace s_date_approx=mdy(10, 29, 2017) if year==2017
replace s_date_approx=mdy(12, 22, 2018) if year==2018
replace s_date_approx=mdy(10, 21, 2019) if year==2019

replace age_dob_m=round((s_date_approx-dob)/30) if year==2012
replace age_dob_m=round((s_date_approx-dob)/30) if year==2015
replace age_dob_m=round((s_date_approx-dob)/30) if year==2017
replace age_dob_m=round((s_date_approx-dob)/30) if year==2018
replace age_dob_m=round((s_date_approx-dob)/30) if year==2019

keep if age_dob_m>=84 | age_dob_m<=204

local binsize = 1
gen bin = .
foreach X of num 84(1)204 {
	di "`X'"
	replace bin=`X' if (age_dob_m>=`X' & age_dob_m<=(`X'+`binsize') )
}
tab bin

preserve
keep if year>=2012 & year<=2013
collapse works, by(bin)

twoway scatter works bin, mcolor("`color2'".6) || lowess works bin, lcolor(black) xtitle("Age in Months", size(medlarge)) ytitle("") title("Proportion of Working Children Before the Law", size(large)) graphregion(color(white)) xlabel(80(10)205,labsize(small))  legend(off) 
graph export "${figuredir}/figurescatter_avg_work.png", replace
restore
