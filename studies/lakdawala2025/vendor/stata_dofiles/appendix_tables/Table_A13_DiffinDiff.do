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

*								Diff in Diff Work
*_______________________________________________________________________________

clear all

*HH Survey 
use "${relabeled_data}/HHsurvey.dta", clear

*Controls
global xvars "post post_rev urban head_schooling head_male head_age indig_head male hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4 adult_women adult_men i.age i.depto#i.year"

*Outcomes
global yvars "works "

*cluster
global cluster "age_mo_year"

*Sample 2012-2019
keep if year>=2012 & year<=2019

rename xxw3 xx
*xxw3 is post times treatment for the third age group (14 y/o cutoff) and one week before the survey recall

rename xxrw3 xxr
*xxrw3 is post reversal times treatment for the third age group (14 y/o cutoff) and one week before the survey recall

*Variables for regressions
global xdid "xx xxr treatw14 post post_rev"
  /*Notes on variables:
  - xx is post times treated, renamed for the labels in the table
  - xxr is post reversal times treated, renamed for the labels in the table
  - treatw14 is treatment for the third age group (14 y/o cutoff) and one week before the survey recall
  - post is post treatment
  - post_rev is post reversal
  */
global dem "urban head_schooling head_male head_age indig_head male hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4 adult_women adult_men eligible_gr i.depto#i.year"



********************************************************************************
* 							    Regressions
********************************************************************************


*Write table header	
file open myff using "${tabledir}/a_tab_DiDpooled_postandreversal_work.tex", write replace
file write myff " \begin{table}[H]"
file write myff "\centering"
file write myff "\caption{Difference in Difference Specification} \label{tab:DDpooled}"
file write myff  " \begin{adjustbox}{center, max width=1.2\textwidth}\begin{threeparttable} "
file write myff " \begin{tabular}{l*{4}{c}} \hline \hline"
file write myff  "  & \multicolumn{3}{c}{Dep. Var.: Any Work} \\ \cline{2-4} "
file write myff  "  & Control: 14-year-olds   \\ "
file write myff  "  & (1)  \\ \hline"
file close myff

eststo clear

*DiD
reg works $xdid $dem  if sww14==1, vce( cluster $cluster) 
eststo est1`y'
sum  works if e(sample)==1 & pre==1
estadd scalar Mean=r(mean)


esttab using "${tabledir}/a_tab_DiDpooled_postandreversal_work", tex frag  cells(b(star fmt(3)) se(par fmt(3))) stats(N Mean, labels(Obs. Mean) fmt(a3)) keep(xx*)  append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none)

*Closing file
file open myff using "${tabledir}/a_tab_DiDpooled_postandreversal_work.tex", write append
file write myff "\hline \hline \\\end{tabular} \begin{tablenotes} "
file write myff "\begin{footnotesize} Notes: Age in months by year clustered standard errors in parentheses. Significance levels denoted by: *** p$<$0.01, ** p$<$0.05, * p$<$0.1. The control variables are: in grade for CCT (only for 14-year-old cut-off), an indicator for urban areas, household head characteristics (schooling, gender, age, and indigenous indicator), gender, number of children in the household in following age categories: 0-6, 7-9, 10-13, and 14-17,  number of adult men and women, and departamento by year fixed effects. The specification includes an indicator for the corresponding age group, an indicator equal to one after the law was established and before it was reversed, an indicator equal to one after the law was reversed, and interactions between the time and the age group indicators. The sample includes 2012-2019. \end{footnotesize}"
file write myff " \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}"
file close myff
	
