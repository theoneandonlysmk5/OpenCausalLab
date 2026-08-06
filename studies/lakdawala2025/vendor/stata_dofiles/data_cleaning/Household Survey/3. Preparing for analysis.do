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

/* This .do file *Includes: 
**1) Distance to offices
**2) Cleaning HH Panel */

/*==================================================
            0: Program set up
==================================================*/
*Written on STATA 17
drop _all

/*==================================================
            1: Distance to Offices
==================================================*/

use "${other_raw}/travel_capitales.dta", clear
**Calculating medians
sum dist, detail 
gen median_directdist= `r(p50)'
gen abovemed_directdist= dist>median_directdist

sum ttime, detail 
gen median_time= `r(p50)'
gen abovemed_time= ttime>median_time

sum tdist, detail 
gen median_dist= `r(p50)'
gen abovemed_dist= tdist>median_dist

*rename code to merge
rename muni_code cod_secc


*Samples by municipality type
gen capital = 1 if muni_name=="Cobija" | muni_name=="Cochabamba" | muni_name=="Trinidad" | muni_name=="Santa Cruz de la Sierra" | muni_name=="Sucre" | muni_name=="Tarija" | muni_name=="Potosí" | muni_name=="Oruro" | muni_name=="La Paz"
replace capital=0 if capital==.


gen mtepsoffices=1 if muni_name=="Riberalta" | muni_name=="Guayaramerín" | muni_name=="Trinidad"| muni_name=="Cobija" | muni_name=="Oruro" | muni_name=="Monteagudo" | muni_name=="Sucre" | muni_name=="Uyuni" | muni_name=="Villazón"| muni_name=="Tupiza"| muni_name=="Llallagua" | muni_name=="Potosí" | muni_name=="Puerto Suarez" | muni_name=="Villamontes" | muni_name=="Yacuiba" | muni_name=="Bermejo"| muni_name=="Tarija"| muni_name=="Warnes" | muni_name=="Montero" | muni_name=="Camiri" | muni_name=="Santa Cruz de la Sierra" | muni_name=="Villa Tunari" | muni_name=="Cochabamba" | muni_name=="El Alto" | muni_name=="La Paz" 
 replace mtepsoffices=0 if mtepsoffices==.
 
save "${other_relabeled}/travel_capitales_tomerge.dta", replace 

/*==================================================
            2: Cleaning HH Panel
==================================================*/

use "${relabeled_data}/Persona/EH_cleaned_persona.dta" , clear



*Calculate dob
replace birth_day=. if birth_day==99|birth_day==88  
gen dob=mdy(birth_month, birth_day,birth_year)
gen s_date=mdy(collection_month, collection_day, collection_year)
gen age_dob=s_date-dob
gen age_dob_m=round(age_dob/30)
label var dob "Date of birth"
label var age_dob "Calculated age (days)"
label var age_dob_m "Calculated age (months)"

*Lag schooling for age
gen lag_schooling=age-5-schooling
replace lag_schooling=0 if lag_schooling<0

*Age groups related to the law with age in years
gen agecat=1 if age>6 & age<10
replace agecat= 2 if age>=10 & age<12
replace agecat=3 if age>=12 & age<14
replace agecat=4 if age>=14 & age<18
replace agecat=5 if age>=18 
label define agecat 1 "7-9" 2 "10-11" 3 "12-13" 4 "14-17" 5 "18-20"
label values agecat agecat

*Paid work
gen paid = wage_worker if works==1
label var paid "Wage worker"
gen paid_a = wage_worker 
label var paid_a "Wage worker (base=all)"

*wages
gen wage_hour_w_a=wage_hour_w
replace wage_hour_w_a=0 if works==0
gen log_wage_hour_w_a=log(wage_hour_w_a+1)
gen log_wage_hour_w=log(wage_hour_w+1)
gen log_ylabor_w=log(ylabor_w+1)
gen plusminearnings=ylabor_w>=1200 if ylabor_w!=.


*Family work
gen wrk_family=(ocu_cat==7) if works==1
gen wrk_family_a=(ocu_cat==7) 
label var wrk_family_a "Unpaid Family worker or apprentice (base=all)"

*Work outside family
gen wrk_out=(ocu_cat<7 | ocu_cat==8) if works==1
gen wrk_out_a=(ocu_cat<7 | ocu_cat==8) 
label var wrk_out_a "Works Outside Family (base=all)"
 
*Work for employer 
gen wrk_foremployer=(ocu_cat<3 | ocu_cat==8) if works==1
gen wrk_foremployer_a=(ocu_cat<3 | ocu_cat==8) 
label var wrk_foremployer_a "Works for an Employer (base=all)"

*Work for others 
gen wrk_forother=(ocu_cat<3 | ocu_cat==8 | ocu_cat==7 | ocu_cat==6) if works==1
gen wrk_forother_a=(ocu_cat<3 | ocu_cat==8 | ocu_cat==7 | ocu_cat==6) 
label var wrk_forother_a "Works for Others (base=all)"

*Self-Employed  
replace self_employed=. if works==0
gen self_employed_a = self_employed
replace self_employed_a=0 if works==0
label var self_employed_a "Self-Employed (base=all)"

*Work more than 30 hours
gen wrk30hrs=(hours_week_w>30 & hours_week_w!=.) if works==1
label var wrk30hrs "Works more than 30 hrs per week"
gen wrk30hrs_a=(hours_week_w>30 & hours_week_w!=.) 
label var wrk30hrs_a "Works more than 30 hrs per week (base=all)"

*Domestic work
gen domestic=(ocu_cat==8) if works==1
label var domestic "Domestic worker"
gen domestic_a=(ocu_cat==8) 
label var domestic_a "Domestic worker (base=all)"

*Hours worked per week
gen hours_week_a= hours_week_w
label var hours_week_a "Hours worked"
drop hours_week
gen hours_week= hours_week_a
replace hours_week=. if works==0
label var hours_week "Hours worked"

*School attendance
replace attendance=. if age<6
label var attendance "Schooling attendance"
gen attendance_a= attendance
replace attendance=. if works==0  

*Other labels
label var works "Works"
label var reads "Reads and writes"

*Sectors
gen agriculture_a=(sector==1)
label var agriculture_a "Agriculture (base=all)"

gen mining_a=(sector==2)
label var mining_a "Mining (base=all)" 

gen manufacture_a=(sector==3)
label var manufacture_a "Manufacturing (base=all)"

gen construction_a=(sector==5)
label var construction_a "Construction (base=all)"

gen sales_a=(sector==6)
label var sales_a "Retail (base=all)"

gen transportation_a=(sector==7)
label var transportation_a "Transport \& Storage (base=all)"

gen accomodation_a=(sector==10)
label var accomodation_a "Accomodation \& Food (base=all)"

gen other_a=(sector==4 | sector==8 | sector==9 | sector==11)
label var other_a "Other industry (base=all)"

*more broad "other" category
gen other_occ= mining_a | manufacture_a | construction_a | transportation_a | accomodation_a | other_a 

*Common occupations/sectors
gen common=1 if sector==1 | sector==6 | sector==3 /*Commerce and retail, agriculture, manufacturing*/

*Forbidden occupations/sectors
gen forbidden=1 if (sector==1 & wrk_family==0 ) | sector==2 | sector==5 
replace forbidden=0 if forbidden==. & works==1
replace forbidden=. if works==0 
label var forbidden "Forbidden work"
gen forbidden_a= forbidden
replace forbidden_a=0 if works==0
label var forbidden_a "Forbidden work"


gen not_forbidden_a=1-forbidden_a
replace not_forbidden_a=0 if works==0
label var not_forbidden_a "Non-forbidden work"
gen not_forbidden=not_forbidden_a
replace not_forbidden=. if works==0
label var not_forbidden "Non-forbidden work"

*Job Location
gen wrk_home=job_location==1
gen wrk_fixedloc=job_location==2
gen wrk_roamingloc=job_location==3


********************************************************************************
*								HH Head vars
********************************************************************************

*head indicator
gen h_hh=(rel_head==1)

*head age
gen age_h=age if h_hh==1

* head marital status
gen married_h=1 if (civil_status== 2 | civil_status== 3) & h_hh==1
replace married_h=0 if (civil_status== 1 | civil_status== 4 | civil_status== 5 | civil_status== 6) & h_hh==1

*Head industry/sector
gen industry_h=sector if h_hh==1

*Head language
gen lang_spa_h=(language_childhood==1)

*Head working position (worker, employee, etc)
gen pos_worker_h=(ocu_cat==1) if h_hh==1
gen pos_employee_h=(ocu_cat==2) if h_hh==1
gen pos_selfemp_h=(ocu_cat==3) if h_hh==1
gen pos_employer_h=(ocu_cat==4 | ocu_cat==5) if h_hh==1
gen pos_other_h=(ocu_cat==6 | ocu_cat==7 | ocu_cat==8) if h_hh==1

*Head identifies an indigenous
gen indig_h=(indigenous==1) if h_hh==1

*Head works at home
gen wrkhome_h=(job_location==1) if h_hh==1

*Filling head vars for everyone in the hh
global hhheadvars "age_  married_ industry_ pos_worker_  pos_employee_ pos_selfemp_ pos_employer_ pos_other_ wrkhome_ indig_ lang_spa_"

foreach x in $hhheadvars {
	bys folio year: egen `x'head=max(`x'h)
	drop `x'h
}

********************************************************************************
*								  HH vars
********************************************************************************


*Household income and children by age group
preserve

use "${relabeled_data}/Persona/EH_cleaned_persona.dta", clear 

**** merge in the data with income
joinby id_year using "${relabeled_data}/Income/EH_cleaned_income", unm(b)
tab _merge 
drop _merge

*total members in hh
gen members=1
bys folio year: egen hhsize=total(members)
drop members

***************************vars of children at hh*******************************
drop if age>=18

*Number of girls and boys
gen gi=1 if male==0
gen bo=1 if male==1
bys folio year: egen girls=total(gi)
bys folio year: egen boys=total(bo)
drop gi bo

*Child income of the hh
bys folio year: egen child_income=total(y_wl_earnings)

*Collapse at the hh level
collapse hhsize child_income y_household girls boys, by(folio year)

*income of adults (total income minus children income)
gen income_adults=y_household-child_income
gen income_adults_pc=income_adults/hhsize
xtile income_q=income_adults_pc,n(5)

tempfile ch_income
save `ch_income', replace

