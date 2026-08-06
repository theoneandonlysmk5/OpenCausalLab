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

* 		Difference in Disc results for expenditure outcomes
*_______________________________________________________________________________


clear all

*set root directory
*Cleaning - move to cleaning if we go with this
use "${relabeled_data}/Expenses/EH_cleaned_expenses.dta", clear

* this eliminates data on 2016 since there was not a module on expenditure in the survey
drop if folio==""
tempfile expenses
save `expenses', replace

*HH Survey
use "${relabeled_data}/HHsurvey.dta", clear
* We will get _merge==1 for the years in which expenses data is not available. (e.g., 2016)

* we will get _merge==2 for households who do not have family members under 21 years old (as HHsurvey only includes households with chilidren or members under 21)
merge m:1 folio year using `expenses'
drop if _merge==2
drop _merge

ihstrans expend_al expend_noal expend expend_dur_t, prefix (ihs_)

global yvars "ihs_expend ihs_expend_al ihs_expend_noal"
*ihs_expend_dur_t

*indicator for children between ages 13 and 15
gen bw13to15=(age_dob_m>=156 & age_dob_m<=180)

*Age in months of children 13 to 15 only
gen auxage=bw13to15*age_dob_m
*Get age of the oldest 13 to 15 y/o in the HH
bys folio year: egen age_child_13to15=max(auxage)
drop auxage

*indicator for HH with a single 13 to 15 year old in hh
bys folio year: egen child_bw13to15=total(bw13to15) 
replace child_bw13to15=. if child_bw13to15>1

*indicator for whether this child is eligible for cct
gen childelig=bw13to15*eligible_gr
replace childelig=. if childelig==0
replace childelig=. if child_bw13to15==.
bys folio year: egen ccteligible=min(childelig) 
replace ccteligible=0 if ccteligible==.

*Keep HHs with a child between the ages of 13 and 15
keep if child_bw13to15==1

*Data at the HH level
collapse (mean) age_child_13to15 urban head_schooling head_male head_age indig_head hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4 adult_women adult_men depto ccteligible $yvars, by(folio year)


*Controls
global xvars "post post_rev urban head_schooling head_male head_age indig_head hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4 adult_women adult_men  i.depto#i.year"


*Post dummy
gen post=(year>=2014 & year<2018)
gen post_rev=(year>=2018)
gen pre=year<2014

*create running variable with 13 to 15 y/o's age
gen runningw14=(age_child_13to15-0.25)-(14*12)

*cluster
egen age_mo_year=group(age_child_13to15 year)

*bandwidth
local bw=12

*sample to estimate 
gen sww14=(abs(runningw14) < `bw')

*treatment variable
gen treatw14 = runningw14 < 0
replace treatw14=. if runningw14==.

*interactions b/w treatment and running var
gen treatxrunningw14 = treatw14*runningw14

*Kernel weights
gen kernel_triw14 = ((`bw' - abs(runningw14)) /`bw') * (abs(runningw14) < `bw')

*post times treat
gen xx14=post*treatw14
gen xxr14=post_rev*treatw14

*DDisc variables
global xw14 "xx14 xxr14 treatw14 runningw14 treatxrunningw14"

*Regressions
foreach y in $yvars{		
reg `y' ${xw14} $xvars [aw=kernel_triw14], vce( cluster age_mo_year)
eststo est_`y'
sum `y' if e(sample)==1 & pre==1
estadd scalar Mean=r(mean)
}

*gen xx14=.
label var xx14 "Post law $\times \mathbbm{1}$\{Child Age$<14 $\}"
*gen xxr14=.
label var xxr14 "Post reversal $\times \mathbbm{1}$\{Child Age$<14 $\}"


	
*Write table header
file open myff using "${tabledir}/expenditure.tex", write replace
file write myff "\begin{table}[H]"
file write myff "\centering "
file write myff "\caption{Effects on Household Expenditure at the 14-Year-Old Cutoff} \label{tab:expediture} \begin{adjustbox}{center, max width=0.9\textwidth}"
file write myff "\begin{threeparttable}"
file write myff "\begin{tabular}{l*{4}{c}} \\ \hline \hline "
*file write myff " & \multicolumn{6}{c}{Panel A: Expenses in Levels}  \\ \cline{2-7}"
file write myff  "  &  Total & Food & Non-Food  \\  "
file write myff  " &  Expenditure (IHS) & Expenditure (IHS) & Expenditure (IHS)  \\ "
file write myff  "  & (1) & (2) & (3)   \\ \hline"
file close myff	

esttab using "${tabledir}/expenditure", tex frag  cells(b(star fmt(3)) se(par fmt(3))) stats(N Mean, labels(Obs. Mean) fmt(a3)) keep(xx14 xxr14) append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none)

*Closing file
file open myff using "${tabledir}/expenditure.tex", write append
file write myff "\hline \hline \\\end{tabular} \vspace{-0.5cm}  \begin{tablenotes} "
file write myff "\item \begin{footnotesize} Notes: Age in months by year clustered standard errors in parentheses. Significance levels denoted by: *** p$<$0.01, ** p$<$0.05, * p$<$0.1. Control variables: CCT eligibility indicator, household head characteristics (schooling, gender, age, and indigenous indicator), gender, number of children in the following age categories: 0-6, 7-9, 10-13, and 14-17, number of adult men and women, an urban dummy, and departamento by year fixed effects.  We also include linear splines of the running variable, defined as the difference between the cutoff age and age a week before the survey date in months. We use a bandwidth of 12 months and a triangular kernel. Survey years: 2012-2019, except 2016, for which expenditure data was not collected. \end{footnotesize}"
file write myff " \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}"
file close myff

