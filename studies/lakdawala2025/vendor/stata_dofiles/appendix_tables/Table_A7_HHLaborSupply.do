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

*								Household outcomes
*_______________________________________________________________________________

clear all

*Write table header	
file open myff using "${tabledir}/a_tab_hh_outcomes.tex", write replace
file write myff "\begin{table}[!h]"
file write myff "\centering"
file write myff "\caption{Effects on Household Labor Supply at the 14-year-old Cut-off} \label{tab:household} \begin{adjustbox}{center, max width=0.9\textwidth}"
file write myff "\begin{threeparttable}"
file write myff " \centering   \begin{tabular}{l*{5}{c}} \hline \hline"
file write myff  "  & Any Adult in HH & Total Hours   & Any Older Sibling & Total Hours    \\"
file write myff  "  & Works & Worked by Adults  &  Works & Worked by Older Siblings  \\"
file write myff  "  & (1) & (2) & (3) & (4)   \\ \hline"
file close myff	

*_______________________________________________________________________________

* 							Adult Outcomes
*_______________________________________________________________________________

*HH survey
use "${relabeled_data}/HHsurvey_ad.dta", clear

*Sample 2012-2019
keep if year>=2012 & year<=2019

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
collapse (mean) age_child_13to15 works head_works ypc_w urban head_schooling head_male head_age indig_head hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4 adult_women adult_men depto ccteligible (sum) hours_week_a, by(folio year)

*Any adult in HH works
gen a_work=works>0
rename hours_week_a a_hrs

*Controls
global xvars "post post_rev urban head_schooling head_male head_age indig_head hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4 adult_women adult_men  i.depto#i.year"

*Outcomes
global yvars "a_work a_hrs  "

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





*_______________________________________________________________________________

*									Siblings
*_______________________________________________________________________________



use "${relabeled_data}/HHsurvey.dta", clear

*Sample after 2012
keep if year>=2012 & year<=2019

*children between 13 and 15
gen bw13to15=(age_dob_m>=156 & age_dob_m<180)

*Age in months of children 13 to 15
gen auxage=bw13to15*age_dob_m
* age of the oldest sibling aged 13-15
bys folio year: egen age_child_13to15=max(auxage)
drop auxage

*HH with a single 13 to 15 year old in hh
bys folio year: egen child_bw13to15=total(bw13to15) 
replace child_bw13to15=. if child_bw13to15>1

*This child is eligible for cct
gen childelig=bw13to15*eligible_gr
replace childelig=. if childelig==0
replace childelig=. if child_bw13to15==.

bys folio year: egen ccteligible=min(childelig) 
replace ccteligible=0 if ccteligible==.

** Keeping only households with children within the age bandwidth (13-15)
keep if child_bw13to15==1

*keep only older children
keep if (age_dob_m>=15*12 & age_dob_m<18*12)


collapse (mean) age_child_13to15 works head_works urban head_schooling head_male head_age indig_head hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4 adult_women adult_men depto ccteligible post post_rev hours_week_a, by(folio year)

gen s_work=works>0
replace s_work=. if works==.

rename hours_week_a s_hrs

*Controls
global xvars "post post_rev urban head_schooling head_male head_age indig_head hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4 adult_women adult_men  ccteligible i.depto#i.year"

*Outcomes
global yvars "s_work s_hrs  "

foreach n in 3  {
local c=`n'*2+8

*create running variable
gen runningsw`c'=(age_child_13to15-0.25)-(`c'*12)

*bandwidth
local bw=12

*sample to estimate 
gen ssww`c'=(abs(runningsw`c') < `bw')

*treatment variable
gen treatsw`c' = runningsw`c' < 0
replace treatsw`c'=. if runningsw`c'==.
label var treatsw`c' "Below cutoff"


*interactions b/w treatment and running var
gen treatxrunningsw`c' = treatsw`c'*runningsw`c'

*Kernel weights
gen kernel_trisw`c' = ((`bw' - abs(runningsw`c')) /`bw') * (abs(runningsw`c') < `bw')

global xw`c' "xx`c' xxr`c' treatsw`c' runningsw`c' treatxrunningsw`c'"


*post times treat
gen xxs`c'=post*treatsw`c'
gen xxrs`c'=post_rev*treatsw`c'

label var xxs`c' "Post law $\times$ Below `c'"
label var xxrs`c' "Post reversal $\times$ Below `c'"

}


*Regression	(reporting only post times treat coefficient)
preserve
rename xxs14 xx14
rename xxrs14 xxr14
foreach y in $yvars{		
reg `y' ${xw14} $xvars [aw=kernel_trisw14] , vce( cluster folio)
eststo est_`y'
sum `y' if e(sample)==1 & treatsw14==0
estadd scalar Mean=r(mean)
}
restore

gen xx14=.
label var xx14 "Post law $\times \mathbbm{1}$\{Child Age$<14 $\}"
gen xxr14=.
label var xxr14 "Post reversal $\times \mathbbm{1}$\{Child Age$<14 $\}"


esttab est_a_work est_a_hrs est_s_work est_s_hrs  using "${tabledir}/a_tab_hh_outcomes", tex frag  cells(b(star fmt(3)) se(par fmt(3))) stats(N Mean, labels(Obs. Mean) fmt(a3)) keep(xx14 xxr14)  append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none)


***************************** Closing file ***********************************

file open myff using "${tabledir}/a_tab_hh_outcomes.tex", write append
file write myff "\hline \hline \\\end{tabular} \begin{tablenotes} "
file write myff "\item \begin{footnotesize} Notes: Age in months by year clustered standard errors in parentheses. Significance levels denoted by: *** p$<$0.01, ** p$<$0.05, * p$<$0.1. The control variables are: an indicator that is one if child in HH is in grade for CCT, an indicator for urban, household head characteristics (schooling, gender, age, and indigenous indicator), number of children in the household in following age categories: 0-6, 7-9, 10-13, and 14-17,  number of adult men and women, and departamento by year fixed effects. The income per capita variable in Column 3 is winsorized at the 99th percentile. The running variable is the difference between age in months of the child in the household and the age cut-off a week before the survey date. Hence, we only include households that have only a single child in the corresponding age range. The specification includes linear splines of the running variable, an indicator that is one between 2014 and 2018, an indicator equal to one in 2018 and after, and interaction between the running variable and the indicator for 2014 and after, and an indicator that is one for the children in the corresponding age group. The bandwidth is 12 months. We use a triangular kernel. The sample includes 2012-2019. \end{footnotesize}"
file write myff " \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}"
file close myff


