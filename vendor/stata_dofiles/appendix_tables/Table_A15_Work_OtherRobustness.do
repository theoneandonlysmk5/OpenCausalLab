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

rename xxw3 xx
rename xxrw3 xxr

eststo clear


*Writting table header
file open myff using "${tabledir}/a_tab_robustness_works2.tex", write replace
file write myff " \begin{table}[!h]"
file write myff "\centering "
file write myff "\caption{Other Robustness Checks: Difference in Discontinuity for Work Probability (14-Year-Old Cutoff)} \label{tab:robustwork2}"
file write myff  " \begin{adjustbox}{center, max width=1.2\textwidth}\begin{threeparttable} "
file write myff " \begin{tabular}{l*{5}{c}} "
file write myff "\hline \hline"
file write myff " & Baseline & Excl. & Excl. & Cluster Age \\ "
file write myff " & Estimation & Indig. & CCT control  & \& Region \\  " 
file write myff " & (1) & (2) & (3) & (4)   \\ \hline "
file close myff


********************************* 14 years old *********************************

*Variables for regressions
global x1w "xx xxr treatw14 runningw14 treatxrunningw14 post post_rev"
global dem "urban head_schooling head_male head_age indig_head male hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4 adult_women adult_men eligible_gr i.depto#i.year"


*Bandwidth
foreach bw in 12{
reg works $x1w $dem [aw=kernel_triw14_`bw'] if sww14_`bw'==1, vce( cluster $cluster) 
eststo est1_`bw'_14
**Mean (pre law)
sum works if pre==1 &  e(sample)==1
estadd scalar Mean=r(mean)

}

local bw=12

*Excluding municipalities with less indigenous people
global eix1w "xx  treatw14 runningw14 treatxrunningw14 post "
reg works $eix1w $dem [aw=kernel_triw14_`bw'] if sww14_`bw'==1 & lessindigsample==1 , vce( cluster $cluster) 
eststo est8_14
sum works if pre==1 &  e(sample)==1
estadd scalar Mean=r(mean)

*not controlling by cct
global dem2 "urban head_schooling head_male head_age indig_head male hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4 adult_women adult_men i.depto#i.year"
reg works $x1w $dem2 [aw=kernel_triw14_`bw'] if sww14_`bw'==1, vce( cluster $cluster) 
eststo est9_14
**Mean (pre law)
sum works if pre==1 &  e(sample)==1
estadd scalar Mean=r(mean)


*clustering by age and region (cannot do post rev)
global x1wc "xx treatw14 runningw14 treatxrunningw14 post"
reg works $x1wc $dem [aw=kernel_triw14_`bw'] if sww14_`bw'==1, vce( cluster age_mo_year cod_secc) 
eststo est11_14
**Mean (pre law)
sum works if pre==1 &  e(sample)==1
estadd scalar Mean=r(mean)

*labels
label var xx "Post law $\times \mathbbm{1}$\{Age$< 14 $\}"
label var xxr "Post reversal $\times \mathbbm{1}$\{Age$< 14 $\}"
                                              
esttab using "${tabledir}/a_tab_robustness_works2", tex frag  cells(b(star fmt(3)) se(par fmt(3))) stats(N Mean, labels(Obs. Mean) fmt(a3))  keep(xx xxr)  append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none)
                      
*************************** Closing file *************************** 
file open myff using "${tabledir}/a_tab_robustness_works2.tex", write append
file write myff "\hline \hline \\\end{tabular} \vspace{-0.5cm} \begin{tablenotes} "
file write myff "\item \begin{footnotesize} Notes: Household level clustered standard errors in parentheses. Controls: in grade for CCT, an indicator for urban, household head characteristics (schooling, gender, age, and indigenous indicator), gender, number of children in the household in following age categories: 0-6, 7-9, 10-13, and 14-17,  number of adult men and women, and departamento by year fixed effects. The running variable is the difference between age in months and the age cut-off a week before the survey date. We include linear splines of the running variable, an indicator for 2014 and after, and an indicator that is one for the children in the corresponding age group. Column 2 excludes municipalities with above median shares of indigenous residents. Column 3 excludes the control that indicates whether the child is eligible for the CCT. Column 4 excludes the year 2014 from the sample. Column 5 clusters by age in months and municipality. For columns 2 and 5, because municipality codes are anonymized in the household survey data starting in 2017, we cannot link the data to other sources using municipality codes for the periods after the law was reversed. We use a triangular kernel. The sample includes 2012-2016 for columns 2 and 5, 2012-2013 and 2015-2019 for column 4, and 2012-2019 for all other columns. \end{footnotesize}"
file write myff " \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}"
file close myff


