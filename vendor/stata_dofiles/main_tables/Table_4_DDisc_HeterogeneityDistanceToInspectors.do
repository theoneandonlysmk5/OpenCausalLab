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
     Difference in Disc heterogeneity results for likelihood of work
==================================================*/

clear all

use "${relabeled_data}/HHsurvey.dta", clear


*Sample 2012-2017
keep if year>=2012 & year<=2016

	
*Write table header	
file open myff using "${tabledir}/6_distance_work.tex", write replace
file write myff "\begin{table}[h!]"
file write myff "\centering "
file write myff "\caption{\centering Heterogeneous Effects of the Law by Distance from MTEPS Offices (Difference-in-Discontinuity)} \label{tab:driving_distance} \begin{adjustbox}{center, max width=1\textwidth}"
file write myff  " \begin{threeparttable} "
file write myff " \begin{tabular}{l*{3}{c}}  \hline \hline \\ "
file write myff " \multicolumn{3}{c}{Panel A: Driving Time} \\ \hline "
file write myff  "  & \multicolumn{2}{c}{Dependent Variable: Works}  \\ \cline{2-3} "
file write myff  "  & All & No MTEPS Offices  \\ "
file write myff  "  & (1) & (2) \\ \hline"
file close myff	

********************************* 14 years old *********************************
********************************* Driving time *********************************

eststo clear


*Distance heterogeneity measure
global heterogeneity "het_time"
local h "het_time"


*Recall: a week before the date of survey
global xw14 "postx`h' treatw14 runningw14 treatxrunningw14 treatw14x`h'   "

*Controls
global xvars " post urban head_schooling head_male head_age indig_head male hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4 adult_women adult_men  i.depto#i.year"


