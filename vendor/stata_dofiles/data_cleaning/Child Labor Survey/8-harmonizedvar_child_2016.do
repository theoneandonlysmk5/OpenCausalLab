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

/* This .do file cleans the ENNA 2016 for the children (Bolivian Child Labor Survey) */

/*==================================================
            0: Program set up
==================================================*/
*Written on STATA 17
drop _all

/*==================================================
            1: Child Survey
==================================================*/

use "${relabeled_dataCS}/childworkbo_2016.dta", replace

*edu_lastgradeaproved_a_h

gen edu_lastgradeapproved_a_h=.
replace edu_lastgradeapproved_a_h=1 if edu_lastgradeapproved_a==3
replace edu_lastgradeapproved_a_h=2 if edu_lastgradeapproved_a==4 | edu_lastgradeapproved_a==7 | edu_lastgradeapproved_a==9
replace edu_lastgradeapproved_a_h=3 if edu_lastgradeapproved_a==5 | edu_lastgradeapproved_a==6 | edu_lastgradeapproved_a==8 | edu_lastgradeapproved_a==10
replace edu_lastgradeapproved_a_h=4 if edu_lastgradeapproved_a>=18 & edu_lastgradeapproved_a<=23
replace edu_lastgradeapproved_a_h=5 if edu_lastgradeapproved_a>=24 & edu_lastgradeapproved_a<=27 
replace edu_lastgradeapproved_a_h=6 if edu_lastgradeapproved_a==13
replace edu_lastgradeapproved_a_h=7 if edu_lastgradeapproved_a==14
replace edu_lastgradeapproved_a_h=8 if edu_lastgradeapproved_a==15
replace edu_lastgradeapproved_a_h=9 if edu_lastgradeapproved_a==1 | edu_lastgradeapproved_a==2 | edu_lastgradeapproved_a==11 | edu_lastgradeapproved_a==12 | edu_lastgradeapproved_a==16 | edu_lastgradeapproved_a==17

label variable edu_lastgradeapproved_a_h "Which was the last highest level or grade that you approved? (Level) Harmonized"
label define edu_lastgradeapproved_a_h 1 "Preschool" 2 "Primary" 3 "Secondary" 4 "Higher Education, University" ///
			5 "Higher Education, non university" 6 "Alternative Youth Education" 7 "Primary Adult Education" ///
			8 "Secondary Adult Education" 9 "None" 99 "Missing"
label value edu_lastgradeapproved_a_h edu_lastgradeapproved_a_h

*edu_enrol
gen edu_enrol_h=edu_enrol
label variable edu_enrol_h "Attendance harmonized"
label define yesno 1 "Yes" 0 "No"
label value  edu_enrol_h yesno

*edu_reasnotenrol_h
gen edu_reasnotenrol_h=.
replace edu_reasnotenrol_h=1 if edu_reasnotenrol==1 | edu_reasnotenrol==2
replace edu_reasnotenrol_h=2 if edu_reasnotenrol==16
replace edu_reasnotenrol_h=3 if edu_reasnotenrol==5
replace edu_reasnotenrol_h=4 if edu_reasnotenrol==4
replace edu_reasnotenrol_h=5 if edu_reasnotenrol==6
replace edu_reasnotenrol_h=6 if edu_reasnotenrol==14
replace edu_reasnotenrol_h=7 if edu_reasnotenrol==11
replace edu_reasnotenrol_h=8 if edu_reasnotenrol==7 | edu_reasnotenrol==8
replace edu_reasnotenrol_h=9 if edu_reasnotenrol==9
replace edu_reasnotenrol_h=10 if edu_reasnotenrol==10
replace edu_reasnotenrol_h=11 if edu_reasnotenrol==3 | edu_reasnotenrol==12 | edu_reasnotenrol==13 | edu_reasnotenrol==15

label variable edu_reasnotenrol_h "Reasons not enrolled Harmonized"
label define edu_reasnotenrol_h  1 "Disease/accident/disability" 2 "Not old enough" ///
				3 "School far away" 4 "Lack of money" 5 "Lack of interest" 6 "Family thinks education is not important" ///
				7 "To learn a job occupation" 8 "To help in family business" 9 "For work" ///
				10 "House tasks/Taking care of children" 11 "Other"
