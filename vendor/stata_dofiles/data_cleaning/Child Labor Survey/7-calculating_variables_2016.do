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

/* This .do file cleans the ENNA 2016 for the children and household (Bolivian Child Labor Survey) */

/*==================================================
            0: Program set up
==================================================*/
*Written on STATA 17
drop _all

/*==================================================
            1: Child Survey
==================================================*/

use "${relabeled_dataCS}/childworkbo_2016.dta", replace

**Creating variables for table

*Child labor 
gen d_worked=(wrk_workedlastweek==1 | (wrk_dedicateonehour>=1 & wrk_dedicateonehour<9) | wrk_impediment_a==1)

*Children who work and are paid either in cash money or in kind
gen d_paid=(wrk_typepayment>=1 & wrk_typepayment<=3) if d_worked==1	
gen d_paid_a=(wrk_typepayment>=1 & wrk_typepayment<=3) 

	
*Children who are selfemployed
gen d_selfemployed=(wrk_jobposition==4) if d_worked==1
gen d_selfemployed_a=(wrk_jobposition==4) 

*Children who work as apprentince 
gen d_apprentice=(wrk_jobposition==5) if d_worked==1

*Weekly worked hours
egen weekworkhrs_a=rowtotal(wrk_hrs_aa wrk_hrs_ba wrk_hrs_ca wrk_hrs_da wrk_hrs_ea wrk_hrs_fa wrk_hrs_ga)
egen weekworkhrs_wrkchild=rowtotal(wrk_hrs_aa wrk_hrs_ba wrk_hrs_ca wrk_hrs_da wrk_hrs_ea wrk_hrs_fa wrk_hrs_ga) if d_worked==1

*Child works more than 30 hours a week

gen d_30hrsweek=(weekworkhrs_wrkchild>30) if d_worked==1
label var d_30hrsweek "Works more than 30 hrs per week"
gen d_30hrsweek_a=(weekworkhrs_a>30) 
label var d_30hrsweek_a "Works more than 30 hrs per week (Base=all)"


*Weekly average number of days that children work

foreach var in wrk_hrs_aa wrk_hrs_ba wrk_hrs_ca wrk_hrs_da wrk_hrs_ea wrk_hrs_fa wrk_hrs_ga{
	gen aux_`var'=(`var'>=1 & `var'<=20)
}
egen daysworked_a=rowtotal(aux_*)
egen daysworked_wrkchild=rowtotal(aux_*) if d_worked==1
drop aux_*

*Hours worked on an average day
gen dayhrsworked_a=weekworkhrs_a/daysworked_a if weekworkhrs_a!=. & daysworked_a!=.
replace dayhrsworked_a=0 if dayhrsworked_a==.
gen dayhrsworked_wrkchild=weekworkhrs_wrkchild/daysworked_wrkchild  if weekworkhrs_wrkchild!=. & daysworked_wrkchild!=. & d_worked==1

*Monthly income

gen ylab=wrk_mainylab_a *30 if wrk_mainylab_b==1 & d_worked==1
replace ylab=wrk_mainylab_a *4.33 if wrk_mainylab_b==2 & d_worked==1
replace ylab=wrk_mainylab_a *2 if wrk_mainylab_b==3 & d_worked==1
replace ylab=wrk_mainylab_a  if wrk_mainylab_b==4 & d_worked==1
replace ylab=wrk_mainylab_a /3 if wrk_mainylab_b==6 & d_worked==1

gen ylab_a=ylab
replace ylab_a=0 if ylab==.

gen usd_ylab=ylab/6.96

*Hourly wage
gen aux1=ylab/30
gen hrywage=aux1/dayhrsworked_wrkchild if d_worked==1
drop aux1

gen usd_hrywage=hrywage/6.96

*Type of work
gen wrk_outhome = (wrk_joblocation>2) if d_worked==1
label var wrk_outhome "Child works outside of their home"

*Work for family
gen wrk_family= (wrk_jobposition==1) if d_worked==1
label var wrk_family "Child works for family"

