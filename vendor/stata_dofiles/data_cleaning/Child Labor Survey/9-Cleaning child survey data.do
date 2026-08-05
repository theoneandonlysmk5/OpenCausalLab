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

/* This .do file cleans both Bolivian Child Labor Survey and merges them in one dataset
*Includes
**1) 2008 child labor survey cleaning
**2) 2016 child labor survey cleaning
**3) Re-weighting process*/

/*==================================================
            0: Program set up
==================================================*/
*Written on STATA 17
drop _all

/*==================================================
            1: 2008 Child labor survey
==================================================*/

********************************************************************************
*								1.1: Child data
********************************************************************************

use "${relabeled_dataCS}/childworkbo_2008.dta", clear

order id number folio
foreach x of varlist number-catchild {
	rename `x' c_`x'
}

label var c_indbelonging "Indigenous"
label var c_nbr_children "Number of children"

gen superficialinj_a= i_1_a 
egen temp = rowtotal(i_2_a i_3_a i_4_a i_5_a i_6_a i_7_a i_8_a i_9_a i_10_a)
gen seriousinj_a= temp > 0
drop temp

label var superficialinj_a "Superficial Injury"
label var seriousinj_a "Serious Injury"

gen dustr_a= r_1_a 
gen exttempsr_a= r_4_a 
gen danginstr_a= r_5_a 
egen temp= rowtotal(r_2_a r_3_a r_6_a r_7_a r_8_a r_9_a r_10_a r_11_a)
gen otherr_a= temp > 0
drop temp

label var dustr_a "Contaminated dust"
label var exttempsr_a "Extreme temperatures"
label var danginstr_a "Dangerous instruments"
label var otherr_a "Other risk"
gen year=2008

tempfile childwork
save `childwork', replace


********************************************************************************
* 								1.2: HH data
********************************************************************************

use "${relabeled_dataCS}/household_2008.dta", clear

*hh head indicator
gen h_hh=(rel_head==1)

*father and mother id
gen f_hh=rel_father
replace f_hh=. if f_hh==997 
gen m_hh=rel_mother
replace m_hh=. if m_hh==997

*fill in father and mother id for everyone in the hh
bys folio: egen father_hh= max(f_hh)
bys folio: egen mother_hh= max(m_hh)
drop f_hh m_hh

*age
gen age_m=age if number==mother_hh
gen age_f=age if number==father_hh
gen age_h=age if h_hh==1

*marital status
gen married_h=1 if (maritalstatus== 2 | maritalstatus== 3) & h_hh==1
replace married_h=0 if (maritalstatus== 1 | maritalstatus== 4 | maritalstatus== 5 | maritalstatus== 6) & h_hh==1

*schooling
gen edu_m=schooling if number==mother_hh
gen edu_f=schooling if number==father_hh
gen edu_h=schooling if h_hh==1

*work dummy 
gen d_worked=  wrk_workedlastweek 
replace d_worked=1 if wrk_impediment_b<10

gen work_m=d_worked if  number==mother_hh
gen work_f=d_worked if number==father_hh
gen work_h=d_worked if h_hh==1

*Industry/sector
gen industry_m=ecoactivity if  number==mother_hh
gen industry_f=ecoactivity if number==father_hh
gen industry_h=ecoactivity if h_hh==1

*Spanish as a first language
gen lang_spa_h=(language_childhood==1)

*hh head gender
gen male_h=gender if h_hh==1

*Position of worker (worker, employee, etc)
gen pos_worker_h=(wrk_jobposition==1) if h_hh==1
gen pos_employee_h=(wrk_jobposition==2) if h_hh==1
gen pos_selfemp_h=(wrk_jobposition==3) if h_hh==1
gen pos_employer_h=(wrk_jobposition==4 | wrk_jobposition==5) if h_hh==1
gen pos_other_h=(wrk_jobposition==6 | wrk_jobposition==7 | wrk_jobposition==8) if h_hh==1

*Indigenous
gen indig_h=(ind_belonging==1) if h_hh==1

*work from home
gen wrkhome_h=(wrk_joblocation==1) if h_hh==1

*Filling in hh head and parent vars for everyone
global hhheadvars "age_  married_ edu_ work_ industry_ male_ pos_worker_  pos_employee_ pos_selfemp_ pos_employer_ pos_other_ wrkhome_ indig_ lang_spa_"
global mothervars "age_  edu_ work_ industry_"
global fathervars "age_ edu_ work_ industry_"

foreach x in $mothervars {
	bys folio: egen `x'mother=max(`x'm)
	drop `x'm
}

foreach x in $fathervars {
	bys folio: egen `x'father=max(`x'f)
	drop `x'f
}

foreach x in $hhheadvars {
	bys folio: egen `x'head=max(`x'h)
	drop `x'h
}


order id number folio
foreach x of varlist number-wrkhome_head {
	rename `x' h_`x'
}


*Household income and children by age group
preserve
use "${relabeled_dataCS}/household_2008.dta", clear

