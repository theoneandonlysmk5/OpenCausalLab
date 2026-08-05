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
clear all
/*==================================================
     Descriptive Statistics by Employer type
==================================================*/

********************************************************************************************************
*								HH Survey
********************************************************************************************************
use "${relabeled_data}/HHsurvey.dta", clear

*Outcomes; yvars0: report median, yvars1: report mean, yvars2: report mean and right justified
global yvars0 "number_workers_w"
global yvars1 "wage_hour_w  firm_taxes location_out_fixed_a location_out_mobile_a location_home_a "
global yvars2 "agriculture_a  sales_a other_occ"

*Sample pre-law and between ages 9 and 15
keep if year>=2012 & year<=2013
keep if age_dob_m>=108 & age_dob_m<=180

*Categories for p-value
gen wrk_type = 1 if wrk_family==1
replace wrk_type = 2 if wrk_foremployer==1

*labels
local lab1 "Firm size (median)"					
local lab2 "Hourly wage (Bolivianos)" 
local lab3 "Formal Firm"			
local lab4 "Works Outside of Home in Fixed Location"
local lab5 "Works Outside of Home in Mobile Location"
local lab6 "Works at Home"
local lab7 "\hspace{0.5cm} Agriculture"	
local lab8 "\hspace{0.5cm} Sales and retail"
local lab9 "\hspace{0.5cm} Other"
				


		*------------------------- Panel A ------------------------*

*Table header
file open myff using "${tabledir}/a_tab_desc_fam_nonfam.tex", write replace
file write myff "\begin{table}[H]"
file write myff " \centering"
file write myff "\caption{Descriptive Statistics by Employer Type \label{tab:famnonfam}} \resizebox{.85\textwidth}{!}{"
file write myff "\begin{threeparttable}"
file write myff " \centering \renewcommand{\TPTminimum}{\linewidth}\makebox[\linewidth]{\begin{tabular}{l*{4}{c}} "
file write myff "\multicolumn{4}{c}{Panel A: Household Data} \\ \hline \hline"
file write myff  "  & Work for & Work for & P-value\\ "
file write myff  "  & External Employer & Family Employer & Diff.\\ "
file write myff  "  & (1) & (2) & (3)  \\ \hline"
file close myff		
	
*Variables for which we report the median	
local k=1

foreach y in $yvars0{
	*desc stats for children with a family employer
	sum `y' if wrk_family==1 ,d
	local m_`k'=round(r(p50),0.001)
	local n_`k'=r(N)
	*desc stats for children with an outside employer	
	sum `y' if wrk_foremployer==1, d
	local m_e`k'=round(r(p50),0.001)
	local n_e`k'=r(N)
	*Difference test
	median `y', by(wrk_type)
	local pval_`k'=round(r(p_cc),0.0001)
	
file open myff using "${tabledir}/a_tab_desc_fam_nonfam.tex", write append
file write myff  " `lab`k'' & `m_e`k''  & `m_`k''  & `pval_`k'' \\"
file close myff		
	
	local ++k 
}

*Variables for which we report the mean
local k=2

foreach y in $yvars1{
	*desc stats for children with a family employer	
	sum `y' if wrk_family==1 
	local m_`k'=round(r(mean),0.001)
	local n_`k'=r(N)
	
	sum `y' if wrk_foremployer==1
	local m_e`k'=round(r(mean),0.001)
	local n_e`k'=r(N)
	
	*Difference test
	ttest `y', by(wrk_type)
	local pval_`k'=round(r(p),0.0001)	
	
file open myff using "${tabledir}/a_tab_desc_fam_nonfam.tex", write append
file write myff  " `lab`k'' & `m_e`k''  & `m_`k'' & `pval_`k''  \\"
file close myff		
	
	local ++k 
}

*Variables grouped under the "sector" category
file open myff using "${tabledir}/a_tab_desc_fam_nonfam.tex", write append
file write myff  " Sector &  &  & \\"
file close myff	

local k=7