gen wrk_family_a= (wrk_jobposition==1) 
label var wrk_family_a "Child works for family"


*Years of education

gen schooling=.
replace schooling=0 if edu_lastgradeapproved_a>=1 & edu_lastgradeapproved_a<=3 
replace schooling=0 if edu_lastgradeapproved_a>=11 & edu_lastgradeapproved_a<=17  //No formal education
replace schooling=0+ edu_lastgradeapproved_b  if edu_lastgradeapproved_a==4 & edu_lastgradeapproved_b!=. //Basic
replace schooling=5+ edu_lastgradeapproved_b  if edu_lastgradeapproved_a==5 & edu_lastgradeapproved_b!=. //Intermediate
replace schooling=8+ edu_lastgradeapproved_b  if edu_lastgradeapproved_a==6 & edu_lastgradeapproved_b!=. //Medium
replace schooling=0+ edu_lastgradeapproved_b  if edu_lastgradeapproved_a==7 & edu_lastgradeapproved_b!=. //Primary
replace schooling=8+ edu_lastgradeapproved_b  if edu_lastgradeapproved_a==8 & edu_lastgradeapproved_b!=. //Secondary
replace schooling=0+ edu_lastgradeapproved_b  if edu_lastgradeapproved_a==9 & edu_lastgradeapproved_b!=. //Primary
replace schooling=6+ edu_lastgradeapproved_b  if edu_lastgradeapproved_a==10 & edu_lastgradeapproved_b!=. //Secondary
replace schooling=12+ edu_lastgradeapproved_b if edu_lastgradeapproved_a==18 & edu_lastgradeapproved_b!=. //Teacher superior school
replace schooling=12+ edu_lastgradeapproved_b if (edu_lastgradeapproved_a>=23 & edu_lastgradeapproved_a<=25) & edu_lastgradeapproved_b!=. //Technics, military and police
replace schooling=15 if schooling>15 & (edu_lastgradeapproved_a>=23 & edu_lastgradeapproved_a<=25) & edu_lastgradeapproved_b!=.
replace schooling=15 if schooling>15 & edu_lastgradeapproved_a==18 & edu_lastgradeapproved_b!=.
replace schooling=12+edu_lastgradeapproved_b if edu_lastgradeapproved_a==19 & edu_lastgradeapproved_b!=. //University
replace schooling=12+edu_lastgradeapproved_b if edu_lastgradeapproved_a==20 & edu_lastgradeapproved_b!=. //Diploma
replace schooling=17 if schooling>15 & edu_lastgradeapproved_a==19 & edu_lastgradeapproved_b!=.
replace schooling=17 if schooling>15 & edu_lastgradeapproved_a==20 & edu_lastgradeapproved_b!=.
replace schooling=17+edu_lastgradeapproved_b if edu_lastgradeapproved_a==21 & edu_lastgradeapproved_b!=. //Master degree
replace schooling=19 if schooling>19 & edu_lastgradeapproved_a==21 & edu_lastgradeapproved_b!=.
replace schooling=19+edu_lastgradeapproved_b if edu_lastgradeapproved_a==22 & edu_lastgradeapproved_b!=. //Doctorate Degree
replace schooling=24 if schooling>24 & edu_lastgradeapproved_a==22 & edu_lastgradeapproved_b!=.
replace schooling=12 if schooling>=26 & edu_lastgradeapproved_a<=27


*Night shift
gen d_nightshift=(edu_shift==3) if edu_attendance==1
label var d_nightshift "Studies in night shift"

*Attends school
gen d_attendschool= (edu_attendance==1)
label var d_attendschool "Attends school"

*Risks and hazards
gen d_danger=(occ_danger1==1|occ_danger2==1) 
gen d_minage=(occ_minage==1) 
gen d_wrktime=(occ_wrktime==1) 
gen d_wnightshift=(occ_nightshift==1) 
gen d_riskedu=(occ_riskedu==1)

label var d_danger "Dangerous job or activity"
label var d_minage "Job under minimum age"
label var d_wrktime "Work for more than 40 hrs a week"
label var d_wnightshift "Work in night shifts"
label var d_riskedu "Work risks education"

