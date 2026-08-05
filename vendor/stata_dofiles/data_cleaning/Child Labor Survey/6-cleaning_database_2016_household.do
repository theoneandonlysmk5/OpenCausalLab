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

/* This .do file cleans the ENNA 2016 for the household (Bolivian Child Labor Survey) */

/*==================================================
            0: Program set up
==================================================*/
*Written on STATA 17
drop _all

/*==================================================
            1: Initial Data
==================================================*/

use "${raw_dataCS}/ENNA_2016/ENNA_2016_household.dta", clear

rename nro 			number
rename estrato		stratum
rename s02a_02		gender
rename s02a_03		age
rename s02a_04a		bdate_dd
rename s02a_04b		bdate_mm
rename s02a_04c		bdate_yy
rename s02a_05		rel_head
rename s02a_06a		rel_wife_partner
rename s02a_06b		rel_father
rename s02a_06c		rel_mother
rename s02a_07_1	languagespoken_a
rename s02a_07_2	languagespoken_b
rename s02a_07_3	languagespoken_e
rename s02a_08		language_childhood
rename s02a_10		maritalstatus

rename s03a_1a 		mgt_place5yearsago_a
rename s03a_1b		mgt_place5yearsago_b

rename s03a_2		ind_belonging_a
rename s03a_2npioc	ind_belonging_b

rename s05a_01 		edu_literacy
rename s05a_02a		edu_lastgradeapproved_a
rename s05a_02b 	edu_lastgradeapproved_b
rename s05a_03a		edu_lastgradeapproved_c
rename s05a_03b		edu_lastgradeapproved_d
rename s05a_05		edu_enrol
rename s05a_05a		edu_reasnotenrolled
rename s05a_06a 	edu_lastgradeenrol_a	
rename s05a_06b 	edu_lastgradeenrol_b
rename s05a_08		edu_schcondcashtransfer
rename s05a_09		edu_typeschool
rename s05b_10		edu_attendance
rename s05b_11		edu_attend_reasnot

rename s06a_01		wrk_workedlastweek
rename s06a_02 		wrk_dedicateonehour
rename s06a_03 		wrk_impediment_b
rename s06a_04		wrk_availability
rename s06a_05		wrk_jobsearch
rename s06a_06aa	wrk_jobsearch_a
rename s06a_06ab	wrk_jobsearch_b
rename s06a_06ac	wrk_jobsearch_c
rename s06a_06e		wrk_jobsearch_e
rename s06a_07		wrk_everworkbefore_a
rename s06a_08a		wrk_timenotwork_a
rename s06a_08b		wrk_timenotwork_b
rename s06a_09 		wrk_everworkbefore_b
rename s06a_10		wrk_reasnotlookjob
rename s06a_10e		wrk_reasnotlookjob_e
rename s06b_11a		wrk_occupation_e
rename s06b_11acod  wrk_occupation_cod
rename s06b_11b 	wrk_tasks_e
rename s06b_12a		wrk_ecoactivity_e
rename s06b_12acod	wrk_ecoactivity_cod
rename s06b_12b		wrk_output_e
rename s06b_14a		wrk_joblength_a
rename s06b_14b		wrk_joblength_b
rename s06b_16		wrk_jobposition
rename s06b_17		wrk_contract
rename s06b_18		wrk_typeinstitution
rename s06b_19  	wrk_formalinstitution
rename s06b_20		wrk_joblocation
rename s06b_20e		wrk_joblocation_e
rename s06b_21		wrk_amountworkers
rename s06b_22		wrk_daysworked
rename s06b_23aa	wrk_hrs_average_hh
rename s06b_23ab	wrk_hrs_average_mm
rename s06c_25a		wrk_mainylab_a
rename s06c_25b		wrk_mainylab_b
rename s06c_26a		wrk_bonus
rename s06c_26b		wrk_aguinaldo
rename s06c_30a 	wrk_inkind_a1
rename s06c_30a1 	wrk_inkind_a2
rename s06c_30a2  	wrk_inkind_a3
rename s06c_30b  	wrk_inkind_b1
rename s06c_30b1  	wrk_inkind_b2
rename s06c_30b2  	wrk_inkind_b3
rename s06c_30c  	wrk_inkind_c1
rename s06c_30c1  	wrk_inkind_c2
rename s06c_30c2  	wrk_inkind_c3
rename s06c_30d  	wrk_inkind_d1
rename s06c_30d1  	wrk_inkind_d2
rename s06c_30d2  	wrk_inkind_d3
rename s06c_30e  	wrk_inkind_e1
rename s06c_30e1  	wrk_inkind_e2
rename s06c_30e2 	wrk_inkind_e3
rename s06d_31a		wrk_mainytotal_a
rename s06d_31b		wrk_mainytotal_b
rename s06d_33a		wrk_mainyafobligations_a		
rename s06d_33b		wrk_mainyafobligations_b

