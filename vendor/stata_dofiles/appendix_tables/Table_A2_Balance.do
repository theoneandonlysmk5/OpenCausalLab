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
            Balance HH Data
==================================================*/

clear all

*HH survey 
use "${relabeled_data}/HHsurvey.dta", clear

*sample 2012-2019
keep if year>=2012 & year<=2019

*Balance Outcomes
global outcomes "head_schooling head_male head_age indig_head male hhsize" 

*Variables for diff in disc regressions
foreach c in 10 12 14 {
global x1`c' " treat`c' running`c' treatxrunning`c' post post_rev"
global x1w`c' " treat`c' runningw`c' treatxrunningw`c' post post_rev"
}


*Writting table header 
file open myff using "${tabledir}/a_tab_balance_work.tex", write replace
file write myff " \begin{table}[H]"
file write myff "\centering"
file write myff "\caption{Balance Table: Difference in Discontinuity - Household Survey} \label{tab:balance1} \begin{adjustbox}{center, max width=0.8\textwidth}"
file write myff "\begin{threeparttable}"
file write myff "\centering \begin{tabular}{l*{7}{c}} "
file write myff "\multicolumn{7}{c}{Panel A: 14-Year-Old Cutoff} \\ \hline \hline"
file write myff  "  & Schooling  & Male & Age & Indigenous & Male & HH size \\ "
file write myff  "  & (HH head) & (HH head) & (HH head) & (HH head) & (child)&  \\ "
file write myff  "  & (1) & (2) & (3) & (4) & (5) & (6) \\ \hline"
file close myff


********************************************************************************
* 							    Regressions
********************************************************************************

********************************* 14 years old *********************************
eststo clear 
foreach y of varlist $outcomes {
reg `y' xx3 xxr3 ${x114}  [aw=kernel_tri14] if s14==1, vce( cluster age_mo_year) 
eststo est14_`y'
**Mean (pre law)
sum `y' if treat14==0 & pre==1 & e(sample)==1
estadd scalar Control_mean=r(mean)
sum `y' if treat14==1 & pre==1 & e(sample)==1
estadd scalar Treated_mean=r(mean)
}

*Labels
label var xx3 "Post Law $\times$ $\mathbbm{1}$\{Age$<14$\}"
label var xxr3 "Post Reversal $\times$ $\mathbbm{1}$\{Age$<14$\}"

esttab using "${tabledir}/a_tab_balance_work", tex frag  cells(b(star fmt(3)) se(par fmt(3))) stats(N Treated_mean Control_mean, labels(Obs. "Mean Control" "Mean Treated") fmt(a3))  keep(xx3 xxr3) append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none)

foreach y of varlist $outcomes {
quietly reg `y' xx3 xxr3 ${x114}  [aw=kernel_tri14]
eststo `y'
}
qui suest $outcomes , vce(robust)
test xx3 xxr3
local p_val14=round(r(p), 0.001)

file open myff using "${tabledir}/a_tab_balance_work.tex", write append
file write myff "\multicolumn{7}{c}{Joint test P-value = `p_val14'}\\"
file write myff "\hline \\"
file close myff

********************************* 12 years old *********************************
file open myff using "${tabledir}/a_tab_balance_work.tex", write append
file write myff "\multicolumn{7}{c}{Panel B: 12-Year-Old Cutoff} \\ \hline \hline"
file write myff  "  & Schooling  & Male & Age & Indigenous & Male & HH size \\ "
file write myff  "  & (HH head) & (HH head) & (HH head) & (HH head) & (child)&  \\ "
file write myff  "  & (1) & (2) & (3) & (4) & (5) & (6) \\ \hline"
file close myff

eststo clear 
foreach y of varlist $outcomes {
reg `y' xx2 xxr2 ${x112}  [aw=kernel_tri12] if s12==1, vce( cluster age_mo_year) 
eststo est12_`y'
**Mean (pre law)
sum `y' if treat12==0 & pre==1  & e(sample)==1
estadd scalar Control_mean=r(mean)
sum `y' if treat12==1 & pre==1  & e(sample)==1
estadd scalar Treated_mean=r(mean)
}

