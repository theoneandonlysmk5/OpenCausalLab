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
					Event study
==================================================*/

clear all

*HH Survey
use "${relabeled_data}/HHsurvey.dta", clear

local color="16 120 149"

*Outcomes
global yvars "works"

*Sample after 2012
keep if year>=2012 & year<=2019

*Independent vars
global xvars "urban head_schooling head_male head_age indig_head male hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4 adult_women adult_men i.year i.depto#i.year"


tab year,gen(y_)
	
gen	yy_1= y_1 | y_2
gen yy_2= y_3 | y_4
gen yy_3= y_5 | y_6
gen yy_4= y_7 | y_8
	

*----------------------------- Every 2 years ----------------------------------*
eststo clear


replace yy_1=0

forvalues i=1(1)4{
	gen treatw10_2_`i'=treatw10*yy_`i'
	gen treatw12_2_`i'=treatw12*yy_`i'
	gen treatw14_2_`i'=treatw14*yy_`i'
}

******************************* comparison 1 ***********************************
	
	*regressions
foreach y in $yvars{		
    local title: variable label `y'
reg `y' treatw10_2_1 treatw10_2_2 treatw10_2_3 treatw10_2_4 treatw10 runningw10 treatxrunningw10 $xvars if sww10==1, vce( cluster age_mo_year)
est sto est1

coefplot (, mcolor("`color'") ciopts(color("`color'")))  , keep(treatw10_2_1 treatw10_2_2 treatw10_2_3 treatw10_2_4) vertical omitted graphregion(color(white)) plotregion(color(white)) xtitle("Years") ytitle("Estimates") title("10 Year-old-cutoff")  ciopts(recast(rcap)) legend(off)  coeflabels(treatw10_2_1 = "2012-13" treatw10_2_2="2014-15" treatw10_2_3="2016-17" treatw10_2_4="2018-19" ) saving(es2_1_`y',replace) yscale(range(-0.1(0.05)0.05))
}

******************************* comparison 2 ***********************************

eststo clear

	*regressions
foreach y in $yvars{
     local title: variable label `y'
reg `y' treatw12_2_1 treatw12_2_2 treatw12_2_3 treatw12_2_4 treatw12 runningw12 treatxrunningw12 $xvars if sww12==1, vce( cluster age_mo_year)
est sto est2

coefplot (, mcolor("`color'") ciopts(color("`color'"))) , keep(treatw12_2_1 treatw12_2_2 treatw12_2_3 treatw12_2_4) vertical omitted graphregion(color(white)) plotregion(color(white)) xtitle("Years") ytitle("Estimates") title("12 Year-old-cutoff")  ciopts(recast(rcap)) legend(off) coeflabels(treatw12_2_1 = "2012-13" treatw12_2_2="2014-15" treatw12_2_3="2016-17" treatw12_2_4="2018-19" ) saving(es2_2_`y',replace) yscale(range(-0.1(0.05)0.05))
}

*_______________________________________________________________________________

*									Combine
*_______________________________________________________________________________

foreach  y in $yvars{
	
gr combine es2_1_`y'.gph es2_2_`y'.gph , ycommon graphregion(color(white) margin(zero)) row(1)  
graph export "${figuredir}/es2_1012_figure_`y'.png", replace


}