label value edu_reasnotenrol_h edu_reasnotenrol_h

*edu_lastgradeenrol_a_h

gen edu_lastgradeenrol_a_h=.
replace edu_lastgradeenrol_a_h=1 if edu_lastgradeenrol_a==3
replace edu_lastgradeenrol_a_h=2 if edu_lastgradeenrol_a==4 | edu_lastgradeenrol_a==7 | edu_lastgradeenrol_a==9
replace edu_lastgradeenrol_a_h=3 if edu_lastgradeenrol_a==5 | edu_lastgradeenrol_a==6 | edu_lastgradeenrol_a==8 | edu_lastgradeenrol_a==10
replace edu_lastgradeenrol_a_h=4 if edu_lastgradeenrol_a>=18 & edu_lastgradeenrol_a<=23
replace edu_lastgradeenrol_a_h=5 if edu_lastgradeenrol_a>=24 & edu_lastgradeenrol_a<=27 
replace edu_lastgradeenrol_a_h=6 if edu_lastgradeenrol_a==13
replace edu_lastgradeenrol_a_h=7 if edu_lastgradeenrol_a==14
replace edu_lastgradeenrol_a_h=8 if edu_lastgradeenrol_a==15
replace edu_lastgradeenrol_a_h=9 if edu_lastgradeenrol_a==1 | edu_lastgradeenrol_a==2 | edu_lastgradeenrol_a==11 | edu_lastgradeenrol_a==12 | edu_lastgradeenrol_a==16 | edu_lastgradeenrol_a==17

label variable edu_lastgradeenrol_a_h "In which grade or level you have enrolled this year? Harmonized"
label define edu_lastgradeenrol_a_h 1 "Preschool" 2 "Primary" 3 "Secondary" 4 "Higher Education, University" ///
			5 "Higher Education, non university" 6 "Alternative Youth Education" 7 "Primary Adult Education" ///
			8 "Secondary Adult Education" 9 "None" 99 "Missing"
label value edu_lastgradeenrol_a_h edu_lastgradeenrol_a_h

*edu_attend_reasnot_h
gen edu_attend_reasnot_h=.
replace edu_attend_reasnot_h=1 if edu_attend_reasnot==1 | edu_attend_reasnot==2
replace edu_attend_reasnot_h=2 if edu_attend_reasnot==4
replace edu_attend_reasnot_h=3 if edu_attend_reasnot==5
replace edu_attend_reasnot_h=4 if edu_attend_reasnot==6
replace edu_attend_reasnot_h=5 if edu_attend_reasnot==14
replace edu_attend_reasnot_h=6 if edu_attend_reasnot==11
replace edu_attend_reasnot_h=7 if edu_attend_reasnot==10
replace edu_attend_reasnot_h=8 if edu_attend_reasnot==8 | edu_attend_reasnot==7
replace edu_attend_reasnot_h=9 if edu_attend_reasnot==9
replace edu_attend_reasnot_h=10 if edu_attend_reasnot==3 | edu_attend_reasnot==12 | edu_attend_reasnot==13 | edu_attend_reasnot==15 | 16

label variable edu_attend_reasnot_h "Reasons to not attend - Harmonized"
label define edu_attend_reasnot_h 1 "Disease/accident/disability" 2 "School far away" 3 "Lack of money" ///
				4 "Lack of interest" 5 "Family thinks education is not important" 6 "To learn a job occupation" ///
				7 "House tasks/Taking care of children" 8 "To help in family business" 9 "For work" 10 "Other"
label value edu_attend_reasnot_h edu_attend_reasnot_h

*wrk_dedicateonehour_h
gen wrk_dedicateonehour_h=wrk_dedicateonehour
label value wrk_dedicateonehour_h wrk_dedicateonehour
label variable wrk_dedicateonehour_h "During last week, did you dedicate at least one hour to: Harmonized"