*total members
gen memb=1
bys folio: egen hhsize=total(memb)
drop memb

*women and men
gen gi=1 if gender==0
gen bo=1 if gender==1
bys folio: egen n_female=total(gi)
bys folio: egen n_male=total(bo)
drop gi bo

drop if age>=18

*girls and boys
gen gi=1 if gender==0
gen bo=1 if gender==1
bys folio: egen girls=total(gi)
bys folio: egen boys=total(bo)
drop gi bo

*children's income
gen monthly_wage1 = wrk_mainytotal_a*30 if wrk_mainytotal_b==1
replace monthly_wage1 = wrk_mainytotal_a*4 if wrk_mainytotal_b==2
replace monthly_wage1 = wrk_mainytotal_a*2 if wrk_mainytotal_b==3
replace monthly_wage1 = wrk_mainytotal_a if wrk_mainytotal_b==4
replace monthly_wage1 = wrk_mainytotal_a/2 if wrk_mainytotal_b==5
replace monthly_wage1 = wrk_mainytotal_a/3 if wrk_mainytotal_b==6
replace monthly_wage1 = wrk_mainytotal_a/2 if wrk_mainytotal_b==7
replace monthly_wage1 = wrk_mainytotal_a/6 if wrk_mainytotal_b==8
replace monthly_wage1 = wrk_mainytotal_a/12 if wrk_mainytotal_b==9

gen monthly_wage2 = wrk_mainylab_a*30 if wrk_mainylab_b==1
replace monthly_wage2 = wrk_mainylab_a*4 if wrk_mainylab_b==2
replace monthly_wage2 = wrk_mainylab_a*2 if wrk_mainylab_b==3
replace monthly_wage2 = wrk_mainylab_a if wrk_mainylab_b==4
replace monthly_wage2 = wrk_mainylab_a/2 if wrk_mainylab_b==5
replace monthly_wage2 = wrk_mainylab_a/3 if wrk_mainylab_b==6
replace monthly_wage2 = wrk_mainylab_a/2 if wrk_mainylab_b==7
replace monthly_wage2 = wrk_mainylab_a/6 if wrk_mainylab_b==8
replace monthly_wage2 = wrk_mainylab_a/12 if wrk_mainylab_b==9

gen monthly_wage3 = wrk_mainyafobligations_a*30 if wrk_mainyafobligations_b==1
replace monthly_wage3 = wrk_mainyafobligations_a*4 if wrk_mainyafobligations_b==2
replace monthly_wage3 = wrk_mainyafobligations_a*2 if wrk_mainyafobligations_b==3
replace monthly_wage3 = wrk_mainyafobligations_a if wrk_mainyafobligations_b==4
replace monthly_wage3 = wrk_mainyafobligations_a/2 if wrk_mainyafobligations_b==5
replace monthly_wage3 = wrk_mainyafobligations_a/3 if wrk_mainyafobligations_b==6
replace monthly_wage3 = wrk_mainyafobligations_a/2 if wrk_mainyafobligations_b==7
replace monthly_wage3 = wrk_mainyafobligations_a/6 if wrk_mainyafobligations_b==8
replace monthly_wage3 = wrk_mainyafobligations_a/12 if wrk_mainyafobligations_b==9
 
egen monthly_wage=rowtotal(monthly_wage3 monthly_wage2) 

bys folio: egen child_income=total(monthly_wage)
collapse hhsize child_income girls boys n_female n_male, by(folio)
tempfile ch_income
save `ch_income', replace

*children in age groups
use "${relabeled_dataCS}/household_2008.dta", clear
gen hh_agecat1=(age<7)
gen hh_agecat2=(age>=7 & age<10)
gen hh_agecat3=(age>=10 & age<14)
gen hh_agecat4=(age>=14 & age<18)

collapse (sum) hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4, by(folio)

tempfile ch_ages
save `ch_ages', replace

restore


*Merging

merge m:m id using `childwork'
drop _merge

rename c_folio folio
merge m:1 folio using `ch_income'
drop if _merge==2
drop _merge

merge m:1 folio using `ch_ages'
drop if _merge==2
drop _merge

*removing child from their age group
replace hh_agecat1= hh_agecat1-1 if c_age<7
replace hh_agecat2= hh_agecat2-1 if c_age>=7 & c_age<10
replace hh_agecat3= hh_agecat3-1 if c_age>=10 & c_age<14
replace hh_agecat4= hh_agecat4-1 if c_age>=14 & c_age<18

foreach x in hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4{
	replace `x'=0 if `x'<0
}

*Number of adult men and women
gen adult_women=n_female-girls
gen adult_men=n_male-boys
drop boys girls

*Recoding sector to match child survey
recode c_ecoactivity 0=1 1=3 2=4 4=17 5=6 6=7 7=9 9=17 10=17 12=17 13=17 15=17 16=17 18=17 19=16
gen c_ecoactivity2= c_ecoactivity
replace c_ecoactivity2=0 if d_worked==0