*Number of children by age group at hh
use "${relabeled_data}/Persona/EH_cleaned_persona.dta", clear
gen hh_agecat1=(age<7)
gen hh_agecat2=(age>=7 & age<10)
gen hh_agecat3=(age>=10 & age<14)
gen hh_agecat4=(age>=14 & age<18)
collapse (sum) hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4, by(folio year)
tempfile ch_ages
save `ch_ages', replace

restore

********************************************************************************
*					     Merging with master data set
********************************************************************************

merge m:1 folio year using `ch_income'
drop if _merge==2
drop _merge

merge m:1 folio year using `ch_ages'
drop if _merge==2
drop _merge

*Removing child from their age group so that he/she is not included
replace hh_agecat1= hh_agecat1-1 if age<7
replace hh_agecat2= hh_agecat2-1 if age>=7 & age<10
replace hh_agecat3= hh_agecat3-1 if age>=10 & age<14
replace hh_agecat4= hh_agecat4-1 if age>=14 & age<18
foreach x in hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4{
	replace `x'=0 if `x'<0
}

*Number of adult women and men
gen adult_women=n_female-girls
gen adult_men=n_male-boys
drop boys girls

*Province var
nsplit cod_secc, digits(4 1) generate(prov temp)
drop temp

*Recode sector to match child labor survey
recode sector  2=3 3=4 4=17 5=6 6=7 7=9 8=17 9=17 10=8 11=17 
recode industry_head  2=3 3=4 4=17 5=6 6=7 7=9 8=17 9=17 10=8 11=17 99=17
label define activity 1 "Agriculture" 3 "Mining" 4 "Manufacturing" 6 "Construction" 7 "Retail" 8 "Accomodation \& Food" 9 "Transport \& Storage" 16 "Domestic Work" 17 "Other"
label values sector activity 
label values industry_head activity 


