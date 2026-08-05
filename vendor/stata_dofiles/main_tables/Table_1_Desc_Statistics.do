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
            Descriptive statistics
==================================================*/

*HH Survey
use "${relabeled_data}/HHsurvey.dta", clear

*Outcomes
global yvars "hours_week self_employed wrk_forother wrk_foremployer wrk_family forbidden  not_forbidden   wrk30hrs  attendance " 

*Sample pre-law and between ages 10 and 15
keep if year>=2012 & year<=2013
keep if age_dob_m>=120 & age_dob_m<=180

gen age10to11=age_dob_m>=120 & age_dob_m<144
gen age12to13=age_dob_m>=144 & age_dob_m<168
gen age14to15=age_dob_m>=168 & age_dob_m<192


*labels
local lab1 "Any work" 
local lab2 "Hours worked"					
local lab3 "Work for self"			
local lab4 "Work for others"
local lab5	"Work for external employer"
local lab6 "Work for family employer"
local lab7 "Prohibited work"
local lab8 "Allowed work"
local lab9 "Work $\geq$ 30 hrs/week "
local lab10 "Attends school"

*HH Characteristics
ren head_schooling x11
ren head_male x12
ren head_age x13
ren indig_head x14
ren hhsize x15
ren male x16

local lab11 "HH Head Years of Schooling"
local lab12 "HH Head is Male"
local lab13 "HH Head Age"
local lab14 "HH Head is Indigenous"
local lab15 "Household Size"
local lab16 "Child is Male"


*Table preamble
 file open myff using "${tabledir}/a_tab_desc_stats.tex", write replace
file write myff "\begin{table}[H]"
file write myff " \centering"
file write myff "\caption{Descriptive Statistics (Pre-Law)\label{tab:sumstats}} \resizebox{.85\textwidth}{!}{"
file write myff "\begin{threeparttable}"
file write myff " \centering {\begin{tabular}{l*{6}{c}} "
file write myff "\multicolumn{6}{c}{Panel A: Household Data} \\ \hline \hline"
file write myff  "  & All Children & Working Children & All Children & All Children& All Children \\ "
file write myff  "  & Ages 10-15 & Ages 10-15 & Ages 10-11 & Ages 12-13 & Ages 14-15 \\ "
file write myff  "  & (1) & (2) & (3) & (4) & (5)  \\ \hline"
// file write myff  "  &  \\ "
file write myff  " \textit{Household \& Child Characteristics} & & & & & & \\ "
file close myff		


		*------------------------- Panel A ------------------------*

** HH Characteristics

forvalues k=11(1)16{
			
	sum x`k' 
	local m_a`k'=round(r(mean),0.001)
	
    sum x`k' if works==1
	local m_`k'=round(r(mean),0.001)
	
    sum x`k' if age10to11==1 
	local m_1011`k'=round(r(mean),0.001)

    sum x`k' if age12to13==1 
	local m_1213`k'=round(r(mean),0.001)

    sum x`k' if age14to15==1 
	local m_1415`k'=round(r(mean),0.001)

	file open myff using "${tabledir}/a_tab_desc_stats.tex", write append
file write myff  " `lab`k'' & `m_a`k''  & `m_`k'' & `m_1011`k'' & `m_1213`k''  & `m_1415`k''  \\"
file close myff		
		
}

file open myff using "${tabledir}/a_tab_desc_stats.tex", write append
file write myff  " \textit{Child Work \& Schooling Outcomes}  & & & & & & \\ "
file close myff	


** Outcomes

		
*For likelihood of working, we only calculate the descriptives for the sample of all children
	sum works 
	local mw=round(r(mean),0.001)
	local sdw=round(r(sd),0.001)
	local nw=r(N)
	
	 sum works if age10to11==1
	local m_1011=round(r(mean),0.001)

    sum works if age12to13==1
	local m_1213=round(r(mean),0.001)

    sum works if age14to15==1
	local m_1415=round(r(mean),0.001)

	file open myff using "${tabledir}/a_tab_desc_stats.tex", write append
	file write myff  " `lab1' & `mw'  &  -  & `m_1011' & `m_1213'  & `m_1415' \\"
	file close myff	

