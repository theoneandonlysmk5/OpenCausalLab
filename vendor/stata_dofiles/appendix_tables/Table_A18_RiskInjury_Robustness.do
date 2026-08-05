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

*					          Risk Outcomes by age cutoff
*_______________________________________________________________________________

clear all

*Child Labor Survey
use "${relabeled_dataCS}/RW_child_labor_survey.dta", clear

*Variables for DDisc regressions
forvalues n=1(1)3{
local c=8+2*`n' 
global x1`c' "xx`n' post treat`c' running`c' treatxrunning`c'"
global x1y`c' "xx`n' post treaty`c' runningy`c' treatxrunningy`c'"
}

*Controls
global dem "h_edu_head h_male_head h_age_head indig_head c_gender hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4 adult_women adult_men c_area i.c_depto#i.year"

*Outcomes: recall on survey date
global outcomes "risks_a"
*Outcomes: recall a year before survey date
global outcomes2 "injury_a"


*Writting table header
file open myff using "${tabledir}/a_tab_DDisc_byage_risk.tex", write replace
file write myff " \begin{table}[H]"
file write myff "\caption{\centering Effects of the Law on Job Risks, and Work Injuries}\label{tab:riskbyage}"
file write myff "\begin{threeparttable}"
file write myff "\centering \renewcommand{\TPTminimum}{\linewidth}\makebox[\linewidth]{\begin{tabular}{lcc}"  
file write myff  "\multicolumn{3}{c}{Panel A: 14-Year-Old Cutoff} \\ \hline \hline"
file write myff  "  & Faces Risks & Has Been \\ "
file write myff  " & at Work & Injured at Work \\"
file write myff  "  & (1) & (2)  \\  \hline "
file close myff

********************************* 14 years old *********************************

*Regressions for date of survey recall
eststo clear
foreach y of varlist $outcomes {
reg `y' $x114 d_worked $dem [aw=kernel_tri14] if s14==1, vce( cluster age_mo_year) 
eststo est_2_`y'
mat coef=r(table)
**Mean (pre law)
sum `y' if year==2008 & s14==1
estadd scalar Mean=r(mean)
}

*Regressions for a year before date of survey recall
preserve
drop xx3
rename xxy3 xx3
foreach y of varlist $outcomes2 {
reg `y' $x1y14 d_worked $dem [aw=kernel_triy14] if sy14==1, vce( cluster age_mo_year) 
eststo est_2_`y'
mat coef=r(table)
**Mean (pre law)
sum `y' if year==2008 & sy14==1
estadd scalar Mean=r(mean)
}
restore

*label
label var xx3 "Post $\times \mathbbm{1}$\{Age$< 14 $\}"
	 
esttab using "${tabledir}/a_tab_DDisc_byage_risk", tex frag  cells(b(star fmt(3)) se(par fmt(3))) stats(N Mean, labels(Obs. Mean) fmt(a3)) keep(xx3) append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none)

file open myff using "${tabledir}/a_tab_DDisc_byage_risk.tex", write append
file write myff "\hline \hline \\"
file close myff

********************************* 12 years old *********************************

file open myff using "${tabledir}/a_tab_DDisc_byage_risk.tex", write append
file write myff "\multicolumn{3}{c}{Panel B: 12-Year-old Cutoff} \\"
file write myff "\hline \hline"
file write myff " & Faces Risks & Has Been \\ "
file write myff " & at Work & Injured at Work \\"
file write myff " & (1) & (2)  \\  \hline"
file close myff	

*Regressions for date of survey recall
eststo clear
foreach y of varlist $outcomes {
reg `y' $x112 d_worked $dem [aw=kernel_tri12] if s12==1, vce( cluster age_mo_year) 
eststo est_2_`y'
mat coef=r(table)
**Mean (pre law)
sum `y' if year==2008 & s12==1
estadd scalar Mean=r(mean)
}

*Regressions for a year before date of survey recall
preserve
drop xx2
rename xxy2 xx2
foreach y of varlist $outcomes2 {
reg `y' $x1y12 d_worked $dem [aw=kernel_triy12] if sy12==1, vce( cluster age_mo_year) 
eststo est_2_`y'
mat coef=r(table)
**Mean (pre law)
sum `y' if year==2008 & sy12==1
estadd scalar Mean=r(mean)
}
restore
 
label var treat12 "Post $\times \mathbbm{1}$\{Age$\geq 12 $\}"
 
esttab using "${tabledir}/a_tab_DDisc_byage_risk", tex frag  cells(b(star fmt(3)) se(par fmt(3))) stats(N Mean, labels(Obs. Mean) fmt(a3)) keep(xx2) append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none)

file open myff using "${tabledir}/a_tab_DDisc_byage_risk.tex", write append
file write myff "\hline \hline \\"
file close myff

********************************* 10 years old *********************************

file open myff using "${tabledir}/a_tab_DDisc_byage_risk.tex", write append
file write myff "\multicolumn{3}{c}{Panel C: 10-Year-old Cutoff} \\  \hline \hline"
file write myff  " & Faces Risks & Has Been \\ "
file write myff  " & at Work & Injured at Work \\"
file write myff " & (1) & (2)  \\  \hline"
file close myff	

*Regressions for date of survey recall
eststo clear
foreach y of varlist $outcomes {
reg `y' $x110 d_worked $dem [aw=kernel_tri10] if s10==1, vce( cluster age_mo_year) 
eststo est_2_`y'
mat coef=r(table)
**Mean (pre law)
sum `y' if year==2008 & s10==1
estadd scalar Mean=r(mean)
}

*Regressions for a year before date of survey recall
preserve
drop xx1
rename xxy1 xx1
foreach y of varlist $outcomes2 {
reg `y' $x1y10 d_worked $dem [aw=kernel_triy10] if sy10==1, vce( cluster age_mo_year) 
eststo est_2_`y'
mat coef=r(table)
**Mean (pre law)
sum `y' if year==2008 & sy10==1
estadd scalar Mean=r(mean)
}
restore

*label
label var xx1 "Post $\times \mathbbm{1}$\{Age$\geq 10 $\}"
                                                                 
esttab using "${tabledir}/a_tab_DDisc_byage_risk", tex frag  cells(b(star fmt(3)) se(par fmt(3))) stats(N Mean, labels(Obs. Mean) fmt(a3)) keep(xx1) append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none)

*Closing file
file open myff using "${tabledir}/a_tab_DDisc_byage_risk.tex", write append
file write myff "\hline \hline \\\end{tabular}} \vspace{-0.5cm} \begin{tablenotes} "
file write myff "\item \begin{footnotesize} Notes: Age in months by year clustered standard errors in parentheses. Significance levels denoted by: *** p$<$0.01, ** p$<$0.05, * p$<$0.1. Control variables: gender, working indicator (Panel B only), urban indicator, age group fixed effects, household head characteristics (schooling, gender, age, and indigenous indicator), gender, number of children in the following age categories: 0-6, 7-9, 10-13, and 14-17, number of adult men and women, and departamento by year fixed effects. For the risk index regression, the running variable is the difference between age in months and the age cutoff at the survey date. For the injury index, the running variable is the difference between age in months and the age cutoff a year before the survey date. The specification includes linear splines of the running variable. The bandwidth for all specifications is 12 months. We use a triangular kernel. Survey years: 2008, 2016.  We use a reweighting method described in Section \ref{strategy}. \end{footnotesize}"
file write myff " \end{tablenotes} \end{threeparttable} \end{table}"
file close myff



