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
clear all
/*==================================================
            RDD Graphs Work
==================================================*/

***********************************************************************************
* 									POST
***********************************************************************************

use "${relabeled_data}/HHsurvey.dta", clear
keep if year>=2014 & year<=2017

replace age_dob_m=round((s_date_approx-dob)/30) if year==2015
replace age_dob_m=round((s_date_approx-dob)/30) if year==2017

local color5="16 120 149"
local color2="93 193 221"

graph set print fontface "Garamond"
graph set window fontface "Garamond"

label var works "Work Probability"
label var hours_week_a "Weekly Hours Worked"
label var not_forbidden_a "Allowed Work"
label var forbidden_a "Prohibited Work"
foreach n in 1 2 3 {
	
local c=`n'*2+8

*create running variable

*** compute bins
local binsize = 1
gen bin = .
foreach X of num 0(1)72 {
	di "`X'"
	replace bin=-`X' if (running`c'>=-`X' & running`c'<=(-`X'+ `binsize') & running`c'<0)
	replace bin=`X' if (running`c'>=`X' & running`c'<=(`X'+`binsize'))
}
tab bin

** RD Analysis: graphs
global outcomes "works"

foreach y in $outcomes {
	
* Take the average of the outcome variable within each bin
capture drop m`y'
bysort bin : egen m`y' = mean(`y')
* Take the average of the running variable within each bin (for graphical purposes only; this makes the dots being centered within each bean)
capture drop mbin
bysort bin : egen mbin = mean(running`c') 

preserve

* Triangular Kernel (select bandwidth)
local bw = 12
keep if inrange(running`c',-`bw',`bw') 
capture gen kernel_tri = ((`bw' - abs(running`c')) /`bw') * (abs(running`c') < `bw')

* RD graph
twoway || lfitci `y' running`c' if running`c' < 0 [aw=kernel_tri], sort msymbol(none) clwidth(medthick) ciplot(rline) lpattern(dash) lcolor(gs9) level(90) ||  lfitci `y' running`c' if running`c' > 0 [aw=kernel_tri], sort msymbol(none)  clwidth(medthick) ciplot(rline) lpattern(dash) lcolor(gs9) level(90)  || lfit `y' running`c' if running`c' < 0 [aw=kernel_tri],sort msymbol(none) clcolor(black) clpat(solid) || lfit `y' running`c' if running`c' > 0 [aw=kernel_tri],sort msymbol(none) clcolor(black) clpat(solid) || scatter m`y' bin, xline(0, lpattern(dashed) lcolor(`color5')) xtitle("Months to threshold", size(large)) ytitle("") title("Post", size(huge)) mcolor("`color2'")  msize(medlarge) legend(off) name(RD_`n'_`y', replace) graphregion(color(white) ) xlabel(#20,labsize(medlarge)) ytitle(Probability, size(medlarge)) saving(rdgph_`c'_`y', replace)
restore
}
drop bin
}


***********************************************************************************
* 									PRE
***********************************************************************************

use "${relabeled_data}/HHsurvey.dta", clear
keep if year==2012 | year==2013

replace age_dob_m=round((s_date_approx-dob)/30) if year==2012


local color5="16 120 149"
local color2="93 193 221"

graph set print fontface "Garamond"
graph set window fontface "Garamond"

label var works "Work Probability"
label var hours_week_a "Weekly Hours Worked"
label var not_forbidden_a "Allowed Work"
label var forbidden_a "Prohibited Work"

foreach n in 3 {
	
local c=`n'*2+8

*** compute bins
local binsize = 1
gen bin = .
foreach X of num 0(1)72 {
	di "`X'"
	replace bin=-`X' if (running`c'>=-`X' & running`c'<=(-`X'+ `binsize') & running`c'<0)
	replace bin=`X' if (running`c'>=`X' & running`c'<=(`X'+`binsize'))
}
tab bin

** RD Analysis: graphs
global outcomes "works"

foreach y in $outcomes {
	
* Take the average of the outcome variable within each bin
capture drop m`y'
bysort bin : egen m`y' = mean(`y')
* Take the average of the running variable within each bin (for graphical purposes only; this makes the dots being centered within each bean)
capture drop mbin
bysort bin : egen mbin = mean(running`c') 

preserve

* Triangular Kernel (select bandwidth)
local bw = 12
keep if inrange(running`c',-`bw',`bw') 
capture gen kernel_tri = ((`bw' - abs(running`c')) /`bw') * (abs(running`c') < `bw')