*For other outcomes, we calculate the descriptives for the sample of all children and for the sample of working children
local k=2

foreach y in $yvars{
		
	sum `y' 
	local m_`k'=round(r(mean),0.001)
	local n_`k'=r(N)
	
	sum `y'_a 
	local m_a`k'=round(r(mean),0.001)
	local n_a`k'=r(N)
	
	 sum `y'_a if age10to11==1
	local m_1011`k'=round(r(mean),0.001)
	local n_1011`k'=r(N)

    sum `y'_a if age12to13==1
	local m_1213`k'=round(r(mean),0.001)
	local n_1213`k'=r(N)

    sum `y'_a if age14to15==1
	local m_1415`k'=round(r(mean),0.001)
	local n_1415`k'=r(N)

if `k'==5 | `k'==6{
	local indent "\hspace{0.5cm}"
}
else{
	local indent ""
}
	
file open myff using "${tabledir}/a_tab_desc_stats.tex", write append
file write myff  " `indent' `lab`k'' & `m_a`k''  & `m_`k'' & `m_1011`k''& `m_1213`k''  & `m_1415`k''  \\"
file close myff		
	
	local ++k 
}

file open myff using "${tabledir}/a_tab_desc_stats.tex", write append
file write myff  "\hline"
file write myff  " Observations & `n_a2' & `n_2' & `n_10112' & `n_12132' & `n_14152' \\"
file close myff	

file open myff using "${tabledir}/a_tab_desc_stats.tex", write append
file write myff "\hline \hline \\"
file close myff

		*------------------------- Panel B ------------------------*

		*Outcomes for which we report the median	
global yvars1 "number_workers_w"
 
*Outcomes for which we report the mean
global yvars2  "wage_hour_w firm_taxes location_out_fixed_a location_out_mobile_a location_home_a"

*Table header
 file open myff using "${tabledir}/a_tab_desc_stats.tex", write append
file write myff "\multicolumn{6}{c}{Panel B: Job Attributes (Household Survey) } \\ \hline \hline"
file write myff  "  &  & Working Children   & Ages 10-11 & Ages 12-13 & Ages 14-15 \\ "
file write myff  "  & & (1) & (2) & (3) & (4)  \\ \hline"
file close myff	

*Labels
local lab1 "Firm size (median)"	
local lab2 "Hourly wage (Bolivianos)" 		
local lab3 "Firm pays taxes"			
local lab4 "Works Outside of Home in Fixed Location"
local lab5 "Works Outside of Home in Mobile Location"
local lab6 "Works at Home"


*For the first outcome, we report the median
local k=1

foreach y in $yvars1{
		
	sum `y' if works==1,d 
	local m_`k'=round(r(p50),0.001)
	local n_`k'=r(N)
	
	 sum `y' if age10to11==1 ,d 
	local m_1011`k'=round(r(p50),0.001)
	local n_1011`k'=r(N)

    sum `y' if age12to13==1 ,d 
	local m_1213`k'=round(r(p50),0.001)
	local n_1213`k'=r(N)

    sum `y' if age14to15==1 ,d 
	local m_1415`k'=round(r(p50),0.001)
	local n_1415`k'=r(N)

	
file open myff using "${tabledir}/a_tab_desc_stats.tex", write append
file write myff  " `lab`k'' &   & `m_`k''  & `m_1011`k''& `m_1213`k''  & `m_1415`k''   \\"
file close myff		
	
	local ++k 
}

*For all other outcomes we report the mean
local k=2

foreach y in $yvars2{
		
	sum `y' if works==1
	local m_`k'=round(r(mean),0.001)
	local n_`k'=r(N)
	
	 sum `y' if age10to11==1 
	local m_1011`k'=round(r(mean),0.001)
	local n_1011`k'=r(N)

    sum `y' if age12to13==1 
	local m_1213`k'=round(r(mean),0.001)
	local n_1213`k'=r(N)

    sum `y' if age14to15==1 
	local m_1415`k'=round(r(mean),0.001)
	local n_1415`k'=r(N)
	
file open myff using "${tabledir}/a_tab_desc_stats.tex", write append
file write myff  " `lab`k'' &   & `m_`k'' & `m_1011`k''& `m_1213`k''  & `m_1415`k''  \\"
file close myff		
	
	local ++k 
}


