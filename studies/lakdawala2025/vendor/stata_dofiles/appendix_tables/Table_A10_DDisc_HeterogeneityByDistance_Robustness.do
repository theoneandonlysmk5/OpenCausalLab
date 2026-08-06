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

* 		Difference in Disc heterogeneity results for likelihood of work
*_______________________________________________________________________________

clear all

*HH Survey
use "${relabeled_data}/HHsurvey.dta", clear


*Sample 2012-2017
keep if year>=2012 & year<=2017

*Add in baseline child labor rates (district level in 2012)
merge m:1 cod_secc using "${other_raw}/baselineCL.dta"
drop if _merge==2
drop _merge

gen postbase = post*works717_centered 
gen treatw14base = treatw14*works717_centered 
gen xxbase = treatw14*works717_centered*post 

egen urbanmean = mean(urban) 
gen urban_centered = urban-urbanmean

gen posturban = post*urban_centered 
gen treatw14urban = treatw14*urban_centered 
gen xxurban = post*treatw14*urban_centered


*Distance heterogeneity measure
global heterogeneity "het_time"
local h "het_time"

foreach h in $heterogeneity{

	rename xxw`h'3 xxwh3  
	global indep "xxwh3 xxw3 `h'"

	*Recall: a week before the date of survey
	global xw14 "postx`h' treatw14 runningw14 treatxrunningw14 treatw14x`h'   "
	global xwplus14 "postx`h' treatw14 runningw14 treatxrunningw14 treatw14x`h' posturban treatw14urban xxurban "
	global xwplus14b "postx`h' treatw14 runningw14 treatxrunningw14 treatw14x`h' postbase treatw14base xxbase"

}

*Controls
global xvars " post urban head_schooling head_male head_age indig_head male hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4 adult_women adult_men  i.depto#i.year"
	
*Write table header	
file open myff using "${tabledir}/6_distance_work_appendix.tex", write replace
file write myff "\begin{table}[h!]"
file write myff "\centering "
file write myff "\caption{\centering Heterogeneous Effects by Distance from MTEPS Offices, Allowing for Heterogeneity by Urban and Baseline Child Labor Rates} \label{tab:het_robust} \begin{adjustbox}{center, max width=1\textwidth}"
file write myff  " \begin{threeparttable} "
file write myff " \begin{tabular}{l*{3}{c}}  \hline \hline \\ "
file write myff " \multicolumn{3}{c}{Panel A: Including Urban Heterogeneity} \\ \hline "
file write myff  "  & \multicolumn{2}{c}{Dependent Variable: Works}  \\ \cline{2-3} "
file write myff  "  & All & No MTEPS Offices  \\ "
file write myff  "  & (1) & (2) \\ \hline"
file close myff	

*************************** 14 years old, Driving Time *************************
********************* Allowing for Heterogeneity by Urban **********************

eststo clear

*Regressions: controlling for urban interactions