recode h_industry_mother 0=1 1=3 2=4 4=17 5=17 6=7 7=9 9=17 10=17 11=17 12=17 13=17 14=17 15=17 16=17 18=17 19=16 99=17
replace h_industry_mother=0 if h_work_mother==0

recode h_industry_head 0=1 1=3 2=4 4=17 5=6 6=7 7=9 9=17 10=17 11=17 12=17 13=17 14=17 15=17 16=17 18=17 19=16 20=17 99=17
replace h_industry_head=0 if h_work_head==0

label define activity 1 "Agriculture" 3 "Mining" 4 "Manufacturing" 6 "Construction" 7 "Retail" 8 "Accomodation \& Food" 9 "Transport \& Storage" 16 "Domestic Work" 17 "Other"
label values c_ecoactivity activity 
label values c_ecoactivity2 activity 
label values h_industry_mother activity 
label values h_industry_head activity 

*hh head is female
gen h_female_head=h_male_head
recode h_female_head 0=1 1=0

*Forbidden work
gen forbidden=1 if (c_ecoactivity==1 & c_wrk_familymemberjobsearch==0 ) | c_ecoactivity==3 | c_ecoactivity==6 
replace forbidden=0 if forbidden==. 

gen forbidden_a= forbidden
replace forbidden_a=0 if d_worked==0
gen not_forbidden_a=1-forbidden_a
replace not_forbidden_a=0 if d_worked==0

*Hazardous by ILO
egen temp=rowtotal(r_1_a r_2_a r_3_a r_4_a r_5_a r_6_a r_7_a r_8_a r_10_a heavylift_a heavyequip_a night_shift_a oc_2_a)
gen hazardousw_a=temp>0
drop temp

egen temp=rowtotal(r_1_a r_2_a r_3_a r_4_a r_5_a r_6_a r_7_a r_8_a r_10_a heavylift_a heavyequip_a night_shift_a oc_2_a) if d_worked==1
gen hazardousw=temp>0 & temp!=. if d_worked==1
drop temp

egen temp=rowtotal(oc_1_a oc_2_a oc_5_a oc_17_a)
gen hazardousoc_a=temp>0
drop temp

egen temp= rowtotal(hazardousw_a hazardousoc_a)
gen hazardous_a= temp>0
drop temp

*Work for employer
gen workforemployer= c_wrk_employer==4

*Work for family
gen workforfamily= c_wrk_employer==1 | c_wrk_employer==2

*age of the youngest
bys folio: egen minage_months=min(age_survey_m)
gen oldersiblings=(age_survey_m!=minage_months) 

*Chores
rename h_hse_takecare h_hse_babysitting
egen chores= rowtotal(c_hse_groceries c_hse_repair c_hse_cook c_hse_dishes c_hse_babysitting c_hse_woodwater c_hse_other)
replace chores=1 if chores>1 & chores!=.

foreach x in  a b c d e f g {
	gen ch_min_`x'= h_hse_hrs_`x'a*60+ h_hse_hrs_`x'b
}
egen ch_min_total=rowtotal(ch_min_a ch_min_b ch_min_c ch_min_d ch_min_e ch_min_f ch_min_g)

rename ch_min_a ch_min_groceries
rename ch_min_b ch_min_cook 
rename ch_min_c ch_min_dishes 
rename ch_min_d ch_min_laundry 
rename ch_min_e ch_min_babysitting
rename ch_min_f ch_min_repair 
rename ch_min_g ch_min_woodwater 

*labels
label var weekworkhrs_a "Hours worked per week (base=all)"
label var c_age "Age (years)"
label var c_gender "Male"
label var  h_age_mother "Mother's age (years)"
label var h_edu_mother "Mother's years of schooling"
label var h_work_mother "Mother works"
label var h_work_father "Father works"
label var  h_age_head "HH head's age (years)"
label var h_married_head "HH head is married" 
label var h_edu_head "HH head's years of schooling"
label var h_work_head "HH head works"
label var h_male_head "HH head is male"
label var hhsize "HH size"
label var h_pos_worker_head "HH head is a worker"
label var h_pos_employee_head "HH head is an employee"
label var h_pos_selfemp_head "HH head is self-employed"
label var h_pos_employer_head "HH head is an employer"
label var h_pos_other_head "HH head has other position"
label var hh_agecat1 "Children in HH  0-6 y/o"
label var hh_agecat2 "Children in HH  7-9 y/o"
label var hh_agecat3 "Children in HH  10-13 y/o"
label var hh_agecat4 "Children in HH  14-17 y/o"
label var lang_spa_head "HH head speaks Spanish"
label var indig_head "HH head is indigenous"
label var c_ecoactivity "Child industry"
label var h_industry_head "HH head industry"
label var adult_women "Adult women"
label var adult_men "Adult men"
label var forbidden_a "Forbidden work"
label var not_forbidden_a "Non-forbidden work'"
label var hazardousw_a "Hazardous work (ILO)"
label var hazardousoc_a "Hazardous occupation (ILO)"
label var hazardous_a "Hazardous (ILO)"
label var minage_months "Age of youngest child in household"
label var oldersiblings "1 if child is not the youngest sibling"