*Elegibility to cash transfer
gen grade_cct=schooling-1 if enrolled==1
replace grade_cct=schooling if enrolled==0
replace grade_cct=. if grade_cct<0

gen eligible=1 if year==2006 & (grade_cct)<5 & enrolled_public==1
replace eligible=1 if year==2007 & (grade_cct)<6  & enrolled_public==1
replace eligible=1 if year>=2008 & year<=2011 & (grade_cct-1)<=8  & enrolled_public==1
replace eligible=1 if year==2012 & (grade_cct)<9  & enrolled_public==1
replace eligible=1 if year==2013 & (grade_cct)<10 & enrolled_public==1
replace eligible=1 if year>=2014 & (grade_cct)<12  & enrolled_public==1
replace eligible=0 if eligible==. & enrolled==1 & enrolled_public==0

**by grade
gen eligible_gr=1 if year==2006 & (grade_cct)<5 
replace eligible_gr=1 if year==2007 & (grade_cct)<6  
replace eligible_gr=1 if year>=2008 & year<=2011 & (grade_cct)<8  
replace eligible_gr=1 if year==2012 & (grade_cct)<9 
replace eligible_gr=1 if year==2013 & (grade_cct)<10 
replace eligible_gr=1 if year>=2014 & (grade_cct)<12 
replace eligible_gr=0 if eligible_gr==.