*All municipalities	
	
	reg works $indep ${xwplus14} $xvars [aw=kernel_triw14] , vce( cluster age_mo_year)
	local observations=e(N)
	local t = _b[xxwh3]/_se[xxwh3]
	local pvalue=  2*ttail(e(df_r),abs(`t'))
	local rsquared=e(r2)

	sum works if e(sample)==1 & pre==1 
	local mean =r(mean)

		*calculating coefficients for near and far
	nlcom (far: _b[xxwh3]+_b[xxw3]) (near: _b[xxw3]), post
	eststo est1`h'
	estadd scalar Mean=`mean': est1`h'
	estadd scalar pval=`pvalue': est1`h'
	estadd scalar obs= `observations': est1`h'


*Municipalities without MTEPS offices
	
	reg works $indep ${xwplus14} $xvars [aw=kernel_triw14] if mtepsoffices==0, vce( cluster age_mo_year)
	local observations=e(N)
	local t = _b[xxwh3]/_se[xxwh3]
	local pvalue=  2*ttail(e(df_r),abs(`t'))
	local rsquared=e(r2)

	sum works if e(sample)==1 & pre==1 
	local mean =r(mean)

		*calculating coefficients for near and far
	nlcom (far: _b[xxwh3]+_b[xxw3]) (near: _b[xxw3]), post
	eststo est2`h'
	estadd scalar Mean=`mean': est2`h'
	estadd scalar pval=`pvalue': est2`h'
	estadd scalar obs= `observations': est2`h'

	*labels
	gen far =. 
	gen near=.
	label var far "Post $\times$ $\mathbbm{1}$\{Age$< 14$\} for Far"
	label var near "Post $\times$ $\mathbbm{1}$\{Age$< 14$\} for Near"
	

esttab est1`h' est2`h' using "${tabledir}/6_distance_work_appendix", tex frag  cells(b(star fmt(3)) se(par fmt(3))) stats(obs Mean pval, labels(Obs. Mean "P-value of difference") fmt(a3))  append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none)

drop near far

file open myff using "${tabledir}/6_distance_work_appendix.tex", write append
file write myff "\hline \hline "
file close myff



******** Allowing for Heterogeneity by Baseline Child Labor Rates **************

eststo clear

file open myff using "${tabledir}/6_distance_work_appendix.tex", write append
file write myff " & & \\ "
file write myff " \multicolumn{3}{c}{Panel B: Allowing for Heterogeneity } \\ "
file write myff " \multicolumn{3}{c}{ by Baseline Child Labor Rates } \\ \hline "
file write myff  "  & \multicolumn{2}{c}{Dependent Variable: Works}  \\ \cline{2-3} "
file write myff  "  & All & No MTEPS Offices  \\ "
file write myff  "  & (1) & (2) \\ \hline"
file close myff	

**Regressions: controlling for baseline CL interactions

*All municipalities	

	reg works $indep ${xwplus14b} $xvars [aw=kernel_triw14] , vce( cluster age_mo_year)
	local observations=e(N)
	local t = _b[xxwh3]/_se[xxwh3]
	local pvalue=  2*ttail(e(df_r),abs(`t'))
	local rsquared=e(r2)

	sum works if e(sample)==1 & pre==1 
	local mean =r(mean)

		*calculating coefficients for near and far
	nlcom (far: _b[xxwh3]+_b[xxw3]) (near: _b[xxw3]), post
	eststo est1`h'
	estadd scalar Mean=`mean': est1`h'
	estadd scalar pval=`pvalue': est1`h'
	estadd scalar obs= `observations': est1`h'


*Municipalities without MTEPS offices
	
	reg works $indep ${xwplus14b} $xvars [aw=kernel_triw14] if mtepsoffices==0, vce( cluster age_mo_year)
	local observations=e(N)
	local t = _b[xxwh3]/_se[xxwh3]
	local pvalue=  2*ttail(e(df_r),abs(`t'))
	local rsquared=e(r2)

	sum works if e(sample)==1 & pre==1 
	local mean =r(mean)

		*calculating coefficients for near and far
	nlcom (far: _b[xxwh3]+_b[xxw3]) (near: _b[xxw3]), post
	eststo est2`h'
	estadd scalar Mean=`mean': est2`h'
	estadd scalar pval=`pvalue': est2`h'
	estadd scalar obs= `observations': est2`h'

	gen far =. 
	gen near=.
	label var far "Post $\times$ $\mathbbm{1}$\{Age$< 14$\} for Far"
	label var near "Post $\times$ $\mathbbm{1}$\{Age$< 14$\} for Near"
	

esttab est1`h' est2`h' using "${tabledir}/6_distance_work_appendix", tex frag  cells(b(star fmt(3)) se(par fmt(3))) stats(obs Mean pval, labels(Obs. Mean "P-value of difference") fmt(a3))  append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none)


drop near far


****************************** Closing file ***********************************
file open myff using "${tabledir}/6_distance_work_appendix.tex", write append
file write myff "\hline \hline \end{tabular} \begin{tablenotes} "
file write myff "\item \begin{scriptsize} \begin{singlespace} Notes: Age in months by year clustered standard errors in parentheses. Significance levels denoted by: *** p$<$0.01, ** p$<$0.05, * p$<$0.1. Municipalities that are classified as Far are above the median distance from a MTEPS office, where distance is calculated as the driving time from the municipality centroid to the nearest MTEPS office. Control variables: CCT eligibility indicator, urban, HH head characteristics (schooling, gender, age,  indigenous indicator), gender, no. of children aged 0-6, 7-9, 10-13, and 14-17, no. of adult men and women, and departamento by year FE.  We also include linear splines of the running variable (difference between the cutoff age and age a week before the survey date in months). The specification for Panel A additionally includes: post $\times$ urban, treatment $\times$ urban, post $\times$ distance $\times$ urban, and treatment $\times$ distance $\times$ urban, where urban is normalized to the sample mean. The specification for Panel B additionally includes: post $\times$ baseline CL rates, treatment $\times$ baseline CL rates, post $\times$ distance $\times$ baseline CL rates, and treatment $\times$ distance $\times$ baseline CL rates, where baseline CL rates are defined at the municipality level, are calculated using data from only 2012 (pre-law), and are normalized to the municipality mean. We use a bandwidth of 12 months and a triangular kernel. Survey years: 2012-2016.  We also report the mean of the dependent variable for the pre-law period. \end{singlespace} \end{scriptsize}"
file write myff " \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}"
file close myff