gen d_workinjury=(wrk_jobinjury_a>=1 & wrk_jobinjury_a<11 | wrk_jobinjury_b>=1 & wrk_jobinjury_b<11 | wrk_jobinjury_c>=1 & wrk_jobinjury_c<11)
label var d_workinjury "Work injury"

gen d_risks=(wrk_risks_a>=1 & wrk_risks_a<12 | wrk_risks_b>=1 & wrk_risks_b<12 | wrk_risks_c>=1 & wrk_risks_c<12)
label var d_risks "Risk at work"

gen d_violence=(wrk_violence_a>=1 & wrk_violence_a<10 | wrk_violence_b>=1 & wrk_violence_b<10 | wrk_violence_c>=1 & wrk_violence_c<10)
label var d_violence "Violence at work"

gen heavylift=(wrk_heavylift==1) if d_worked==1 & wrk_heavylift!=.
gen heavyequip=(wrk_dangerequipment_a==1) if d_worked==1 & wrk_dangerequipment_a!=.
label var heavylift "Heavy lifting"
label var heavyequip "Heavy equipment"

gen heavylift_a=(wrk_heavylift==1) 
gen heavyequip_a=(wrk_dangerequipment_a==1)
label var heavylift_a "Heavy lifting"
label var heavyequip_a "Heavy equipment"

recode wrk_risks_a (99=.) 
gen risks=(wrk_risks_a>=1 & wrk_risks_a<=11) if d_worked==1 & wrk_risks_a!=.
gen risks_a=(wrk_risks_a>=1 & wrk_risks_a<=11) 
label var risks "Risk"
label var risks_a "Risk"

local lab1 "Dirt or contaminated dust"
local lab2 "Fire, gas, flames"
local lab3 "Loud noise or vibrations"
local lab4 "Extreme heat or cold"
local lab5 "Dangerous instruments (knives, explosives, etc)"
local lab6 "Underground work"
local lab7 "Work at height"
local lab8 "Work in water"
local lab9 "Darkness, isolation or without ventilation"
local lab10 "Chemical products (Pesticide, glue)"
local lab11 "Other"

