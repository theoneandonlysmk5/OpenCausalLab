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

/* This .do file cleans the ETI 2008 for the children (Bolivian Child Labor Survey) */

/*==================================================
            0: Program set up
==================================================*/
*Written on STATA 17
drop _all

/*==================================================
            1: Child Survey
==================================================*/

use "${relabeled_dataCS}/childworkbo_2008.dta", replace


*indbelonging

label drop indbelonging 
label define indbelonging 1 "Quechua" 2 "Aymara" 3 "Guarani" 4 "Chiquitano" 5 "Mojeño" ///
				6 "Other (especify)" 7 "None" 8 "Peasant" 99 "Incomplete information"
label value indbelonging


*edu_lastgradeapproved_a_h

gen edu_lastgradeapproved_a_h=edu_lastgradeapproved_a 
label variable edu_lastgradeapproved_a_h "Which was the last highest level or grade that you approved? (Level) Harmonized"

label define edu_lastgradeapproved_a_h 1 "Preschool" 2 "Primary" 3 "Secondary" 4 "Higher Education, University" ///
			5 "Higher Education, non university" 6 "Alternative Youth Education" 7 "Primary Adult Education" ///
			8 "Secondary Adult Education" 9 "None" 99 "Missing"
label value edu_lastgradeapproved_a_h edu_lastgradeapproved_a_h


*edu_enrol
gen edu_enrol_h=edu_everenrolled
label variable edu_enrol_h "Attendance harmonized"
label define yesno 1 "Yes" 0 "No"
label value  edu_enrol_h yesno

*edu_reasnotenrol_h
gen edu_reasnotenrol_h=.
replace edu_reasnotenrol_h=1 if edu_reasnoteverenrolled==2
replace edu_reasnotenrol_h=2 if edu_reasnoteverenrolled==1
replace edu_reasnotenrol_h=3 if edu_reasnoteverenrolled==3
replace edu_reasnotenrol_h=4 if edu_reasnoteverenrolled==4
replace edu_reasnotenrol_h=5 if edu_reasnoteverenrolled==5
replace edu_reasnotenrol_h=6 if edu_reasnoteverenrolled==6
replace edu_reasnotenrol_h=7 if edu_reasnoteverenrolled==8
replace edu_reasnotenrol_h=8 if edu_reasnoteverenrolled==10
replace edu_reasnotenrol_h=9 if edu_reasnoteverenrolled==9
replace edu_reasnotenrol_h=10 if edu_reasnoteverenrolled==11
replace edu_reasnotenrol_h=11 if edu_reasnoteverenrolled==7 | edu_reasnoteverenrolled==12

label variable edu_reasnotenrol_h "Reasons not enrolled Harmonized"
label define edu_reasnotenrol_h  1 "Disease/accident/disability" 2 "Not old enough" ///
				3 "School far away" 4 "Lack of money" 5 "Lack of interest" 6 "Family thinks education is not important" ///
				7 "To learn a job occupation" 8 "To help in family business" 9 "For work" ///
				10 "House tasks/Taking care of children" 11 "Other"
label value edu_reasnotenrol_h edu_reasnotenrol_h

*edu_lastgradeenrol_a_h

gen edu_lastgradeenrol_a_h=edu_lastgradeenrol_a 
label variable edu_lastgradeenrol_a_h "Which was the last highest level or grade that you approved? (Level) Harmonized"

label variable edu_lastgradeenrol_a_h "In which grade or level you have enrolled this year? Harmonized"
label define edu_lastgradeenrol_a_h 1 "Preschool" 2 "Primary" 3 "Secondary" 4 "Higher Education, University" ///
			5 "Higher Education, non university" 6 "Alternative Youth Education" 7 "Primary Adult Education" ///
			8 "Secondary Adult Education" 9 "None" 99 "Missing"
label value edu_lastgradeenrol_a_h edu_lastgradeenrol_a_h