file open myff using "${tabledir}/a_tab_desc_stats.tex", write append
file write myff  "\hline"
file write myff  " Observations &  & `n_1'  & `n_10111' & `n_12131' & `n_14151' \\"
file close myff	

file open myff using "${tabledir}/a_tab_desc_stats.tex", write append
file write myff "\hline \hline \\"
file close myff	

*------------------------- Panel C ------------------------*

*CL survey
use "${relabeled_dataCS}/RW_child_labor_survey.dta", clear

*Sample between ages 10 and 15
keep if age_survey_m>=120 & age_survey_m<=180

gen age10to11=age_survey_m>=120 & age_survey_m<144
gen age12to13=age_survey_m>=144 & age_survey_m<168
gen age14to15=age_survey_m>=168 & age_survey_m<192


*Outcomes
global yvars "risks injury"

*Labels
local lab1 "Risk at work"					
local lab2 "Injured at work"					

*Table Preamble
file open myff using "${tabledir}/a_tab_desc_stats.tex", write append
file write myff "\multicolumn{6}{c}{Panel C: Job Attributes (Child Labor Survey) } \\ \hline \hline"
file write myff  "  & All Children & Working Children & Ages 10-11 & Ages 12-13 & Ages 14-15 \\ "
file write myff  "  & (1) & (2) & (3) & (4) & (5)   \\ \hline"
file close myff		


*Statistics calculated for 2008 (pre-law) and weighted
local k=1

foreach y in $yvars{
		
	sum `y' if year==2008 [aw=weights] 
	local m_`k'=round(r(mean),0.001)
	local n_`k'=r(N)

	sum `y'_a if year==2008 [aw=weights] 
	local m_a`k'=round(r(mean),0.001)
	local n_a`k'=r(N)	

	sum `y'_a if year==2008 & age10to11==1 [aw=weights] 
	local m_1011`k'=round(r(mean),0.001)
	local n_1011`k'=r(N)

	sum `y'_a if year==2008 & age12to13==1 [aw=weights] 
	local m_1213`k'=round(r(mean),0.001)
	local n_1213`k'=r(N)	
	
	sum `y'_a if year==2008 & age14to15==1 [aw=weights] 
	local m_1415`k'=round(r(mean),0.001)
	local n_1415`k'=r(N)
	
	
file open myff using "${tabledir}/a_tab_desc_stats.tex", write append
file write myff  " `lab`k'' & `m_a`k''  & `m_`k'' & `m_1011`k''& `m_1213`k''  & `m_1415`k''  \\"
file close myff		
	
	local ++k 
}

file open myff using "${tabledir}/a_tab_desc_stats.tex", write append
file write myff  "\hline"
file write myff  " Observations & `n_a2' & `n_2' & `n_10112' & `n_12132' & `n_14152' \\"
file close myff		

*Closing file

file open myff using "${tabledir}/a_tab_desc_stats.tex", write append
file write myff "\hline \hline \\\end{tabular}}  \vspace{-0.5cm} \begin{tablenotes}" 
file write myff "\item\begin{singlespace} \begin{footnotesize}Notes: The table shows the mean of the variables, except for firm size, where the median is displayed.  Definitions of the variables appear in Appendix \ref{sec:app3}. The list of prohibited tasks appears in Appendix \ref{sec:app2}. The sample in both panels includes children from ages 10 to 15. The survey years are 2012-2013 in Panels A and B, and 2008 in Panel C. Observations of the child labor survey are reweighted using the method described in Section 6.1. \end{footnotesize} \end{singlespace}"
file write myff " \end{tablenotes} \end{threeparttable}} \end{table}"
file close myff



