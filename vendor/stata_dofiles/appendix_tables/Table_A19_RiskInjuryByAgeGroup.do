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

*									risk DiDisc
*_______________________________________________________________________________

clear all

*Child Labor Survey
use "${relabeled_dataCS}/RW_child_labor_survey.dta", clear

*globals for DDisc regressions
global x "xx post treat running treatxrunning"
global xy "xx post treaty runningy treatxrunningy"
global x2 "${x}  running2 treatxrunning2 "
global x2y "${xy}  runningy2 treatxrunningy2"


* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* 									Bandwidth									*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

*Writting file for risk outcomes
file open myff using "${tabledir}/a_tab_robustness_srwriskv2.tex", write replace
file write myff " \begin{table}[H]"
file write myff "\centering "
file write myff "\caption{Robustness Checks: Difference in Discontinuity for Risk Outcomes} \label{tab:robustsrwrisk}"
file write myff  "\begin{adjustbox}{center, max width=1.2\textwidth} \begin{threeparttable} "
file write myff " \renewcommand{\TPTminimum}{\linewidth}\makebox[\linewidth]{\begin{tabular}{l*{7}{c}} "
file write myff "\multicolumn{7}{c}{Panel A: Different Bandwidth Specifications} \\ \hline \hline"
file write myff " & \multicolumn{3}{c}{Risk Index} & \multicolumn{3}{c}{Injury Index} \\ \cmidrule(lr){2-4}\cmidrule(lr){5-7} "
file write myff " & \multicolumn{6}{c}{ \begin{footnotesize}  \textit{Bandwidth (months)}  \end{footnotesize} } \\"
file write myff " &  & Baseline &  &  & Baseline  &  \\ "
file write myff " & 6 & 12 & 24 & 6 & 12 & 24  \\ "
file write myff " & (1) & (2) & (3) & (4) & (5) & (6)  \\ \hline"
file close myff

*Controls
global dem2 "h_edu_head h_male_head h_age_head indig_head c_gender hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4 adult_women adult_men c_area i.c_depto#i.year"

*Outcomes with date of survey recall
global outcomes "risks_a  "

*Outcomes with one year before date of survey recall
global outcomes2 "injury_a"


*Regressions with different bandwidths
foreach y in $outcomes{
foreach bw in  6 12 24 {
reg `y' $x $dem2 s10 s12 s14 [aw=kernel_tri_`bw'] if s_`bw'==1, vce( cluster age_mo_year) 
eststo est`bw'_`y'
**Mean (pre law)
sum `y' if year==2008 & s_`bw'==1
estadd scalar Mean=r(mean)
}
}

preserve
drop xx
rename xxy xx
foreach bw in  6 12 24 {
foreach y of varlist $outcomes2 {
reg `y' $xy $dem2  sy10 sy12 sy14 [aw=kernel_triy_`bw'] if sy_`bw'==1, vce( cluster age_mo_year) 
eststo est_`bw'_`y'
**Mean (pre law)
sum `y' if year==2008 & sy_`bw'==1
estadd scalar Mean=r(mean)
}
}
restore

*labels
label var xx "Post $ \times$ Treated"

esttab using "${tabledir}/a_tab_robustness_srwriskv2", tex frag  cells(b(star fmt(3)) se(par fmt(3))) stats(N r2 Mean, labels(Obs. R-squared Mean) fmt(a3)) keep(xx)  append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none)

file open myff using "${tabledir}/a_tab_robustness_srwriskv2.tex", write append
file write myff "\hline \hline \\"
file close myff

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* 				No controls, Quadratic, Donut 									*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

file open myff using "${tabledir}/a_tab_robustness_srwriskv2.tex", write append
file write myff "\multicolumn{7}{c}{Panel B: Without Controls, Quadratic Splines, and Donut Specification} \\ \hline \hline"
file write myff " & \multicolumn{3}{c}{Risk Index} & \multicolumn{3}{c}{Injury Index} \\ \cmidrule(lr){2-4}\cmidrule(lr){5-7} "
file write myff " & No Controls & Quadratic & Donut & No Controls & Quadratic & Donut  \\ "
file write myff " & (1) & (2) & (3) & (4) & (5) & (6) \\ \hline"
file close myff


eststo clear

foreach y in $outcomes{
 
*No controls 
reg `y' $x  s10 s12 s14 [aw=kernel_tri] if ss==1, vce( cluster age_mo_year) 
eststo est2`y'
**Mean (pre law)
sum `y' if year==2008 & ss==1
estadd scalar Mean=r(mean)

*Quadratic
reg `y' $x2 $dem2 s10 s12 s14 [aw=kernel_tri] if ss==1, vce( cluster age_mo_year) 
eststo est3`y'
**Mean (pre law)
sum `y' if year==2008 & ss==1
estadd scalar Mean=r(mean)

*Donut
reg `y' $x $dem2 s10 s12 s14 [aw=kernel_tri] if ds_12==1, vce( cluster age_mo_year) 
eststo est4`y'
**Mean (pre law)
sum `y' if year==2008 & ds_12==1
estadd scalar Mean=r(mean)


}


preserve
drop xx
rename xxy xx

*No controls
reg injury_a $xy  sy10 sy12 sy14 [aw=kernel_triy] if ssy==1, vce( cluster age_mo_year) 
eststo est2_injury
**Mean (pre law)
sum injury_a if year==2008 & ssy==1
estadd scalar Mean=r(mean)

*Quadratic
reg injury_a $x2y $dem2  sy10 sy12 sy14 [aw=kernel_triy] if ssy==1, vce( cluster age_mo_year) 
eststo est3_injury
**Mean (pre law)
sum injury_a if year==2008 & ssy==1
estadd scalar Mean=r(mean)

*Donut
reg injury_a $xy $dem2  sy10 sy12 sy14 [aw=kernel_triy] if dsy_12==1, vce( cluster age_mo_year) 
eststo est4_injury
**Mean (pre law)
sum injury_a if year==2008 & dsy_12==1
estadd scalar Mean=r(mean)

restore

*Label
label var xx "Post $\times$ Treated"

esttab using "${tabledir}/a_tab_robustness_srwriskv2", tex frag  cells(b(star fmt(3)) se(par fmt(3))) stats(N r2 Mean, labels(Obs. R-squared Mean) fmt(a3)) keep(xx)  append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none)


*Closing file
file open myff using "${tabledir}/a_tab_robustness_srwriskv2.tex", write append
file write myff "\hline \hline \\\end{tabular}} \begin{tablenotes} "
file write myff "\item \begin{footnotesize} Notes: Household level clustered standard errors in parentheses. Significance levels denoted by: *** p$<$0.01, ** p$<$0.05, * p$<$0.1. The control variables are: gender, urban indicator, age group fixed effects, household head characteristics (schooling, gender, age, and indigenous indicator), gender, number of children in the following age categories: 0-6, 7-9, 10-13, and 14-17, number of adult men and women, and departamento by year fixed effects. The running variables are the difference between age in months and the age cut-off at the survey date for the risk and hazardous work indices, and the difference between age in months and the age cut-off a year before the survey date for the injury index. The specification includes linear splines of the running variable, an indicator that is one in 2016, and an indicator that is one for the children in the corresponding age group. We use a triangular kernel. The sample includes 2008 and 2016. \end{footnotesize}"
file write myff " \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}"
file close myff