*edu_attend_reasnot_h
gen edu_attend_reasnot_h=.
replace edu_attend_reasnot_h=1 if edu_attend_reasnot==2
replace edu_attend_reasnot_h=2 if edu_attend_reasnot==3
replace edu_attend_reasnot_h=3 if edu_attend_reasnot==4
replace edu_attend_reasnot_h=4 if edu_attend_reasnot==5
replace edu_attend_reasnot_h=5 if edu_attend_reasnot==6
replace edu_attend_reasnot_h=6 if edu_attend_reasnot==8
replace edu_attend_reasnot_h=7 if edu_attend_reasnot==11
replace edu_attend_reasnot_h=8 if edu_attend_reasnot==10
replace edu_attend_reasnot_h=9 if edu_attend_reasnot==9
replace edu_attend_reasnot_h=10 if edu_attend_reasnot==1 | edu_attend_reasnot==7 | edu_attend_reasnot==12

label variable edu_attend_reasnot_h "Reasons to not attend - Harmonized"
label define edu_attend_reasnot_h 1 "Disease/accident/disability" 2 "School far away" 3 "Lack of money" ///
				4 "Lack of interest" 5 "Family thinks education is not important" 6 "To learn a job occupation" ///
				7 "House tasks/Taking care of children" 8 "To help in family business" 9 "For work" 10 "Other"
label value edu_attend_reasnot_h edu_attend_reasnot_h

*wrk_dedicateonehour_h
gen wrk_dedicateonehour_h=wrk_dedicateonehour
label variable wrk_dedicateonehour_h "During last week, did you dedicate at least one hour to: Harmonized"
recode wrk_dedicateonehour_h (7=8) (9=7)
label define wrk_dedicateonehour_h 1 "Agricultural activities or animal husbandry" ///
			2 "Forest harvest, fishing or hunting activities" 3 "Familiar or own business activities" ///
			4 "Sell on the street, or in any other moving market stall" 5 "Craft, food preparing, knitting activities" ///
			6 "Offer services paid in cash or in kind (watching cars, announcer shoeshine, carrying bags)" ///
			7 "Assist or work in minning or harvest activities" 8 "Work as a housemaid" ///
			9 "Do any other activity in which you earned money" 10 "No activity"
label value wrk_dedicateonehour_h wrk_dedicateonehour_h

*wrk_jobsearch_a_h
gen wrk_jobsearch_a_h=.
replace wrk_jobsearch_a_h=1 if wrk_jobsearch_a==2
replace wrk_jobsearch_a_h=2 if wrk_jobsearch_a==5
replace wrk_jobsearch_a_h=3 if wrk_jobsearch_a==3
replace wrk_jobsearch_a_h=4 if wrk_jobsearch_a==4
replace wrk_jobsearch_a_h=5 if wrk_jobsearch_a==1 | wrk_jobsearch_a==6 | wrk_jobsearch_a==7
label variable wrk_jobsearch_a_h "Last week, did you search for a job or try to open a business - Harmonized"
label define wrk_jobsearch_a_h 1 "Answering or posting ads" 2 "Obtaining resources or clients" ///
			3 "Job agency or other" 4 "Help from family or friends to find a job" 5 "Other"
label value wrk_jobsearch_a_h wrk_jobsearch_a_h

gen wrk_jobsearch_b_h=.
replace wrk_jobsearch_b_h=1 if wrk_jobsearch_b==2
replace wrk_jobsearch_b_h=2 if wrk_jobsearch_b==5
replace wrk_jobsearch_b_h=3 if wrk_jobsearch_b==3
replace wrk_jobsearch_b_h=4 if wrk_jobsearch_b==4
replace wrk_jobsearch_b_h=5 if wrk_jobsearch_b==1 | wrk_jobsearch_b==6 | wrk_jobsearch_b==7

gen wrk_jobsearch_c_h=.
replace wrk_jobsearch_c_h=1 if wrk_jobsearch_c==2
replace wrk_jobsearch_c_h=2 if wrk_jobsearch_c==5
replace wrk_jobsearch_c_h=3 if wrk_jobsearch_c==3
replace wrk_jobsearch_c_h=4 if wrk_jobsearch_c==4
replace wrk_jobsearch_c_h=5 if wrk_jobsearch_c==1 | wrk_jobsearch_c==6 | wrk_jobsearch_c==7

