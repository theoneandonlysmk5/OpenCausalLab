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

*									Work Robustness
*_______________________________________________________________________________

clear all

eststo clear


*HH Survey
use "${relabeled_data}/HHsurvey.dta", clear

*Sample 2012-2019
keep if year>=2012 & year<=2019

*cluster
global cluster "age_mo_year"

*Writting table header
file open myff using "${tabledir}/a_tab_robustness_works1.tex", write replace
file write myff " \begin{table}[!h]"
file write myff "\centering "
file write myff "\caption{Functional Form Robustness Checks: Difference in Discontinuity for Work Probability (14-Year-Old Cutoff)} \label{tab:robustwork1}"
file write myff  " \begin{adjustbox}{center, max width=0.9\textwidth}\begin{threeparttable} "
file write myff " \begin{tabular}{l*{9}{c}} "
file write myff "\hline \hline"
file write myff " & \multicolumn{3}{c}{Bandwidth (months)} & &  &  \multicolumn{2}{c}{Polynomials Pre-Post} &   \\ "
file write myff " & 6 & 12 & 24 &  No Controls & Quadratic & Linear & Quadratic & Donut  \\ \cmidrule(lr){2-4} \cmidrule(lr){5-5} \cmidrule(lr){6-6} \cmidrule(lr){7-8}  " 
file write myff " &  & (Baseline) & & & & & &   \\ "
file write myff " & (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8)  \\ \hline "
file close myff


********************************* 14 years old *********************************
rename xxw3 xx
rename xxrw3 xxr

*Variables for regressions
global x1w "xx xxr treatw14 runningw14 treatxrunningw14 post post_rev"
global dem "urban head_schooling head_male head_age indig_head male hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4 adult_women adult_men eligible_gr i.depto#i.year"


*Bandwidth
foreach bw in  6 12 24{
reg works $x1w $dem [aw=kernel_triw14_`bw'] if sww14_`bw'==1, vce( cluster $cluster) 
eststo est1_`bw'_14
**Mean (pre law)
sum works if pre==1 &  e(sample)==1
estadd scalar Mean=r(mean)

}

local bw=12

*no controls
reg works $x1w eligible_gr [aw=kernel_triw14_`bw'] if sww14_`bw'==1, vce( cluster $cluster) 
eststo est2`bw'_14
**Mean (pre law)
sum works if pre==1 &  e(sample)==1
estadd scalar Mean=r(mean)

*quadratic
global x2w "$x1w running2w14 treatxrunning2w14"
reg works $x2w $dem [aw=kernel_triw14_`bw'] if sww14_`bw'==1, vce( cluster $cluster) 
eststo est3_14
**Mean (pre law)
sum works if pre==1 &  e(sample)==1
estadd scalar Mean=r(mean)

*poly linear
global x1wp "$x1w postxrunningw14 postrxrunningw14"
reg works $x1wp $dem [aw=kernel_triw14_`bw'] if sww14_`bw'==1, vce( cluster $cluster) 
eststo est4_14
**Mean (pre law)
sum works if pre==1 &  e(sample)==1
estadd scalar Mean=r(mean)

*poly- quad
global x2wp "$x1w running2w14 treatxrunning2w14 postxrunning2w14 postrxrunning2w14"
reg works $x2wp $dem [aw=kernel_triw14_`bw'] if sww14_`bw'==1, vce( cluster $cluster) 
eststo est5_14
**Mean (pre law)
sum works if pre==1 &  e(sample)==1
estadd scalar Mean=r(mean)

*Donut
reg works $x1w $dem [aw=kernel_triw14_`bw'] if donsww14==1, vce( cluster $cluster) 
eststo est7_14
**Mean (pre law)
sum works if pre==1 &  e(sample)==1
estadd scalar Mean=r(mean)

*labels
label var xx "Post law $\times \mathbbm{1}$\{Age$< 14 $\}"
label var xxr "Post reversal $\times \mathbbm{1}$\{Age$< 14 $\}"
                                              
esttab using "${tabledir}/a_tab_robustness_works1", tex frag  cells(b(star fmt(3)) se(par fmt(3))) stats(N Mean, labels(Obs. Mean) fmt(a3))  keep(xx xxr)  append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none)
                      
*************************** Closing file *************************** 
file open myff using "${tabledir}/a_tab_robustness_works1.tex", write append
file write myff "\hline \hline \\\end{tabular} \vspace{-0.5cm} \begin{tablenotes} "
file write myff "\item \begin{footnotesize} Notes: Household level clustered standard errors in parentheses. Controls: in grade for CCT, an indicator for urban, household head characteristics (schooling, gender, age, and indigenous indicator), gender, number of children in the household in following age categories: 0-6, 7-9, 10-13, and 14-17,  number of adult men and women, and departamento by year fixed effects. The running variable is the difference between age in months and the age cut-off a week before the survey date. We include linear splines of the running variable, an indicator for 2014 and after, and an indicator that is one for the children in the corresponding age group. Column 5 also includes quadratic splines of the running variable. Column 6 includes linear splines that that vary across both sides of the cut-off and before and after the law. Column 7 has linear and quadratic splines that vary across both sides of the cut-off and before and after the law. Column 8 omits children within 1 month of the age threshold. We use a triangular kernel. The sample includes 2012-2019. \end{footnotesize}"
file write myff " \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}"
file close myff