*wrk_jobsearch_a_h
gen wrk_jobsearch_a_h=wrk_jobsearch_a
gen wrk_jobsearch_b_h=wrk_jobsearch_b
gen wrk_jobsearch_c_h=wrk_jobsearch_c

label variable wrk_jobsearch_a_h "Last week, did you search for a job or try to open a business - Harmonized"
label variable wrk_jobsearch_b_h "Last week, did you search for a job or try to open a business - Harmonized"
label variable wrk_jobsearch_c_h "Last week, did you search for a job or try to open a business - Harmonized"


label variable wrk_jobsearch_a_h "Last week, did you search for a job or try to open a business - Harmonized"
label define wrk_jobsearch_a_h 1 "Answering or posting ads" 2 "Obtaining resources or clients" ///
			3 "Job agency or other" 4 "Help from family or friends to find a job" 5 "Other"
label value wrk_jobsearch_a_h wrk_jobsearch_b_h wrk_jobsearch_c_h wrk_jobsearch_a_h

*wrk_everworkbefore
rename wrk_everworkbefore wrk_everworkbefore_a

*wrk_joblocation_h
gen wrk_joblocation_h=.
replace wrk_joblocation_h=1 if wrk_joblocation==1
replace wrk_joblocation_h=3 if wrk_joblocation==2
replace wrk_joblocation_h=4 if wrk_joblocation==4
replace wrk_joblocation_h=5 if wrk_joblocation==5
replace wrk_joblocation_h=6 if wrk_joblocation==7
replace wrk_joblocation_h=7 if wrk_joblocation==6
replace wrk_joblocation_h=8 if wrk_joblocation>=8 & wrk_joblocation<=11

label variable wrk_joblocation_h "Where do you do this job? Harmonized"
label define wrk_joblocation_h 1 "In a private house" 2 "Private land" 3 "Farmland" ///
			4 "Mobile store" 5 "Fixed store" 6 "Home services" 7 "Transport vehicle" 8 "Other"
label value wrk_joblocation_h wrk_joblocation_h

*wrk_contract_h
gen wrk_contract_h=wrk_typecontract

label variable wrk_contract_h "Type of contract - Harmonized"
label define wrk_contract_h 1 "Permanently" 2 "Eventually" 3 "For a product"
label value wrk_contract_h wrk_contract_h

*wrk_incomeuse_a

gen wrk_incomeuse_h=wrk_incomeuse_a
recode wrk_incomeuse_h (2=7) (3=2) 
recode wrk_incomeuse_h (7=3)

label variable wrk_incomeuse_h "What do you spend your income into: Harmonized"
label define wrk_incomeuse_h 1 "School payments" 2 "Self benefit (food, clothes, leisure)" ///
			3 "Home benefit (Food, electricity, water)" 4 "Savings" 5 "Other"
label values wrk_incomeuse_h  wrk_incomeuse_h

*wrk_risks_a
gen wrk_risks_a_h=wrk_risks_a
gen wrk_risks_b_h=wrk_risks_b
gen wrk_risks_c_h=wrk_risks_c

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
			10 "Chemical products (pesticide, glue)" 11 "Other" 12 "None"
label value wrk_risks_b_h wrk_risks_b_h


label define wrk_risks_c_h 0 "No third risks" 1 "Dirt or dust" 2 "Fire, gas, flames" ///
			3 "Loud noise or vibrations" 4 "Extreme heat or cold" 5 "Dangerous instruments (knives, explosives, etc)" ///
			6 "Underground work" 7 "Work at height" 8 "Work in water" 9 "Darkness or confinement" ///
			10 "Chemical products (pesticide, glue)" 11 "Other" 12 "None"
label value wrk_risks_c_h wrk_risks_c_h

*wrk_jobinjury_a_h
gen wrk_jobinjury_a_h=wrk_jobinjury_a
gen wrk_jobinjury_b_h=wrk_jobinjury_b
gen wrk_jobinjury_c_h=wrk_jobinjury_c