save "${relabeled_dataCS}/RD_2008.dta", replace

/*==================================================
            2: 2016 Child labor survey
==================================================*/

********************************************************************************
*								2.1: Child data
********************************************************************************

use "${relabeled_dataCS}/childworkbo_2016.dta", clear

order id number folio
foreach x of varlist number-occ_danger2 {
	rename `x' c_`x'
}

label var c_indbelonging "Indigenous"

gen superficialinj_a= i_1_a 
egen temp = rowtotal(i_2_a i_3_a i_4_a i_5_a i_6_a i_7_a i_8_a i_9_a i_10_a)
gen seriousinj_a= temp > 0
drop temp

label var superficialinj_a "Superficial Injury"
label var seriousinj_a "Serious Injury"

gen dustr_a= r_1_a 
gen exttempsr_a= r_4_a 
gen danginstr_a= r_5_a 
egen temp= rowtotal(r_2_a r_3_a r_6_a r_7_a r_8_a r_9_a r_10_a r_11_a)
gen otherr_a= temp > 0
drop temp

label var dustr_a "Contaminated dust"
label var exttempsr_a "Extreme temperatures"
label var danginstr_a "Dangerous instruments"
label var otherr_a "Other risk"

gen year=2016

tempfile childwork
save `childwork', replace


********************************************************************************
* 								2.2: HH data
********************************************************************************

use "${relabeled_dataCS}/household_2016.dta", clear

*hh head indicator
gen h_hh=(rel_head==1)

*father and mother id
gen f_hh=rel_father
replace f_hh=. if f_hh==997 
gen m_hh=rel_mother
replace m_hh=. if m_hh==997

*fill in father and mother id for everyone in the hh
bys folio: egen father_hh= max(f_hh)
bys folio: egen mother_hh= max(m_hh)
drop f_hh m_hh

*age
gen age_m=age if number==mother_hh
gen age_f=age if number==father_hh
gen age_h=age if h_hh==1

*head marital status
gen married_h=1 if (maritalstatus== 2 | maritalstatus== 3) & h_hh==1
replace married_h=0 if (maritalstatus== 1 | maritalstatus== 4 | maritalstatus== 5 | maritalstatus== 6) & h_hh==1

*schooling
gen edu_m=schooling if number==mother_hh
gen edu_f=schooling if number==father_hh
gen edu_h=schooling if h_hh==1
 
*Work dummy
gen d_worked=  wrk_workedlastweek 
replace d_worked=1 if wrk_impediment_b<10

gen work_m=d_worked if  number==mother_hh
gen work_f=d_worked if number==father_hh
gen work_h=d_worked if h_hh==1

*Industry/sector
gen industry_m=ecoactivity if  number==mother_hh
gen industry_f=ecoactivity if number==father_hh
gen industry_h=ecoactivity if h_hh==1

*Spanish as a first language
gen lang_spa_h=(language_childhood==1)

*gender hh head
gen male_h=gender if h_hh==1

*Position of worker (worker, employee, etc)
gen pos_worker_h=(wrk_jobposition==1) if h_hh==1
gen pos_employee_h=(wrk_jobposition==2) if h_hh==1
gen pos_selfemp_h=(wrk_jobposition==3) if h_hh==1
gen pos_employer_h=(wrk_jobposition==4 | wrk_jobposition==5) if h_hh==1
gen pos_other_h=(wrk_jobposition==6 | wrk_jobposition==7 | wrk_jobposition==8) if h_hh==1

*Indigenous
gen indig_h=(ind_belonging_a==1) if h_hh==1

*Work at home
gen wrkhome_h=(wrk_joblocation==1) if h_hh==1

*Filling in hh head and parent vars for everyone
global hhheadvars "age_  married_ edu_ work_ industry_ male_ pos_worker_  pos_employee_ pos_selfemp_ pos_employer_ pos_other_ wrkhome_ indig_ lang_spa_"
global mothervars "age_  edu_ work_ industry_"
global fathervars "age_ edu_ work_ industry_"

foreach x in $mothervars {
	bys folio: egen `x'mother=max(`x'm)
	drop `x'm
}

foreach x in $fathervars {
	bys folio: egen `x'father=max(`x'f)
	drop `x'f
}

foreach x in $hhheadvars {
	bys folio: egen `x'head=max(`x'h)
	drop `x'h
}


order id number folio
foreach x of varlist number-wrkhome_head {
	rename `x' h_`x'
}


*Household income and children by age group
preserve
use "${relabeled_dataCS}/household_2016.dta", clear
*total members
gen members=1
bys folio: egen hhsize=total(members)
drop members

*women and men
gen gi=1 if gender==0
gen bo=1 if gender==1
bys folio: egen n_female=total(gi)
bys folio: egen n_male=total(bo)
drop gi bo

drop if age>=18
*girls and boys
gen gi=1 if gender==0
gen bo=1 if gender==1
bys folio: egen girls=total(gi)
bys folio: egen boys=total(bo)
drop gi bo