rename s06e_40		secnd_worklastweek
rename s06f_41a		secnd_occupation_e
rename s06f_41acod	secnd_occupation_cod
rename s06f_42		secnd_position
rename s06f_45 		secnd_daysworked
rename s06f_46a		secnd_hrs_average_hh
rename s06f_46b		secnd_hrs_average_mm

rename s08a_01		childwkr_familymeberworked
rename s08a_03aa	childwkr_reastowork_a
rename s08a_03ab	childwkr_reastowork_b
rename s08a_03ac	childwkr_reastowork_c
rename s08a_03e		childwkr_reastowork_e
rename s08a_04		childwkr_approval
rename s08a_06		childwkr_jobagency
rename cob_op		occ_cat
rename cob_op2dig	occ_cat2dig
rename caeb_op		ecoactivity
rename e			schyears
rename condact		work_status
rename phrs			hours_worked_mainocc
rename shrs			hours_worked_secndocc
rename tothrs		hours_worked_tot

keep folio upm area depto factor number gender age bdate_dd bdate_mm bdate_yy rel_head rel_wife_partner rel_father rel_mother languagespoken_a languagespoken_b languagespoken_e language_childhood maritalstatus mgt_* ind_belonging_a ind_belonging_b ///
edu_* wrk_* secnd_* childwkr_* occ_cat occ_cat2dig ecoactivity schyears work_status hours_worked_mainocc hours_worked_secndocc hours_worked_tot stratum yprilab yseclab ylab ynolab yper yhog yhogpc


*Binary variables

local binary edu_literacy edu_enrol edu_schcondcashtransfer edu_attendance wrk_workedlastweek wrk_availability wrk_jobsearch ///
				wrk_everworkbefore_a wrk_inkind_a1 wrk_inkind_b1 wrk_inkind_c1 wrk_inkind_d1 wrk_inkind_e1 ///
				secnd_worklastweek childwkr_familymeberworked childwkr_jobagency 
recode `binary' (2=0)
label define binaria  0 "No" 1 "Yes"
label value `binary' binaria

recode gender (2=0)
label define gender 0 "Female" 1 "Male" 
label value gender gender

label drop area
recode area (2=0)
label define area 0 "Rural" 1 "Urban"
label value area area

*Labeling variables