label variable wrk_jobsearch_b_h "Last week, did you search for a job or try to open a business - Harmonized"
label variable wrk_jobsearch_c_h "Last week, did you search for a job or try to open a business - Harmonized"
label value wrk_jobsearch_b_h wrk_jobsearch_c_h wrk_jobsearch_a_h

*wrk_jobposition_h
gen wrk_jobposition_h=.
replace wrk_jobposition_h=1 if wrk_jobposition==1
replace wrk_jobposition_h=2 if wrk_jobposition==2
replace wrk_jobposition_h=3 if wrk_jobposition==5
replace wrk_jobposition_h=4 if wrk_jobposition==6
replace wrk_jobposition_h=5 if wrk_jobposition==3
replace wrk_jobposition_h=6 if wrk_jobposition==7
replace wrk_jobposition_h=7 if wrk_jobposition==8
replace wrk_jobposition_h=8 if wrk_jobposition==4

label variable wrk_jobposition_h "In this job, you are: Harmonized"
label define wrk_jobposition_h 1 "Worker or family assistant" 2 "Employee" 3 "Employer with salary" ///
				4 "Employer without salary" 5 "Self employed" 6 "Production cooperative" 7 "Apprentice without remuneration" ///
				8 "Home worker"
label value wrk_jobposition_h wrk_jobposition_h

*wrk_joblocation_h
gen wrk_joblocation_h=.
replace wrk_joblocation_h=1 if wrk_joblocation==2 | wrk_joblocation==10
replace wrk_joblocation_h=2 if wrk_joblocation==1
replace wrk_joblocation_h=3 if wrk_joblocation==8
replace wrk_joblocation_h=4 if wrk_joblocation==3
replace wrk_joblocation_h=5 if wrk_joblocation==4
replace wrk_joblocation_h=6 if wrk_joblocation==6
replace wrk_joblocation_h=7 if wrk_joblocation==7
replace wrk_joblocation_h=8 if wrk_joblocation==5 | wrk_joblocation==9 | wrk_joblocation==11

label variable wrk_joblocation_h "Where do you do this job? Harmonized"
label define wrk_joblocation_h 1 "In a private house" 2 "Private land" 3 "Farmland" ///
			4 "Mobile store" 5 "Fixed store" 6 "Home services" 7 "Transport vehicle" 8 "Other"
label value wrk_joblocation_h wrk_joblocation_h

*wrk_contract_h
gen wrk_contract_h=. 
replace wrk_contract_h=1 if wrk_contract==3
replace wrk_contract_h=2 if wrk_contract==1
replace wrk_contract_h=3 if wrk_contract==2

label variable wrk_contract_h "Type of contract - Harmonized"
label define wrk_contract_h 1 "Permanently" 2 "Eventually" 3 "For a product"
label value wrk_contract_h wrk_contract_h

*wrk_incomeuse_a

gen wrk_incomeuse_h=wrk_incomeuse
recode wrk_incomeuse_h (2=7) (3=2) 
recode wrk_incomeuse_h (7=3)

label variable wrk_incomeuse_h "What do you spend your income into: Harmonized"
label define wrk_incomeuse_h 1 "School payments" 2 "Self benefit (food, clothes, leisure)" ///
			3 "Home benefit (Food, electricity, water)" 4 "Savings" 5 "Other"
label values wrk_incomeuse_h wrk_incomeuse_h 


*wrk_risks_a
gen wrk_risks_a_h=wrk_risks_a
gen wrk_risks_b_h=wrk_risks_b
gen wrk_risks_c_h=wrk_risks_c

recode wrk_risks_a_h (10 12=13) (11=10) (14=12)
recode wrk_risks_b_h (10 12=13) (11=10) (14=12)
recode wrk_risks_c_h (10 12=13) (11=10) (14=12)

label variable wrk_risks_a_h "Are you exposed to any of the following elements: (Harmonized)"
label variable wrk_risks_b_h "Are you exposed to any of the following elements: (Harmonized)"
label variable wrk_risks_c_h "Are you exposed to any of the following elements: (Harmonized)"

label define wrk_risks_a_h 1 "Dirt or dust" 2 "Fire, gas, flames" ///
			3 "Loud noise or vibrations" 4 "Extreme heat or cold" 5 "Dangerous instruments (knives, explosives, etc)" ///
			6 "Underground work" 7 "Work at height" 8 "Work in water" 9 "Darkness or confinement" ///
			10 "Chemical products (pesticide, glue)" 11 "Other" 12 "None"