*children's income
gen monthly_wage1 = wrk_mainytotal_a*30 if wrk_mainytotal_b==1
replace monthly_wage1 = wrk_mainytotal_a*4 if wrk_mainytotal_b==2
replace monthly_wage1 = wrk_mainytotal_a*2 if wrk_mainytotal_b==3
replace monthly_wage1 = wrk_mainytotal_a if wrk_mainytotal_b==4
replace monthly_wage1 = wrk_mainytotal_a/2 if wrk_mainytotal_b==5
replace monthly_wage1 = wrk_mainytotal_a/3 if wrk_mainytotal_b==6
replace monthly_wage1 = wrk_mainytotal_a/2 if wrk_mainytotal_b==7
replace monthly_wage1 = wrk_mainytotal_a/6 if wrk_mainytotal_b==8
replace monthly_wage1 = wrk_mainytotal_a/12 if wrk_mainytotal_b==9

gen monthly_wage2 = wrk_mainylab_a*30 if wrk_mainylab_b==1
replace monthly_wage2 = wrk_mainylab_a*4 if wrk_mainylab_b==2
replace monthly_wage2 = wrk_mainylab_a*2 if wrk_mainylab_b==3
replace monthly_wage2 = wrk_mainylab_a if wrk_mainylab_b==4
replace monthly_wage2 = wrk_mainylab_a/2 if wrk_mainylab_b==5
replace monthly_wage2 = wrk_mainylab_a/3 if wrk_mainylab_b==6
replace monthly_wage2 = wrk_mainylab_a/2 if wrk_mainylab_b==7
replace monthly_wage2 = wrk_mainylab_a/6 if wrk_mainylab_b==8
replace monthly_wage2 = wrk_mainylab_a/12 if wrk_mainylab_b==9

gen monthly_wage3 = wrk_mainyafobligations_a*30 if wrk_mainyafobligations_b==1
replace monthly_wage3 = wrk_mainyafobligations_a*4 if wrk_mainyafobligations_b==2
replace monthly_wage3 = wrk_mainyafobligations_a*2 if wrk_mainyafobligations_b==3
replace monthly_wage3 = wrk_mainyafobligations_a if wrk_mainyafobligations_b==4
replace monthly_wage3 = wrk_mainyafobligations_a/2 if wrk_mainyafobligations_b==5
replace monthly_wage3 = wrk_mainyafobligations_a/3 if wrk_mainyafobligations_b==6
replace monthly_wage3 = wrk_mainyafobligations_a/2 if wrk_mainyafobligations_b==7
replace monthly_wage3 = wrk_mainyafobligations_a/6 if wrk_mainyafobligations_b==8
replace monthly_wage3 = wrk_mainyafobligations_a/12 if wrk_mainyafobligations_b==9
 
egen monthly_wage=rowtotal(monthly_wage3 monthly_wage2) 

bys folio: egen child_income=total(monthly_wage)
collapse hhsize child_income yhog girls boys n_female n_male, by(folio)

*non-children income 
gen income_adults=yhog-child_income
gen income_adults_pc=income_adults/hhsize
xtile income_q=income_adults_pc,n(5)
tempfile ch_income
save `ch_income', replace

*children in age groups
use "${relabeled_dataCS}/household_2016.dta", clear
gen hh_agecat1=(age<7)
gen hh_agecat2=(age>=7 & age<10)
gen hh_agecat3=(age>=10 & age<14)
gen hh_agecat4=(age>=14 & age<18)

collapse (sum) hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4, by(folio)

tempfile ch_ages
save `ch_ages', replace

restore


*Merging all data

merge m:m id using `childwork'
drop if _merge==1
drop _merge

rename c_folio folio
merge m:1 folio using `ch_income'
drop if _merge==2
drop _merge

merge m:1 folio using `ch_ages'
drop if _merge==2
drop _merge

*removing child from their age group
replace hh_agecat1= hh_agecat1-1 if c_age<7
replace hh_agecat2= hh_agecat2-1 if c_age>=7 & c_age<10
replace hh_agecat3= hh_agecat3-1 if c_age>=10 & c_age<14
replace hh_agecat4= hh_agecat4-1 if c_age>=14 & c_age<18

foreach x in hh_agecat1 hh_agecat2 hh_agecat3 hh_agecat4{
	replace `x'=0 if `x'<0
}

*Number of adult men and women
gen adult_women=n_female-girls
gen adult_men=n_male-boys
drop boys girls

*Recoding sector to match child survey
recode c_ecoactivity 0=1 1=3 2=4 4=17 5=6 6=7 7=9 9=17 10=17 12=17 13=17 15=17 16=17 18=17 19=16
gen c_ecoactivity2= c_ecoactivity
replace c_ecoactivity2=0 if d_worked==0

recode h_industry_mother 0=1 1=3 2=4 4=17 5=17 6=7 7=9 9=17 10=17 11=17 12=17 13=17 14=17 15=17 16=17 18=17 19=16 99=17
replace h_industry_mother=0 if h_work_mother==0