label variable folio 		"Household ID"
label variable upm			"Primary unit sample"
label variable number		"Personal number in household"
label variable gender 		"Gender"
label variable age			"How old are you?"
label variable bdate_dd			"Date of birth? Day"
label variable bdate_mm			"Date of birth? Month"
label variable bdate_yy			"Date of birth? Year"
label variable rel_head			"Relationship with the head of household"
label variable rel_wife_partner	"Who is your wife or partner?"
label variable rel_father		"Who is your father?"
label variable rel_mother		"Who is your mother?"
label variable languagespoken_a	"What languages do you speak?"
label variable languagespoken_b	"What languages do you speak?"
label variable languagespoken_e	"What languages do you speak?"
label variable language_childhood 	"Mother tongue"
label variable maritalstatus 		"Marital status"
label variable mgt_place5yearsago_a	"Where did you live 5 years ago (2011)"
label variable mgt_place5yearsago_b	"Specify Department-Province-Municipality"
label variable ind_belonging_a	"Do you consider yourself as part of the following indigenous groups?"
label variable ind_belonging_b	"Do you consider yourself as part of the following indigenous groups?"
label variable edu_literacy		"Can you read and write?"
label variable edu_lastgradeapproved_a	"What was the last level or grade higher that you approved? (Level)"
label variable edu_lastgradeapproved_b	"What was the last level or grade higher that you approved? (Grade)"
label variable edu_lastgradeapproved_c	"To enter into that level, which grade or level did you have to approve? (Level)"
label variable edu_lastgradeapproved_d	"To enter into that level, which grade or level did you have to approve? (Grade)"
label variable edu_enrol			"Have you enrolled in any grade or level this year?"
label variable edu_reasnotenrolled		"Why were you not enrolled this year (2016)?"
label variable edu_lastgradeenrol_a		"In which grade or level you have enrolled this year(2016)? (Grade)"
label variable edu_lastgradeenrol_b		"In which grade or level you have enrolled this year(2016)? (Level)"
label variable edu_schcondcashtransfer	"Did you receive Bono Juancito Pinto last year (2015)?"
label variable edu_typeschool			"The type of school that you assist is?"
label variable edu_attendance 		"Do you attend to the level that you have enrolled this year?(2016)"
label variable edu_attend_reasnot	"Reasons to not attend to the level you enrolled"
label variable wrk_workedlastweek	"During last week, did you work at least an hour?"
label variable wrk_dedicateonehour	"During last week, did you dedicate at least one hour to:"
label variable wrk_impediment_b		"Last week, did you have any work or activity that you could not do?"
label variable wrk_availability 	"Last week, did you want to work and were you available?"
label variable wrk_jobsearch		"During the last 4 weeks did you look for a job?"
label variable wrk_jobsearch_a  	"What did you do?"
label variable wrk_jobsearch_b  	"What did you do?"
label variable wrk_jobsearch_c  	"What did you do?"
label variable wrk_jobsearch_e	 	"What did you do? Specify"
label variable wrk_everworkbefore_a	"Have you ever worked before?"
label variable wrk_everworkbefore_b	"You are:"
label variable wrk_timenotwork_a	"How long have you not worked? Time"
label variable wrk_timenotwork_b	"How long have you not worked? Period"
label variable wrk_reasnotlookjob 	" Why have you not looked for a job?"
label variable wrk_reasnotlookjob_e 	" Why have you not looked for a job? Specify"
label variable wrk_occupation_e		"Last week, what was your main job? Specify"
label variable wrk_occupation_cod 		"Last week, what was your main job? cod"
label variable wrk_tasks_e			"What are your tasks? Specify"
label variable wrk_ecoactivity_e	"What is the main economic activity of your work establishment? Specify"
label variable wrk_ecoactivity_cod	"What is the main economic activity of your work establishment? cod"
label variable wrk_output_e			"Mainly, what your company produce? Specify"
label variable wrk_joblength_a 		"How long have you been working here? Time"
label variable wrk_joblength_b 		"How long have you been working here? Period"
label variable wrk_jobposition		"In this job, you are:"
label variable wrk_contract 	"In this job, you:"
label variable wrk_typeinstitution	"The administration of the company, institution or place you work is:"
label variable wrk_formalinstitution	"The institution that you work for has NIT (Identification Tax Number)"
label variable wrk_joblocation 		"Where do you do this job?"
label variable wrk_joblocation_e 	"Where do you do this job?. Specify"
label variable wrk_amountworkers		"How many people work in the company, including you"
label variable wrk_daysworked		"How many days a week do you regularly work in this occupation? Use num. 5 to identify half days"
label variable wrk_hrs_average_hh	"In average, hoy many hours a day do you work in your occupation? (Hours)"
label variable wrk_hrs_average_mm	"In average, hoy many hours a day do you work in your occupation? (Minutes)"
label variable wrk_mainylab_a		"How much is your liquid salary, without law reductions? (Amount)"
label variable wrk_mainylab_b		"How much is your liquid salary, without law reductions (Frequency)?"
label variable wrk_bonus			"In the last 12 months did you receive an extra bonus, productivity bonus or a christmas bonus?"
label variable wrk_aguinaldo		"In the last 12 months did you receive a christmas bonus?"
label variable wrk_inkind_a1 		"In your job, did you receive food and beverage"
label variable wrk_inkind_a2 		"In your job, did you receive food and beverage"	
label variable wrk_inkind_a3 		"In your job, did you receive food and beverage"
label variable wrk_inkind_b1 		"In your job, did you receive transport towards and from your place of work"
label variable wrk_inkind_b2 		"In your job, did you receive transport towards and from your place of work"
label variable wrk_inkind_b3 		"In your job, did you receive transport towards and from your place of work"
label variable wrk_inkind_c1 		"In your job, did you receive clothes and shoes that you use frequently"
label variable wrk_inkind_c2 		"In your job, did you receive clothes and shoes that you use frequently"
label variable wrk_inkind_c3 		"In your job, did you receive clothes and shoes that you use frequently"
label variable wrk_inkind_d1 		"In your job, did you receive housing or accommodation that can be use by family members?"
label variable wrk_inkind_d2 		"In your job, did you receive housing or accommodation that can be use by family members?"
label variable wrk_inkind_d3 		"In your job, did you receive housing or accommodation that can be use by family members?"
label variable wrk_inkind_e1 		"In your job, did you receive other like kindergarten services, sport installations?"
label variable wrk_inkind_e2 		"In your job, did you receive other like kindergarten services, sport installations?"
label variable wrk_inkind_e3 		"In your job, did you receive other like kindergarten services, sport installations?"
label variable wrk_mainytotal_a		"How much is your labor total income in you main job? Amount"
label variable wrk_mainytotal_b  	"How much is your labor total income in you main job? Frequency"
label variable wrk_mainyafobligations_a 	"Once all your duties are paid (wages, inputs) how much income is left?"
label variable wrk_mainyafobligations_b 	"Once all your duties are paid (wages, inputs) how much income is left? Frequency"
label variable secnd_worklastweek	"Besides the mentioned job, did you have another job last week?"
label variable secnd_occupation_e		"What is the main economic activity of this company, institution? Specify"
label variable secnd_occupation_cod		"What is the main economic activity of this company, institution? Cod"
label variable secnd_position			"In this job, you are:"	
label variable secnd_daysworked		"How many days a week do you regularly work in this occupation? Use num. 5 to identify half days"
label variable secnd_hrs_average_hh	"In average, hoy many hours a day do you work in your occupation? (Hours)"
label variable secnd_hrs_average_mm	"In average, hoy many hours a day do you work in your occupation? (Minutes)"
label variable childwkr_familymeberworked	"Last week, Did any member of your family between 5 and 6 work or do an activity, or had a job but could not do it temporarily?"
label variable childwkr_reastowork_a		"What are the main reasons why the child works?"
label variable childwkr_reastowork_b		"What are the main reasons why the child works?"
label variable childwkr_reastowork_c		"What are the main reasons why the child works?"
label variable childwkr_reastowork_e		"What are the main reasons why the child works? Specify"
label variable childwkr_approval			"In this job or activity you:"
label variable childwkr_jobagency			"In this job or activity, was the child hired by a job agency?"
label variable area 						"Urban rural"
label variable depto						"Department"
label variable factor 						"Expansion factor"
label variable occ_cat		"Main job occupation group"
label variable occ_cat2dig	"Main job occupation group"
label variable ecoactivity	"Economic Activity Classification"
label variable schyears		"Schooling years"
label variable work_status	"Main occupation status"
label variable hours_worked_mainocc	 "Weekly worked hours in main occupation"
label variable hours_worked_secndocc	 "Weekly worked hours in secondary occupation"
label variable hours_worked_tot		"Total hours worked"
label variable stratum		"Stratum"