foreach y in $yvars2{

	*desc stats for children with a family employer
	sum `y' if wrk_family==1 
	local m_`k'=round(r(mean),0.001)
	local n_`k'=r(N)
	
	*desc stats for children with an outside employer		
	sum `y' if wrk_foremployer==1
	local m_e`k'=round(r(mean),0.001)
	local n_e`k'=r(N)
	
	*Difference test
	ttest `y', by(wrk_type)
	local pval_`k'=round(r(p),0.0001)	
	
file open myff using "${tabledir}/a_tab_desc_fam_nonfam.tex", write append
file write myff  " `lab`k'' & `m_e`k''  & `m_`k''  & `pval_`k''  \\"
file close myff		
	
	local ++k 
}


file open myff using "${tabledir}/a_tab_desc_fam_nonfam.tex", write append
file write myff  "\hline"
file write myff  " Observations & `n_e1' & `n_1' & \\"
file close myff	

file open myff using "${tabledir}/a_tab_desc_fam_nonfam.tex", write append
file write myff "\hline \hline \\"
file close myff


********************************************************************************************************
*								CL Survey
********************************************************************************************************

clear all

use "${relabeled_dataCS}/RW_child_labor_survey.dta", clear

keep if age_survey_m>=108 & age_survey_m<=180

*Categories for p-value
gen wrk_type = 1 if workforfamily==1
replace wrk_type = 2 if workforemployer==1
label define type 1 "F" 2 "E"
label values wrk_type type

local lab1 "Risk at work"					
local lab2 "Injured at work"					


		*------------------------- Panel B ------------------------*


 file open myff using "${tabledir}/a_tab_desc_fam_nonfam.tex", write append
file write myff "\multicolumn{4}{c}{Panel B: Child Labor Survey Data } \\ \hline \hline"
file write myff  "  & Work for & Work for & P-value\\ "
file write myff  "  & External Employer & Family Employer & Diff. \\ "
file write myff  "  & (1) & (2) & (3)   \\ \hline"
file close myff		

*Sample between ages 9 and 15
global yvars " risks  injury"


*Descriptive statistics for 2008 (pre-law)
local k=1

foreach y in $yvars{
	*desc stats for children with a family employer
	sum `y' if year==2008 & workforfamily==1 [aw=weights] 
	local m_`k'=round(r(mean),0.001)
	local n_`k'=r(N)

	*desc stats for children with an outside employer	
	sum `y' if year==2008 & workforemployer==1 [aw=weights] 
	local m_e`k'=round(r(mean),0.001)
	local n_e`k'=r(N)	
	
	*Difference test
	mean `y' if year==2008 [aw=weights] , over(wrk_type) coeflegend
	test _b[c.`y'@1bn.wrk_type]=_b[c.`y'@2.wrk_type]
	local pval_`k'=round(r(p),0.0001)	
	
file open myff using "${tabledir}/a_tab_desc_fam_nonfam.tex", write append
file write myff  " `lab`k'' & `m_e`k''  & `m_`k'' & `pval_`k'' \\"
file close myff		
	
	local ++k 
}

file open myff using "${tabledir}/a_tab_desc_fam_nonfam.tex", write append
file write myff  "\hline"
file write myff  " Observations & `n_e1' & `n_1' & \\"
file close myff		


file open myff using "${tabledir}/a_tab_desc_fam_nonfam.tex", write append
file write myff "\hline \hline \\\end{tabular}}  \vspace{-0.5cm} \begin{tablenotes}" 
file write myff "\item\begin{footnotesize} Notes: The table shows the mean of the variables, except for firm size, where the median is displayed.  Definitions of the variables appear in Appendix \ref{sec:app3}. The sample in both panels includes children from ages 9 to 15. The survey years are 2012-2013 in Panel A, and 2008 in Panel B. Observations of the child labor survey are reweighted using the method described in Section 6.1. The third column shows the p-values of the differences between columns 1 and 2. \end{footnotesize} "
file write myff " \end{tablenotes} \end{threeparttable}} \end{table}"
file close myff



