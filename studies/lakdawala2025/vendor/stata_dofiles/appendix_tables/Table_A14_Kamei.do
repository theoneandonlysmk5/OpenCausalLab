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

* 						Replicating Kamei 2021
*_______________________________________________________________________________

clear all

*HH Survey
use "${relabeled_data}/HHsurvey.dta", clear

*Sample between 2012 and 2014
keep if year>=2012 & year<=2019
gen kyears = (year>=2012 & year<=2014& year~=.)

*Sample: ages 7-16
keep if age>=7 & age<=16 & age~=.

*Kamei's DD variables
gen age1011 = (age>=10 & age<=11)
gen age1213 = (age>=12 & age<=13)
gen post1011 = age1011*post
gen post1213 = age1213*post
global ddvars post1011 post1213
label var post1011 "Post-Law $\times \mathbbm{1}$\{Age 10-11\}"
label var post1213 "Post-Law $\times \mathbbm{1}$\{Age 12-13\}"

gen age13 = (age==13)
gen post13 = age13*post
label var post13 "Post-Law $\times \mathbbm{1}$\{Age=13\}"

*Kamei's Controls
global xvars i.year i.depto i.hhsize i.urban i.head_schooling i.age

*Kamei's specs
reg wrk_foremployer_a $ddvars $xvars if male==1 & kyears==1
reg wrk_foremployer_a $ddvars $xvars if male==0 & kyears==1

reg wrk_family_a $ddvars $xvars if male==1 & kyears==1
reg wrk_family_a $ddvars $xvars if male==0 & kyears==1

*Kamei's specs without younger controls (i.e., 12 and 13 v. 14-16 only)
reg wrk_family_a $ddvars $xvars if male==1 & age>=12 & kyears==1
reg wrk_family_a $ddvars $xvars if male==0 & age>=12 & kyears==1

*Kamei's specs with narrow age band (i.e., 13 v. 14 only)
reg wrk_family_a $ddvars $xvars if male==1 & age>=13 & age<=14 & kyears==1
reg wrk_family_a $ddvars $xvars if male==0 & age>=13 & age<=14 & kyears==1

reg wrk_family_a $ddvars $xvars if age>=13 & age<=14 & kyears==1





*Table preamble
file open myff using "${tabledir}/a_tab_kamei.tex", write replace
file write myff " \begin{table}[!h]"
file write myff "\centering"
file write myff "\caption{\centering Reconciling Results with Kamei (2021)} \label{tab:kamei}"
file write myff  " \begin{adjustbox}{center, max width=1.2\textwidth}\begin{threeparttable} "
file write myff " \centering \begin{tabular}{l*{6}{c}} \hline\hline"
file write myff  "  & \multicolumn{5}{c}{Dep. Var.: Work for Family}  \\ \cline{2-6}  "
file write myff  "  & \multicolumn{2}{c}{Kamei (2021)} &  \multicolumn{3}{c}{Narrow Age Comparison}  \\  "
file write myff  "  & \multicolumn{2}{c}{Ages 7-16} &  \multicolumn{3}{c}{Ages 13-14} \\  \cline{2-6} "
file write myff  " & Boys &  Girls & Boys &  Girls & All Children \\ "
file write myff  "   & (1) & (2) & (3) & (4) & (5)  \\ \hline"
file close myff


********************************************************************************
* 							    Regressions
********************************************************************************


reg wrk_family_a $ddvars $xvars if male==1 & kyears==1
eststo est1 

reg wrk_family_a $ddvars $xvars if male==0 & kyears==1
eststo est2

reg wrk_family_a post13 $xvars if male==1 & age>=13 & age<=14 & kyears==1
eststo est3

reg wrk_family_a post13 $xvars if male==0 & age>=13 & age<=14 & kyears==1
eststo est4

reg wrk_family_a post13 $xvars if age>=13 & age<=14 & kyears==1
eststo est5


esttab using "${tabledir}/a_tab_kamei", tex frag  cells(b(star fmt(3)) se(par fmt(3))) stats(N , labels(Obs. ) fmt(a3)) keep(post1011 post1213 post13)  append label nomtitles nodepvar nonumbers star(* 0.10 ** 0.05 *** 0.01) collabels(none)

eststo clear

****************************** Closing file ***********************************

file open myff using "${tabledir}/a_tab_kamei.tex", write append
file write myff "\hline \hline \\\end{tabular} \begin{tablenotes} "
file write myff "\item \begin{footnotesize} Notes: Significance levels denoted by: *** p$<$0.01, ** p$<$0.05, * p$<$0.1. For all columns, the specification is a difference in difference regression with dummy variables for each age group interacted with a post-law dummy.  Additional controls include fixed effects for year, departamento, household size, household head's years of schooling, urban status, and age in years.  Sample years are 2012-2014. Columns 1-2, the sample includes all children age 7-16 (separately by gender).  For Columns 3-5, the sample includes only children age 13-14. \end{footnotesize}"
file write myff " \end{tablenotes} \end{threeparttable} \end{adjustbox} \end{table}"
file close myff