*Creating a variable for child id identificator

tostring number , gen (number1)
gen aux1="0"+number1 if number<10
replace aux1=number1 if number>=10 & number!=.
tostring folio , gen (folio1)
gen aux2=folio1+aux1
drop number1 aux1 folio
destring folio1, generate(folio)
drop folio1
destring aux2, gen(id)
drop aux2

label variable id "Personal id"

*Categorical variables

label define rel_head 1 "Head" 2 "Spouse or partner" 3 "Daughter/son" 4 "Aware" 5 "Daughter/son in law" ///
			6 "Siblings or brother/sister in law" 7 "Parents" 8 "Father in law" 9 "Grandchild" 10 "Other relative" ///
			11 "Other who is not a relative" 12 "Housekeeper who lives inside the house" 13 "Relative from housekeeper" 
label value rel_head rel_head

recode languagespoken_a (6=1) (2=3) (27=2) (12=4) (7 10 12 14 20 24 26 29 32 36=5) (41 42 45 46 54 55 56 58 60=6) (995 996 998 =99)
label define languagespoken_a 1 "Spanish" 2 "Quechua" 3 "Aymara" 4 "Guarani" 5 "Other native" ///
			6 "Foreign" 99 "Missing"
label value languagespoken_a languagespoken_a

recode languagespoken_b (6=1) (2=3) (27=2) (4=5)(12=4) (7 10 11 12 14 19 20 21 24 26 29 34 36=5) (41 51 52 54 55 56 58 62=6) (995 998=99)
label define languagespoken_b  1 "Spanish" 2 "Quechua" 3 "Aymara" 4 "Guarani" 5 "Other native" ///
			6 "Foreign" 99 "Missing"
label value languagespoken_b languagespoken_b

recode language_childhood (6=1) (2=3) (27=2) (4=5)(12=4) (7 10 11 12 14 19 20 21 24 26 29 34 36=5) (41 51 52 54 55 56 58 62=6) (995 998=99)
label define language_childhood 1 "Spanish" 2 "Quechua" 3 "Aymara" 4 "Guarani" 5 "Other native" ///
			6 "Foreign" 7 "Does not speak yet" 
label value language_childhood language_childhood 


label define maritalstatus 1 "Single" 2 "Married" 3 "Co-habiting/Domestic partner" 4 "Separated" ///
			5 "Divorced" 6 "Widow(er)"
label value maritalstatus maritalstatus 

label define mgt_place5yearsago_a 1 "Here" 2 "Another region of this country" 3 "Abroad" 4 "Have not been born"
label value mgt_place5yearsago_a mgt_place5yearsago_a

label define ind_belonging_a 1 "I do belong" 2 "I do not belong" 3 "I am not bolivian"
label value ind_belonging_a ind_belonging_a

recode ind_belonging_b (1 7 8=6)(28=1) (3=2) (13=3) (11=4) (22=5) (700=8) 
replace ind_belonging_b =6 if ind_belonging_b>8 & ind_belonging_b!=.
label define ind_belonging_b 1 "Quechua" 2 "Aymara" 3 "Guarani" 4 "Chiquitano" 5 "Mojeño" ///
				6 "Other (especify)" 7 "None" 8 "Peasant" 
label value ind_belonging_b ind_belonging_b


recode edu_lastgradeapproved_a (11=1) (12=2) (13=3) (21=4) (22=5) (23=6) (31=7) (32=8) (41=9) (42=10) 
recode edu_lastgradeapproved_a (51=11) (52=12) (61=13) (62=14) (63=15) (64=16) (65=17) (71=18) (72=19) (73=20) (74=21) (75=22) (76=23) (77=24) (78=25) (79=26) (80=27)