**by grade for age
gen date30march=mdy(3,30,year)
gen age30mar=round((date30march-dob)/365)
gen gradeforage=1 if age30mar==6
forvalues i=2(1)11{
replace gradeforage=`i' if age30mar==`i'+5
replace gradeforage=. if gradeforage>12
}
gen eligible_grage=1 if year==2006 & (gradeforage)<5 
replace eligible_grage=1 if year==2007 & (gradeforage)<6  
replace eligible_grage=1 if year>=2008 & year<=2011 & (gradeforage)<8  
replace eligible_grage=1 if year==2012 & (gradeforage)<9 
replace eligible_grage=1 if year==2013 & (gradeforage)<10 
replace eligible_grage=1 if year>=2014 & (gradeforage)<12 
replace eligible_grage=0 if eligible_grage==.

*Received CCT
rename receives_cct_juancito received_cct

*Size of a firm 
winsor number_workers, gen( number_workers_w ) p(0.05) high
gen number_workers_a= number_workers_w
replace number_workers_a=0 if works==0

*firm pays taxes
recode firm_taxes 2=0
recode firm_taxes 3=0
recode firm_taxes 99=.

*Terciles and median of firm size, and micro enterprise
xtile aux1=number_workers_w , n(2) 
xtile aux2=number_workers_w , n(3) 


_pctile number_workers_w , nq(2)
ret li
_pctile number_workers_w, nq(3)
ret li

sum number_workers_w,d
local p75= `r(p75)'

gen abovemed_firmsize=aux1
recode abovemed_firmsize 1=0 2=1
replace abovemed_firmsize=0 if works==0

gen abovep75_firmsize=number_workers_w>= `p75'
replace abovep75_firmsize=0 if works==0

gen notsmall_firm= number_workers_w>10
replace notsmall_firm=. if number_workers_w==.
replace notsmall_firm=0 if works==0

tab aux2, gen(terc_)

drop aux1 aux2

forvalues i=1(1)3{
	label var terc_`i' "Tercile"
	gen terc_a_`i'=terc_`i'
	replace terc_a_`i'=0 if works==0
	}

tab abovemed_firmsize, gen(med_)	
tab notsmall_firm, gen(size_)
tab abovep75_firmsize, gen(p75_)

forvalues i=1(1)2{
	gen med_a_`i'=med_`i'
	replace med_a_`i'=0 if works==0
	
	gen size_a_`i'=size_`i'
	replace size_a_`i'=0 if works==0
	
	gen p75_a_`i'=size_`i'
	replace p75_a_`i'=0 if works==0
	}

*Formal contract (above median and p75)
gen formal_contract= contract==1 | contract==3
summ formal_contract, detail
gen formal_contract50=formal_contract> r(p50) if formal_contract!=.
replace formal_contract50=0 if formal_contract50==.
gen formal_contract75=formal_contract> r(p75) if formal_contract!=.
replace formal_contract75=0 if formal_contract75==.

*Municipal level firm size (adults and children - above median and p75)
gen no_workers_children=number_workers if age<18
gen no_workers_adults=number_workers if age>17

bys cod_secc: egen aux1=mean(no_workers_children) if age<18
bys cod_secc: egen aux2=mean(no_workers_adults) if age>17

bys cod_secc: egen mun_workers_children=max(aux1) 
bys cod_secc: egen mun_workers_adults=max(aux2) 

drop aux1 aux2

summ mun_workers_children, detail
gen mun_workers_children50=mun_workers_children> r(p50)

summ mun_workers_adults, detail
gen mun_workers_adults50=mun_workers_adults> r(p50)

*Municipal level formal contract (adults and children - above median and p75)
gen formal_contract_children=formal_contract if age<18
gen formal_contract_adults=formal_contract if age>17

bys cod_secc: egen aux1=mean(formal_contract_children) if age<18
bys cod_secc: egen aux2=mean(formal_contract_adults) if age>17

bys cod_secc: egen mun_contract_children=max(aux1) 
bys cod_secc: egen mun_contract_adults=max(aux2) 

drop aux1 aux2

summ mun_contract_children, detail
gen mun_contract_children50=mun_contract_children> r(p50)

summ mun_contract_adults, detail
gen mun_contract_adults50=mun_contract_adults> r(p50)


*label vars
label var age "Age (years)"
label var male "Male"
label var income_adults "HH Income"
label var head_age "HH head's age (years)"
label var married_head "HH head is married" 
label var head_schooling "HH head's years of schooling"
label var head_works "HH head works"
label var head_male "HH head is male"
label var hhsize "HH size"
label var income_q "Income quintiles"
label var pos_worker_head "HH head is a worker"
label var pos_employee_head "HH head is an employee"
label var pos_selfemp_head "HH head is self-employed"
label var pos_employer_head "HH head is an employer"
label var pos_other_head "HH head has other position"
label var hh_agecat1 "Children in HH  0-6 y/o"
label var hh_agecat2 "Children in HH  7-9 y/o"
label var hh_agecat3 "Children in HH  10-13 y/o"
label var hh_agecat4 "Children in HH  14-17 y/o"
label var lang_spa_head "HH head speaks Spanish"
label var indig_head "HH head is indigenous"
label var indigenous "Indigenous"
label var sector "Child industry"
label var industry_head "HH head industry"
label var adult_women "Adult women"
label var adult_men "Adult men"
label var eligible "Eligibility to CCT"

*Interactions between hh head gender and characteristics
gen g_h_works=(1-head_male)*head_works
gen g_h_edu=(1-head_male)*head_schooling
gen g_h_married=(1-head_male)*married_head
gen g_h_age= (1-head_male)*head_age
gen g_h_worker =(1-head_male)*pos_worker_head 
gen g_h_employee =(1-head_male)*pos_employee_head 
gen g_h_selfemp =(1-head_male)*pos_selfemp_head 
gen g_h_employer =(1-head_male)*pos_employer_head 
gen g_h_other =(1-head_male)*pos_other_head 
gen g_h_indig =(1-head_male)*indig_head

*Labels for interactions
label var g_h_works "Female \times head works"
label var g_h_edu "Female \times head's education'"
label var g_h_married "Female \times head married"
label var g_h_age "Female \times head's age"
label var g_h_worker "Female \times head is a worker" 
label var g_h_employee "Female \times head is an emplyee"
label var g_h_selfemp "Female \times head is self-employed"
label var g_h_employer "Female \times head is an employer"
label var g_h_other "Female \times head has other position"
label var g_h_indig "Female \times head is indigenous"

*Media
merge m:1 cod_secc using "${other_raw}/comassets_chlab_bolivia.dta"
drop if _merge==2
drop _merge

*Distance
merge m:1 cod_secc using "${other_relabeled}/travel_capitales_tomerge.dta"
drop if _merge==2
drop _merge

*Media use variables by municipality in 2014
foreach x in s5c_13 s5c_14 s5c_15 s5c_16{
recode `x' 2=0
}