label value wrk_risks_a_h wrk_risks_a_h

label define wrk_risks_b_h 0 "No second risks" 1 "Dirt or dust" 2 "Fire, gas, flames" ///
			3 "Loud noise or vibrations" 4 "Extreme heat or cold" 5 "Dangerous instruments (knives, explosives, etc)" ///
			6 "Underground work" 7 "Work at height" 8 "Work in water" 9 "Darkness or confinement" ///
			10 "Chemical (pesticide, glue)" 11 "Other" 12 "None"
label value wrk_risks_b_h wrk_risks_b_h


label define wrk_risks_c_h 0 "No third risks" 1 "Dirt or dust" 2 "Fire, gas, flames" ///
			3 "Loud noise or vibrations" 4 "Extreme heat or cold" 5 "Dangerous instruments (knives, explosives, etc)" ///
			6 "Underground work" 7 "Work at height" 8 "Work in water" 9 "Darkness or confinement" ///
			10 "Chemical products (pesticide, glue)" 11 "Other" 12 "None"
label value wrk_risks_c_h wrk_risks_c_h


*wrk_jobinjury_a
gen wrk_jobinjury_a_h=wrk_jobinjury_a
recode wrk_jobinjury_a_h (10=13) (9 11=10) (12=11)
recode wrk_jobinjury_a_h (13=9)

gen wrk_jobinjury_b_h=wrk_jobinjury_b
recode wrk_jobinjury_b_h (10=13) (9 11=10) (12=11)
recode wrk_jobinjury_b_h (13=9)

gen wrk_jobinjury_c_h=wrk_jobinjury_c
recode wrk_jobinjury_c_h (10=13) (9 11=10) (12=11)
recode wrk_jobinjury_c_h (13=9)

label variable wrk_jobinjury_a_h "Did you have any of the following injuries in your job?- Harmonized"
label variable wrk_jobinjury_b_h "Did you have any of the following injuries in your job?- Harmonized"
label variable wrk_jobinjury_c_h "Did you have any of the following injuries in your job?- Harmonized"

label define wrk_jobinjury_a_h 1 "Superficial injuries or bites, blisters, etc" ///
			2 "Fractures or mutilations" 3 "Dislocation or distention" 4 "Burns, scalds or freezing" ///
			5 "Respiratory problems" 6 "Sight problems" 7 "Skin injuries" 8 "Stomach problems, diarrhea or chemical poisoning" ///
			9 "Exhaustion for tasks intensity" 10 "Other" 11 "None" 
label values wrk_jobinjury_a_h wrk_jobinjury_b_h wrk_jobinjury_c_h wrk_jobinjury_a_h

*wrk_injuryeffects_h

gen wrk_injuryeffects_h=wrk_injuryeffects
recode wrk_injuryeffects_h (3=4) (5 6=3) (7 8=5) 

label variable wrk_injuryeffects_h "How were you affected by the worst injury? Harmonized"

label define wrk_injuryeffects_h 1 "Permanently disabled" 2 "Impeded me from doing activities" ///
			3 "I left school" 4 "Other" 5 "It was not serious"
label values wrk_injuryeffects_h wrk_injuryeffects_h

*wrk_violence
gen wrk_violence_a_h=.
replace wrk_violence_a_h=1 if wrk_violence_a==1 | wrk_violence_a==2
replace wrk_violence_a_h=2 if wrk_violence_a==3
replace wrk_violence_a_h=3 if wrk_violence_a==4
replace wrk_violence_a_h=4 if wrk_violence_a==5
replace wrk_violence_a_h=5 if wrk_violence_a==7
replace wrk_violence_a_h=6 if wrk_violence_a==6 | wrk_violence_a==8
replace wrk_violence_a_h=7 if wrk_violence_a==9