label define edu_lastgradeapproved_a 1 "1.None" 2 "2.Literacy course" 3 "3.Initial education or pre-escolar" ///
			4 "4.Basic (1 to 5 years)" 5 "5.Intermediate (1 to 3 years)" 6 "6.Medium (1 to 4 years)" ///
			7 "7.Primary (1 to 8 years)" 8 "8.Secondary (1 to 4 years)" 9 "9.Primary (1 to 6 years)" 10 "10.Secondary (1 to 6 years)"	///
			11 "11.Basic Education for Adults" 12 "12.Center of Adults Medium Education" 13 "13.Youth Alternative Education" 14 "14.Primary Adult Education" ///
			15 "15.Adult Secondary Education" 16 "16.National Post Literacy Program" 17 "17.Especial education" ///
			18 "18.Teacher Superior School (Normal)" 19 "19.University" 20 "20.Post-graduate diploma" 21 "21.Masters Degree" ///
			22 "22.Doctorate Degree" 23 "23.University technician" 24 "24.Technical institute(More or equal to 2 years)" ///
			25 "25.Military and Police school" 26 "26.Adult Technician school" 27 "27.Other post secondary education (less than 2 years)"
label value edu_lastgradeapproved_a edu_lastgradeapproved_a

recode edu_lastgradeapproved_c (11=1) (12=2) (13=3) (21=4) (22=5) (23=6) (31=7) (32=8) (41=9) (42=10) 
recode edu_lastgradeapproved_c (51=11) (52=12) (61=13) (62=14) (63=15) (64=16) (65=17) (71=18) (72=19) (73=20) (74=21) (75=22) (76=23) (77=24) (78=25) (79=26) (80=27)
label define edu_lastgradeapproved_c 1 "1.None" 2 "2.Literacy course" 3 "3.Initial education or pre-escolar" ///
			4 "4.Basic (1 to 5 years)" 5 "5.Intermediate (1 to 3 years)" 6 "6.Medium (1 to 4 years)" ///
			7 "7.Primary (1 to 8 years)" 8 "8.Secondary (1 to 4 years)" 9 "9.Primary (1 to 6 years)" 10 "10.Secondary (1 to 6 years)"	///
			11 "11.Basic Education for Adults" 12 "12.Center of Adults Medium Education" 13 "13.Youth Alternative Education" 14 "14.Primary Adult Education" ///
			15 "15.Adult Secondary Education" 16 "16.National Post Literacy Program" 17 "17.Especial education" ///
			18 "18.Teacher Superior School (Normal)" 19 "19.University" 20 "20.Post-graduate diploma" 21 "21.Masters Degree" ///
			22 "22.Doctorate Degree" 23 "23.University technician" 24 "24.Technical institute(More or equal to 2 years)" ///
			25 "25.Military and Police school" 26 "26.Adult Technician school" 27 "27.Other (less than 2 years)"
label value edu_lastgradeapproved_c edu_lastgradeapproved_c
 
label define edu_reasnotenrolled 1 "Finish studying" 2 "Disease/accident/Disability" 3 "Pregnancy" 4 "Lack of money to pay for enrolment" ///
				5 "School is far away" 6 "School is unsafe" 7 "Teaching is not good" 8 "Lack of interest" 9 "To do house tasks" ///
				10 "To help in business/Family activity" 11 "For working (excluding 10)" 12 "To learn a job occupation" ///
				13 "Education is not important" 14 "Other"
label value edu_reasnotenrolled edu_reasnotenrolled
 
recode edu_lastgradeenrol_a (11=1) (12=2) (13=3) (21=4) (22=5) (23=6) (31=7) (32=8) (41=9) (42=10) 
recode edu_lastgradeenrol_a (51=11) (52=12) (61=13) (62=14) (63=15) (64=16) (65=17) (71=18) (72=19) (73=20) (74=21) (75=22) (76=23) (77=24) (78=25) (79=26) (80=27)
label define edu_lastgradeenrol_a 1 "1.None" 2 "2.Literacy course" 3 "3.Initial education or pre-escolar" ///
			4 "4.Basic (1 to 5 years)" 5 "5.Intermediate (1 to 3 years)" 6 "6.Medium (1 to 4 years)" ///
			7 "7.Primary (1 to 8 years)" 8 "8.Secondary (1 to 4 years)" 9 "9.Primary (1 to 6 years)" 10 "10.Secondary (1 to 6 years)"	///
			11 "11.Basic Education for Adults" 12 "12.Center of Adults Medium Education" 13 "13.Youth Alternative Education" 14 "14.Primary Adult Education" ///
			15 "15.Adult Secondary Education" 16 "16.National Post Literacy Program" 17 "17.Especial education" ///
			18 "18.Teacher Superior School (Normal)" 19 "19.University" 20 "20.Post-graduate diploma" 21 "21.Masters Degree" ///
			22 "22.Doctorate Degree" 23 "23.University technician" 24 "24.Technical institute(More or equal to 2 years)" ///
			25 "25.Military and Police school" 26 "26.Adult Technician school" 27 "27.Other (less than 2 years)"