egen aux=rowtotal(s5c_14 s5c_15 s5c_16)
gen any= aux>0 if year==2014 & aux!=.

bys cod_secc: egen auxphoneuse=mean(s5c_14) if year==2014
bys cod_secc: egen auxpcuse=mean( s5c_15) if year==2014
bys cod_secc: egen auxinternetuse=mean( s5c_16) if year==2014
bys cod_secc: egen auxany=mean(aux) if year==2014

bys cod_secc: egen phoneuse=max(auxphoneuse  ) 
bys cod_secc: egen pcuse=max( auxpcuse  ) 
bys cod_secc: egen internetuse=max( auxinternetuse ) 
bys cod_secc: egen anyuse=max( auxany ) 

 drop s5c_13 s5c_14 s5c_15 s5c_16  aux*
 
 *Informal mechanisms
gen location_out_fixed_a= wrk_home==0 & wrk_fixedloc==1 & works==1
gen location_out_mobile_a= wrk_home==0 & wrk_fixedloc==0 & works==1 
gen  firm_taxes_a=firm_taxes
replace firm_taxes_a=0 if firm_taxes_a==.
gen location_home_a= wrk_home==1 & works==1

 
************ Difference in Discontinuity Variables ************

 *complete running variable with aprox dates
gen s_date_approx=mdy(10, 16, 2012) if year==2012
replace s_date_approx=mdy(10, 19, 2015) if year==2015
replace s_date_approx=mdy(10, 29, 2017) if year==2017
replace s_date_approx=mdy(12, 22, 2018) if year==2018
replace s_date_approx=mdy(10, 21, 2019) if year==2019

replace age_dob_m=round((s_date_approx-dob)/30) if year==2012
replace age_dob_m=round((s_date_approx-dob)/30) if year==2015
replace age_dob_m=round((s_date_approx-dob)/30) if year==2017
replace age_dob_m=round((s_date_approx-dob)/30) if year==2018
replace age_dob_m=round((s_date_approx-dob)/30) if year==2019


*Post dummy
gen pre=year<2014
gen post=(year>=2014 & year<2018)
gen post_rev=(year>=2018)

