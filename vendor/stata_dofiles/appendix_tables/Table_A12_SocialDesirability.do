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

* 						Social Desirability Bias Checks
*_______________________________________________________________________________

clear all

*HH Survey
use "${relabeled_data}/HHsurvey.dta", clear

*12 compared to 13
scalar ll_t=12*12
scalar ul_t=ll_t+11
scalar ul_nt=14*12

gen treatdid1213= (age_dob_m-0.25)<ul_t & (age_dob_m-0.25)>=ll_t
replace treatdid1213=. if (age_dob_m-0.25)<ll_t | (age_dob_m-0.25)>=ul_nt

*post times treats
	gen xxdid1213=post*treatdid1213
	label var xxdid1213 "Post Law $\times$ $\mathbbm{1}$\{ Age$=12$\}"
	
	gen xxdidr1213=post_rev*treatdid1213
	label var xxdidr1213 "Post Reversal $\times$ $\mathbbm{1}$\{Age$=12$\}"

*Controls + DiD time vars
global xvars "post post_rev urban head_schooling head_male head_age indig_head male hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4 adult_women adult_men i.depto#i.year"
*DiD time vars only
global xvars2 "post post_rev"

*Outcomes
global yvars "works"

*Sample between 2012 and 2019
keep if year>=2012 & year<=2019

*Table preamble
file open myff using "${tabledir}/a_tab_socdesirability.tex", write replace
file write myff " \begin{table}[!h]"
file write myff "\centering"
file write myff "\caption{\centering Examining Potential Social Desirability Bias} \label{tab:socdesirability}"
file write myff  " \begin{adjustbox}{center, max width=1.2\textwidth}\begin{threeparttable} "
file write myff " \centering \begin{tabular}{l*{3}{c}} \hline\hline"
file write myff  "  & Ages 12 vs. 13 & Excluding 2014  \\  "
file write myff  " & (Diff-in-Diff) & (Diff-in-Disc)  \\ "
file write myff  "  & (1) & (2) \\ \hline"
file close myff


********************************************************************************
* 							    Regressions
********************************************************************************

*Regressions - 12 v 13 DD
foreach y in $yvars{
preserve
rename 	xxdid1213 xxdd
rename  xxdidr1213 xxddr
reg `y' xxdd xxddr treatdid1213 $xvars , vce( cluster age_mo_year) 
eststo est3`y'
sum  `y' if e(sample)==1 & pre==1
estadd scalar Mean=r(mean)
restore
}

gen xxdd=.
label var xxdd "Post Law $\times$ $\mathbbm{1}$\{Treated\}"
gen xxddr=. 
label var xxddr "Post Reversal $\times$ $\mathbbm{1}$\{Treated\}"

* DDisc omitting 2014
rename xxw3 xx
rename xxrw3 xxr
label var xx "Post law $\times \mathbbm{1}$\{Age$< 14 $\}"
label var xxr "Post reversal $\times \mathbbm{1}$\{Age$< 14 $\}"

*Variables for regressions
global x1w "xx xxr treatw14 runningw14 treatxrunningw14 post post_rev"
global dem "urban head_schooling head_male head_age indig_head male hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4 adult_women adult_men eligible_gr i.depto#i.year"

*remove 2014
reg works $x1w $dem [aw=kernel_triw14_12] if sww14_12==1 & year!=2014, vce( cluster age_mo_year) 
eststo est10_14
**Mean (pre law)
sum works if pre==1 &  e(sample)==1
estadd scalar Mean=r(mean)

esttab using "${tabledir}/a_tab_socdesirability", tex frag  cells(b(star fmt(3)) se(par fmt(3))) stats(N Mean, labels(Obs. Mean) fmt(a3)) keep(xxdd xxddr xx xxr)  append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none)

eststo clear

****************************** Closing file ***********************************

file open myff using "${tabledir}/a_tab_socdesirability.tex", write append
file write myff "\hline \hline \\\end{tabular} \begin{tablenotes} "
file write myff "\item \begin{footnotesize} Notes: Age in months by year clustered standard errors in parentheses. Significance levels denoted by: *** p$<$0.01, ** p$<$0.05, * p$<$0.1. For Column 1, teh specification is a difference-in-difference with $Treated=1$ for 12 year-olds, and $=0$ for 13 year-olds. Controls: indicator for urban areas, household head characteristics (schooling, gender, age, and indigenous indicator), gender, number of children in the household in following age categories: 0-6, 7-9, 10-13, and 14-17, number of adult men and women, age-by-month and departamento-by-year fixed effects. The specification includes an indicator for $Treated$, an indicator equal to one after the law was established, and one equal to one after the law was reversed, and an interaction between $Treated$ and the two indicators post law and reversal. The sample includes 2012-2019.  For Column 2, the specification is a difference-in-discontinuity.  Controls: in grade for CCT, an indicator for urban, household head characteristics (schooling, gender, age, and indigenous indicator), gender, number of children in the household in following age categories: 0-6, 7-9, 10-13, and 14-17,  number of adult men and women, and departamento by year fixed effects. The running variable is the difference between age in months and the age cut-off a week before the survey date. We include linear splines of the running variable, an indicator for 2014 and after, and an indicator that is one for the children in the corresponding age group. The sample includes 2012-2013 and 2015-2019. \end{footnotesize}"
file write myff " \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}"
file close myff