label value edu_lastgradeenrol_a edu_lastgradeenrol_a

recode edu_typeschool (2=0)
label define edu_typeschool 1 "Public or Agreement School" 0 "Private School"
label value edu_typeschool edu_typeschool

label define edu_attend_reasnot 1 "Vacation" 2 "Finish studying" 3 "Disease/accident/Disability" 4 "Pregnancy" ///
				5 "Lack of money" 6 "School is far away" 7 "School is unsafe" 8 "School is not good" ///
				9 "Lack of interest" 10 "To do house tasks" 11 "To help in business/Family activity" 12 "For working (excluding 11)" ///
				13 "To learn a job occupation" 14  "Other"
label value edu_attend_reasnot edu_attend_reasnot

label define wrk_dedicateonehour 1 "Agricultural activities or animal husbandry for household consumption" ///
				2 "Agricultural activities or animal husbandry for market selling"  3 "Familiar or own business activities" ///
			4 "Sell on the street, or in any other moving market stall" 5 "Craft, food preparing, knitting activities" ///
			6 "Paid services (home tasks, watching cars, shoeshine, carrying bags)" ///
			7 "Any other activity in which you earned money or payment in kind"  ///
			8 "No activity"
label value wrk_dedicateonehour wrk_dedicateonehour

label define wrk_impediment_b 1 "Vacation or permission" 2 "License or maternity leave" 3 "Disease or accident" ///
			4 "Lack of materials, commodities or clients" 5 "Bad season" 6 "Strike or labor conflict" ///
			7 "Bad weather" 8 "Being suspended" 9 "Personal o family problems" 10 "None"
label value wrk_impediment_b wrk_impediment_b


label define wrk_jobsearch_a 1 "Consulting with employers" 2 "Assisting to a work interview" 3 "Answering or posting ads" ///
			4 "Job agency" 5 "Internet search" 6 "Asking from family or friends to find a job" 7 "Obtaining resources or clients" ///
			8 "Continuous job search in newspapers" 9 "Posting CV in social network" 10 "Other" 
label values wrk_jobsearch_a wrk_jobsearch_a 

label define wrk_jobsearch_b 1 "Consulting with employers" 2 "Assisting to a work interview" 3 "Answering or posting ads" ///
			4 "Job agency" 5 "Internet search" 6 "Asking from family or friends to find a job" 7 "Obtaining resources or clients" ///
			8 "Continuous job search in newspapers" 9 "Posting CV in social network" 10 "Other" 
label values wrk_jobsearch_b wrk_jobsearch_b 

label define wrk_jobsearch_c 1 "Consulting with employers" 2 "Assisting to a work interview" 3 "Answering or posting ads" ///
			4 "Job agency" 5 "Internet search" 6 "Asking from family or friends to find a job" 7 "Obtaining resources or clients" ///
			8 "Continuous job search in newspapers" 9 "Posting CV in social network" 10 "Other" 
label values wrk_jobsearch_c wrk_jobsearch_c

 
recode wrk_timenotwork_b (2=1) (4=2) (8=3)
label define wrk_timenotwork_b 1 "Week" 2 "Month" 3 "Year"
label value wrk_timenotwork_b wrk_timenotwork_b

label define wrk_everworkbefore_b 1 "Student" 2 "Housekeeper or responsible for house chores" 3 "Retired or meritorious" 4 "Ill of disabled" ///
			5 "Elderly" 6 "Other" 
label value wrk_everworkbefore_b  wrk_everworkbefore_b 

label define wrk_reasnotlookjob 1 "Secure job, I will start in less than 4 weeks" 2 "Searched before and waiting for answer" ///
			3 "I do not think I will find a job" 4 "Tired of looking for a job" 5 "Waiting for a better work activity" 6 "I am studying" ///
			7 "Retired/elderly" 8 "Not old enough" 9 "Disease/accident/Disability" 10 "Does not need to work" 11 "House chores/Pregnant/Taking acre of children" ///
			12 "Waiting for harvest or working season" 13 "Other (Specify)"
label value wrk_reasnotlookjob wrk_reasnotlookjob

recode wrk_joblength_b (2=1) (4=2) (8=3)
label define wrk_joblength_b 1 "Week" 2 "Month" 3 "Year"
label value wrk_joblength_b wrk_joblength_b

label define wrk_jobposition 1 "Worker" 2 "Employee" 3 "Self employed" 4 "Employer with salary" 5 "Employer without salary" ///
			6 "Production cooperative" 7 "Apprentice without remuneration" 8 "Housekeeper"
label value wrk_jobposition wrk_jobposition

label define wrk_contract 1 "Signed a contract with expiration date" 2 "Did not sign a contract but has work for product" 3 "Did not sign a contract, but has a verbal agreement" ///
			4 "Fixed term" 5 "Did not sing a contract"