recode h_industry_head 0=1 1=3 2=4 4=17 5=6 6=7 7=9 9=17 10=17 11=17 12=17 13=17 14=17 15=17 16=17 18=17 19=16 20=17 99=17
replace h_industry_head=0 if h_work_head==0

label define activity 1 "Agriculture" 3 "Mining" 4 "Manufacturing" 6 "Construction" 7 "Retail" 8 "Accomodation \& Food" 9 "Transport \& Storage" 16 "Domestic Work" 17 "Other"
label values c_ecoactivity activity 
label values c_ecoactivity2 activity 
label values h_industry_mother activity 
label values h_industry_head activity 

*hh head is female
gen h_female_head=h_male_head
recode h_female_head 0=1 1=0

*Forbidden work
gen forbidden=1 if (c_ecoactivity==1 & wrk_family==0 ) | c_ecoactivity==3 | c_ecoactivity==6 
replace forbidden=0 if forbidden==. 

gen forbidden_a= forbidden
replace forbidden_a=0 if d_worked==0
gen not_forbidden_a=1-forbidden_a
replace not_forbidden_a=0 if d_worked==0

*Hazardous by ILO
egen temp=rowtotal(r_1_a r_2_a r_3_a r_4_a r_5_a r_6_a r_7_a r_8_a r_10_a heavylift_a heavyequip_a night_shift_a oc_2_a)
gen hazardousw_a=temp>0
drop temp

egen temp=rowtotal(r_1_a r_2_a r_3_a r_4_a r_5_a r_6_a r_7_a r_8_a r_10_a heavylift_a heavyequip_a night_shift_a oc_2_a) if d_worked==1
gen hazardousw=temp>0 & temp!=. if d_worked==1
drop temp

egen temp=rowtotal(oc_1_a oc_2_a oc_5_a oc_17_a)
gen hazardousoc_a=temp>0
drop temp

egen temp= rowtotal(hazardousw_a hazardousoc_a)
gen hazardous_a= temp>0
drop temp

*Consent responses
gen consenty= c_wrk_permission
recode consenty 99=0 

gen consentn= c_wrk_permission
recode consentn 1=0 99=0 0=1

gen consentdk= c_wrk_permission
recode consentdk 1=0 99=1 

*Consent (permit needed)
gen needed_consent=consent if c_age>=10 & c_age<=11 & d_selfemployed==1
replace needed_consent=consent if (c_age>=12 & c_age<=17) & (d_selfemployed==1 | c_wrk_jobposition==1 )
gen needed_consent_a=0 if d_worked==0

*Permit needed
gen permitres=c_wrk_permission
recode permitres 99=1 0=1
gen need_permit= permitres
replace need_permit=0 if (c_age>=10 & c_age<=11 & d_selfemployed==1) | ((c_age>=12 & c_age<=17) & (d_selfemployed==1 | c_wrk_jobposition==1 )) 
replace need_permit=. if c_age<10


*age of the youngest
bys folio: egen minage_months=min(age_survey_m)
gen oldersiblings=(age_survey_m!=minage_months) 

*Chores
egen chores= rowtotal(c_hse_groceries c_hse_repair c_hse_cook c_hse_dishes c_hse_babysitting c_hse_woodwater c_hse_other)
replace chores=1 if chores>1 & chores!=.

foreach x in  groceries repair cook dishes laundry babysitting woodwater {
	gen ch_min_`x'= c_hse_hrs_`x'_h*60+ c_hse_hrs_`x'_m
}
egen ch_min_total=rowtotal(ch_min_groceries ch_min_repair ch_min_cook ch_min_dishes ch_min_laundry ch_min_babysitting ch_min_woodwater)

*labels
label var weekworkhrs_a "Hours worked per week (base=all)"
label var c_age "Age (years)"
label var c_gender "Male"
label var  h_age_mother "Mother's age (years)"
label var h_edu_mother "Mother's years of schooling"
label var h_work_mother "Mother works"
label var h_work_father "Father works"
label var income_adults "Income"
label var  h_age_head "HH head's age (years)"
label var h_married_head "HH head is married" 
label var h_edu_head "HH head's years of schooling"
label var h_work_head "HH head works"
label var h_male_head "HH head is male"
label var hhsize "HH size"
label var income_q "Income quintiles"
label var h_pos_worker_head "HH head is a worker"
label var h_pos_employee_head "HH head is an employee"
label var h_pos_selfemp_head "HH head is self-employed"
label var h_pos_employer_head "HH head is an employer"
label var h_pos_other_head "HH head has other position"
label var hh_agecat1 "Children in HH  0-6 y/o"
label var hh_agecat2 "Children in HH  7-9 y/o"
label var hh_agecat3 "Children in HH  10-13 y/o"
label var hh_agecat4 "Children in HH  14-17 y/o"
label var lang_spa_head "HH head speaks Spanish"
label var indig_head "HH head is indigenous"
label var c_ecoactivity "Child industry"
label var h_industry_head "HH head industry"
label var adult_women "Adult women"
label var adult_men "Adult men"
label var forbidden_a "Forbidden work"
label var not_forbidden_a "Non-forbidden work'"
label var hazardousw_a "Hazardous work (ILO)"
label var hazardousoc_a "Hazardous occupation (ILO)"
label var hazardous_a "Hazardous (ILO)"
label var consenty "Respond yes to consent"
label var consentn "Respond no to consent"
label var consentdk "Respond don't know to consent"
label var needed_consent "Consent for children who need permit"
label var needed_consent_a "Consent for children who need permit (all)"
label var need_permit "Proportion of children who respond to permit out of the ones who needed it"
label var minage_months "Age of youngest child in household"
label var oldersiblings "1 if child is not the youngest sibling"
label var chores "Did any chores last week"