*Labels
label var xx2 "Post Law $\times$ $\mathbbm{1}$\{Age$\geq 12$\}"
label var xxr2 "Post Reversal $\times$ $\mathbbm{1}$\{Age$\geq 12$\}"

esttab using "${tabledir}/a_tab_balance_work", tex frag  cells(b(star fmt(3)) se(par fmt(3))) stats(N Treated_mean Control_mean, labels(Obs. "Mean Control" "Mean Treated") fmt(a3))  keep(xx2 xxr2) append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none)

foreach y of varlist $outcomes {
quietly reg `y' xx2 xxr2 ${x112}  [aw=kernel_tri12]
eststo `y'
}
qui suest $outcomes , vce(robust)
test xx2 xxr2
local p_val12=round(r(p), 0.001)

file open myff using "${tabledir}/a_tab_balance_work.tex", write append
file write myff "\multicolumn{7}{c}{Joint test P-value = `p_val12'}\\"
file write myff "\hline \\"
file close myff

********************************* 10 years old *********************************
file open myff using "${tabledir}/a_tab_balance_work.tex", write append
file write myff "\multicolumn{7}{c}{Panel C: 10-Year-Old Cutoff} \\ \hline \hline"
file write myff  "  & Schooling  & Male & Age & Indigenous & Male & HH size \\ "
file write myff  "  & (HH head) & (HH head) & (HH head) & (HH head) & (child)&  \\ "
file write myff  "  & (1) & (2) & (3) & (4) & (5) & (6) \\ \hline"
file close myff

eststo clear 
foreach y of varlist $outcomes {
reg `y' xx1 xxr1 ${x110}  [aw=kernel_tri10] if s10==1, vce( cluster age_mo_year) 
eststo est10_`y'
**Mean (pre law)
sum `y' if treat10==0 & pre==1  & e(sample)==1
estadd scalar Control_mean=r(mean)
sum `y' if treat10==1 & pre==1  & e(sample)==1
estadd scalar Treated_mean=r(mean)
}

*Labels
label var xx1 "Post Law $\times$ $\mathbbm{1}$\{Age$\geq 10$\}"
label var xxr1 "Post Reversal $\times$ $\mathbbm{1}$\{Age$\geq 1$\}"

esttab using "${tabledir}/a_tab_balance_work", tex frag  cells(b(star fmt(3)) se(par fmt(3))) stats(N  Treated_mean Control_mean, labels(Obs.  "Mean Control" "Mean Treated") fmt(a3))  keep(xx1 xxr1) append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none)


foreach y of varlist $outcomes {
quietly reg `y' xx1 xxr1 ${x110}  [aw=kernel_tri10]
eststo `y'
}
qui suest $outcomes , vce(robust)
test xx1 xxr1
local p_val10=round(r(p), 0.001)

file open myff using "${tabledir}/a_tab_balance_work.tex", write append
file write myff "\multicolumn{7}{c}{Joint test P-value = `p_val10'}\\"
file write myff "\hline \\"
file close myff


 file open myff using "${tabledir}/a_tab_balance_work.tex", write append
file write myff "\hline \hline \\\end{tabular} \begin{tablenotes} "
file write myff "\item \begin{footnotesize} Notes: Age in months by year clustered standard errors in parentheses. Significance levels denoted by: *** p$<$0.01, ** p$<$0.05, * p$<$0.1. The running variable is the difference between age in months and the age cut-off at the survey date. The specification includes linear splines of the running variable, an indicator that is one from 2014 to 2017, an indicator equal to one on 2018 and after, and an indicator that is one for the children in the corresponding age group. The bandwidth for all specifications is 12 months. We use a triangular kernel. The sample includes 2012-2019. \end{footnotesize}"
file write myff " \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}"
file close myff

 
 