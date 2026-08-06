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

*______________________________________________________________________________________________________________________________
 *					
 *							Balance reweighted risk samples
 *______________________________________________________________________________________________________________________________
 
clear all

*Child labor survey
use "${relabeled_dataCS}/RW_child_labor_survey.dta", clear

*Variables for DDisc regressions
global x "xx post treat running treatxrunning"

********************************************************************************
**								Balance 30%									  **
********************************************************************************

*Outcomes
global balance "c_gender hhsize h_age_head h_edu_head h_male_head indig_head h_area"

*Writting table header
file open myff using "${tabledir}/a_tab_balance_rwrisk_30pc.tex", write replace
file write myff " \begin{table}[H]"
file write myff "\centering"
file write myff "\caption{Balance for 30\% of Child Labor Survey Data} \label{tab:reweightbalance}"
file write myff  " \begin{adjustbox}{center, max width=1.2\textwidth}\begin{threeparttable} "
file write myff "\begin{tabular}{l*{8}{c}} "
file write myff "\hline \hline"
file write myff  "  & Male & HH Size & Age & Education & Male & Indigenous & Urban \\ "
file write myff  "  &  &  & HH Head & HH Head  & HH Head  & HH Head  &\\ "
file write myff  "  & (1) & (2) & (3) & (4) & (5) & (6) & (7)\\ \hline"
file close myff


*Regression balance outcomes
eststo clear

foreach y of varlist $balance {
reg `y' post [aw=weights] if ss==1 & sample==0, vce( cluster age_mo_year) 
eststo est_2_`y'
mat coef=r(table)
**Mean (pre law)
sum `y' if year==2008 & ss==1
estadd scalar Mean=r(mean)
}

esttab using "${tabledir}/a_tab_balance_rwrisk_30pc", tex frag  cells(b(star fmt(3)) se(par fmt(3))) stats(N Mean, labels(Obs. Mean) fmt(a3)) keep(post) append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none)

*Joint test
eststo clear
foreach y of varlist $balance {
reg `y' post [aw=weights] if ss==1 & sample==0
eststo `y'
}
qui suest $balance , vce(robust)
test post
local p_val=round(r(p), 0.001)


file open myff using "${tabledir}/a_tab_balance_rwrisk_30pc.tex", write append
file write myff "\multicolumn{7}{c}{Joint test P-value = `p_val'}\\"
file close myff

*Closing file
file open myff using "${tabledir}\a_tab_balance_rwrisk_30pc.tex", write append
file write myff "\hline \hline \\\end{tabular} \begin{tablenotes} "
file write myff "\item \begin{footnotesize} Notes: Household level clustered standard errors in parentheses. Significance levels denoted by: *** p$<$0.01, ** p$<$0.05, * p$<$0.1. The specification includes an indicator that is one in 2016. The running variable is multiplied by -1 for the 13 and 14 year-olds age group for interpretability. The bandwidth for all specifications is 12 months. The sample is 30\% of the 2008 and 2016 observations that were not used in the reweighting exercise. \end{footnotesize}"
file write myff " \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}"
file close myff

  
 
********************************************************************************
** 							Balance - Full sample	   						  **
********************************************************************************
*balance outcomes
global balance "c_gender hhsize h_age_head h_edu_head h_male_head indig_head h_area"

*Writting table header
file open myff using "${tabledir}/a_tab_balance_rwrisk_fullsample.tex", write replace
file write myff " \begin{table}[H]"
file write myff "\centering"
file write myff "\caption{Balance for Reweighted Child Labor Survey Data - Full sample} \label{tab:balance2}"
file write myff  " \begin{adjustbox}{center, max width=1.2\textwidth}\begin{threeparttable} "
file write myff "\begin{tabular}{l*{8}{c}} "
file write myff " \hline \hline"
file write myff  "  & Male & HH Size & Age & Education & Male & Indigenous & Urban \\ "
file write myff  "  &  &  & HH Head & HH Head  & HH Head  & HH Head  &\\ "
file write myff  "  & (1) & (2) & (3) & (4) & (5) & (6) & (7)\\ \hline"
file close myff

*Regression balance outcomes
eststo clear

foreach y of varlist $balance {
reg `y' $x s10 s12 s14 [aw=kernel_tri] if ss==1 , vce( cluster age_mo_year) 
eststo est_2_`y'
mat coef=r(table)
**Mean (pre law)
sum `y' if year==2008 & ss==1
estadd scalar Mean=r(mean)
}

label var xx  "Post $\times$ Treated "
esttab using "${tabledir}/a_tab_balance_rwrisk_fullsample", tex frag  cells(b(star fmt(3)) se(par fmt(3))) stats(N Mean, labels(Obs. Mean) fmt(a3)) keep(xx) append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none)

*Joint test
eststo clear
foreach y of varlist $balance {
reg `y' $x s10 s12 s14 [aw=kernel_tri] if ss==1  
eststo `y'
}
qui suest $balance , vce(robust)
test xx
local p_val=round(r(p), 0.001)


file open myff using "${tabledir}/a_tab_balance_rwrisk_fullsample.tex", write append
file write myff "\multicolumn{7}{c}{Joint test P-value = `p_val'}\\"
file close myff


file open myff using "${tabledir}/a_tab_balance_rwrisk_fullsample.tex", write append
file write myff "\hline \hline \\\end{tabular} \begin{tablenotes} "
file write myff "\item \begin{footnotesize} Notes: Age in months by year clustered standard errors in parentheses. Significance levels denoted by: *** p$<$0.01, ** p$<$0.05, * p$<$0.1.  The running variable is the difference between age in months and the age cut-off at the survey date. The specification includes linear splines of the running variable, an indicator that is one in 2016, and an indicator that is one for the children in the corresponding age group. The bandwidth for all specifications is 12 months. We use a triangular kernel. The sample includes 2008 and 2016. \end{footnotesize}"
file write myff " \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}"
file close myff 
  