label value wrk_contract wrk_contract

label define wrk_typeinstitution 1 "Public administration" 2 "Public enterprise" 3 "Private (Big or medium business)" ///
			4 "Private (Micro or family business)" 5 "Non Profit Organization" 6 "International Organization"
label value wrk_typeinstitution wrk_typeinstitution

label define wrk_formalinstitution 1 "Yes, in a general regime" 2 "Yes, in simplified regimen" 3 "Does not have/In process" 4 "I do not know"
label value wrk_formalinstitution wrk_formalinstitution

label define wrk_joblocation 1 "Private house" 2 "Exclusive land" ///
			3 "Mobile store" 4 "Fixed store" 5 "Transport" 6 "Home services" 7 "Moving job" 8 "Presales moving job" 9 "Other"
label values wrk_joblocation wrk_joblocation

label define wrk_mainylab_b	1 "Daily" 2 "Weekly" 3 "Biweekly" 4 "Monthly" 5 "Bimonthly" 6 "Quarterly" 7 "Biannual" 8 "Annually"
label values wrk_mainylab_b wrk_mainylab_b

label define wrk_inkind_a2 1 "Daily" 2 "Weekly" 3 "Biweekly" 4 "Monthly" 5 "Bimonthly" 6 "Quarterly" 7 "Biannual" 8 "Annually"
label value wrk_inkind_a2 wrk_inkind_a2

label define wrk_inkind_b2 1 "Daily" 2 "Weekly" 3 "Biweekly" 4 "Monthly" 5 "Bimonthly" 6 "Quarterly" 7 "Biannual" 8 "Annually"
label value wrk_inkind_b2 wrk_inkind_b2

label define wrk_inkind_c2 1 "Daily" 2 "Weekly" 3 "Biweekly" 4 "Monthly" 5 "Bimonthly" 6 "Quarterly" 7 "Biannual" 8 "Annually"
label value wrk_inkind_c2 wrk_inkindc_c2

label define wrk_inkind_d2 1 "Daily" 2 "Weekly" 3 "Biweekly" 4 "Monthly" 5 "Bimonthly" 6 "Quarterly" 7 "Biannual" 8 "Annually"
label value wrk_inkind_d2 wrk_inkind_d2

label define wrk_inkind_e2 1 "Daily" 2 "Weekly" 3 "Biweekly" 4 "Monthly" 5 "Bimonthly" 6 "Quarterly" 7 "Biannual" 8 "Annually"
label value wrk_inkind_e2 wrk_inkind_e2

label define wrk_mainytotal_b 1 "Daily" 2 "Weekly" 3 "Biweekly" 4 "Monthly" 5 "Bimonthly" 6 "Quarterly" 7 "Biannual" 8 "Annually"
label value wrk_mainytotal_b wrk_mainytotal_b

label define wrk_mainyafobligations_b 1 "Daily" 2 "Weekly" 3 "Biweekly" 4 "Monthly" 5 "Bimonthly" 6 "Quarterly" 7 "Biannual" 8 "Annually"
label value wrk_mainyafobligations_b wrk_mainyafobligations_b

label define secnd_position 1 "Worker" 2 "Employee" 3 "Self employed" 4 "Employer with salary" 5 "Employer without salary" ///
			6 "Production cooperative" 7 "Apprentice without remuneration" 8 "Housekeeper"
label value secnd_position secnd_position

label define childwkr_reastowork_a 1 "Generate income of my own" 2 "To support family business or activity (fulfill home income)" ///
			3 "To overcome the temporary problems of lack of income" 4 "Learn, get experience and skills" ///
			5 "Keep family or community habits" 6 "Other"
label value childwkr_reastowork_a childwkr_reastowork_a

label define childwkr_reastowork_b 1 "Generate income of my own" 2 "To support family business or activity (fulfill home income)" ///
			3 "To overcome the temporary problems of lack of income" 4 "Learn, get experience and skills" ///
			5 "Keep family or community habits" 6 "Other"
label value childwkr_reastowork_b childwkr_reastowork_b

label define childwkr_reastowork_c 1 "Generate income of my own" 2 "To support family business or activity (fulfill home income)" ///
			3 "To overcome the temporary problems of lack of income" 4 "Learn, get experience and skills" ///
			5 "Keep family or community habits" 6 "Other"
label value childwkr_reastowork_c childwkr_reastowork_c

label define childwkr_approval 1 "Know and approve the place and conditions of work" 2 "Do not know the place nor the working conditions" ///
			3 "Know and do not approve the place nor the working condition"
label value childwkr_approval childwkr_approval

label drop depto
label define depto 1 "Chuquisaca" 2 "La Paz" 3 "Cochabamba" 4 "Oruro" 5 "Potosi" 6 "Tarija" ///
			7 "Santa Cruz" 8 "Beni" 9 "Pando"
label values depto depto

