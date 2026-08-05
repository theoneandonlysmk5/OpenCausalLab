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
   Difference in Disc gender heterogeneity results for likelihood of work
==================================================*/

clear all

*HH Survey
use "${relabeled_data}/HHsurvey.dta", clear

*Sample 2012-2017
keep if year>=2012 & year<=2019
	
*Write table header	
file open myff using "${tabledir}/het_gender.tex", write replace
file write myff "\begin{table}[h!]"
file write myff "\centering "
file write myff "\caption{\centering Heterogeneous Effects of the Law by Gender (Difference-in-Discontinuity)} \label{tab:gender} \begin{adjustbox}{center, max width=1\textwidth}"
file write myff  " \begin{threeparttable} "
file write myff " \begin{tabular}{l*{1}{c}}  \hline \hline \\ "
file write myff  "  & Works  \\ "
file write myff  "  & (1) \\ \hline   "
file close myff	

********************************* 14 years old *********************************
********************************* Driving time *********************************

eststo clear


*Distance heterogeneity measure
global heterogeneity "male"
local h "male"

gen postxmale=post*male
gen post_revxmale= post_rev*male
gen treatw14xmale=treatxrunningw14*male
gen xxwh3 = xxw3*male
gen xxrwh3 = xxrw3*male
global xw14 "postx`h' post_revx`h' treatw14 runningw14 treatxrunningw14 treatw14x`h' `h'  "

*Controls
global xvars "post post_rev urban head_schooling head_male head_age indig_head male hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4 adult_women adult_men eligible_gr i.depto#i.year"


*regressions
foreach h in $heterogeneity{
	preserve		

reg works xxw3 xxwh3 xxrw3 xxrwh3 ${xw14} $xvars [aw=kernel_triw14] , vce( cluster age_mo_year)
local observations=e(N)
local tpost = _b[xxwh3]/_se[xxwh3]
local pvaluepost=  2*ttail(e(df_r),abs(`tpost'))
local tpostrev = _b[xxrwh3]/_se[xxrwh3]
local pvaluepostrev=  2*ttail(e(df_r),abs(`tpostrev'))
local rsquared=e(r2)

sum works if e(sample)==1 & pre==1 
local mean =r(mean)

	*calculating coefficients for boys and girls
nlcom (girls: _b[xxwh3]+_b[xxw3]) (boys: _b[xxw3]), post
eststo est4`h'

reg works xxw3 xxwh3 xxrw3 xxrwh3 ${xw14} $xvars [aw=kernel_triw14] , vce( cluster age_mo_year)

nlcom (girls: _b[xxrwh3]+_b[xxrw3]) (boys: _b[xxrw3]), post
eststo est5`h'
estadd scalar Mean=`mean': est5`h'
estadd scalar pvalpost=`pvaluepost': est5`h'
estadd scalar pvalpostrev=`pvaluepostrev': est5`h'
estadd scalar obs= `observations': est5`h'

restore

	*labels
	gen girls =. 
	gen boys =.
	label var girls "Post $\times$ $\mathbbm{1}$\{Age$< 14$\} for Girls"
	label var boys "Post $\times$ $\mathbbm{1}$\{Age$< 14$\} for Boys"
	

esttab est4`h' using "${tabledir}/het_gender", tex frag  cells(b(star fmt(3)) se(par fmt(3))) noobs append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none) nolines  

label var girls "Post reversal $\times$ $\mathbbm{1}$\{Age$< 14$\} for Girls"
label var boys "Post reversal $\times$ $\mathbbm{1}$\{Age$< 14$\} for Boys"
	

esttab est5`h' using "${tabledir}/het_gender", tex frag  cells(b(star fmt(3)) se(par fmt(3))) stats(obs Mean pvalpost pvalpostrev, labels(Obs. Mean "P-value of diff. by Gender in Post" "P-value of diff. by Gender in Post Reversal") fmt(a3))  append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none) nolines prefoot(\hline)

drop girls boys
}

file open myff using "${tabledir}/het_gender.tex", write append
file write myff "\hline \hline \end{tabular} \begin{tablenotes} "
file write myff "\item \begin{scriptsize} \begin{singlespace} Notes: Age in months by year clustered standard errors in parentheses. Significance levels denoted by: *** p$<$0.01, ** p$<$0.05, * p$<$0.1. Control variables: CCT eligibility indicator, urban, HH head characteristics (schooling, gender, age,  indigenous indicator), gender, no. of children aged 0-6, 7-9, 10-13, and 14-17, no. of adult men and women, and departamento by year FE.  We also include linear splines of the running variable (difference between the cutoff age and age a week before the survey date in months).  We use a bandwidth of 12 months and a triangular kernel. Survey years: 2012-2019.  We also report the mean of the dependent variable for the pre-law period. \end{singlespace} \end{scriptsize}"
file write myff " \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}"
file close myff