foreach n in 1 2 3  {
local c=`n'*2+8

*create running variable (recall at survey date AND a week before the survey)
gen running`c'=age_dob_m-(`c'*12)
gen runningw`c'=(age_dob_m-0.25)-(`c'*12)

*create running variable for McCrary tests
gen runningmcr`c'=age_dob_m-(`c'*12)
**multiplying the group around the 14 y/o cutoff by -1 to account for the treatment group being the younger children
if `n'==3 { 
    replace runningmcr`c'=running`c'*(-1)
}

*bandwidth
local bw=12

*sample to estimate (recall at survey date AND a week before the survey)
gen s`c'=(abs(running`c') <= `bw')
gen sww`c'=(abs(runningw`c') <= `bw')

*treatment variable (survey date recall)
if `n'==3 |`n'==4 {  
gen treat`c' = running`c' < 0
replace treat`c'=. if running`c'==.
label var treat`c' "Below cutoff"
}
else{
    gen treat`c' = running`c' >= 0
	replace treat`c'=. if running`c'==.
label var treat`c' "Above and in cutoff"
} 
*treatment variable (week before the survey date recall)
if `n'==3 |`n'==4 {  
gen treatw`c' = runningw`c' < 0
replace treatw`c'=. if runningw`c'==.
label var treatw`c' "Below cutoff"
}
else{
    gen treatw`c' = runningw`c' >= 0
	replace treatw`c'=. if runningw`c'==.
label var treatw`c' "Above and in cutoff"
} 


*interactions b/w treatment and running var (recall at survey date AND a week before the survey)
gen treatxrunning`c' = treat`c'*running`c'
gen treatxrunningw`c' = treatw`c'*runningw`c'

*Quadratic variables (recall at survey date AND a week before the survey)
gen running2`c' = running`c'^2
gen treatxrunning2`c' = treat`c'*running`c'*running`c'
gen running2w`c' = runningw`c'^2
gen treatxrunning2w`c' = treatw`c'*runningw`c'*runningw`c'

*Interactions b/w running var and post (recall at survey date AND a week before the survey)
gen postxrunning`c' = post*running`c'
gen postxrunningw`c' = post*runningw`c'
gen postxrunning2w`c' = post*running2w`c'

gen postrxrunningw`c' = post_rev*runningw`c'
gen postrxrunning2w`c' = post_rev*running2w`c'

*Kernel weights (recall at survey date AND a week before the survey)
gen kernel_tri`c' = ((`bw' - abs(running`c')) /`bw') * (abs(running`c') <= `bw')
gen kernel_triw`c' = ((`bw' - abs(runningw`c')) /`bw') * (abs(runningw`c') <= `bw')

*post times treat
gen xxw`n'=post*treatw`c'
gen xx`n'=post*treat`c'

gen xxrw`n'=post_rev*treatw`c'
gen xxr`n'=post_rev*treat`c'

if `n'==3 |`n'==4 {  
label var xxw`n' "Post Law $\times$ $\mathbbm{1}$\{Age$< `c'$\}"
label var xxrw`n' "Post Reversal $\times$ $\mathbbm{1}$\{Age$< `c'$\}"
}
else{
label var xxw`n' "Post Law $\times$ $\mathbbm{1}$\{Age$\geq `c'$\}"
label var xxrw`n' "Post Reversal $\times$ $\mathbbm{1}$\{Age$\geq `c'$\}"
}

*sample to estimate in donut estimation
gen donsww`c'=(abs(runningw`c') <= 24) & (abs(runningw`c') >1)

*bandwidth for bandwidth robustness checks
foreach bw in 6 12 18 24{

*sample to estimate 
gen sww`c'_`bw'=(abs(runningw`c') <= `bw')

*Kernel weights
gen kernel_triw`c'_`bw' = ((`bw' - abs(runningw`c')) /`bw') * (abs(runningw`c') < `bw')
}
}


				* * * * Variables for exact age * * * * 
				
*years for which we have exact age				
gen exactsample= year==2013 | year==2014 | year==2016

foreach n in 1 2 3  {
local c=`n'*2+8
if `n'==4 { 
    local c=`n'*2+10
}
*create running variable
gen drunning`c'=age_dob-(`c'*365)
gen drunningw`c'=(age_dob-7)-(`c'*365)

*bandwidth
local dbw=365

*sample to estimate 
gen ds`c'=(abs(drunning`c') <= `dbw')
gen dsww`c'=(abs(drunningw`c') <= `dbw')