forvalues i= 1(1)11{
gen r_`i'=(wrk_risks_a==`i') if d_worked==1 & wrk_risks_a!=.
label var r_`i' "`lab`i''"
gen r_`i'_a=(wrk_risks_a==`i')
label var r_`i'_a "`lab`i''"
}

egen risks_s_a=rowtotal(r_1_a r_2_a r_3_a r_4_a r_5_a r_6_a r_7_a r_8_a r_9_a r_10_a r_11_a) 
egen risks_s=rowtotal(r_1_a r_2_a r_3_a r_4_a r_5_a r_6_a r_7_a r_8_a r_9_a r_10_a r_11_a) if d_worked==1 & wrk_risks_a!=.

local lab1 "Superficial injuries or bites, blisters, etc"
local lab2 "Fractures or mutilations"
local lab3 "Dislocation or distention"
local lab4 "Burns, scalds or freezing"
local lab5 "Respiratory problems"
local lab6 "Sight problems"
local lab7 "Skin injuries"
local lab8 "Stomach problems, diarrhea or chemical poisoning"
local lab9 "Exhaustion for tasks intensity" 
local lab10 "Other"

gen injury=(wrk_jobinjury_a>=1 & wrk_jobinjury_a<=10) if d_worked==1 & wrk_jobinjury_a!=.
gen injury_a=(wrk_jobinjury_a>=1 & wrk_jobinjury_a<=10) 
label var injury "Injury"
label var injury_a "Injury"

forvalues i= 1(1)10{
gen i_`i'=(wrk_jobinjury_a==`i') if d_worked==1 & wrk_jobinjury_a!=.
label var i_`i' "`lab`i''"
gen i_`i'_a=(wrk_jobinjury_a==`i')
label var i_`i'_a "`lab`i''"
}
egen injury_s_a=rowtotal(i_1_a i_2_a i_3_a i_4_a i_5_a i_6_a i_7_a i_8_a i_9_a i_10_a) 
egen injury_s=rowtotal(i_1_a i_2_a i_3_a i_4_a i_5_a i_6_a i_7_a i_8_a i_9_a i_10_a) if d_worked==1 & wrk_jobinjury_a!=.


local lab1 "Being yelled, insulted, threatened often"
local lab2 "Discriminated"
local lab3 "Being physically abused (beaten, hurt)"
local lab4 "Impeded from eaten"
local lab5 "Impeded from getting paid"
local lab6 "Being isolated"
local lab7 "Being forbidden to leave"
local lab8 "Being forced to dress uncomfortably"
local lab9 "Sexual abused or molested"
local lab10 "Other"

recode  wrk_violence_a (9=10) (8=9) (7=8) (10=11) (2=.) 
gen violence=(wrk_violence_a>=1 & wrk_violence_a<=10) if d_worked==1 & wrk_violence_a!=.
gen violence_a=(wrk_violence_a>=1 & wrk_violence_a<=10)
label var violence "Violence"
label var violence_a "Violence"

forvalues i= 1(1)10{
gen v_`i'=(wrk_violence_a==`i') if d_worked==1 & wrk_violence_a!=.
label var v_`i' "`lab`i''"
gen v_`i'_a=(wrk_violence_a==`i')
label var v_`i'_a "`lab`i''"
}

egen violence_s_a=rowtotal(v_1_a v_2_a v_3_a v_4_a v_5_a v_6_a v_7_a v_8_a v_9_a v_10_a)
egen violence_s=rowtotal(v_1_a v_2_a v_3_a v_4_a v_5_a v_6_a v_7_a v_8_a v_9_a v_10_a) if d_worked==1 & wrk_violence_a!=.

gen sh1=(wrk_shift==1) if d_worked==1 & wrk_shift!=.
gen sh2=(wrk_shift==2) if d_worked==1 & wrk_shift!=.
gen sh3=(wrk_shift==3) if d_worked==1 & wrk_shift!=.
gen sh1_a=(wrk_shift==1)
gen sh2_a=(wrk_shift==2)
gen sh3_a=(wrk_shift==3)

label var sh1 "Day Shift"
label var sh2 "Night Shift"
label var sh3 "Mixed shift"
label var sh1_a "Day Shift"
label var sh2_a "Night Shift"
label var sh3_a "Mixed shift"

*Under age
gen under_age=(age<14) if d_worked==1 
label var under_age "Under age"
gen under_age_a=(age<14) 
label var under_age_a "Under age"

*Working over 40 hrs
gen overhrs=(weekworkhrs_a>40) if d_worked==1 & weekworkhrs_a!=.
label var overhrs "More than 40 hrs"
gen overhrs_a=(weekworkhrs_a>40) 
label var overhrs_a "More than 40 hrs"

*Night shifts
gen night_shift=(wrk_shift==2 | wrk_shift==3) if wrk_shift!=. & d_worked==1
gen night_shift_a=(wrk_shift==2 | wrk_shift==3) 
label var night_shift "Night shift"
label var  night_shift_a "Night shift"

*Being prevented of assisting to school because of work
gen missedscho=(edu_reasnotenrol>=7 & edu_reasnotenrol<=11) if d_worked==1 & edu_reasnotenrol!=.
gen missedscho_a=(edu_reasnotenrol>=7 & edu_reasnotenrol<=11) 
label var missedscho "Schooling risk"
label var missedscho_a "Schooling risk"

*sindicate
gen sindicate=(rgh_syndic==1) if rgh_syndic!=. & d_worked==1
gen sindicate_a=(rgh_syndic==1)
label var sindicate "Labor union"
label var sindicate_a "Labor union"

*consent
gen consent=(wrk_agreejob==1) if d_worked==1 & wrk_agreejob!=.
gen consent_a=(wrk_agreejob==1) 
label var consent "Consent"
label var consent_a "Consent" 

*Types of work table
local lab1 "Worker or family assistant"
local lab2 "Employee"
local lab3 "Employer with salary"
local lab4 "Employer without salary"
local lab5 "Self employed"
local lab6 "Production cooperative"
local lab7 "Apprentice without remuneration"
local lab8 "Home worker"

gen jobposition=.
replace jobposition=1 if wrk_jobposition==1
replace jobposition=2 if wrk_jobposition==2
replace jobposition=3 if wrk_jobposition==3
replace jobposition=4 if wrk_jobposition==5
replace jobposition=5 if wrk_jobposition==4
replace jobposition=6 if wrk_jobposition==6
replace jobposition=7 if wrk_jobposition==7
replace jobposition=8 if wrk_jobposition>=8 & wrk_jobposition<=10
replace jobposition=. if d_worked==0


forvalues i= 1(1)8{
gen j_`i'=(jobposition==`i') if d_worked==1 & jobposition!=.
label var j_`i' "`lab`i''"
gen j_`i'_a=(jobposition==`i')
label var j_`i'_a "`lab`i''"
}

*reason to work
gen rwrk_ownmoney_a= wrk_reastowork_a==1 
gen rwrk_homeincome_a= wrk_reastowork_a==2 
gen rwrk_selfgrowth_a= wrk_reastowork_a==3 | wrk_reastowork_a==4 
gen rwrk_other_a= wrk_reastowork_a==5 | wrk_reastowork_a==6 

*who would it harm if stopped working
gen hswrk_self_a=wrk_stopworkharm==1
gen hswrk_family_a=wrk_stopworkharm==2
gen hswrk_noharm_a=wrk_stopworkharm==3

*benefit from work or chores
gen ben_wrkch_skills_a=rgh_selfbenefit_a==1 
gen ben_wrkch_personaldev_a= rgh_selfbenefit_a==2 | rgh_selfbenefit_a==3
gen ben_wrkch_money_a=rgh_selfbenefit_a==4

*House chores
label var hse_groceries "Buy groceries"
label var hse_repair "Repair equipment" 
label var hse_cook "Cook"
label var hse_dishes "Do dishes or clean"
label var hse_laundry "Do laundry"
label var hse_babysitting "Babysit or care for the elderly"
label var hse_woodwater "Pick up wood or water"

global chores "groceries repair cook dishes laundry babysitting woodwater"

foreach chore in $chores{
	
	gen hse_t_`chore'= hse_hrs_`chore'_h + (hse_hrs_`chore'_m/60)
	
	label var hse_t_`chore' "Time spent in ``chore''"
}