label variable wrk_jobinjury_a_h "Did you have any of the following injuries in your job?- Harmonized"
label variable wrk_jobinjury_b_h "Did you have any of the following injuries in your job?- Harmonized"
label variable wrk_jobinjury_c_h "Did you have any of the following injuries in your job?- Harmonized"

label define wrk_jobinjury_a_h 1 "Superficial injuries or bites, blisters, etc" ///
			2 "Fractures or mutilations" 3 "Dislocation or distention" 4 "Burns, scalds or freezing" ///
			5 "Respiratory problems" 6 "Sight problems" 7 "Sking injuries" 8 "Stomach problems, diarrhea or chemical poisoning" ///
			9 "Exhaustion for tasks intensity" 10 "Other" 11 "None" 
label values wrk_jobinjury_a_h wrk_jobinjury_b_h wrk_jobinjury_c_h wrk_jobinjury_a_h


*wrk_injuryeffects_h

gen wrk_injuryeffects_h=wrk_injuryeffects

label variable wrk_injuryeffects_h "How were you affected by the worst injury? Harmonized"

label define wrk_injuryeffects_h 1 "Permanently disabled" 2 "Impeded me from doing activities" ///
			3 "I left school" 4 "Other" 5 "It was not serious"
label values wrk_injuryeffects_h wrk_injuryeffects_h

*wrk_violence
gen wrk_violence_a_h=.
replace wrk_violence_a_h=1 if wrk_violence_a==1
replace wrk_violence_a_h=2 if wrk_violence_a==3
replace wrk_violence_a_h=3 if wrk_violence_a==4
replace wrk_violence_a_h=4 if wrk_violence_a==5
replace wrk_violence_a_h=5 if wrk_violence_a==8
replace wrk_violence_a_h=6 if wrk_violence_a==2 | wrk_violence_a==6 | wrk_violence_a==7 | wrk_violence_a==9
replace wrk_violence_a_h=7 if wrk_violence_a==10

gen wrk_violence_b_h=.
replace wrk_violence_b_h=1 if wrk_violence_b==1
replace wrk_violence_b_h=2 if wrk_violence_b==3
replace wrk_violence_b_h=3 if wrk_violence_b==4
replace wrk_violence_b_h=4 if wrk_violence_b==5
replace wrk_violence_b_h=5 if wrk_violence_b==8
replace wrk_violence_b_h=6 if wrk_violence_b==2 | wrk_violence_b==6 | wrk_violence_b==7 | wrk_violence_b==9
replace wrk_violence_b_h=7 if wrk_violence_b==10

gen wrk_violence_c_h=.
replace wrk_violence_c_h=1 if wrk_violence_c==1
replace wrk_violence_c_h=2 if wrk_violence_c==3
replace wrk_violence_c_h=3 if wrk_violence_c==4
replace wrk_violence_c_h=4 if wrk_violence_c==5
replace wrk_violence_c_h=5 if wrk_violence_c==8
replace wrk_violence_c_h=6 if wrk_violence_c==2 | wrk_violence_c==6 | wrk_violence_c==7 | wrk_violence_c==9
replace wrk_violence_c_h=7 if wrk_violence_c==10


label variable  wrk_violence_a_h "While working, has this happened to you? (Harmonized)"
label variable  wrk_violence_b_h "While working, has this happened to you? (Harmonized)"
label variable  wrk_violence_c_h "While working, has this happened to you? (Harmonized)"


label define wrk_violence_a_h 1 "Being yelled, insulted, threatened often" 2 "Being physically abused (beaten, hurt)" ///
			3 "Impeded from eaten" 4 "Impeded from getting paid" 5 "Sexual abused or molested" ///
			6 "Other" 7 "None"
label value wrk_violence_a_h wrk_violence_b_h wrk_violence_c_h wrk_violence_a_h

*hse_risk

