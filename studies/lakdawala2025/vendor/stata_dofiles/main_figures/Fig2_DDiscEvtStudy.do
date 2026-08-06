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


eststo clear
	
	*regressions
foreach y in $yvars{
     local title: variable label `y'
reg `y' treatw14_2_1 treatw14_2_2 treatw14_2_3 treatw14_2_4 treatw14 runningw14 treatxrunningw14 $xvars  eligible_gr if sww14==1, vce( cluster age_mo_year)
est sto est3

coefplot (, mcolor("`color'") ciopts(color("`color'"))) , keep(treatw14_2_1 treatw14_2_2 treatw14_2_3 treatw14_2_4) vertical omitted graphregion(color(white)) plotregion(color(white)) xtitle("Years") ytitle("Estimates") title("14 Year-old-cutoff")  ciopts(recast(rcap)) legend(off) coeflabels(treatw14_2_1 = "2012-13" treatw14_2_2="2014-15" treatw14_2_3="2016-17" treatw14_2_4="2018-19" ) saving(es2_3_`y', replace) yscale(range(-0.1(0.05)0.05)) ylabel(-0.1(0.05)0.05)

graph export "${figuredir}/es2_14_figure_`y'.png", replace

}