*treatment variable
if `n'==3 |`n'==4 {  
gen dtreat`c' = drunning`c' < 0
replace dtreat`c'=. if drunning`c'==.
label var dtreat`c' "Below cutoff"
}
else{
    gen dtreat`c' = drunning`c' >= 0
	replace dtreat`c'=. if drunning`c'==.
label var dtreat`c' "Above and in cutoff"
} 

if `n'==3 |`n'==4 {  
gen dtreatw`c' = drunningw`c' < 0
replace dtreatw`c'=. if drunningw`c'==.
label var dtreatw`c' "Below cutoff"
}
else{
    gen dtreatw`c' = drunningw`c' >= 0
	replace dtreatw`c'=. if drunningw`c'==.
label var dtreatw`c' "Above and in cutoff"
} 

*interactions b/w treatment and running var
gen dtreatxrunning`c' = dtreat`c'*drunning`c'
gen dtreatxrunningw`c' = dtreatw`c'*drunningw`c'

*Kernel weights
gen dkernel_tri`c' = ((`dbw' - abs(drunning`c')) /`dbw') * (abs(drunning`c') < `dbw')
gen dkernel_triw`c' = ((`dbw' - abs(drunningw`c')) /`dbw') * (abs(drunningw`c') < `dbw')

*post times treat
gen dxx`c'=post*dtreatw`c'

if `n'==3 |`n'==4 {  
label var dxx`c' "Post $\times$ Below `c'"
}
else{
label var dxx`c' "Post $\times$ Above and in `c'"
}

} 

		* * * * * Pooled DiD Treatment vars * * * * * 

gen treatdid10= (age_dob_m-0.25)<144 & (age_dob_m-0.25)>=120
gen treatdid12= (age_dob_m-0.25)<168 & (age_dob_m-0.25)>=144

replace treatdid10=. if (age_dob_m-0.25)<108 | (age_dob_m-0.25)>180
replace treatdid12=. if (age_dob_m-0.25)<108 | (age_dob_m-0.25)>180

gen treat10didbc= (age_dob_m-0.25)<144 & (age_dob_m-0.25)>=120
gen treat12didbc= (age_dob_m-0.25)<168 & (age_dob_m-0.25)>=144

replace treat10didbc=. if (age_dob_m-0.25)<84 | (age_dob_m-0.25)>192
replace treat12didbc=. if (age_dob_m-0.25)<84 | (age_dob_m-0.25)>192

*post times treats
	gen xxdid10=post*treatdid10
	label var xxdid10 "Post Law $\times$ $\mathbbm{1}$\{$10 \leq $ Age$<12$\}"
	
	gen xxdid12=post*treatdid12
	label var xxdid12 "Post Law $\times$ $\mathbbm{1}$\{$12 \leq $ Age$<14$\}"
	
	gen xxdidr10=post_rev*treatdid10
	label var xxdidr10 "Post Reversal $\times$ $\mathbbm{1}$\{$10 \leq $ Age$<12$\}"
	
	gen xxdidr12=post_rev*treatdid12
	label var xxdidr12 "Post Reversal $\times$ $\mathbbm{1}$\{$12 \leq $ Age$<14$\}"
	
	gen xxdidbc10=post*treat10didbc
	label var xxdidbc10 "Post Law $\times$ $\mathbbm{1}$\{$10 \leq $ Age$<12$\}"
	
	gen xxdidbc12=post*treat12didbc
	label var xxdidbc12 "Post Law $\times$ $\mathbbm{1}$\{$12 \leq $ Age$<14$\}"
	
	gen xxdidbcr10=post_rev*treat10didbc
	label var xxdidbcr10 "Post Reversal $\times$ $\mathbbm{1}$\{$10 \leq $ Age$<12$\}"
	
	gen xxdidbcr12=post_rev*treat12didbc
	label var xxdidbcr12 "Post Reversal $\times$ $\mathbbm{1}$\{$12 \leq $ Age$<14$\}"

			* * * * * Heterogeneity vars * * * * * 

*Interactions b/w running var and post
gen postxurban = post* urban

foreach n in 1 2 3  {
local c=`n'*2+8

gen treat`c'xurban=treat`c'*urban
gen treatw`c'xurban=treatw`c'*urban

*Interactions b/w running var and post and urban
gen postxrunning`c'xurban = postxrunning`c'*urban
gen postxrunningw`c'xurban = postxrunningw`c'*urban

*post times treat times urban

gen xxwu`n'=xxw`n'*urban
if `n'==3 {  
label var xxwu`n' "Post $\times$ $\mathbbm{1}$\{Age$< `c'$\} $\times$ Urban"
}
else{
label var xxwu`n' "Post $\times$ $\mathbbm{1}$\{Age$\geq `c'$\} $\times$ Urban"
}
}

