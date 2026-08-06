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
				McCrary Tests
==================================================*/
clear all

*_______________________________________________________________________________

*									HH survey
*_______________________________________________________________________________


*HH Survey
use "${relabeled_data}/HHsurvey.dta", clear

*Post Law
keep if year>=2012 & year<=2019


gen reversal=year>=2018 
replace reversal=.  if year==. 


foreach n in 1 2 3 {
local c=`n'*2+8


local bw=12
*create running variable

twoway (hist running`c' if running`c'<=`bw' & running`c'>=-`bw' & pre==1, discrete percent w(1) start(-`bw') bfcolor(gs8%30) blcolor(gs8%30) xscale(r(-`bw' `bw')))   (hist running`c' if running`c'<=`bw' & running`c'>=-`bw' & post==1, discrete percent w(1) start(-`bw') bfcolor(none) blcolor(black) xscale(r(-`bw' `bw'))) ,   xline(-0.5, lcolor(red) lwidth(thick)) legend(order(1 "Pre" 2 "Post")) title("`c' Year-Old Cut-off") ytitle("Frequency (%)")  xtitle("Months to threshold") graphregion(color(white)) saving(histogram_running`c', replace) 

}


grc1leg histogram_running14.gph histogram_running12.gph histogram_running10.gph, ycommon graphregion(color(white)) rows(1) title("Panel A: Pre- and Post-law Periods", size(medium)) saving(a_hist_prepost, replace)

foreach n in 1 2 3 {
local c=`n'*2+8


local bw=12
*create running variable

twoway (hist running`c' if running`c'<=`bw' & running`c'>=-`bw' & post==1, discrete percent w(1) start(-`bw') bfcolor(gs8%30) blcolor(gs8%30) xscale(r(-`bw' `bw')))   (hist running`c' if running`c'<=`bw' & running`c'>=-`bw' & reversal==1, discrete percent w(1) start(-`bw') bfcolor(none) blcolor(black) xscale(r(-`bw' `bw'))) ,   xline(-0.5, lcolor(red) lwidth(thick)) legend(order(1 "Post" 2 "Reversal")) title("`c' Year-Old Cut-off") ytitle("Frequency (%)")  xtitle("Months to threshold") graphregion(color(white)) saving(histogram_running`c', replace) 

}


grc1leg histogram_running14.gph histogram_running12.gph histogram_running10.gph, ycommon graphregion(color(white)) rows(1) title("Panel B: Post-law and Reversal Periods", size(medium)) saving(a_hist_postrev, replace)

gr combine a_hist_prepost.gph a_hist_postrev.gph , ycommon graphregion(color(white)) rows(2)
graph export "${figuredir}/a_figure_7.png", replace
