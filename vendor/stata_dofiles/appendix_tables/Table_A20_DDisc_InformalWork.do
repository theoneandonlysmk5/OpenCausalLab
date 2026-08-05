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

* 		Difference in Disc results for referee re
*_______________________________________________________________________________

clear all

*HH Survey
use "${relabeled_data}/HHsurvey.dta", clear

gen informal = 1 if works==1 & firm_taxes==0
replace informal = 0 if informal==. & works~=.

*Outcomes
global yvars "works informal "

*Sample 2012 to 2019
keep if year>=2012 & year<=2019

*Globals with diff in disc vars

	*Recall: survey date
global x14 "treat14 running14 treatxrunning14"
	*Recall: a week before the survey date
global xw14 "treatw14 runningw14 treatxrunningw14 "


********************************* 14 years old *********************************
	
*Write table header
file open myff using "${tabledir}/formal_informal.tex", write replace
file write myff "\begin{table}[H]"
file write myff "\centering "
file write myff "\caption{Difference in Discontinuity Effects of the Law on the Work Probabilities by Work Type for the 14-Year-Old Cutoff} \label{tab:formal_informal} \begin{adjustbox}{center, max width=0.9\textwidth}"
file write myff "\begin{threeparttable}"
file write myff "\begin{tabular}{l*{3}{c}} \\ \hline \hline "
file write myff  "  & Any & Informal   \\  "
file write myff  "  & Work & Work  \\  "
file write myff  "  & (1) & (2)  \\ \hline"
file close myff	

*Controls
global xvars "post post_rev urban head_schooling head_male head_age indig_head male hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4 adult_women adult_men eligible_gr i.depto#i.year"

*regressions
foreach y in $yvars{		
reg `y' xxw3 xxrw3 ${xw14} $xvars [aw=kernel_triw14], vce( cluster age_mo_year)
eststo est1`y'
sum `y' if e(sample)==1 & pre==1
estadd scalar Mean=r(mean)
}
esttab using "${tabledir}/formal_informal", tex frag  cells(b(star fmt(a3)) se(par fmt(a3))) stats(N Mean, labels(Obs. Mean)) keep(xxw3 xxrw3) append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none)

eststo clear

*Closing file
file open myff using "${tabledir}/formal_informal.tex", write append
file write myff "\hline \hline \\\end{tabular} \vspace{-0.5cm}  \begin{tablenotes} "
file write myff "\item \begin{footnotesize} Notes: Age in months by year clustered standard errors in parentheses. Significance levels denoted by: *** p$<$0.01, ** p$<$0.05, * p$<$0.1. Control variables: CCT eligibility indicator, household head characteristics (schooling, gender, age, and indigenous indicator), gender, number of children in the following age categories: 0-6, 7-9, 10-13, and 14-17, number of adult men and women, an urban dummy, and departamento by year fixed effects.  We also include linear splines of the running variable, defined as the difference between the cutoff age and age a week before the survey date in months. We use a bandwidth of 12 months and a triangular kernel. Survey years: 2012-2017. \end{footnotesize}"
file write myff " \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}"
file close myff