*hh chore risk

recode hse_risks_a hse_risks_b hse_risks_c (12=.) 
gen hse_risks=(hse_risks_a>=1 & hse_risks_a<=11) | (hse_risks_b>=1 & hse_risks_b<=11) | (hse_risks_c>=1 & hse_risks_c<=11) 
label var hse_risks "Risk in HH chores"

* hh chore dangerous equipment
rename hse_dangerequipment_a hse_dangerequipment

*hh chore injury
recode hse_injure_a hse_injure_b hse_injure_c (11=.) 
gen hse_injury=(hse_injure_a>=1 & hse_injure_a<=10) | (hse_injure_b>=1 & hse_injure_b<=10) | (hse_injure_c>=1 & hse_injure_c<=10) 
label var hse_injury "Injury in HH chores"

*hh chores violence
gen hse_violence=(hse_violence_a>=1 & hse_violence_a<=10) |(hse_violence_b>=1 & hse_violence_b<=10) | (hse_violence_c>=1 & hse_violence_c<=10)  
label var hse_violence "Violence in HH chores"


*sectors

gen ecoactivity_h=.
replace ecoactivity_h=1 	if ecoactivity==0
replace ecoactivity_h=2 	if ecoactivity==1
replace ecoactivity_h=3		if ecoactivity==2
replace ecoactivity_h=4		if ecoactivity==3
replace ecoactivity_h=4		if ecoactivity==4
replace ecoactivity_h=5		if ecoactivity==5
replace ecoactivity_h=6		if ecoactivity==6
replace ecoactivity_h=8		if ecoactivity==7
replace ecoactivity_h=7		if ecoactivity==8
replace ecoactivity_h=9		if ecoactivity==9
replace ecoactivity_h=10	if ecoactivity==10
replace ecoactivity_h=11	if ecoactivity==11
replace ecoactivity_h=12	if ecoactivity==12
replace ecoactivity_h=13	if ecoactivity==13
replace ecoactivity_h=13	if ecoactivity==14
replace ecoactivity_h=14	if ecoactivity==15
replace ecoactivity_h=15	if ecoactivity==16
replace ecoactivity_h=16	if ecoactivity==17
replace ecoactivity_h=16	if ecoactivity==18
replace ecoactivity_h=17	if ecoactivity==19
replace ecoactivity_h=18	if ecoactivity==20
replace ecoactivity_h=18	if ecoactivity==99
label variable ecoactivity_h "Main job economic activity classification"