*regressions
foreach h in $heterogeneity{
	preserve		

	rename xxw`h'3 xxwh3  
	global indep "xxwh3 xxw3 `h'"

reg works $indep ${xw14} $xvars [aw=kernel_triw14] , vce( cluster age_mo_year)
local observations=e(N)
local t = _b[xxwh3]/_se[xxwh3]
local pvalue=  2*ttail(e(df_r),abs(`t'))
local rsquared=e(r2)

sum works if e(sample)==1 & pre==1 
local mean =r(mean)

	*calculating coefficients for near and far
nlcom (far: _b[xxwh3]+_b[xxw3]) (near: _b[xxw3]), post
eststo est4`h'
estadd scalar Mean=`mean': est4`h'
estadd scalar pval=`pvalue': est4`h'
estadd scalar obs= `observations': est4`h'

reg works $indep ${xw14} $xvars [aw=kernel_triw14] if mtepsoffices==0, vce( cluster age_mo_year)
local observations=e(N)
local t = _b[xxwh3]/_se[xxwh3]
local pvalue=  2*ttail(e(df_r),abs(`t'))
local rsquared=e(r2)

sum works if e(sample)==1 & pre==1 
local mean =r(mean)

	*calculating coefficients for near and far
nlcom (far: _b[xxwh3]+_b[xxw3]) (near: _b[xxw3]), post
eststo est5`h'
estadd scalar Mean=`mean': est5`h'
estadd scalar pval=`pvalue': est5`h'
estadd scalar obs= `observations': est5`h'



restore

	*labels
	gen far =. 
	gen near=.
	label var far "Post $\times$ $\mathbbm{1}$\{Age$< 14$\} for Far"
	label var near "Post $\times$ $\mathbbm{1}$\{Age$< 14$\} for Near"
	

esttab est4`h' est5`h' using "${tabledir}/6_distance_work", tex frag  cells(b(star fmt(3)) se(par fmt(3))) stats(obs Mean pval, labels(Obs. Mean "P-value of difference") fmt(a3))  append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none)

drop near far
}

file open myff using "${tabledir}/6_distance_work.tex", write append
file write myff "\hline \hline "
file close myff












********************************* Straight line distance *********************************

*Distance heterogeneity measure
global heterogeneity "het_dist"
local h "het_dist"


*Recall: a week before the date of survey
global xw14 "postx`h' treatw14 runningw14 treatxrunningw14 treatw14x`h'   "
eststo clear

*Controls
global xvars " post urban head_schooling head_male head_age indig_head male hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4 adult_women adult_men eligible_gr i.depto#i.year"

file open myff using "${tabledir}/6_distance_work.tex", write append
file write myff " & & \\ "
file write myff " \multicolumn{3}{c}{Panel B: Direct Distance (\`\`as the crow flies'')} \\ \hline "
file write myff  "  & \multicolumn{2}{c}{Dependent Variable: Works}  \\ \cline{2-3} "
file write myff  "  & All & No MTEPS Offices  \\ "
file write myff  "  & (1) & (2) \\ \hline"
file close myff	

*regressions
foreach h in $heterogeneity{
	preserve		

	rename xxw`h'3 xxwh3  
	global indep "xxwh3 xxw3 `h'"


	
reg works $indep ${xw14} $xvars [aw=kernel_triw14] , vce( cluster age_mo_year)
local observations=e(N)
local t = _b[xxwh3]/_se[xxwh3]
local pvalue=  2*ttail(e(df_r),abs(`t'))
local rsquared=e(r2)

sum works if e(sample)==1 & pre==1 
local mean =r(mean)

	*calculating coefficients for near and far
nlcom (far: _b[xxwh3]+_b[xxw3]) (near: _b[xxw3]), post
eststo est4`h'
estadd scalar Mean=`mean': est4`h'
estadd scalar pval=`pvalue': est4`h'
estadd scalar obs= `observations': est4`h'


reg works $indep ${xw14} $xvars [aw=kernel_triw14] if mtepsoffices==0, vce( cluster age_mo_year)
local observations=e(N)
local t = _b[xxwh3]/_se[xxwh3]
local pvalue=  2*ttail(e(df_r),abs(`t'))
local rsquared=e(r2)

sum works if e(sample)==1 & pre==1 
local mean =r(mean)

nlcom (far: _b[xxwh3]+_b[xxw3]) (near: _b[xxw3]), post
eststo est5`h'
estadd scalar Mean=`mean': est5`h'
estadd scalar pval=`pvalue': est5`h'
estadd scalar obs= `observations': est5`h'

restore

	gen far =. 
	gen near=.
	label var far "Post $\times$ $\mathbbm{1}$\{Age$< 14$\} for Far"
	label var near "Post $\times$ $\mathbbm{1}$\{Age$< 14$\} for Near"
	

esttab est4`h' est5`h' using "${tabledir}/6_distance_work", tex frag  cells(b(star fmt(3)) se(par fmt(3))) stats(obs Mean pval, labels(Obs. Mean "P-value of difference") fmt(a3))  append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none)


drop near far
}

****************************** Closing file ***********************************
file open myff using "${tabledir}/6_distance_work.tex", write append
file write myff "\hline \hline \end{tabular} \begin{tablenotes} "
file write myff "\item \begin{scriptsize} \begin{singlespace} Notes: Age in months by year clustered standard errors in parentheses. Significance levels denoted by: *** p$<$0.01, ** p$<$0.05, * p$<$0.1. Municipalities that are classified as Far are above the median distance from a MTEPS office. Control variables: CCT eligibility indicator, urban, HH head characteristics (schooling, gender, age,  indigenous indicator), gender, no. of children aged 0-6, 7-9, 10-13, and 14-17, no. of adult men and women, and departamento by year FE.  We also include linear splines of the running variable (difference between the cutoff age and age a week before the survey date in months).  We use a bandwidth of 12 months and a triangular kernel. Survey years: 2012-2016.  We also report the mean of the dependent variable for the pre-law period. \end{singlespace} \end{scriptsize}"
file write myff " \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}"
file close myff