gen wrk_violence_b_h=.
replace wrk_violence_b_h=1 if wrk_violence_b==1 | wrk_violence_b==2
replace wrk_violence_b_h=2 if wrk_violence_b==3
replace wrk_violence_b_h=3 if wrk_violence_b==4
replace wrk_violence_b_h=4 if wrk_violence_b==5
replace wrk_violence_b_h=5 if wrk_violence_b==7
replace wrk_violence_b_h=6 if wrk_violence_b==6 | wrk_violence_b==8
replace wrk_violence_b_h=7 if wrk_violence_b==9

gen wrk_violence_c_h=.
replace wrk_violence_c_h=1 if wrk_violence_c==1 | wrk_violence_c==2
replace wrk_violence_c_h=2 if wrk_violence_c==3
replace wrk_violence_c_h=3 if wrk_violence_c==4
replace wrk_violence_c_h=4 if wrk_violence_c==5
replace wrk_violence_c_h=5 if wrk_violence_c==7
replace wrk_violence_c_h=6 if wrk_violence_c==6 | wrk_violence_c==8
replace wrk_violence_c_h=7 if wrk_violence_c==9


label variable  wrk_violence_a_h "While working, has this happened to you? (Harmonized)"
label variable  wrk_violence_b_h "While working, has this happened to you? (Harmonized)"
label variable  wrk_violence_c_h "While working, has this happened to you? (Harmonized)"


label define wrk_violence_a_h 1 "Being yelled, insulted, threatened often" 2 "Being physically abused (beaten, hurt)" ///
			3 "Impeded from eaten" 4 "Impeded from getting paid" 5 "Sexual abused or molested" ///
			6 "Other" 7 "None"
label value wrk_violence_a_h wrk_violence_b_h wrk_violence_c_h wrk_violence_a_h

*hse_risk

gen hse_risks_a_h=hse_risks_a
recode hse_risks_a_h (9=13) (8 10 11 =9) (12=10)
recode hse_risks_a_h (13=8) 

gen hse_risks_b_h=hse_risks_b
recode hse_risks_b_h (9=13) (8 10 11 =9) (12=10)
recode hse_risks_b_h (13=8) 

gen hse_risks_c_h=hse_risks_c
recode hse_risks_c_h (9=13) (8 10 11 =9) (12=10)
recode hse_risks_c_h (13=8) 


label variable hse_risks_a_h "Are you exposed to any of the following elements: (Harmonized)"
label variable hse_risks_b_h "Are you exposed to any of the following elements: (Harmonized)"
label variable hse_risks_c_h "Are you exposed to any of the following elements: (Harmonized)"


label define hse_risks_a_h 1 "Dirt or dust" 2 "Fire, gas, flames" 3 "Extreme heat or cold" 4 "Dangerous instruments (knives, explosives)" ///
			5 "Work at height" 6 "Work in water" 7 "Darkness or confinement" 8 "Qhemical products (pesticide, glue)" 9 "Other" 10 "None"
label value hse_risks_a_h  hse_risks_b_h  hse_risks_c_h  hse_risks_a_h 

*occ_cat_h
gen occ_cat_h=occ_cat

label variable occ_cat_h "Occupation Clasification Code"
label define occ_cat_h 0 "Armed Forces" 1 "Managers" 2 "Professionals" 3 "Technicians and Associate professionals" 4 "Clerical support workers" ///
			5 "Service and sales workers" 6 "Skilled agricultural, forestry and fishery workers" 7 "Craft and related trades workers" ///
			8 "Plant and machine operators, assemblers" 9 "Elementary occupations" 
label value occ_cat_h occ_cat_h