label define ecoactivity_h 1 "Agriculture, forestry, hunting, fishery and forestry" 2 "Mines and quarries" ///
		3 "Manufacturing industry" 4 "Water, energy and gas supply and distribution" 5 "Construction" ///
		6 "Wholesale and retail" 7 "Accommodation services and food services" 8 "Transport and storage" ///
		9 "Information and communication" 10 "Financial services and insurance" 11 "Real estate activities" ///
		12 "Professional and technical services" 13 "Public Administration, defense and Social Security" ///
		14 "Education services" 15 "Health and social services" 16 "Other activity services" ///
		17 "Private homes service that hire domestic service" 18 "Extraterritorial agency Service" ///
		99 "Unspecified"
label value ecoactivity_h ecoactivity_h

local lab1 "Agriculture, forestry, hunting, fishery and forestry"
local lab2 "Mines and quarries"
local lab3 "Manufacturing industry"
local lab4 "Water, energy and gas supply and distribution"
local lab5 "Construction"
local lab6 "Wholesale and retail"
local lab7 "Accommodation services and food services"
local lab8 "Transport and storage"
local lab9 "Information and communication"
local lab10 "Financial services and insurance"
local lab11 "Real estate activities"
local lab12 "Professional and technical services"
local lab13 "Public Administration, defense and Social Security"
local lab14 "Education services"
local lab15 "Healt and social services"
local lab16 "Other activity services"
local lab17 "Private homes service that hire domestic service"
local lab18 "Extraterritorial agency Service"

forvalues i= 1(1)18{
gen oc_`i'=(ecoactivity_h==`i') if d_worked==1 & ecoactivity_h!=.
label var oc_`i' "`lab`i''"
gen oc_`i'_a=(ecoactivity_h==`i')
label var oc_`i'_a "`lab`i''"
}

gen child_ind=ecoactivity
recode child_ind 0=1 1=3 2=4 4=17 5=6 6=7 7=9 9=17 10=17 12=17 13=17 15=17 16=17 18=17 19=16
gen child_ind2= child_ind
replace child_ind2=0 if d_worked==0

label define activity2 1 "Agriculture" 3 "Mining" 4 "Manufacturing" 6 "Construction" 7 "Retail" 8 "Accomodation \& Food" 9 "Transport \& Storage" 16 "Domestic Work" 17 "Other"
label values child_ind activity2 
label values child_ind2 activity2 

*Labelling
label variable d_worked "Working children"
label variable d_paid "Paid Work"
label variable d_paid_a "Paid Work (Base=all)"
label variable d_selfemployed  "Selfemployed"
label variable d_apprentice  "Children working as apprentice"
label variable weekworkhrs_a "Weekly worked hours (all)"
label variable weekworkhrs_wrkchild "Weekly worked hours (Working children)"
label variable daysworked_a "Days worked (all)"
label variable daysworked_wrkchild "Days worked (Working children)"
label variable dayhrsworked_a "Hours worked on an average day (all)"
label variable dayhrsworked_wrkchild  "Hours worked on an average day (Working children)"
label variable ylab "Monthly income"
label variable hrywage "Hourly wage"
label variable usd_ylab "Monthly income (USD)"
label variable usd_hrywage "Hourly wage (USD)"
label variable schooling "Years of education"

*Labelling categories
label define d_worked 1 "Working children" 0 "Not Working children"
label value d_worked d_worked

label define d_paid 1 "Paid" 0 "Not paid"
label value d_paid d_paid

label define d_selfemployed 1 "Selfmployed" 0 "Rest"
label value d_selfemployed d_selfemployed

label define d_apprentice 1 "Apprentice" 0 "Rest"
label value d_apprentice d_apprentice

*Survey conducted field work date

gen aux1=10
gen aux2=2016

gen survey_date=ym(aux2,aux1)
format survey_date %tm
drop aux1 aux2
label variable survey_date "Approximate date of the survey field work"



*Age categories

gen agecat=1 if age<10
replace agecat= 2 if age>=10 & age<12
replace agecat=3 if age>=12 & age<14
replace agecat=4 if age>=14 & age<=17
label define agecat 1 "7-9" 2 "10-11" 3 "12-13" 4 "14-17" 
label values agecat agecat


preserve
tempfile datecollection
use "${relabeled_data}/HHsurvey.dta", clear
keep if year==2016
gen doc=mdy(collection_month,collection_day,2016)
keep doc folio 
destring folio, replace
collapse doc, by(folio)
save `datecollection', replace
restore