* RD graph
twoway || lfitci `y' running`c' if running`c' < 0 [aw=kernel_tri], sort msymbol(none) clwidth(medthick) ciplot(rline) lpattern(dash) lcolor(gs9) level(90) ||  lfitci `y' running`c' if running`c' > 0 [aw=kernel_tri], sort msymbol(none)  clwidth(medthick) ciplot(rline) lpattern(dash) lcolor(gs9) level(90)  || lfit `y' running`c' if running`c' < 0 [aw=kernel_tri],sort msymbol(none) clcolor(black) clpat(solid) || lfit `y' running`c' if running`c' > 0 [aw=kernel_tri],sort msymbol(none) clcolor(black) clpat(solid) || scatter m`y' bin, xline(0, lpattern(dashed) lcolor(`color5')) xtitle("Months to threshold", size(large)) ytitle("") title("Pre", size(huge)) mcolor("`color2'")  msize(medlarge) legend(off) name(RD_`n'_`y', replace) graphregion(color(white) ) xlabel(#20,labsize(medlarge)) ytitle(Probability, size(medlarge)) saving(rdgph_pre_`c'_`y',replace) 
restore
}
drop bin
}



***********************************************************************************
* 								   REVERSAL
***********************************************************************************

use "${relabeled_data}/HHsurvey.dta", clear
keep if year==2018 | year==2019


replace age_dob_m=round((s_date_approx-dob)/30) if year==2018
replace age_dob_m=round((s_date_approx-dob)/30) if year==2019

local color5="16 120 149"
local color2="93 193 221"

graph set print fontface "Garamond"
graph set window fontface "Garamond"

label var works "Work Probability"
label var hours_week_a "Weekly Hours Worked"
label var not_forbidden_a "Allowed Work"
label var forbidden_a "Prohibited Work"

foreach n in 3 {
	
local c=`n'*2+8


*** compute bins
local binsize = 1
gen bin = .
foreach X of num 0(1)72 {
	di "`X'"
	replace bin=-`X' if (running`c'>=-`X' & running`c'<=(-`X'+ `binsize') & running`c'<0)
	replace bin=`X' if (running`c'>=`X' & running`c'<=(`X'+`binsize'))
}
tab bin

** RD Analysis: graphs
global outcomes "works"

foreach y in $outcomes {
	
* Take the average of the outcome variable within each bin
capture drop m`y'
bysort bin : egen m`y' = mean(`y')
* Take the average of the running variable within each bin (for graphical purposes only; this makes the dots being centered within each bean)
capture drop mbin
bysort bin : egen mbin = mean(running`c') 

preserve

* Triangular Kernel (select bandwidth)
local bw = 12
keep if inrange(running`c',-`bw',`bw') 
capture gen kernel_tri = ((`bw' - abs(running`c')) /`bw') * (abs(running`c') < `bw')

* RD graph
twoway || lfitci `y' running`c' if running`c' < 0 [aw=kernel_tri], sort msymbol(none) clwidth(medthick) ciplot(rline) lpattern(dash) lcolor(gs9) level(90) ||  lfitci `y' running`c' if running`c' > 0 [aw=kernel_tri], sort msymbol(none)  clwidth(medthick) ciplot(rline) lpattern(dash) lcolor(gs9) level(90)  || lfit `y' running`c' if running`c' < 0 [aw=kernel_tri],sort msymbol(none) clcolor(black) clpat(solid) || lfit `y' running`c' if running`c' > 0 [aw=kernel_tri],sort msymbol(none) clcolor(black) clpat(solid) || scatter m`y' bin, xline(0, lpattern(dashed) lcolor(`color5')) xtitle("Months to threshold", size(large)) ytitle("") title("Reversal", size(huge)) mcolor("`color2'")  msize(medlarge) legend(off) name(RD_`n'_`y', replace) graphregion(color(white) ) xlabel(#20,labsize(medlarge)) ytitle(Probability, size(medlarge)) saving(rdgph_rev_`c'_`y',replace) 
restore
}
drop bin
}

*_______________________________________________________________________________

*									Combine
*_______________________________________________________________________________

foreach n in 3 {
local c=`n'*2+8

foreach y in $outcomes {
local label: variable label `y'
gr combine rdgph_pre_`c'_`y'.gph rdgph_`c'_`y'.gph rdgph_rev_`c'_`y'.gph, ycommon graphregion(color(white))  row(1) xsize(6) ysize(2) iscale(*1.3)
graph export "${figuredir}/figure_`n'_`y'.png", replace

}
}