*Ordering variables
order folio nbr_children id number bdate_dd bdate_mm bdate_yy gender age area depto prov secc mun indbelonging indbelonging_e ///
edu_literacy edu_everenrolled edu_enrol_h edu_reasnoteverenrolled edu_reasnotenrol_h edu_reasnoteverenrolled_e ///
edu_lastgradeapproved_a edu_lastgradeapproved_a_h edu_lastgradeapproved_b edu_attendance edu_lastgradeenrol_a ///
edu_lastgradeenrol_a_h edu_lastgradeenrol_b edu_shift edu_missedschool ///
edu_missedschool_days edu_missedschool_reason edu_missedschool_reason_e edu_attend_reasnot edu_attend_reasnot_h edu_attend_reasnot_e ///
edu_repetition_a edu_repetition_b edu_repetition_reas edu_repetition_reas_e edu_ageschoolattend edu_trainprogram ///
edu_trainprogram_e edu_trainprogram_cod ///
 wrk_workedlastweek wrk_dedicateonehour wrk_dedicateonehour_h wrk_impediment_a wrk_impediment_b wrk_occupation_e wrk_occupation_cod ///
 wrk_tasks_e wrk_ecoactivity_e wrk_ecoactivity_cod wrk_joblocation wrk_joblocation_h wrk_joblocation_e wrk_jobposition wrk_jobposition_h  ///
 wrk_typepayment wrk_mainylab_a wrk_mainylab_b wrk_contract wrk_contract_h wrk_mainyinkind_a wrk_mainyinkind_b ///
 wrk_bonus_a wrk_bonus_b wrk_mainytotal_a wrk_mainytotal_b wrk_mainyafobligations_a wrk_mainyafobligations_b ///
 wrk_keepincome wrk_whokeepsincome wrk_whokeepsincome_e wrk_incomeuse wrk_incomeuse_h wrk_incomeuse_e wrk_hrs_* ///
 wrk_employer wrk_employer_e wrk_ablechangeemployer wrk_ablechangeemployer_e wrk_feelingaboutjob ///
 wrk_lowincome wrk_extrahours wrk_wrkingtime wrk_extrawork wrk_laborstability wrk_unsafe wrk_streetwork ///
 wrk_dangerequipment wrk_tasks wrk_noimproves wrk_wrkenviroment wrk_shift wrk_shift2 wrk_reastowork ///
 wrk_reastowork_e wrk_stopworkharm wrk_stopworkharm_e wrk_availability wrk_familymemberjobsearch ///
 wrk_jobsearch wrk_jobsearch_a wrk_jobsearch_b wrk_jobsearch_c wrk_jobsearch_a_h wrk_jobsearch_b_h wrk_jobsearch_c_h ///
 wrk_jobsearch_e wrk_everworkbefore_a ///
 wrk_everworkbefore_b wrk_everworkbefore_e wrk_timenotwork_a wrk_timenotwork_b wrk_reasnotlookjob ///
 wrk_reasnotlookjob_e wrk_workedlastyear wrk_jobinjury_a wrk_jobinjury_b wrk_jobinjury_c ///
 wrk_jobinjury_a_h wrk_jobinjury_b_h wrk_jobinjury_c_h wrk_jobinjury_e wrk_injuryeffects wrk_injuryeffects_h ///
 wrk_injuryeffects_e wrk_injurecause wrk_injurecause_e ///
 wrk_heavylift wrk_heavyequipment wrk_heavyequipment_e1 codh1 wrk_heavyequipment_e2 codh2 ///
 wrk_risks_a wrk_risks_b wrk_risks_c wrk_risks_a_h wrk_risks_b_h wrk_risks_c_h wrk_risks_e wrk_violence_a wrk_violence_b wrk_violence_c ///
 wrk_violence_a_h wrk_violence_b_h wrk_violence_c_h wrk_violence_e  /// 
 secnd_worklastweek secnd_occupation_e secnd_occupation_cod secnd_ecoactivity_e secnd_ecoactivity_cod ///
 secnd_hrs_* ///
 trd_occupation_code trd_worklastweek trd_nroper_3 ///
 hse_groceries hse_repair hse_cook hse_dishes hse_laundry hse_babysitting hse_woodwater hse_other hse_none ///
 hse_risks_a hse_risks_b hse_risks_c hse_risks_a_h hse_risks_b_h hse_risks_c_h hse_risks_e hse_hrs_* hse_shift hse_shift2 ///
 rgh_syndic rgh_syndic_e ///
 inadultcompany adultinterference_1 adultinterference_2 ecoactivity ecoactivity_h occ_cat occ_cat_h upm factor members ///
 wrk_status surveyresult ///
 catchild d_worked d_paid d_selfemployed d_apprentice weekworkhrs_all weekworkhrs_wrkchild daysworked_all ///
 daysworked_wrkchild dayhrsworked_all dayhrsworked_wrkchild ylab hrywage schooling ///
 
 save "${relabeled_dataCS}/childworkbo_2008.dta", replace
 
    