gen hse_risks_a_h=.
replace hse_risks_a_h=1 if hse_risks_a==1
replace hse_risks_a_h=2 if hse_risks_a==2
replace hse_risks_a_h=3 if hse_risks_a==4
replace hse_risks_a_h=4 if hse_risks_a==5
replace hse_risks_a_h=5 if hse_risks_a==7
replace hse_risks_a_h=6 if hse_risks_a==8
replace hse_risks_a_h=7 if hse_risks_a==9
replace hse_risks_a_h=8 if hse_risks_a==10
replace hse_risks_a_h=9 if hse_risks_a==11 | hse_risks_a==3 | hse_risks_a==6
replace hse_risks_a_h=10 if hse_risks_a==12

gen hse_risks_b_h=.
replace hse_risks_b_h=1 if hse_risks_b==1
replace hse_risks_b_h=2 if hse_risks_b==2
replace hse_risks_b_h=3 if hse_risks_b==4
replace hse_risks_b_h=4 if hse_risks_b==5
replace hse_risks_b_h=5 if hse_risks_b==7
replace hse_risks_b_h=6 if hse_risks_b==8
replace hse_risks_b_h=7 if hse_risks_b==9
replace hse_risks_b_h=8 if hse_risks_b==10
replace hse_risks_b_h=9 if hse_risks_b==11 | hse_risks_b==3 | hse_risks_b==6
replace hse_risks_b_h=10 if hse_risks_b==12

gen hse_risks_c_h=.
replace hse_risks_c_h=1 if hse_risks_c==1
replace hse_risks_c_h=2 if hse_risks_c==2
replace hse_risks_c_h=3 if hse_risks_c==4
replace hse_risks_c_h=4 if hse_risks_c==5
replace hse_risks_c_h=5 if hse_risks_c==7
replace hse_risks_c_h=6 if hse_risks_c==8
replace hse_risks_c_h=7 if hse_risks_c==9
replace hse_risks_c_h=8 if hse_risks_c==10
replace hse_risks_c_h=9 if hse_risks_c==11 | hse_risks_c==3 | hse_risks_c==6
replace hse_risks_c_h=10 if hse_risks_c==12


label variable hse_risks_a_h "Are you exposed to any of the following elements: (Harmonized)"
label variable hse_risks_b_h "Are you exposed to any of the following elements: (Harmonized)"
label variable hse_risks_c_h "Are you exposed to any of the following elements: (Harmonized)"


label define hse_risks_a_h 1 "Dirt or dust" 2 "Fire, gas, flames" 3 "Extreme heat or cold" 4 "Dangerous instruments (knives, explosives)" ///
			5 "Work at height" 6 "Work in water" 7 "Darkness or confinement" 8 "Chemical products (pesticide, glue)" 9 "Other" 10 "None"
label value hse_risks_a_h  hse_risks_b_h  hse_risks_c_h  hse_risks_a_h 


*occ_cat
gen occ_cat_h=occ_cat
recode occ_cat_h (7=9)

label variable occ_cat_h "Occupation Clasification Code"
label define occ_cat_h 0 "Armed Forces" 1 "Managers" 2 "Professionals" 3 "Technicians and Associate professionals" 4 "Clerical support workers" ///
			5 "Service and sales workers" 6 "Skilled agricultural, forestry and fishery workers" 7 "Craft and related trades workers" ///
			8 "Plant and machine operators, assemblers" 9 "Elementary occupations" 
label value occ_cat_h occ_cat_h




