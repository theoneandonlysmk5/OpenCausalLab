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
     Difference in Disc results for informal channels outcomes, 2012-2019
==================================================*/

clear all

use "${relabeled_data}/HHsurvey.dta", clear

*Outcomes
global yvars1 "location_out_fixed_a location_out_mobile_a location_home_a  "
global yvars "location_out_fixed_a location_out_mobile_a location_home_a  number_workers_a  "

*Sample 2012-2019
keep if year>=2012 & year<=2019

*Globals with diff in disc vars
global x14 "treat14 running14 treatxrunning14"
global xw14 "treatw14 runningw14 treatxrunningw14 "

	
*Write table header	
file open myff using "${tabledir}/a_table_DDisc_informal_channels.tex", write replace
file write myff "\begin{table}[H]"
file write myff "\centering "
file write myff "\caption{Effects of the Law on Job Location and Firm Size} \label{tab:informal_channels} \begin{adjustbox}{center, max width=1.2\textwidth}"
file write myff "\begin{threeparttable}"
file write myff "\begin{tabular}{l*{5}{c}} \\ \multicolumn{5}{c}{Panel A: All Children} \\\hline \hline "
file write myff  "  & Works in Fixed & Works in Mobile & Works at Home \\  "
file write myff  " & Location Out of Home &  Location Out of Home & \\ "
file write myff  "  & (1) & (2) & (3) &  \\ \hline"
file close myff	

********************************* 14 years old *********************************

*Controls
global xvars "post post_rev urban head_schooling head_male head_age indig_head male hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4 adult_women adult_men eligible_gr i.depto#i.year"

*regressions for all children
foreach y in $yvars1{		
reg `y' xxw3 xxrw3 ${xw14} $xvars [aw=kernel_triw14], vce( cluster age_mo_year)
eststo est1`y'
sum `y' if e(sample)==1 & pre==1
estadd scalar Mean=r(mean)
}
esttab using "${tabledir}/a_table_DDisc_informal_channels", tex frag  cells(b(star fmt(3)) se(par fmt(3))) stats(N Mean, labels(Obs. Mean) fmt(a3)) keep(xxw3 xxrw3) append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none)

eststo clear

file open myff using "${tabledir}/a_table_DDisc_informal_channels.tex", write append
file write myff "\hline \hline \\ "
file close myff

file open myff using "${tabledir}/a_table_DDisc_informal_channels.tex", write append
file write myff "\multicolumn{5}{c}{Panel B: Working Children} \\ \hline \hline"
file write myff  "   & Works in Fixed & Works in Mobile & Works at Home & Firm \\  "
file write myff  " & Location Out of Home &  Location Out of Home & & Size \\ "
file write myff  "  & (4) & (5) & (6) & (7) \\ \hline"
file close myff	

*regressions for working children
foreach y in $yvars{		
reg `y' xxw3 xxrw3 ${xw14} $xvars [aw=kernel_triw14] if works==1, vce( cluster age_mo_year)
eststo est1`y'
sum `y' if e(sample)==1 & pre==1
estadd scalar Mean=r(mean)
}
esttab using "${tabledir}/a_table_DDisc_informal_channels", tex frag  cells(b(star fmt(3)) se(par fmt(3))) stats(N Mean, labels(Obs. Mean) fmt(a3)) keep(xxw3 xxrw3) append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none)

eststo clear

file open myff using "${tabledir}/a_table_DDisc_informal_channels.tex", write append
file write myff "\hline \hline \\\end{tabular} \vspace{-0.5cm}  \begin{tablenotes} "
file write myff "\item \begin{footnotesize} Notes: Age in months by year clustered standard errors in parentheses. Significance levels denoted by: *** p$<$0.01, ** p$<$0.05, * p$<$0.1. The sample in Panel A includes all children, while the sample in Panel B is restricted to working children only. Control variables: CCT eligibility indicator, household head characteristics (schooling, gender, age, and indigenous indicator), gender, number of children in the following age categories: 0-6, 7-9, 10-13, and 14-17, number of adult men and women, an urban dummy, and departamento by year fixed effects.  We also include linear splines of the running variable, defined as the difference between the cutoff age and age a week before the survey date in months. We use a bandwidth of 12 months and a triangular kernel. Survey years: 2012-2019. \end{footnotesize}"
file write myff " \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}"
file close myff


