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

* 		Difference in Disc heterogeneity (driving distance) results for allowed work
*_______________________________________________________________________________

*HH Survey
use "${relabeled_data}/HHsurvey.dta", clear

*Outcomes
global yvar "works"

*Distance heterogeneity measure
global heterogeneity "het_time"

*Sample 2012-2017
keep if year>=2012 & year<=2017

*Diff in disc heterogeneity vars
foreach c in 10 12  {
global xw`c' "postxhet_dist treatw`c' runningw`c' treatxrunningw`c' treatw`c'xhet_dist   "
global xwplus`c' "postxhet_dist postxurbanxhet_dist treatw`c' runningw`c' treatxrunningw`c' postxurban  treatw`c'xurban  treatw`c'xhet_dist treatw`c'xurbanxhet_dist "

}

*Write tabl header	
file open myff using "${tabledir}/a_tab_work_drivingtime_1012cutoff.tex", write replace
file write myff "\begin{table}[h!]"
file write myff "\centering "
file write myff "\caption{\centering Heterogeneous Effects of the Law by Driving Time from MTEPS Offices (Difference-in-Discontinuity)} \label{tab:driving_time_1012} \begin{adjustbox}{center, max width=1\textwidth}"
file write myff  " \begin{threeparttable} "
file write myff " \begin{tabular}{l*{3}{c}}"
file write myff " \multicolumn{3}{c}{Panel A: 12-Year-Old Cutoff} \\ \hline \hline"
file write myff  "  & \multicolumn{2}{c}{Dependent Variable: Works}  \\ \cline{2-3} "
file write myff  "  & All & No MTEPS Offices  \\ "
file write myff  "  & (1) & (2) \\ \hline"
file close myff	



********************************* 12 years old *********************************

eststo clear

*Controls
global xvars " post urban head_schooling head_male head_age indig_head male hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4 adult_women adult_men  i.depto#i.year"

*regressions
foreach h in $heterogeneity{
	preserve		

	rename xxw`h'2 xxwh2  
	global indep "xxwh2 xxw2 `h' " 
	global indep_u "xxwh2 xxwu2 xxw2 `h' " 

	*All municipalities
reg $yvar $indep_u ${xwplus12} $xvars [aw=kernel_triw12], vce( cluster age_mo_year)
test xxwh2
local pvalue2 = r(p)

reg $yvar $indep ${xw12} $xvars [aw=kernel_triw12] , vce( cluster age_mo_year)
local observations=e(N)
local t = _b[xxwh2]/_se[xxwh2]
local pvalue=  2*ttail(e(df_r),abs(`t'))
local rsquared=e(r2)

sum $yvar if e(sample)==1 & pre==1 
local mean =r(mean)

nlcom (far: _b[xxwh2]+_b[xxw2]) (near: _b[xxw2]), post
eststo est4`h'
estadd scalar Mean=`mean': est4`h' 
estadd scalar pval=`pvalue': est4`h' 
estadd scalar obs= `observations': est4`h' 
estadd scalar pval2=`pvalue2': est4`h'

	*Municipalities without MTEPS offices
reg $yvar $indep_u ${xwplus12} $xvars [aw=kernel_triw12] if mtepsoffices==0, vce( cluster age_mo_year)
test xxwh2
local pvalue2 = r(p)

reg $yvar $indep ${xw12} $xvars [aw=kernel_triw12] if mtepsoffices==0, vce( cluster age_mo_year)
local observations=e(N)
local t = _b[xxwh2]/_se[xxwh2]
local pvalue=  2*ttail(e(df_r),abs(`t'))

sum $yvar if e(sample)==1 & pre==1 
local mean =r(mean)

nlcom (far: _b[xxwh2]+_b[xxw2]) (near: _b[xxw2]), post
eststo est6`h'
estadd scalar Mean=`mean': est6`h'
estadd scalar pval=`pvalue': est6`h'
estadd scalar obs= `observations': est6`h'
estadd scalar pval2=`pvalue2': est6`h'


restore

*labels
	gen far =. 
	gen near=.
	label var far "Post $\times$ $\mathbbm{1}$\{Age$\geq 12$\} for Far"
	label var near "Post $\times$ $\mathbbm{1}$\{Age$\geq 12$\} for Near"
	
esttab  est4`h' est6`h' using "${tabledir}/a_tab_work_drivingtime_1012cutoff", tex frag  cells(b(star fmt(3)) se(par fmt(3))) stats(obs Mean pval pval2, labels(Obs. Mean "P-value of difference" "P-value of difference (urban controls)") fmt(a3))  append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none)

file open myff using "${tabledir}/a_tab_work_drivingtime_1012cutoff.tex", write append
file write myff "\hline \hline "
file close myff

drop near far
}
********************************* 10 years old *********************************

eststo clear

*Controls
global xvars " post urban head_schooling head_male head_age indig_head male hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4 adult_women adult_men i.depto#i.year"

file open myff using "${tabledir}/a_tab_work_drivingtime_1012cutoff.tex", write append
file write myff "  & & \\ "
 file write myff " \multicolumn{3}{c}{Panel B: 10-Year-Old Cutoff} \\ \hline "
file write myff  "  & \multicolumn{2}{c}{Dependent Variable: Works}  \\ \cline{2-3} "
file write myff  "  & All & No MTEPS Offices \\ "
file write myff  "  & (1) & (2)  \\ \hline"
file close myff	

* regressions
foreach h in $heterogeneity{
	preserve		

	rename xxw`h'1 xxwh1  
	global indep "xxwh1 xxw1 `h'"
	global indep_u "xxwh1 xxwu1 xxw1 `h'"

	*All municipalities
reg $yvar $indep_u ${xwplus10} $xvars [aw=kernel_triw10], vce( cluster age_mo_year)
test xxwh1
local pvalue2 = r(p)

reg $yvar $indep ${xw10} $xvars [aw=kernel_triw10] , vce( cluster age_mo_year)
local observations=e(N)
local t = _b[xxwh1]/_se[xxwh1]
local pvalue=  2*ttail(e(df_r),abs(`t'))

sum $yvar if e(sample)==1 & pre==1 
local mean =r(mean)

nlcom (far: _b[xxwh1]+_b[xxw1]) (near: _b[xxw1]), post
eststo est4`h'
estadd scalar Mean=`mean': est4`h'
estadd scalar pval=`pvalue': est4`h'
estadd scalar obs= `observations': est4`h'
estadd scalar pval2=`pvalue2': est4`h'

	*Municipalities without MTEPS offices
reg $yvar $indep_u ${xwplus10} $xvars [aw=kernel_triw10] if mtepsoffices==0, vce( cluster age_mo_year)
test xxwh1
local pvalue2 = r(p)

reg $yvar $indep ${xw10} $xvars [aw=kernel_triw10] if mtepsoffices==0, vce( cluster age_mo_year)
local observations=e(N)
local t = _b[xxwh1]/_se[xxwh1]
local pvalue=  2*ttail(e(df_r),abs(`t'))

sum $yvar if e(sample)==1 & treatw10==0 
local mean =r(mean)

nlcom (far: _b[xxwh1]+_b[xxw1]) (near: _b[xxw1]), post
eststo est6`h'
estadd scalar Mean=`mean': est6`h'
estadd scalar pval=`pvalue': est6`h'
estadd scalar obs= `observations': est6`h'
estadd scalar pval2=`pvalue2': est6`h'

restore

*labels
	gen far =. 
	gen near=.
	label var far "Post $\times$ $\mathbbm{1}$\{Age$\geq 10$\} for Far"
	label var near "Post $\times$ $\mathbbm{1}$\{Age$\geq 10$\} for Near"
	
esttab est4`h' est6`h' using "${tabledir}/a_tab_work_drivingtime_1012cutoff", tex frag  cells(b(star fmt(3)) se(par fmt(3))) stats(obs Mean pval pval2, labels(Obs. Mean "P-value of difference" "P-value of difference (urban controls)") fmt(a3))  append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none)

drop near far
}


****************************** Closing file ***********************************
file open myff using "${tabledir}/a_tab_work_drivingtime_1012cutoff.tex", write append
file write myff "\hline \hline \end{tabular} \begin{tablenotes} "
file write myff "\item \begin{scriptsize} Notes: Age in months by year clustered standard errors in parentheses. Significance levels denoted by: *** p$<$0.01, ** p$<$0.05, * p$<$0.1. Municipalities that are classified as Far are above the median distance from a MTEPS office. Control variables: CCT eligibility indicator, urban, HH head characteristics (schooling, gender, age,  indigenous indicator), gender, no. of children aged 0-6, 7-9, 10-13, and 14-17, no. of adult men and women, and departamento by year FE.  We also include linear splines of the running variable (difference between the cutoff age and age a week before the survey date in months). The specification for the p-value with urban controls additionally includes: post $\times$ urban, treatment $\times$ urban, post $\times$ distance $\times$ urban, and treatment $\times$ distance $\times$ urban. We use a bandwidth of 12 months and a triangular kernel. Survey years: 2012-2016.  We also report the mean of the dependent variable for the control group.  \end{scriptsize}"
file write myff " \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}"
file close myff





