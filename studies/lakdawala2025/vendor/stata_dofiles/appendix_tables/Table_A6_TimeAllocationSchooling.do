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

*_______________________________________________________________________________

* 								Schooling, 2012-2017
*_______________________________________________________________________________

clear all

*Child Labor Survey
use "${relabeled_dataCS}/RW_child_labor_survey.dta", clear

*Variables for DDisc regressions (recall day of survey)
global x "xx post treat running treatxrunning"

*Controls
global dem "h_edu_head h_male_head h_age_head indig_head c_gender hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4 adult_women adult_men c_area i.c_depto#i.year"

*Outcomes 
global outcomes "ch_min_total "

*Regressions for all children
eststo clear
foreach y of varlist $outcomes {
reg `y' $x  $dem s10 s12 s14 [aw=kernel_tri] if ss==1, vce( cluster age_mo_year) 
eststo est`y'
mat coef=r(table)
**Mean (below cutoff)
sum `y' if year==2008 & ss==1
estadd scalar Mean=r(mean)
}
                                             

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

*HH Survey
use "${relabeled_data}/HHsurvey.dta", clear

*Sample 2012-2019
keep if year>=2012 & year<=2019



*Globals with diff in disc vars
global x14 "treat14 running14 treatxrunning14"
global x12 "treat12 running12 treatxrunning12"
global x10 "treat10 running10 treatxrunning10"

*Late for grade
gen grade_diff=gradeforage - level_enrolled 
gen late4gr= (grade_diff>1)

*School and work
gen sch_wrk=attendance_a ==1 & works==1
gen nosch_wrk=attendance_a ==0 & works==1
gen sch_nowrk=attendance_a ==1 & works==0

************************************************************************************************************************
* 										14 year-old cut-off
************************************************************************************************************************	

*Controls	
global xvars "post post_rev urban head_schooling head_male head_age indig_head male hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4 adult_women adult_men eligible_gr i.depto#i.year"

global yvars "late4gr"
*Regression
preserve 
rename xx3 xx
foreach x in $yvars{ 
	reg `x' xx xxr3 ${x14} $xvars [aw=kernel_tri14] if attendance_a==1, vce( cluster age_mo_year)
	eststo est_`x'
	sum `x' if e(sample)==1 & pre==1
	estadd scalar Mean=r(mean)
}
	restore
	
	global yvars "attendance_a  sch_nowrk sch_wrk nosch_wrk"
*Regression
preserve 
rename xx3 xx
foreach x in $yvars{ 
	reg `x' xx xxr3 ${x14} $xvars [aw=kernel_tri14], vce( cluster age_mo_year)
	eststo est_`x'
	sum `x' if e(sample)==1 & pre==1
	estadd scalar Mean=r(mean)
}
	restore
	
*Write table header	
file open myff using "${tabledir}/4_table_DDisc_timeuse.tex", write replace
file write myff "\begin{table}[!h]"
file write myff "\centering "
file write myff "\caption{Effect of the Law on Time Allocation and Schooling}"
file write myff "\label{tab:schooling}\begin{adjustbox}{center, max width=0.9\textwidth}\begin{threeparttable}"
file write myff  "{\centering { \begin{tabular}{lcccccc} \\\hline \hline" 
file write myff  "  &  Attends & Late for & Work & Both School & School & Minutes Spent\\"
file write myff  "  &  School & Grade &  Only &  \& Work &   Only & on Chores\\"

file write myff  "  & (1) & (2) & (3) & (4) & (5) & (6) \\ \hline    "
file close myff		
	
*labels
gen xx=.
label var xx "Post law $\times$ $\mathbbm{1}$\{Age$< 14$\}"
label var xxr3 "Post reversal $\times$  $\mathbbm{1}$\{Age$< 14$\}"

esttab est_attendance_a  est_late4gr est_nosch_wrk est_sch_wrk est_sch_nowrk  estch_min_total using "${tabledir}/4_table_DDisc_timeuse", tex frag  cells(b(star fmt(3)) se(par fmt(3))) stats(N Mean, labels(Obs. Mean) fmt(a3)) keep(xx xxr3)  append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none)

****************************** Closing file ***********************************
file open myff using "${tabledir}/4_table_DDisc_timeuse.tex", write append
file write myff "\hline \hline \\\end{tabular}}} \begin{tablenotes} "
file write myff "\item \begin{footnotesize} Notes: Age in months by year clustered standard errors in parentheses. Significance levels denoted by: *** p$<$0.01, ** p$<$0.05, * p$<$0.1. Control variables: CCT eligibility indicator (Columns 1-5), household head characteristics (schooling, gender, age, and indigenous indicator), gender, number of children in the following age categories: 0-6, 7-9, 10-13, and 14-17, number of adult men and women, an indicator for urban, and departamento by year fixed effects. For Columns 1-5, we include linear splines of the running variable, defined as the difference between the cutoff age and age at the survey in months. For Column 6, we do a stacked difference in disconinuity by multiplying the running variable by -1 for the 13 and 14 year-olds age group for interpretability. The running variable is the stacked difference between age in months and the age cutoff at the survey date, and the specification includes linear splines of the running variable. We use a bandwidth of 12 months and a triangular kernel for all specifications. Survey years for Columns 1-5: 2012-2019. Survey years for Column 6: 2008 and 2016.  We also report the mean of the dependent variable in the pre-law period. \end{footnotesize}"
file write myff " \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}"
file close myff




