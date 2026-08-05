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
    Formal channels
==================================================*/

clear all

*Child Labor Survey
use "${relabeled_dataCS}/RW_child_labor_survey.dta", clear

*Variables for DDisc regressions (recall day of survey)
global x "xx post treat running treatxrunning"
*Variables for DDisc regressions (recall a year before survey)
global xy "xx post treaty runningy treatxrunningy"

*Controls
global dem "h_edu_head h_male_head h_age_head indig_head c_gender hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4 adult_women adult_men c_area i.c_depto#i.year"

*Outcomes (recall day of survey)
global outcomes "risks_a "
*Outcomes (recall a year before survey)
global outcomes2 "injury_a"

*Regressions for all children
eststo clear
foreach y of varlist $outcomes {
reg `y' $x  $dem s10 s12 s14 [aw=kernel_tri] if ss==1, vce( cluster age_mo_year) 
eststo est_1_`y'
mat coef=r(table)
**Mean (below cutoff)
sum `y' if year==2008 & ss==1
estadd scalar Mean=r(mean)
}

preserve
drop xx
rename xxy xx
foreach y of varlist $outcomes2 {
reg `y' $xy  $dem sy10 sy12 sy14 [aw=kernel_triy] if ssy==1, vce( cluster age_mo_year) 
eststo est_1_`y'
mat coef=r(table)
**Mean (below cutoff)
sum `y' if year==2008 & ssy==1
estadd scalar Mean=r(mean)
}
restore

******************************************************************************************************************

*Regressions for working children
foreach y of varlist $outcomes {
reg `y' $x  $dem s10 s12 s14 [aw=kernel_tri] if ss==1 & d_worked==1, vce( cluster age_mo_year) 
eststo est_2_`y'
mat coef=r(table)
**Mean (below cutoff)
sum `y' if year==2008 & ss==1 & d_worked==1
estadd scalar Mean=r(mean)
}

preserve
drop xx
rename xxy xx
foreach y of varlist $outcomes2 {
reg `y' $xy d_worked $dem sy10 sy12 sy14 [aw=kernel_triy] if ssy==1 & d_worked==1, vce( cluster age_mo_year) 
eststo est_2_`y'
mat coef=r(table)
**Mean (below cutoff)
sum `y' if year==2008 & ssy==1 & d_worked==1
estadd scalar Mean=r(mean)
}
restore
                                                               

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

*HH Survey
 use "${relabeled_data}/HHsurvey.dta", clear

*Sample from 2012 to 2019
keep if year>=2012 & year<=2019

*Diff in Disc variables
global x14 "treatw14 runningw14 treatxrunningw14"


************************************************************************************************************************
* 										14 year-old cut-off
************************************************************************************************************************	
	
*Controls
global xvars "post post_rev head_schooling head_male head_age indig_head male hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4 adult_women adult_men eligible_gr i.depto#i.year"

*Regression
rename xxw3 xx
reg log_wage_hour_w xx xxrw3 ${x14} $xvars [aw=kernel_triw14_18] if sww14_18==1, vce( cluster age_mo_year)
eststo est_1_log_wage_hour_w
sum number_workers_w if e(sample)==1 & pre==1
estadd scalar Mean=r(mean): est_1_log_wage_hour_w

*Label
label var xx "Post Law $\times$ Treated"

*Writting table header
file open myff using "${tabledir}/a_table_DDisc_formal_channels.tex", write replace
file write myff " \begin{table}[H] \centering"
file write myff "\caption{\centering Effects of the Law on Risk, Injuries at Work and Wages}  \label{tab:formal_channels}"
file write myff  " \begin{adjustbox}{center, max width=0.9\textwidth}\begin{threeparttable} "
file write myff "\begin{tabular}{lccccc}" 
file write myff  " \hline \hline"
file write myff  "  & Faces Risks & Faces Risks & Has Been & Has Been & Log Hourly \\ "
file write myff  " & at Work  & at Work & Injured at Work & Injured at Work & Wage \\"
file write myff  "  & (1) & (2) & (3) & (4) & (5) \\  \hline "
file close myff

*Writting coefficients                                                                 
esttab est_1_risks_a est_2_risks_a est_1_injury_a est_2_injury_a est_1_log_wage_hour_w using "${tabledir}/a_table_DDisc_formal_channels", tex frag  cells(b(star fmt(3)) se(par fmt(3))) stats(N Mean, labels(Obs. Mean) fmt(a3)) keep(xx xxrw3) append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none)

*Closing table
file open myff using "${tabledir}/a_table_DDisc_formal_channels.tex", write append
file write myff  " Sample & All Children & Working Children & All Children  & Working Children & Paid Workers \\  \hline "
file write myff "\hline \hline \end{tabular} \begin{tablenotes} "
file write myff "\item \begin{footnotesize} Notes: Age in months by year clustered standard errors in parentheses. Significance levels denoted by: *** p$<$0.01, ** p$<$0.05, * p$<$0.1. The sample in columns 1 to 4 comes from the child labor survey, and the sample in column 5 comes from the household survey. Control variables: gender, working indicator (Panel B only), urban indicator, age group fixed effects, household head characteristics (schooling, gender, age, and indigenous indicator), gender, number of children in the following age categories: 0-6, 7-9, 10-13, and 14-17, number of adult men and women, and departamento by year fixed effects. For the risk index regressions, the running variable is the difference between age in months and the age cutoff at the survey date. For the injury index, the running variable is the difference between age in months and the age cutoff a year before the survey date. In columns 1 to 4, we do a stacked difference in disconinuity by multiplying the running variable by -1 for the 13 and 14 year-olds age group for interpretability. For column 5, we do a difference in discontinuity in which the running variable is the difference between age in months and the age cut-off a week before the survey date. The specification includes linear splines of the running variable. The bandwidth for all specifications is 12 months. We use a triangular kernel. Survey years: 2008 and 2016 in columns 1 to 4 and 2012-2019 in column 5.  We use a reweighting method for columns 1 to 4 described in Section \ref{strategy}. \end{footnotesize}"
file write myff " \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}"
file close myff