*Interactions with heterogeneity variable
rename abovemed_time het_time
rename abovemed_directdist het_dist
rename abovemed_dist het_ddist
global heterogeneity "het_time het_dist het_ddist"

foreach h in $heterogeneity {
	
	gen postx`h' = post* `h'

gen postxurbanx`h' = post*urban* `h'

foreach n in 1 2 3  {
local c=`n'*2+8

gen running`c'x`h' = running`c'*`h'
gen runningw`c'x`h' = runningw`c'*`h'

gen running`c'xurbanx`h' = running`c'*urban*`h'
gen runningw`c'xurbanx`h' = runningw`c'*urban*`h' 

gen treat`c'x`h'=treat`c'*`h'
gen treatw`c'x`h'=treatw`c'*`h'

gen treat`c'xurbanx`h'=treat`c'*urban*`h'
gen treatw`c'xurbanx`h'=treatw`c'*urban*`h'

gen treatxrunning`c'x`h'= treatxrunning`c'*`h'
gen treatxrunningw`c'x`h' = treatxrunningw`c'*`h'

gen treatxrunning`c'xurbanx`h' = treatxrunning`c'*urban*`h'
gen treatxrunningw`c'xurbanx`h' = treatxrunningw`c'*urban*`h'

gen postxrunning`c'x`h' = postxrunning`c'*`h'
gen postxrunningw`c'x`h' = postxrunningw`c'*`h'

gen postxrunning`c'xurbanx`h' = postxrunning`c'*urban*`h'
gen postxrunningw`c'xurbanx`h' = postxrunningw`c'*urban*`h'

gen xxw`h'`n'=xxw`n'*`h'
if `n'==3 {  
label var xxw`h'`n' "Post $\times$ $\mathbbm{1}$\{Age$< `c'$\} $\times$ Far"
}
else{
label var xxw`h'`n' "Post $\times$ $\mathbbm{1}$\{Age$\geq `c'$\} $\times$ Far"
}

gen xxwu`h'`n'=xxw`n'*urban*`h'
if `n'==3 {  
label var xxwu`h'`n' "Post $\times$ $\mathbbm{1}$\{Age$< `c'$\} $\times$ Urban $\times$ Far"
}
else{
label var xxwu`h'`n' "Post $\times$ $\mathbbm{1}$\{Age$\geq `c'$\} $\times$ Urban $\times$ Far"
}

}
}	

* Municipality categories
 capture drop capital
 gen capital = 1 if muni_name=="Cobija" | muni_name=="Cochabamba" | muni_name=="Trinidad" | muni_name=="Santa Cruz de la Sierra" | muni_name=="Sucre" | muni_name=="Tarija" | muni_name=="Potosí" | muni_name=="Oruro" | muni_name=="La Paz"
 replace capital=0 if capital==.
replace capital=. if muni_name==""

 capture drop mtepsoffices
 
 gen mtepsoffices=1 if muni_name=="Riberalta" | muni_name=="Guayaramerín" | muni_name=="Trinidad"| muni_name=="Cobija" | muni_name=="Oruro" | muni_name=="Monteagudo" | muni_name=="Sucre" | muni_name=="Uyuni" | muni_name=="Villazón"| muni_name=="Tupiza"| muni_name=="Llallagua" | muni_name=="Potosí" | muni_name=="Puerto Suarez" | muni_name=="Villamontes" | muni_name=="Yacuiba" | muni_name=="Bermejo"| muni_name=="Tarija"| muni_name=="Warnes" | muni_name=="Montero" | muni_name=="Camiri" | muni_name=="Santa Cruz de la Sierra" | muni_name=="Villa Tunari" | muni_name=="Cochabamba" | muni_name=="El Alto" | muni_name=="La Paz" 
 replace mtepsoffices=0 if mtepsoffices==.
replace mtepsoffices=. if muni_name==""

 
*Sample of municipalities with less than the median population of indigenous people by municipality
bys cod_secc: gen tagmun=_n
summ p_indigenas if tagmun==1, d
local median_indigenous=`r(p50)' 
drop tagmun
gen lessindigsample= p_indigenas<`median_indigenous'

*Clusters for standard errors
egen age_mo_year=group(age_dob_m year)
 
*Keep sample of children and young adults
preserve
keep if age<21
save "${relabeled_data}/HHsurvey.dta", replace
restore

*Working adults sample
keep if age<65

save "${relabeled_data}/HHsurvey_ad.dta", replace