merge m:1   folio using `datecollection'
*keep if _m==3
drop _merge
*age by date

gen dob=mdy(bdate_mm,bdate_dd, bdate_yy)
gen age_survey=doc-dob
gen age_survey_m=round(age_survey/30)
label var dob "Date of birth"
label var age_survey "Calculated age (days)"
label var age_survey_m "Calculated age (months)"



save "${relabeled_dataCS}/childworkbo_2016.dta", replace




*indbelonging

use "${relabeled_dataCS}/household_2016.dta", replace

keep id age ind_belonging_b
keep if age>=5 & age<=17
drop age
rename ind_belonging_b indbelonging

save "${relabeled_dataCS}/indbelonging.dta", replace

use "${relabeled_dataCS}/childworkbo_2016.dta", clear

merge m:m id using "${relabeled_dataCS}/indbelonging.dta"
drop _merge
order folio number id depto area gender age bdate_* indbelonging

label define indbelonging 1 "Quechua" 2 "Aymara" 3 "Guarani" 4 "Chiquitano" 5 "Mojeño" ///
				6 "Other (especify)" 7 "None" 8 "Peasant" 
label value indbelonging indbelonging


save "${relabeled_dataCS}/childworkbo_2016.dta", replace

*Adding a municipality identificator

use "${raw_dataCS}/ENNA_2016/upm_2016.dta", clear

keep num_upm NOMBRE_MUNICIPIO I02_dep

destring I02_dep, gen(dept)
destring NOMBRE_MUNICIPIO, gen(mun)

drop NOMBRE_MUNICIPIO I02_dep dept
rename num_upm upm


label variable mun 	"Municipality Code"

save "${relabeled_dataCS}/municipality_2016.dta", replace

use "${relabeled_dataCS}/childworkbo_2016.dta", clear

merge m:m upm using "${relabeled_dataCS}/municipality_2016.dta"

drop if _merge==2
drop _merge

nsplit mun, digits(4 1) generate(prov temp)
drop temp

save "${relabeled_dataCS}/childworkbo_2016.dta", replace



/*==================================================
            2: Household Survey
==================================================*/

use "${relabeled_dataCS}/household_2016.dta", replace

*Years of education

gen schooling=.
replace schooling=0 if edu_lastgradeapproved_a>=1 & edu_lastgradeapproved_a<=3 
replace schooling=0 if edu_lastgradeapproved_a>=11 & edu_lastgradeapproved_a<=17  //No formal education
replace schooling=0+ edu_lastgradeapproved_b  if edu_lastgradeapproved_a==4 & edu_lastgradeapproved_b!=. //Basic
replace schooling=5+ edu_lastgradeapproved_b  if edu_lastgradeapproved_a==5 & edu_lastgradeapproved_b!=. //Intermediate
replace schooling=8+ edu_lastgradeapproved_b  if edu_lastgradeapproved_a==6 & edu_lastgradeapproved_b!=. //Medium
replace schooling=0+ edu_lastgradeapproved_b  if edu_lastgradeapproved_a==7 & edu_lastgradeapproved_b!=. //Primary
replace schooling=8+ edu_lastgradeapproved_b  if edu_lastgradeapproved_a==8 & edu_lastgradeapproved_b!=. //Secondary
replace schooling=0+ edu_lastgradeapproved_b  if edu_lastgradeapproved_a==9 & edu_lastgradeapproved_b!=. //Primary
replace schooling=6+ edu_lastgradeapproved_b  if edu_lastgradeapproved_a==10 & edu_lastgradeapproved_b!=. //Secondary
replace schooling=12+ edu_lastgradeapproved_b if edu_lastgradeapproved_a==18 & edu_lastgradeapproved_b!=. //Teacher superior school
replace schooling=12+ edu_lastgradeapproved_b if (edu_lastgradeapproved_a>=23 & edu_lastgradeapproved_a<=25) & edu_lastgradeapproved_b!=. //Technics, military and police
replace schooling=15 if schooling>15 & (edu_lastgradeapproved_a>=23 & edu_lastgradeapproved_a<=25) & edu_lastgradeapproved_b!=.
replace schooling=15 if schooling>15 & edu_lastgradeapproved_a==18 & edu_lastgradeapproved_b!=.
replace schooling=12+edu_lastgradeapproved_b if edu_lastgradeapproved_a==19 & edu_lastgradeapproved_b!=. //University
replace schooling=12+edu_lastgradeapproved_b if edu_lastgradeapproved_a==20 & edu_lastgradeapproved_b!=. //Diploma
replace schooling=17 if schooling>15 & edu_lastgradeapproved_a==19 & edu_lastgradeapproved_b!=.
replace schooling=17 if schooling>15 & edu_lastgradeapproved_a==20 & edu_lastgradeapproved_b!=.
replace schooling=17+edu_lastgradeapproved_b if edu_lastgradeapproved_a==21 & edu_lastgradeapproved_b!=. //Master degree
replace schooling=19 if schooling>19 & edu_lastgradeapproved_a==21 & edu_lastgradeapproved_b!=.
replace schooling=19+edu_lastgradeapproved_b if edu_lastgradeapproved_a==22 & edu_lastgradeapproved_b!=. //Doctorate Degree
replace schooling=24 if schooling>24 & edu_lastgradeapproved_a==22 & edu_lastgradeapproved_b!=.
replace schooling=12 if schooling>=26 & edu_lastgradeapproved_a<=27

*Years of education head
gen schooling_head=schooling if rel_head==1

*Dummy if head lives with couple
sort folio
gen aux1=(rel_head==2)
egen aux2=max(aux1), by(folio)
gen liveswithcouple=(aux2==1) if rel_head==1 
drop aux*

*Number of family members
gen aux3=1
egen number_famimemb=count(aux3), by(folio)
drop aux3

*Number of children under 5 years old
gen aux4=(age<=5)
egen number_childunder5=total(aux4), by(folio)
drop aux4

*Labelling variables
label variable schooling "Years of education"
label variable schooling_head "Head years of education"
label variable liveswithcouple "Head living with couple"
label variable number_famimemb "Number of family members"
label variable number_childunder5 "Number of children under 5 years old"

*Labelling cathegories
label define liveswithcouple 1 "Lives with couple" 0 "Does not live with couple"
label values liveswithcouple liveswithcouple

*Survey conducted field work date

gen aux1=10
gen aux2=2016

gen survey_date=ym(aux2,aux1)
format survey_date %tm
drop aux1 aux2
label variable survey_date "Approximate date of the survey field work"


save "${relabeled_dataCS}/household_2016.dta", replace