*Ordering variables
order folio number id depto area mun prov gender age bdate_dd bdate_mm bdate_yy indbelonging ///
edu_literacy edu_lastgradeapproved_a edu_lastgradeapproved_a_h edu_lastgradeapproved_b ///
edu_enrol edu_enrol_h edu_reasnotenrol edu_reasnotenrol_h edu_reasnotenrol_e edu_lastgradeenrol_a edu_lastgradeenrol_a_h ///
edu_lastgradeenrol_b edu_shift edu_shift_e edu_attendance edu_attend_reasnot edu_attend_reasnot_h edu_attend_reasnot_e ///
wrk_workedlastweek wrk_dedicateonehour wrk_dedicateonehour_h ///
wrk_impediment_a wrk_impediment_b wrk_availability wrk_jobsearch wrk_jobsearch_a wrk_jobsearch_b wrk_jobsearch_c ///
wrk_jobsearch_a_h wrk_jobsearch_b_h wrk_jobsearch_c_h wrk_jobsearch_e ///
wrk_everworkbefore_a wrk_timenotwork_a wrk_timenotwork_b wrk_reasnotlookjob wrk_reaslookjob_a ///
wrk_reaslookjob_b wrk_reaslookjob_e wrk_occupation_a wrk_occupation_e wrk_occupation_cod wrk_tasks_e wrk_ecoactivity_e ///
wrk_ecoactivity_cod wrk_output_e wrk_joblength_a wrk_joblength_b wrk_jobposition  wrk_jobfamcommunity wrk_joblocation wrk_joblocation_h ///
wrk_joblocation_e wrk_hrs_* wrk_mtimeworksimilar wrk_mtimeworksimilar_* ///
wrk_shift wrk_reastowork_a wrk_reastowork_b wrk_reastowork_e wrk_stopworkharm wrk_agreejob wrk_studypermit ///
wrk_jobthroughagency wrk_typecontract wrk_contract_h wrk_vacations wrk_typepayment wrk_mainylab_a wrk_mainylab_b wrk_aguinaldo ///
wrk_mainytotal_a wrk_mainytotal_b wrk_mainyafobligations_a wrk_mainyafobligations_b wrk_incomeuse_a wrk_incomeuse_b wrk_incomeuse_h ///
wrk_incomeuse_e wrk_permission wrk_risks_a wrk_risks_b wrk_risks_c wrk_risks_a_h wrk_risks_b_h wrk_risks_c_h wrk_risks_e ///
wrk_heavylift wrk_dangerequipment_a wrk_dangerequipment_e wrk_dangerequipment_e1 wrk_jobinjury_a wrk_jobinjury_b wrk_jobinjury_c ///
wrk_jobinjury_a_h wrk_jobinjury_b_h wrk_jobinjury_c_h wrk_jobinjury_e ///
wrk_injuryeffects wrk_injuryeffects_h wrk_injuryeffects_e wrk_violence_a wrk_violence_b wrk_violence_c ///
wrk_violence_a_h wrk_violence_b_h wrk_violence_c_h wrk_violence_e ///
secnd_worklastweek secnd_occupation secnd_occupation_e secnd_occupation_cod secnd_tasks_e secnd_hrs_* ///
secnd_shift secnd_position secnd_jobfamcommunity secnd_typepayment ///
secnd_incomeuse_a secnd_incomeuse_b secnd_incomeuse_e secnd_reastowork_a secnd_reastowork_b secnd_reastowork_e ///
secnd_comformable ///
hse_groceries hse_repair hse_cook hse_dishes hse_laundry hse_babysitting hse_woodwater ///
hse_other hse_hrs_*  hse_shift hse_agree hse_risks_a hse_risks_b hse_risks_c ///
hse_risks_a_h hse_risks_b_h hse_risks_c_h ///
hse_risks_e hse_heavylift hse_dangerequipment hse_dangerequipment_e hse_dangerequipment_e1 hse_injure_a ///
hse_injure_b hse_injure_c hse_injure_e hse_injureeffects hse_injureeffects_e hse_violence_a hse_violence_b ///
hse_violence_c hse_violence_e  ///
rgh_syndic rgh_rest rgh_restreasnot rgh_selfbenefit_a rgh_selfbenefit_b ///
rgh_selfbenefit_e ///
upm stratum factor work_status occ_cat occ_cat_h ecoactivity ecoactivity_h wrk_timededi htot_tdh wrk_category ///
occ_danger1 occ_minage occ_wrktime occ_nightshift occ_riskedu occ_danger2 ///
 d_worked d_paid d_selfemployed ///
d_apprentice weekworkhrs_a weekworkhrs_wrkchild daysworked_a daysworked_wrkchild dayhrsworked_a ///
dayhrsworked_wrkchild ylab hrywage schooling survey_date

save "${relabeled_dataCS}/childworkbo_2016.dta", replace