label define occ_cat 0 "Armed forces occupations" 1 "Public administration and enterprise Managers" 2 "Scientific and intellectual professionals" 3 "Medium level technicians" ///
			4 "Clerical support workers" 5 "Service and sales workers" 6 "Agricultural, forestry and fishery workers" ///
			7 "Construction, manufacture workers and others" 8 "Plant and machine operators, assemblers" ///
			9 "Unskilled workers"  99 "Unspecified"
label values occ_cat occ_cat 

drop occ_cat2dig

label define  ecoactivity 0 "Agricultural, forestry and fishery" 1 "Mines and quarries" ///
			2 "Manufacturing industry" 3 "Electricity, gas, air conditioner supply" 4 "Water supply, waste management" 5 "Construction" ///
			6 "Wholesale and retail" 7 "Transport and storage" 8 "Accommodation services and food services" ///
			9 "Information and communication" 10 "Financial services and insurance" 11 "Real estate activities" ///
			12 "Professional and technical services" 13 "Administrative activity services" 14 "Public Administration, defense and Social Security" ///
			15 "Education services" 16 "Health and social assistance services" 17 "Artistic and entertaining activities" ///
			18 "Other activity services" 19 "Private home activities" 20 "Extraterritorial agency Service" ///
			99 "Unspecified"
label values ecoactivity ecoactivity

label define work_status 1 "Occupied" 2 "Unemployed" 3 "future starters" 4 "Temporarily" 5 "Permanent"
label value work_status work_status


order folio  number id area depto gender age bdate_dd bdate_mm bdate_yy rel_head rel_wife_partner ///
rel_father rel_mother languagespoken_a languagespoken_b languagespoken_e language_childhood maritalstatus ///
 ind_belonging_a ind_belonging_b  mgt_place5yearsago_a mgt_place5yearsago_b ///
 edu_literacy edu_lastgradeapproved_a edu_lastgradeapproved_b edu_lastgradeapproved_c ///
 edu_lastgradeapproved_d edu_enrol edu_reasnotenrolled edu_lastgradeenrol_a ///
 edu_lastgradeenrol_b edu_schcondcashtransfer edu_typeschool edu_attendance ///
 edu_attend_reasnot wrk_workedlastweek wrk_dedicateonehour wrk_impediment_b ///
 wrk_availability wrk_jobsearch wrk_jobsearch_a wrk_jobsearch_b wrk_jobsearch_c ///
 wrk_jobsearch_e wrk_everworkbefore_a wrk_everworkbefore_b wrk_timenotwork_a wrk_timenotwork_b ///
  wrk_reasnotlookjob wrk_reasnotlookjob_e wrk_occupation_e ///
 wrk_occupation_cod wrk_tasks_e wrk_ecoactivity_e wrk_ecoactivity_cod wrk_output_e ///
 wrk_joblength_a wrk_joblength_b wrk_jobposition wrk_contract wrk_typeinstitution ///
 wrk_formalinstitution wrk_joblocation wrk_joblocation_e wrk_amountworkers ///
 wrk_daysworked wrk_hrs_average_hh wrk_hrs_average_mm wrk_mainylab_a wrk_mainylab_b ///
 wrk_bonus wrk_aguinaldo wrk_inkind_a1 wrk_inkind_a2 wrk_inkind_a3 wrk_inkind_b1 ///
 wrk_inkind_b2 wrk_inkind_b3 wrk_inkind_c1 wrk_inkind_c2 wrk_inkind_c3 wrk_inkind_d1 ///
 wrk_inkind_d2 wrk_inkind_d3 wrk_inkind_e1 wrk_inkind_e2 wrk_inkind_e3 wrk_mainytotal_a ///
 wrk_mainytotal_b wrk_mainyafobligations_a wrk_mainyafobligations_b secnd_worklastweek ///
 secnd_occupation_e secnd_occupation_cod secnd_position secnd_daysworked ///
 secnd_hrs_average_hh secnd_hrs_average_mm childwkr_familymeberworked ///
 childwkr_reastowork_a childwkr_reastowork_b childwkr_reastowork_c childwkr_reastowork_e ///
 childwkr_approval childwkr_jobagency  factor upm stratum occ_cat ecoactivity ///
 schyears work_status hours_worked_mainocc hours_worked_secndocc hours_worked_tot
 
save "${relabeled_dataCS}/household_2016.dta", replace

************
*creating a variable for obs than can be matched with child_work

use "${relabeled_dataCS}/household_2016.dta", replace

merge m:m id using "${relabeled_dataCS}/childworkbo_2016.dta"

gen aux1=(_merge==3)
egen aux2=total(aux1), by(folio)

gen match_child_database=(rel_head==1 & (aux2>=1 & aux2<=8))
label variable match_child_database "Households whose children were interviewed in the child labor survey"

drop aux*
drop edu_reasnotenrol-_merge

order folio number id match_child_database

save "${relabeled_dataCS}/household_2016.dta", replace


