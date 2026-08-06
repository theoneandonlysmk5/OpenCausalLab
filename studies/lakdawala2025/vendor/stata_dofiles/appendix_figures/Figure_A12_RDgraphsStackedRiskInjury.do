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
		Reweighted RD graphs - presentation
==================================================*/
 
 clear all
 
 use "${relabeled_dataCS}/RW_child_labor_survey.dta", clear
 
local bw=12
 
  local color5="16 120 149"
local color2="93 193 221"

graph set print fontface "Garamond"
graph set window fontface "Garamond"

*_______________________________________________________________________________

*									Pre
*_______________________________________________________________________________


 keep if year==2008

*** compute bins
local binsize = 1
gen bin = .
foreach X of num 0(1)72 {
	di "`X'"
	replace bin=-`X' if (running>=-`X' & running<=(-`X'+ `binsize') & running<0)
	replace bin=`X' if (running>=`X' & running`c'<=(`X'+`binsize'))
}
tab bin

gen biny = .
foreach X of num 0(1)72 {
	di "`X'"
	replace biny=-`X' if (runningy>=-`X' & runningy<=(-`X'+ `binsize') & runningy<0)
	replace biny=`X' if (runningy>=`X' & runningy<=(`X'+`binsize'))
}

*******************************************************************************
** RD Analysis: graphs
global outcomes "risks_a" 
global outcomes3 "injury_a "

foreach y in $outcomes {
	
* Take the average of the outcome variable within each bin
capture drop m`y'
bysort bin : egen m`y' = mean(`y')
* Take the average of the running variable within each bin (for graphical purposes only; this makes the dots being centered within each bean)
capture drop mbin
bysort bin : egen mbin = mean(running) 

preserve

* Triangular Kernel (select bandwidth)
keep if inrange(running,-`bw',`bw') 

* RD graph
local label: variable label `y'
twoway || lfitci `y' running if running < 0 [aw=kernel_tri], sort msymbol(none) clwidth(medthick) ciplot(rline) lpattern(dash) lcolor(gs9) level(90) ||  lfitci `y' running if running > 0 [aw=kernel_tri], sort msymbol(none)  clwidth(medthick) ciplot(rline) lpattern(dash) lcolor(gs9) level(90)  || lfit `y' running if running < 0 [aw=kernel_tri],sort msymbol(none) clcolor(black) clpat(solid) || lfit `y' running if running > 0 [aw=kernel_tri],sort msymbol(none) clcolor(black) clpat(solid) || scatter m`y' bin, xline(0, lpattern(dashed)  lcolor(`color5')) xtitle("Months to threshold", size(medlarge)) ytitle("") title("Panel A: `label'", size(medlarge)) mcolor("`color2'") msize(small) legend(off) name(sRD_`y', replace) graphregion(color(white)) xlabel(#20,labsize(small)) ylabel(0(0.1)0.6) ytitle(Probability, size(medlarge)) saving(sprwpre_rdgph_`y',replace) 
restore
}



**************************************************************
foreach y in $outcomes3 {
	
* Take the average of the outcome variable within each bin
capture drop m`y'
bysort biny : egen m`y' = mean(`y')
* Take the average of the running variable within each bin (for graphical purposes only; this makes the dots being centered within each bean)
capture drop mbiny
bysort biny : egen mbiny = mean(runningy) 

preserve

* Triangular Kernel (select bandwidth)
keep if inrange(runningy,-`bw',`bw') 

* RD graph
local label: variable label `y'
twoway || lfitci `y' runningy if runningy < 0 [aw=kernel_triy], sort msymbol(none) clwidth(medthick) ciplot(rline) lpattern(dash) lcolor(gs9) level(90) ||  lfitci `y' runningy if runningy > 0 [aw=kernel_triy], sort msymbol(none)  clwidth(medthick) ciplot(rline) lpattern(dash) lcolor(gs9) level(90)  || lfit `y' runningy if runningy < 0 [aw=kernel_triy],sort msymbol(none) clcolor(black) clpat(solid) || lfit `y' runningy if runningy > 0 [aw=kernel_triy],sort msymbol(none) clcolor(black) clpat(solid) || scatter m`y' biny, xline(0, lpattern(dashed)  lcolor(`color5')) xtitle("Months to threshold", size(medlarge)) ytitle("") title("Panel B: `label'", size(medlarge)) mcolor("`color2'") msize(small) legend(off) name(sRD_`y', replace) graphregion(color(white)) xlabel(#20,labsize(small)) ylabel(0(0.1)0.6) ytitle(Probability, size(medlarge)) saving(sprwpre_rdgph_`y', replace) 
restore

}
drop bin biny

*  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *
*  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *
*  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *
*  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *
*  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *

 
 use "${relabeled_dataCS}/RW_child_labor_survey.dta", clear
 
 
local bw=12
 
  local color5="16 120 149"
local color2="93 193 221"

graph set print fontface "Garamond"
graph set window fontface "Garamond"


*_______________________________________________________________________________

*									Post
*_______________________________________________________________________________


 keep if year==2016
 
 
*** compute bins
local binsize = 1
gen bin = .
foreach X of num 0(1)24 {
	di "`X'"
	replace bin=-`X' if (running>=-`X' & running<=(-`X'+ `binsize') & running<0)
	replace bin=`X' if (running>=`X' & running<=(`X'+`binsize') )
}
tab bin

gen biny = .
foreach X of num 0(1)24 {
	di "`X'"
	replace biny=-`X' if (runningy>=-`X' & runningy<=(-`X'+ `binsize') & runningy<0)
	replace biny=`X' if (runningy>=`X' & runningy<=(`X'+`binsize'))
}

*******************************************************************************
** RD Analysis: graphs
global outcomes "risks_a" 
global outcomes2 "hazardousw_a" 
global outcomes3 "injury_a "

foreach y in $outcomes {
	
* Take the average of the outcome variable within each bin
capture drop m`y'
bysort bin : egen m`y' = mean(`y')
* Take the average of the running variable within each bin (for graphical purposes only; this makes the dots being centered within each bean)
capture drop mbin
bysort bin : egen mbin = mean(running) 

preserve

* Triangular Kernel (select bandwidth)
local bw = 12
keep if inrange(running,-`bw',`bw') 

* RD graph
local label: variable label `y'
twoway || lfitci `y' running if running < 0 [aw=kernel_tri], sort msymbol(none) clwidth(medthick) ciplot(rline) lpattern(dash) lcolor(gs9) level(90) ||  lfitci `y' running if running > 0 [aw=kernel_tri], sort msymbol(none)  clwidth(medthick) ciplot(rline) lpattern(dash) lcolor(gs9) level(90)  || lfit `y' running if running < 0 [aw=kernel_tri],sort msymbol(none) clcolor(black) clpat(solid) || lfit `y' running if running > 0 [aw=kernel_tri],sort msymbol(none) clcolor(black) clpat(solid) || scatter m`y' bin, xline(0, lpattern(dashed)  lcolor(`color5')) xtitle("Months to threshold", size(medlarge)) ytitle("") title("Panel A: `label'", size(medlarge)) mcolor("`color2'") msize(small) legend(off) name(sRD_`y', replace) graphregion(color(white)) xlabel(#20,labsize(small)) ylabel(0(0.05)0.2) ytitle(Probability, size(medlarge)) saving(sprdgph_`y',replace)  
restore
}



**************************************************************
foreach y in $outcomes3 {
	
* Take the average of the outcome variable within each bin
capture drop m`y'
bysort biny : egen m`y' = mean(`y')
* Take the average of the running variable within each bin (for graphical purposes only; this makes the dots being centered within each bean)
capture drop mbiny
bysort biny : egen mbiny = mean(runningy) 

preserve

* Triangular Kernel (select bandwidth)
local bw = 12
keep if inrange(runningy,-`bw',`bw') 

* RD graph
local label: variable label `y'
twoway || lfitci `y' runningy if runningy < 0 [aw=kernel_triy], sort msymbol(none) clwidth(medthick) ciplot(rline) lpattern(dash) lcolor(gs9) level(90) ||  lfitci `y' runningy if runningy > 0 [aw=kernel_triy], sort msymbol(none)  clwidth(medthick) ciplot(rline) lpattern(dash) lcolor(gs9) level(90)  || lfit `y' runningy if runningy < 0 [aw=kernel_triy],sort msymbol(none) clcolor(black) clpat(solid) || lfit `y' runningy if runningy > 0 [aw=kernel_triy],sort msymbol(none) clcolor(black) clpat(solid) || scatter m`y' biny, xline(0, lpattern(dashed)  lcolor(`color5')) xtitle("Months to threshold", size(medlarge)) ytitle("") title("Panel B: `label'", size(medlarge)) mcolor("`color2'") msize(small) legend(off) name(sRD_`y', replace) graphregion(color(white)) xlabel(#20,labsize(small)) ylabel(0(0.05)0.2) ytitle(Probability, size(medlarge)) saving(sprdgph_`y', replace) 
restore

}
drop bin biny

*_______________________________________________________________________________

*									Combine (Presentation)
*_______________________________________________________________________________

gr combine sprwpre_rdgph_risks_a.gph  sprwpre_rdgph_injury_a.gph  , ycommon graphregion(color(white) margin(zero))  row(1) saving(spresrw_row1, replace) title(Pre)

gr combine  sprdgph_risks_a.gph  sprdgph_injury_a.gph , ycommon graphregion(color(white) margin(zero))  row(1) saving(spresrw_row2, replace) title(Post)

gr combine spresrw_row1.gph spresrw_row2.gph , ycommon graphregion(color(white) margin(zero)) row(2) 
graph export "${figuredir}/rwpres_risk.png", replace