save "${relabeled_dataCS}/RD_2016.dta", replace


/*==================================================
            3: Re-weighting and Diff in Disc variables
==================================================*/

use "${relabeled_dataCS}/RD_2008.dta", clear
 

 gen post=0
 
 set seed 794758
 gen aux= runiform() if age_survey_m>=108 & age_survey_m<=180 
 gen sample=aux<=0.7 if age_survey_m>=108 & age_survey_m<=180
 drop aux 
  append using "${relabeled_dataCS}/RD_2016.dta", force
  
  replace post=1 if post==.
  
 set seed 794758
 gen aux= runiform() if post==1 & age_survey_m>=108 & age_survey_m<=180
 replace sample=aux<=0.7 if post==1 & age_survey_m>=108 & age_survey_m<=180
 drop aux
  
  probit post  h_area c_gender hhsize h_age_head h_edu_head h_male_head indig_head if sample==1 
  predict probpost, pr
  
  *diff in disc vars
  foreach n in 1 2 3  {
local c=`n'*2+8


*create running variable
gen running`c'=age_survey_m-(`c'*12)
gen runningy`c'=(age_survey_m-12)-(`c'*12)

*bandwidth
local bw=12

*sample to estimate 
gen s`c'=(abs(running`c') <= `bw')
gen sy`c'=(abs(runningy`c') <= `bw')

*treatment variable
if `n'==3 {  
gen treat`c' = running`c' < 0
replace treat`c'=. if running`c'==.
label var treat`c' "$\mathbbm{1}$\{Age$< `c'$\}"
}
else{
    gen treat`c' = running`c' >= 0
	replace treat`c'=. if running`c'==.
label var treat`c' "$\mathbbm{1}$\{Age$\geq `c'$\}"
} 

if `n'==3 {  
gen treaty`c' = runningy`c' < 0
replace treaty`c'=. if runningy`c'==.
label var treaty`c' "$\mathbbm{1}$\{Age$< `c'$\}"
}
else{
    gen treaty`c' = runningy`c' >= 0
	replace treaty`c'=. if runningy`c'==.
label var treaty`c' "$\mathbbm{1}$\{Age$\geq `c'$\}"
} 


*interactions b/w treatment and running var
gen treatxrunning`c' = treat`c'*running`c'
gen treatxrunningy`c' = treaty`c'*runningy`c'


*Kernel weights
gen kernel_tri`c' = ((`bw' - abs(running`c')) /`bw') * (abs(running`c') <= `bw')
gen kernel_triy`c' = ((`bw' - abs(runningy`c')) /`bw') * (abs(runningy`c') <= `bw')


*post times treat
gen xx`n'=post*treat`c'
gen xxy`n'=post*treaty`c'


if `n'==3 {  
label var xx`n' "Post $\times$ $\mathbbm{1}$\{Age$< `c'$\} "
}
else{
label var xx`n' "Post $\times$ $\mathbbm{1}$\{Age$\geq `c'$\} "
} 


*Weights
replace kernel_tri`c' = kernel_tri`c'/(1-probpost) if post==0
replace kernel_triy`c' = kernel_triy`c'/(1-probpost) if post==0
replace kernel_tri`c' = kernel_tri`c'/(probpost) if post==1
replace kernel_triy`c' = kernel_triy`c'/(probpost) if post==1

}


gen weights = 1/(1-probpost) if post==0
replace weights = 1/probpost if post==1
label var post "Post"

*********************Difference in Discontinuity vars*********************

*Running variable for survey date and a year before the survey date recall
**14 y/o cutoff is multiplied by -1 to account for the treatment group being to the left of the threshold
gen running=running10 if s10==1
replace running=running12 if s12==1
replace running=-running14 if s14==1

gen runningy=runningy10 if sy10==1
replace runningy=runningy12 if sy12==1
replace runningy=-runningy14 if sy14==1

*Treatment variable for survey date and a year before the survey date recall
gen treat=treat10 if s10==1
replace treat=treat12 if s12==1
replace treat=treat14 if s14==1

gen treaty=treaty10 if sy10==1
replace treaty=treaty12 if sy12==1
replace treaty=treaty14 if sy14==1

