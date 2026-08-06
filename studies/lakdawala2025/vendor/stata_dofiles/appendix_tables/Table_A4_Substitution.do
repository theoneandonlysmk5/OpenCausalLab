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

* 							Substitution Checks
*_______________________________________________________________________________

clear all

*HH Survey
use "${relabeled_data}/HHsurvey.dta", clear

*Sample between 2012 and 2019
keep if year>=2012 & year<=2019

*****Age DD

*Covariates
global dem "urban head_schooling head_male head_age indig_head male hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4 adult_women adult_men "

*Departamento-year ID for reghdfe
egen depyr = group(depto year)


*14 yo vs 15 yo and *14 yo vs 17 yo
gen under15 = (age_dob_m<180)
gen u15post = under15*post
gen u15rev = under15*post_rev
global xdid15 "u15post u15rev"
label var u15post  "Post Law $\times$ $\mathbbm{1}$\{Age$< 15$\}"
label var u15rev  "Post Reversal $\times$  $\mathbbm{1}$\{Age$< 15$\}"

*14-16 yo vs 17-18 yo
gen under17 = (age_dob_m<204)
gen u17post = under17*post
gen u17rev = under17*post_rev
global xdid17 "u17post u17rev"
label var u17post  "Post Law $\times$ $\mathbbm{1}$\{Age$< 17$\}"
label var u17rev  "Post Reversal $\times$  $\mathbbm{1}$\{Age$< 17$\}"

*Continuous age interaction
gen agepost = age_dob_m*post
gen agerev = age_dob_m*post_rev
global xdidage "agepost agerev"
label var agepost  "Post Law $\times$ Age"
label var agerev  "Post Reversal $\times$ Age"



*Regressions

*14 v 15
reghdfe works $xdid15 $dem if (age_dob_m>=168 & age_dob_m<192 &age_dob_m~=.), absorb(depyr age_dob_m) vce(cluster age_mo_year)
eststo est_1415
sum works if e(sample)==1 & pre==1
estadd scalar Mean=r(mean)
	
*14-16 v 17-18
reghdfe works $xdid17 $dem if (age_dob_m>=168 & age_dob_m<216 & age_dob_m~=.), absorb(depyr age_dob_m) vce(cluster age_mo_year)
eststo est_1418
sum works if e(sample)==1 & pre==1
estadd scalar Mean=r(mean)

*Continuous age interaction
reghdfe works $xdidage $dem if (age_dob_m>=168 & age_dob_m<216 & age_dob_m~=.), absorb(depyr age_dob_m) vce(cluster age_mo_year)
eststo est_cont
sum works if e(sample)==1 & pre==1
estadd scalar Mean=r(mean)




*****Distance DD

*Sample between 2012 and 2016 (for which we have munic. codes)
keep if year>=2012 & year<=2016

*Age groups
gen g13=(age_dob_m<=167 & age_dob_m>=156)
gen g14=(age_dob_m<=179 & age_dob_m>=168)

gen kernel_triw14_bw24 = ((24 - abs(runningw14)) /24) * (abs(runningw14) <= 24)


*DiD vars
gen near=het_time
recode near 1=0 0=1
gen xxdistw=near*post
label var xxdistw "Post $\times$ Near MTEPS"

*Add in baseline child labor rates (district level in 2012)
merge m:1 cod_secc using "${other_raw}/baselineCL.dta"
drop if _merge==2
drop _merge

gen postbase = post*works717_centered 

gen urbanXpost=urban*post
gen nearXurban = urban*near


reghdfe works xxdistw $dem postbase urbanXpost nearXurban if g14==1, a(cod_secc depyr age_dob_m) cluster(cod_secc) 
eststo estdist14
sum  works if e(sample)==1 & pre==1 & near==1
estadd scalar Mean=r(mean)



********************************************************************************
* 							    Table
********************************************************************************

*Table preamble
file open myff using "${tabledir}/a_tab_substitution.tex", write replace
file write myff " \begin{table}[!h]"
file write myff "\centering"
file write myff "\caption{\centering Examining Potential Substitution to Older Children} \label{tab:substitution}"
file write myff  " \begin{adjustbox}{center, max width=0.9\textwidth}\begin{threeparttable} "
file write myff " \centering \begin{tabular}{l*{5}{c}} \hline\hline"
file write myff  "  & Ages 14 & Ages 14-16 vs.  & Continuous Age & Distance DD  \\  "
file write myff  " & vs. 15   & 17-18 & Interaction  & (Age 14 Only)\\ "
file write myff  "  & (1) & (2) & (3) & (4)   \\ \hline"
file close myff



esttab est_1415 est_1418 est_cont estdist14 using "${tabledir}/a_tab_substitution", tex frag  cells(b(star fmt(3)) se(par fmt(3))) stats(N Mean, labels(Obs. Mean) fmt(a3)) keep(u15post u15rev u17post u17rev agepost agerev xxdistw)  append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none)

eststo clear

****************************** Closing file ***********************************

file open myff using "${tabledir}/a_tab_substitution.tex", write append
file write myff "\hline \hline \\\end{tabular} \begin{tablenotes} "
file write myff "\item \begin{footnotesize} Notes:  Significance levels denoted by: *** p$<$0.01, ** p$<$0.05, * p$<$0.1. For Columns 1-3, the specification is a difference in difference with Treated as a dummy variable for being below the indicated age. Post Law is a dummy for the law implementation period (2014-2017) and Post Reversal is a dummy for the reversal period (2018-2019).  Controls: indicator for urban areas, household head characteristics (schooling, gender, age, and indigenous indicator), gender, number of children in the household in following age categories: 0-6, 7-9, 10-13, and 14-17, number of adult men and women, age-by-month and departamento-by-year fixed effects.  Standard errors are clustered by age-year.  The sample inlcudes 2012-2019. For Column 4, the specification is a difference in difference with Treated as a dummy variable for being near (closer than the median) to an MTEPS office. The definitions for Post Law and the controls remain the same as in Columns 1-3.  Additional controls: Post Law interacted with urban and with baseline municipality child labor rates, urban interacted with Treated.  Standard errors are clustered by municipality.  The sample inlcudes 2012-2016. \end{footnotesize}"
file write myff " \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}"
file close myff