*Treatment and running variable interaction for survey date and a year before the survey date recall
gen treatxrunning=treatxrunning10 if s10==1
replace treatxrunning=treatxrunning12 if s12==1
replace treatxrunning=-treatxrunning14 if s14==1

gen treatxrunningy=treatxrunningy10 if sy10==1
replace treatxrunningy=treatxrunningy12 if sy12==1
replace treatxrunningy=-treatxrunningy14 if sy14==1

*Triangular kernel for survey date and a year before the survey date recall
gen kernel_tri=kernel_tri10 if s10==1
replace kernel_tri=kernel_tri12 if s12==1
replace kernel_tri=kernel_tri14 if s14==1

gen kernel_triy=kernel_triy10 if sy10==1
replace kernel_triy=kernel_triy12 if sy12==1
replace kernel_triy=kernel_triy14 if sy14==1

*Variable of interest for survey date and a year before the survey date recall
gen xx= post*treat
gen xxy= post*treaty

*Sample for survey date and a year before the survey date recall
gen ss=s10|s12|s14
gen ssy=sy10|sy12|sy14


************************ Robustness DDisc vars**********************************

*Quadratic variables
gen running2 = running^2
gen treatxrunning2 = treat*running*running
gen runningy2 = runningy^2
gen treatxrunningy2 = treaty*runningy*runningy

*bandwidth
foreach bw in 6 12 24{

*sample to estimate 
gen s_`bw'=(abs(running) <= `bw')
gen sy_`bw'=(abs(runningy) <= `bw')

gen ds_`bw'=(abs(running) <= `bw') & (abs(running) > 1)
gen dsy_`bw'=(abs(runningy) <= `bw') & (abs(runningy) > 1)

*Kernel weights
gen kernel_tri_`bw' = ((`bw' - abs(running)) /`bw') * (abs(running) <= `bw')
gen kernel_triy_`bw' = ((`bw' - abs(runningy)) /`bw') * (abs(runningy) <= `bw')
replace kernel_tri_`bw' = kernel_tri_`bw'/(1-probpost) if post==0
replace kernel_triy_`bw' = kernel_triy_`bw'/(1-probpost) if post==0
replace kernel_tri_`bw' = kernel_tri_`bw'/(probpost) if post==1
replace kernel_triy_`bw' = kernel_triy_`bw'/(probpost) if post==1
}

*Clusters for standard errors
egen age_mo_year=group(age_survey_m year)

*Heterogeneity measure

*gen cod_secc= c_mun
gen co_mun = c_mun - c_depto*1000 - c_prov*10 if year==2008
gen cod_secc= c_depto*10000+c_prov*100+co_mun if year==2008
replace cod_secc= c_mun if year==2016

merge m:1 cod_secc using "${other_relabeled}/travel_capitales_tomerge.dta"
drop if _merge==2
drop _merge

rename abovemed_time het_time
rename abovemed_directdist het_dist
rename abovemed_dist het_ddist

global heterogeneity "het_time"

gen urban=c_area

** INTERACTIONS **

*Interactions b/w running var and post
gen postxurban = post* urban

*Interactions b/w treatment and urban
gen treatxurban=treat*urban
gen treatyxurban=treaty*urban

*interactions b/y treatment and running var with urban
gen treatxrunningxurban = treatxrunning*urban
gen treatxrunningyxurban = treatxrunningy*urban

*Interactions b/y running var and post
gen postxrunning = post*running
gen postxrunningy = post*runningy

gen postxrunningxurban = postxrunning*urban
gen postxrunningyxurban = postxrunningy*urban

*Leah added this ---> double check!
gen xxu=xx*urban
gen xxyu=xxy*urban

*Interactions with heterogeneity var

foreach h in $heterogeneity {
	
gen postx`h' = post* `h'

gen postxurbanx`h' = post*urban* `h'

gen runningx`h' = running*`h'
gen runningyx`h' = runningy*`h'

gen runningxurbanx`h' = running*urban*`h'
gen runningyxurbanx`h' = runningy*urban*`h' 

gen treatx`h'=treat*`h'
gen treatyx`h'=treaty*`h'

gen treatxurbanx`h'=treat*urban*`h'
gen treatyxurbanx`h'=treaty*urban*`h'

gen treatxrunningx`h'= treatxrunning*`h'
gen treatxrunningyx`h' = treatxrunningy*`h'

gen treatxrunningxurbanx`h' = treatxrunning*urban*`h'
gen treatxrunningyxurbanx`h' = treatxrunningy*urban*`h'

gen postxrunningx`h' = postxrunning*`h'
gen postxrunningyx`h' = postxrunningy*`h'

gen postxrunningxurbanx`h' = postxrunning*urban*`h'
gen postxrunningyxurbanx`h' = postxrunningy*urban*`h'

gen xx`h'=xx*`h'
gen xxy`h'=xxy*`h'

gen xxu`h'=xx*urban*`h'
gen xxyu`h'=xxy*urban*`h'

}

save "${relabeled_dataCS}/RW_child_labor_survey.dta", replace




