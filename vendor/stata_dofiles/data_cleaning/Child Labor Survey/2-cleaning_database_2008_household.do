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

/* This .do file cleans the ETI 2008 for the household (Bolivian Child Labor Survey) */

/*==================================================
            0: Program set up
==================================================*/
*Written on STATA 17
drop _all

/*==================================================
            1: Initial Data
==================================================*/

use "${raw_dataCS}/ETI_2008/ETI_2008_household.dta", clear

*Renaming variables
rename miembros 	members
rename resfinal		surveyresult
rename condtra		workcondition
rename id_person 	number
rename s1_02		gender
rename s1_03 		age
rename s1_04a		bdate_dd
rename s1_04b		bdate_mm
rename s1_04c		bdate_yy
rename s1_05		maritalstatus
rename s1_06a		birthcertificate
rename s1_06b		id_possession
rename s1_07		rel_head
rename s1_08a		rel_wife_partner
rename s1_08b		rel_father
rename s1_08c 		rel_stepfather
rename s1_08d		rel_mother
rename s1_08e		rel_stepmother
rename s1_09		language_childhood
rename s1_09b 		language_childhood_e		
rename s1_101		languagespoken_a
rename s1_102		languagespoken_b
rename s1_10b		languagespoken_e
rename s1_11 		verification1
rename s1_12		ind_belonging
rename s1_12b		ind_belonging_e

rename s1_13a		mgt_placeofbirth
rename s1_13b		mgt_placeofbirth_depto
rename s1_13c 		mgt_placeofbirth_province
rename s1_13d		mgt_placeofbirth_mun
rename s1_14		mgt_reasontomove
rename s1_14b		mgt_reasontomove_e
rename s1_15a		mgt_lenghtplaceliving_a
rename s1_15b		mgt_lenghtplaceliving_b
rename s1_16		verification2

rename s2_17		edu_literacy
rename s2_18		edu_everenrolled
rename s2_19		edu_schooldecision
rename s2_20		edu_reasnoteverenrolled
rename s2_20b 		edu_reasnoteverenrolled_e
rename s2_21		edu_ageschoolstarted
rename s2_22a		edu_lastgradeapproved_a
rename s2_22b		edu_lastgradeapproved_b
rename s2_23		edu_attendance
rename s2_24a		edu_gradeacurrenattendance_a
rename s2_24b		edu_gradeacurrenattendance_b
rename s2_25		edu_shift
rename s2_26		edu_typeschool
rename s2_27		edu_skipschool
rename s2_28		edu_returntoschooldecis
rename s2_29		edu_attend_reasnot
rename s2_29b		edu_attend_reasnot_e
rename s2_30		edu_trainprogram
rename s2_31		edu_trainprogram_e
rename codofici		edu_trainprogram_cod

rename s3_32		verification3
rename s3_33		wrk_workedlastweek
rename s3_34		wrk_dedicateonehour
rename s3_35a		wrk_impediment_a
rename s3_35b		wrk_impediment_b
rename s3_36		wrk_occupation_e
rename codocp3 		wrk_occupation_cod
rename s3_37		wrk_tasks_e
rename s3_38 		wrk_ecoactivity_e
rename codacp3		wrk_ecoactivity_cod
rename s3_39		wrk_joblocation
rename s3_39b		wrk_joblocation_e
rename s3_40		wrk_jobposition
rename s3_41		wrk_amountworkers
rename s3_42a		wrk_hrs_aa
rename s3_42b		wrk_hrs_ab
rename s3_42c		wrk_hrs_ba
rename s3_42d		wrk_hrs_bb
rename s3_42e		wrk_hrs_ca
rename s3_42f		wrk_hrs_cb
rename s3_42g		wrk_hrs_da
rename s3_42h		wrk_hrs_db
rename s3_42i		wrk_hrs_ea
rename s3_42j		wrk_hrs_eb
rename s3_42k		wrk_hrs_fa
rename s3_42l		wrk_hrs_fb
rename s3_42m		wrk_hrs_ga
rename s3_42n		wrk_hrs_gb
rename s3_43		wrk_typepayment
rename s3_44		verification4
rename s3_45a		wrk_mainylab_a
rename s3_45b		wrk_mainylab_b
rename s3_46 		wrk_contract
rename s3_47a1		wrk_mainyinkind_a
rename s3_47a2		wrk_mainyinkind_b
rename s3_47b1		wrk_bonus_a
rename s3_47b2		wrk_bonus_b
rename s3_48a		wrk_mainytotal_a
rename s3_48b		wrk_mainytotal_b
rename s3_49a 		wrk_mainyafobligations_a
rename s3_49b		wrk_mainyafobligations_b

rename s3_50		secnd_worklastweek
rename s3_51		secnd_occupation_e
rename codocs3		secnd_occupation_cod
rename s3_52		secnd_ecoactivity_e
rename codacs3		secnd_ecoactivity_cod
rename s3_53a		secnd_hrs_aa
rename s3_53b		secnd_hrs_ab
rename s3_53c		secnd_hrs_ba
rename s3_53d		secnd_hrs_bb
rename s3_53e		secnd_hrs_ca
rename s3_53f		secnd_hrs_cb
rename s3_53g		secnd_hrs_da
rename s3_53h		secnd_hrs_db
rename s3_53i		secnd_hrs_ea
rename s3_53j		secnd_hrs_eb
rename s3_53k		secnd_hrs_fa
rename s3_53l		secnd_hrs_fb
rename s3_53m		secnd_hrs_ga
rename s3_53n		secnd_hrs_gb

rename s3_54a		trd_worklastweek
rename s3_54b		trd_hrs

rename s3_55		wrk_agestarwork
rename s3_56		wrk_mainjobimportance
rename s3_57		wrk_availability
rename s3_58		wrk_jobsearch
rename s3_591		wrk_jobsearch_a
rename s3_592		wrk_jobsearch_b
rename s3_593		wrk_jobsearch_c
rename s3_59b		wrk_jobsearch_e
rename s3_60		wrk_everworkbefore_a
rename s3_61a		wrk_timenotwork_a
rename s3_61b		wrk_timenotwork_b
rename s3_62		wrk_everworkbefore_b 
rename s3_62b		wrk_everworkbefore_e
rename s3_63		wrk_reasnotlookjob
rename s3_63b		wrk_reasnotlookjob_e
rename s3_64		wrk_workedlastyear
rename s3_65		wrk_dedicateonehour2
rename s3_66		wrk_occupation2_e
rename codocu_12m	wrk_occupation2_cod
rename s3_67		wrk_ecoactivity2_e
rename codacu_12m	wrk_ecoactivity2_cod
rename s3_68 		wrk_jobposition2
rename s3_69jul 	wrk_monthsworked_1
rename s3_69ago		wrk_monthsworked_2
rename s3_69sep 	wrk_monthsworked_3 
rename s3_69oct		wrk_monthsworked_4  
rename s3_69nov		wrk_monthsworked_5  
rename s3_69dic		wrk_monthsworked_6  
rename s3_69ene		wrk_monthsworked_7  
rename s3_69feb		wrk_monthsworked_8  
rename s3_69mar		wrk_monthsworked_9  
rename s3_69abr		wrk_monthsworked_10  
rename s3_69may		wrk_monthsworked_11  
rename s3_69jun		wrk_monthsworked_12 
rename s3_69j_a		wrk_monthsworked_13
rename s4_70		verification5

rename s4_711		hse_groceries
rename s4_712 		hse_cook
rename s4_713		hse_cleaning
rename s4_714		hse_laundry
rename s4_715 		hse_takecare
rename s4_716 		hse_repair
rename s4_717 		hse_woodwater
rename s4_718		hse_none
rename s4_72a 		hse_hrs_aa
rename s4_72b  		hse_hrs_ab
rename s4_72c  		hse_hrs_ba
rename s4_72d  		hse_hrs_bb
rename s4_72e  		hse_hrs_ca
rename s4_72f  		hse_hrs_cb
rename s4_72g  		hse_hrs_da
rename s4_72h  		hse_hrs_db
rename s4_72i  		hse_hrs_ea
rename s4_72j  		hse_hrs_eb
rename s4_72k  		hse_hrs_fa		
rename s4_72l  		hse_hrs_fb
rename s4_72m  		hse_hrs_ga
rename s4_72n 		hse_hrs_gb
rename s4_73		verification6

rename s5_74 		par_idealsituation
rename s5_751		par_wrkeffects_a
rename s5_752		par_wrkeffects_b
rename s5_753		par_wrkeffects_c
rename s5_75b		par_wrkeffects_e
rename s5_761		par_reastowork_a
rename s5_762		par_reastowork_b
rename s5_763		par_reastowork_c
rename s5_76b		par_reastowork_e
rename s5_77		par_stopworkharm
rename s5_77b		par_stopworkharm_e
rename ceob_1		occ_cat
rename cpaeb_1 		ecoactivity
rename urbarur		area

*Binary variables

local binary 	birthcertificate id_possession edu_literacy edu_everenrolled edu_attendance ///
				edu_trainprogram wrk_workedlastweek wrk_impediment_a trd_worklastweek ///
				secnd_worklastweek wrk_availability  wrk_jobsearch wrk_everworkbefore_a ///
				wrk_workedlastyear hse_groceries hse_cook hse_cleaning hse_laundry ///
				hse_takecare hse_repair hse_woodwater hse_none

recode `binary' (2=0)
label define binaria  0 "No" 1 "Yes"
label value `binary' binaria

recode gender (2=0)
label define gender 0 "Female" 1 "Male" 
label value gender gender

recode wrk_mainyinkind_a (8=99) (2=0)
label define wrk_mainyinkind_a 0 "No" 1 "Yes" 99 "Missing"
label value wrk_mainyinkind_a wrk_mainyinkind_a 

recode wrk_mainyinkind_b (888888=.)

recode wrk_bonus_a (8=99) (2=0)
label define wrk_bonus_a 0 "No" 1 "Yes" 99 "Missing"
label value wrk_bonus_a wrk_bonus_a
recode wrk_bonus_b (888888=.)

recode wrk_agestarwork (88 888=.)

recode wrk_mainjobimportance (8=99) (2=0)
label define wrk_mainjobimportance 0 "No" 1 "Yes" 99 "Missing"
label value wrk_mainjobimportance wrk_mainjobimportance

recode area (2=0)
label define area 0 "Rural" 1 "Urban"
label value area area

*Labeling variables

label variable folio 		"Household ID"
label variable members		"Members"
label variable number	"Personal number in household"
label variable surveyresult	"Final survey results"
label variable workcondition	"Work condition"
label variable gender				"Gender"
label variable age					"How old are you?"
label variable bdate_dd			"Date of birth? Day"
label variable bdate_mm			"Date of birth? Month"
label variable bdate_yy			"Date of birth? Year"
label variable maritalstatus 	"Marital status"
label variable birthcertificate	"Do you have a birth certificate?"
label variable id_possession	"Do you have a personal ID?"
label variable rel_head			"Relationship with the head of household"
label variable rel_wife_partner	"Who is your wife or partner?"
label variable rel_father		"Who is your father?"
label variable rel_stepfather	"Who is you stepfather?"
label variable rel_mother		"Who is your mother?"
label variable rel_stepmother	"Who is your stepmother?"
label variable language_childhood "Mother tongue"
label variable language_childhood_e "Mother tongue"
label variable languagespoken_a	"What languages do you speak?"
label variable languagespoken_b	"What languages do you speak?"
label variable languagespoken_e	"What languages do you speak?"
label variable ind_belonging	"Do you consider yourself as part of the following indigenous groups?"
label variable ind_belonging_e	"Do you consider yourself as part of the following indigenous groups?"
label variable mgt_placeofbirth	"Where were you born?"
label variable mgt_placeofbirth_depto	"Code department"
label variable mgt_placeofbirth_province	"Name province"
label variable mgt_placeofbirth_mun "Name municipality"
label variable mgt_reasontomove "What was the reason you decided to leave this place?"
label variable mgt_reasontomove_e "What was the reason you decided to leave this place?"
label variable mgt_lenghtplaceliving_a	"How many years have you been living here?"
label variable mgt_lenghtplaceliving_b 	"How many months have you been living here?"
label variable edu_literacy		"Can you read and write?"
label variable edu_everenrolled	"Have you ever enrolled in preschool, primary or an alternative school?"
label variable edu_schooldecision "Who decided you would not go to school?"
label variable edu_reasnoteverenrolled	"Why have you never been to school?"
label variable edu_reasnoteverenrolled_e	"Why have you never been to school?"
label variable edu_ageschoolstarted		"At what age did you start your education?"
label variable edu_lastgradeapproved_a	"What was the last level or grade higher that you approved? (Level)"
label variable edu_lastgradeapproved_b	"What was the last level or grade higher that you approved? (Grade)"
label variable edu_attendance			"Do you currently assist to preschool, school, institute or university?"
label variable edu_gradeacurrenattendance_a	"What grade or level do you currently assist?(Level)"
label variable edu_gradeacurrenattendance_b	"What grade or level do you currently assist?(Grade)"
label variable edu_shift				"School shift"
label variable edu_typeschool			"The type of school that you assist is?"
label variable edu_skipschool			"In the current school year did you skip school temporarily?"
label variable edu_returntoschooldecis	"Who decided that you would return to school?"
label variable edu_attend_reasnot 		"Reasons why you do not attend to school"
label variable edu_attend_reasnot_e		"Reasons why you do not attend to school"
label variable edu_trainprogram			"Have you ever attend a job training program? (Carpentry, Hairdressing)"
label variable edu_trainprogram_e		"Have you ever attend a job training program? (Carpentry, Hairdressing)"
label variable edu_trainprogram_cod		"Have you ever attend a job training program? (Carpentry, Hairdressing)"
label variable wrk_workedlastweek		"During last week, did you work at least an hour?"
label variable wrk_dedicateonehour		"During last week, did you dedicate at least one hour to:"
label variable wrk_impediment_a 				"Last week, did you have any work or activity that you could not do?"
label variable wrk_impediment_b					"What was the impediment?"
label variable wrk_occupation_e			"Last week, what was you main occupation. Specify"
label variable wrk_occupation_cod		"Main occupation code"
label variable wrk_tasks_e				"What are your tasks? Specify"
label variable wrk_ecoactivity_e		"What in the main economic activity of your enterprise?"
label variable wrk_ecoactivity_cod		"Main economic activity code"
label variable wrk_joblocation			"Where do you do this job?"
label variable wrk_joblocation_e		"Where do you do this job? Specify"
label variable wrk_jobposition			"In this job, you are:"
label variable wrk_amountworkers		"How many people work in the company, including you"
foreach x of varlist wrk_hrs_* {
	label variable `x' "Last week, how many hours and minutes a day did you dedicate to this job"
}
label variable wrk_typepayment 			"For the job that you do, how do you get paid?"
label variable wrk_mainylab_a			"How much is your liquid salary, without law reductions? Amount"
label variable wrk_mainylab_b			"How much is your liquid salary, without law reductions? Frequency"
label variable wrk_contract				"Job type contract"
label variable wrk_mainyinkind_a		"Last month, In your work did you receive food, transport, clothing?"
label variable wrk_mainyinkind_b		"Last month, In your work did you receive food, transport, clothing? Amount"
label variable wrk_bonus_a				"In the last 12 months did you receive an extra bonus, productivity bonus or a christmas bonus?"
label variable wrk_bonus_b				"In the last 12 months did you receive an extra bonus, productivity bonus or a christmas bonus? Amount"
label variable wrk_mainytotal_a			"How much is your labor total income in you main job? Amount"
label variable wrk_mainytotal_b			"How much is your labor total income in you main job? frequency"
label variable wrk_mainyafobligations_a	"Once all your duties are paid (wages, inputs) how much income is left? Amount"		
label variable wrk_mainyafobligations_b	"Once all your duties are paid (wages, inputs) how much income is left? Frequency"
label variable secnd_worklastweek		"Besides the mentioned job, did you have another job last week?"
label variable secnd_occupation_e		"Last week, what was your secondary occupation. Specify"
label variable secnd_occupation_cod		"Last week, what was your secondary occupation. Cod"
label variable secnd_ecoactivity_e 		"What in the main economic activity of your secondary work enterprise? Specify"
label variable secnd_ecoactivity_cod	"What in the main economic activity of your secondary work enterprise? Cod"
foreach x of varlist secnd_hrs_* {
	label variable `x' "Last week, how many hours and minutes a day did you dedicate to this job"
}
label variable trd_worklastweek			"Besides the main and secondary activities you mentioned, did you have another job last week?"
label variable trd_hrs					"How many hours a week did you work in this third activity?"
label variable wrk_agestarwork			"At what age did you start working for the first time?"
label variable wrk_mainjobimportance	"The job declared as main, was it the most important during this last 12 months?"
label variable wrk_availability		"Last week, did you want to work and were you available?"
label variable wrk_jobsearch		"Last week, did you search for a job or try to open a business?"
label variable wrk_jobsearch_a 		"What did you do?"
label variable wrk_jobsearch_b 		"What did you do?"
label variable wrk_jobsearch_c 		"What did you do?"
label variable wrk_jobsearch_e 		"What did you do? Specify"
label variable wrk_everworkbefore_a "Have you ever worked or done an activity to earn money before?"
label variable wrk_timenotwork_a	"How long have you not worked? (time)"
label variable wrk_timenotwork_b	"How long have you not worked? (Period)"
label variable wrk_everworkbefore_b	"If you have not, you are:"
label variable wrk_everworkbefore_e "If you have not, you are: (Specify)"
label variable wrk_reasnotlookjob	"Why have you not looked for a job?"
label variable wrk_reasnotlookjob_e	"Why have you not looked for a job? Specify"
label variable wrk_workedlastyear	"Have you worked in the last 12 months at least an hour?"
label variable wrk_dedicateonehour2	"In the last 12 months, did you dedicate at least one hour to:"
label variable wrk_occupation2_e 	"Last week, what was you main occupation. Specify"
label variable wrk_occupation2_cod 	"Main occupation code"
label variable wrk_ecoactivity2_e	"What is the main economic activity of your company?"
label variable wrk_ecoactivity2_cod "Main economic activity code"
label variable wrk_jobposition2		"In this job, you are:"
label variable wrk_monthsworked_1	"Did you work on July 2007"
label variable wrk_monthsworked_2	"Did you work on August 2007"
label variable wrk_monthsworked_3	"Did you work on September 2007"
label variable wrk_monthsworked_4	"Did you work on October 2007"
label variable wrk_monthsworked_5	"Did you work on November 2007"
label variable wrk_monthsworked_6	"Did you work on December 2007"
label variable wrk_monthsworked_7	"Did you work on January 2008"
label variable wrk_monthsworked_8	"Did you work on February 2008"
label variable wrk_monthsworked_9	"Did you work on March 2008"
label variable wrk_monthsworked_10	"Did you work on April 2008"
label variable wrk_monthsworked_11	"Did you work on May 2008"
label variable wrk_monthsworked_12	"Did you work on June 2008"
label variable wrk_monthsworked_13	"Did you work on July 2008"
label variable hse_groceries 		"For this home, did you buy groceries?"	
label variable hse_cook				"For this home, did you did you	cook?"
label variable hse_cleaning			"For this home, did you did you clean the house or do dishes?"
label variable hse_laundry			"For this home, did you did you do laundry?"
label variable hse_takecare			"For this home, did you did you baby sited or taken care of elderly or sick?"
label variable hse_repair			"For this home, did you did you repair any equipment?"
label variable hse_woodwater		"For this home, did you did you pick up wood or water?"
label variable hse_none				"None"
foreach x of varlist hse_hrs_* {
	label variable `x' "Last week, how many hours and minutes a day did you dedicate to this job?"
}
label variable par_idealsituation	"If you could choose, what would be an ideal situation:" 
label variable par_wrkeffects_a		"What problem(s) do you face as an effect of your job?"
label variable par_wrkeffects_b		"What problem(s) do you face as an effect of your job?"
label variable par_wrkeffects_c		"What problem(s) do you face as an effect of your job?"
label variable par_wrkeffects_e		"What problem(s) do you face as an effect of your job? Specify"
label variable par_reastowork_a		"Main reasons to work"
label variable par_reastowork_b		"Main reasons to work"
label variable par_reastowork_c		"Main reasons to work"
label variable par_reastowork_e		"Main reasons to work (Specify)"
label variable par_stopworkharm		"Parents perception of the effects of their children stop working"
label variable par_stopworkharm_e	"Parents perception of the effects of their children stop working"
label variable occ_cat 				"Occupation Classification Code"	
label variable ecoactivity			"Economic Activity Classification code"
label variable upm					"Primary unit sample"
label variable area 				"Urban rural"
label variable factor				"Expansion factor"

*Categorical variables
 

label define surveyresult 1 "Complete interview" 2 "Incomplete interview" 3 "Temporally absent" 4 "Unqualified respondent" ///
				5  "Lack of contact" 6 "Rejection" 7 "Unoccupied house"
label value surveyresult surveyresult

label drop s1_04b

label define workcondition 0 "Child not working" 1 "Child working" 2 "Adult not working" 3 "Adult working" ///
				4 "Adult who does not know if is working or not" 5 "Child between 0 and 4 years old" 6 "Child who does not know if is working or not"
label value workcondition workcondition

recode maritalstatus (7 8=99)
label define maritalstatus 1 "Single" 2 "Married" 3 "Co-habiting/Domestic partner" 4 "Separated" ///
			5 "Divorced" 6 "Widow(er)" 99 "Missing" 
label value maritalstatus maritalstatus 

recode rel_head (88=99)
label define rel_head 1 "Head" 2 "Spouse or partner" 3 "Daughter/son" 4 "Aware" 5 "Daughter/son in law" ///
			6 "Siblings or brother/sister in law" 7 "Parents" 8 "Father in law" 9 "Grandchild" 10 "Other relative" ///
			11 "Other who is not a relative" 12 "Housekeeper" 13 "Relative from housekeeper" 99 "Missing"
label value rel_head rel_head


recode language_childhood (8=7)
label define language_childhood 1 "Spanish" 2 "Quechua" 3 "Aymara" 4 "Guarani" 5 "Other native" ///
			6 "Foreign" 7 "Does not speak yet" 
label value language_childhood language_childhood 

label define languagespoken_a 1 "Spanish" 2 "Quechua" 3 "Aymara" 4 "Guarani" 5 "Other native" ///
			6 "Foreign"
label value languagespoken_a languagespoken_a

label define languagespoken_b 0 "No second language" 1 "Spanish" 2 "Quechua" 3 "Aymara" 4 "Guarani" 5 "Other native" ///
			6 "Foreign"
label value languagespoken_b languagespoken_b


recode ind_belonging (8=99)
label define ind_belonging 1 "Quechua" 2 "Aymara" 3 "Guarani" 4 "Chiquitano" 5 "Mojeño" ///
				6 "Other (especify)" 7 "None" 99 "Incomplete information"
label value ind_belonging ind_belonging

recode mgt_placeofbirth (8=99)
label define mgt_placeofbirth 1 "Here" 2 "Another region of this country" 3 "Abroad" 99 "Missing"
label value mgt_placeofbirth mgt_placeofbirth

recode mgt_placeofbirth_depto (88=99)
label define mgt_placeofbirth_depto 1 "Chiquisaca" 2 "La Paz" 3 "Cochabamba" 4 "Oruro" 5 "Potosi" ///
			6 "Tarija" 7 "Santa Cruz" 8 "Beni" 9 "Pando" 99 "Missing"
label value mgt_placeofbirth_depto mgt_placeofbirth_depto

recode mgt_reasontomove (8 9 =99)
label define mgt_reasontomove  1 "To look for a job" 2 "Moved with job" 3 "Education" 4 "Health" ///
	5 "Family reason" 6 "Another reason" 99 "Missing"
label value mgt_reasontomove mgt_reasontomove

recode mgt_lenghtplaceliving_b (88=99)
label define mgt_lenghtplaceliving_b 99 "Missing"
label value mgt_lenghtplaceliving_b mgt_lenghtplaceliving_b

recode edu_schooldecision (5=99)
label define edu_schooldecision 1 "Myself" 2 "Parents or tutors" 3 "The person who I work for" 4 "The person who my parents work with" 99 "Missing" 
label value edu_schooldecision edu_schooldecision

recode edu_reasnoteverenrolled (88=99)
label define edu_reasnoteverenrolled 1 "Not old enough" 2 "Disease/accident/disability" ///
				3 "School far away" 4 "Lack of money" 5 "Parents or tutors do not allow schooling" ///
				6 "School is unsafe" 7 "To learn a job occupation" 8 "For work" 9 "To help in family business" ///
				10 "House tasks/Taking care of children" 11 "Lack of interest" 12 "Other" 99 "Missing"
label value edu_reasnoteverenrolled edu_reasnoteverenrolled

recode edu_ageschoolstarted (88=99)
label define edu_ageschoolstarted 99 "Missing"
label value edu_ageschoolstarted edu_ageschoolstarted

recode edu_lastgradeapproved_a (88=99)
label define edu_lastgradeapproved_a 1 "Preschool" 2 "Primary" 3 "Secondary" 4 "Higher Education, University" ///
			5 "Higher Education, non university" 6 "Alternative Youth Education" 7 "Primary Adult Education" ///
			8 "Secondary Adult Education" 9 "None" 99 "Missing"
label value edu_lastgradeapproved_a edu_lastgradeapproved_a

recode edu_gradeacurrenattendance_a (88=99)
label define edu_gradeacurrenattendance_a 1 "Preschool" 2 "Primary" 3 "Secondary" 4 "Higher Education, University" ///
			5 "Higher Education, non university" 6 "Alternative Youth Education" 7 "Primary Adult Education" ///
			8 "Secondary Adult Education" 9 "None" 99 "Missing"
label value edu_gradeacurrenattendance_a edu_gradeacurrenattendance_a

recode edu_lastgradeapproved_b (88=99)
label define edu_lastgradeapproved_b 99 "Missing"
label value edu_lastgradeapproved_b edu_lastgradeapproved_b

label define edu_shift 1 "Morning" 2 "Afternoon" 3 "Night"
label value edu_shift edu_shift

recode edu_typeschool (8=99)
label define edu_typeschool 1 "Private" 2 "Public" 3 "Public in agreement" 99 "Missing"
label value edu_typeschool edu_typeschool

label define edu_skipschool 1 "From 1 to 3 weeks" 2 "From 3 to 6 months" 3 "I did not skip school"
label value edu_skipschool edu_skipschool

recode edu_returntoschooldecis (5=99)
label define edu_returntoschooldecis 1 "Myself" 2 "Parents or tutors" 3 "The person who I work for" 4 "The person who my parents work with" 99 "Missing"
label value edu_returntoschooldecis edu_returntoschooldecis

recode edu_attend_reasnot (88=99)
label define edu_attend_reasnot 1 "Vacation" 2 "Disease" 3 "School far away" ///
		4 "Lack of money" 5 "Lack of interest" 6 "Parents or tutor do not allow schooling" ///
		7 "School is unsafe" 8 "To learn a job occupation" 9 "For work" 10 "To help in family business" ///
		11 "House tasks/Taking care of children" 12 "Not old enough" 13 "Other" 99 "Missing"
label value edu_attend_reasnot edu_attend_reasnot

label define wrk_dedicateonehour 1 "Agricultural activities or animal husbandry" ///
			2 "Forest harvest, fishing or hunting activities" 3 "Familiar or own business activities" ///
			4 "Sell on the street, or in any other moving market stall" 5 "Craft, food preparing, knitting activities" ///
			6 "Offer services paid in cash or in kind (watching cars, announcer shoeshine, carrying bags)" ///
			7 "Assist or work in mining or harvest activities" 8 "Work as a housemaid" ///
			9 "Do any other activity in which you earned money" 10 "No activity"
label value wrk_dedicateonehour wrk_dedicateonehour		

label define wrk_impediment_b 1 "Vacation or permission" 2 "Disease or accident" ///
			3 "Lack of materials, commodities or clients" 4 "Strike or labor conflict" ///
			5 "Bad weather" 6 "Being suspended" 7 "Personal o family problems"
label value wrk_impediment_b wrk_impediment_b

recode wrk_joblocation (88=99)
label define wrk_joblocation 1 "In a private land" 2 "In the rooms of my home" ///
			3 "Mobile store" 4 "Store" 5 "Peddler" 6 "Home services" 7 "Transport vehicle" ///
			8 "Farmland" 9 "Construction area" 10 "In a private house" 11 "Other" 99 "Missing"
label value wrk_joblocation wrk_joblocation

recode wrk_amountworkers (8888=.)

recode wrk_jobposition (88=99)
label define wrk_jobposition 1 "Worker" 2 "Employee" 3 "Self employed" 4 "Employer with salary" ///
			5 "Employer without salary" 6 "Production cooperative" 7 "Apprentice without remuneration" ///
			8 "Family worker or apprentice without remuneration" 99 "Missing"
label value wrk_jobposition wrk_jobposition

recode wrk_typepayment (8=99)
label define wrk_typepayment 1 "Cash" 2 "Cash and payment in kind" 3 "Payment in kind only" 4 "I do not get paid" 99 "Missing"
label value wrk_typepayment wrk_typepayment

recode wrk_mainylab_b (8=99)
label define wrk_mainylab_b 1 "Daily" 2 "Weekly" 3 "Biweekly" 4 "Monthly" 5 "Annually" 99 "Missing" 
label value wrk_mainylab_b wrk_mainylab_b

recode wrk_mainytotal_a (888888=.)
recode wrk_mainytotal_b (8=99)
label define wrk_mainytotal_b 1 "Daily" 2 "Weekly" 3 "Biweekly" 4 "Monthly" 5 "Annually" 99 "Missing"
label value wrk_mainytotal_b wrk_mainytotal_b

recode wrk_contract (8=99)
label define wrk_contract 1 "You signed a contract with an expiration date" ///
			2 "Not signed a contract but you have a work for a product" ///
			3 "Fixed term" 4 "Not signed a contract" 99 "Missing"
label value wrk_contract wrk_contract

recode wrk_mainyafobligations_a ( 888888 =.)
recode wrk_mainyafobligations_b (8=99)
label define wrk_mainyafobligations_b 1 "Daily" 2 "Weekly" 3 "Biweekly" 4 "Monthly" 5 "Annually" 99 "Missing"
label value wrk_mainyafobligations_b wrk_mainyafobligations_b

label define wrk_jobsearch_a 1 "Asking employers" 2 "Answering or posting ads" ///
			3 "Job agency" 4 "Help from family or friends to find a job" 5 "Obtaining resources or clients" ///
			6 "Continuous queries in newspapers" 7 "Other (Specify)"
label value wrk_jobsearch_a wrk_jobsearch_a


label define wrk_jobsearch_b 0 "No second action" 1 "Asking employers" 2 "Answering or posting ads" ///
			3 "Job agency" 4 "Help from family or friends to find a job" 5 "Obtaining resources or clients" ///
			6 "Continuous queries to newspapers" 7 "Other (Specify)"
label value wrk_jobsearch_b wrk_jobsearch_b

label define wrk_jobsearch_c 0 "No third action" 1 "Asking employers" 2 "Answering or posting ads" ///
			3 "Job agency" 4 "Help from family or friends to find a job" 5 "Obtaining resources or clients" ///
			6 "Continuous queries to newspapers" 7 "Other (Specify)"
label value wrk_jobsearch_c wrk_jobsearch_c

encode wrk_timenotwork_b, gen(aux1)
drop wrk_timenotwork_b 
gen wrk_timenotwork_b= aux1
recode wrk_timenotwork_b (1 2 6=99)(3=1)(4=2)(5=3)
label define wrk_timenotwork_b 1 "Week" 2 "Month" 3 "Year" 99 "Missing"
label value wrk_timenotwork_b wrk_timenotwork_b
label variable wrk_timenotwork_b	"How long have you not worked? (Period)"
drop aux1

label define wrk_everworkbefore_b 1 "Student" 2 "Housewife or responsible of house tasks" 3 "Retired" 4 "Sick or disable" 5 "Elderly" 6 "Other"
label value wrk_everworkbefore_b wrk_everworkbefore_b

label define wrk_reasnotlookjob 1 "Secure job, I will start in less than 4 weeks" ///
	2 "Has a temporary job" 3 "I do not have enough qualifications" 4 "Tired of looking for a job" ///
	5 "Because I am studying" 6 "Retired" 7 "Not old enough" 8 "Strong disease" 9 "I do not need to work" ///
	10 "My family does not allow it" 11 "Home duties/taking care of children" 12 "Other"
label value wrk_reasnotlookjob wrk_reasnotlookjob

label define wrk_dedicateonehour2 1 "Agricultural activities or animal husbandry" ///
			2 "Forest harvest, fishing or hunting activities" 3 "Familiar or own business activities" ///
			4 "Sell on the street, or in any other moving market stall" 5 "Craft, food preparing, knitting activities" ///
			6 "Offer services paid in cash or in kind (watching cars, announcer shoeshine, carrying bags)" ///
			7 "Assist or work in mining or harvest activities" 8 "Work as a housemaid" ///
			9 "Do any other activity in which you earned money" 10 "No activity"
label value wrk_dedicateonehour2 wrk_dedicateonehour2

recode wrk_jobposition2 (88=99)
label define wrk_jobposition2 1 "Worker" 2 "Employee" 3 "Self employed" 4 "Employer with salary" ///
			5 "Employer without salary" 6 "Production cooperative" 7 "Apprentice without remuneration" ///
			8 "Family worker or apprentice without remuneration" 99 "Missing"
label value wrk_jobposition2 wrk_jobposition2

local monthwork wrk_monthsworked_*
recode `monthwork' (2=0) 

label define  wrk_monthsworked_1 1 "I worked" 0 "I did not worked"
foreach var of varlist wrk_monthsworked_1-wrk_monthsworked_13 {
    label value `var' wrk_monthsworked_1
 }
 
foreach x of varlist wrk_hrs_* {
	label variable `x' "Last week, how many hours and minutes a day did you dedicate to this job"
	recode `x' (88=99)
	
}

foreach x of varlist secnd_hrs_* {
	label variable `x' "Last week, how many hours and minutes a day did you dedicate to this job"
	recode `x' (88=99)
	
}

foreach x of varlist hse_hrs_* {
	label variable `x' "Last week, how many hours and minutes a day did you dedicate to this job"
	recode `x' (88=99)
	
}

 


label define par_idealsituation 1 "Focus mainly to work" 2 "Focus only to study" 3 "Combine work and study" ///
				4 "Focus only on home duties" 5 "Combine home duties with study" 6 "Combine home duties with work" ///
				7 "Combine home duties, work and study" 8 "Stay only at home"
label value par_idealsituation par_idealsituation

label define par_wrkeffects_a 1 "Accidents, diseases, bad health" 2 "Bad grades in school" 3 "Does not have time to go to school" ///
			4 "Tiredness" 5 "Does not have to play" 6 "Emotional abuse (Intimidation, insults)" 7 "Physical abuse" 8 "Sexual abuse" ///
			9 "Sexual harasment" 10 "None" 11 "Other" 
label value par_wrkeffects_a par_wrkeffects_a

label define par_wrkeffects_b 0 "No second option" 1 "Accidents, diseases, bad health" 2 "Bad grades in school" 3 "Does not have time to go to school" ///
			4 "Tiredness" 5 "Does not have to play" 6 "Emotional abuse (Intimidation, insults)" 7 "Physical abuse" 9 "Sexual abuse" ///
			10 "Sexual harasment" 11 "None" 12 "Other" 
label value par_wrkeffects_b par_wrkeffects_b

label define par_wrkeffects_c 0 "No third option" 1 "Accidents, diseases, bad health" 2 "Bad grades in school" 3 "Does not have time to go to school" ///
			4 "Tiredness" 5 "Does not have to play" 6 "Emotional abuse (Intimidation, insults)" 7 "Physical abuse" 9 "Sexual abuse" ///
			10 "Sexual harasment" 11 "None" 12 "Other" 
label value par_wrkeffects_c par_wrkeffects_c

label define par_reastowork_a 1 "To generate and fulfill home income" 2 "To help pay a family debt" ///
			3 "To help in family business" 4 "To acquire skills" 5 "Education is not useful for the future" ///
			6 "There is not a school/is far away" 7 "Can not afford to pay school" 8 "Child is not interested" ///
			9 "To replace someone who temporarily can not work" 10 "Impede from making bad friends" 11 "Other"
label value par_reastowork_a par_reastowork_a


label define par_reastowork_b 0 "No second reason" 1 "To generate and fulfill home income" 2 "To help pay a family debt" ///
			3 "To help in family business" 4 "To acquire skills" 5 "Education is not useful for the future" ///
			6 "There is not a school/is far away" 7 "Can not afford to pay school" 8 "Child is not interested in school" ///
			9 "To replace someone who temporarily can not work" 10 "Impede from making bad friends" 11 "Other"
label value par_reastowork_b par_reastowork_b

label define par_reastowork_c 0 "No third reason" 1 "To generate and fulfill home income" 2 "To help pay a family debt" ///
			3 "To help in family business" 4 "To acquire skills and experience" 5 "Education is not useful for the future" ///
			6 "There is not a school/is far away" 7 "Can not afford to pay school" 8 "Child is not interested" ///
			9 "To replace someone who temporarily can not work" 10 "Impede from making bad friends" 11 "Other"
label value par_reastowork_c par_reastowork_c

label define par_stopworkharm 1 "The standard of living would be reduced" 2 "Our home would no be able to survive" ///
			3 "I would have to hire someone else to do their tasks" 4 "Children would have to stop studying" 5 "Nothinig" ///
			6 "Other (Specify)" 
label value par_stopworkharm par_stopworkharm 

label define occ_cat 0 "Armed forces" 1 "Managers" 2 "Professionals" 3 "Medium level technicians" ///
			4 "Clerical support workers" 5 "Service and sales workers" 6 "Agricultural, forestry and fishery workers" ///
			7 "Manufacturing industry, construction and mines" 8 "Plant and machine operators, assemblers" ///
			9 "Unskilled workers" 99 "Missing"
label value occ_cat occ_cat

recode ecoactivity (999 888888 =99)
label define  ecoactivity 1 "Agriculture, forestry, hunting and forestry" 2 "Fishing" ///
			3 "Mines and quarries" 4 "Manufacturing industry" 5 "Water, energy and gas supply and distribution" ///
			6 "Construction" 7 "Wholesale and retail trade; vehicle repair" 8 "Accommodation and food services" ///
			9 "Transport, storage and communication" 10 "Financial services" 11 "Real estate activities" ///
			12 "Public Administration, defense and Social Security" 13 "Education" ///
			14 "Health and social services" 15 "Personal, social and communitarian services" ///
			16 "Private homes service that hire domestic service" 17 "Organizational services and Extraterritorial" ///
			99 "Missing"
label value ecoactivity ecoactivity	

*Creating a variable for child id identificator
tostring number , gen (number1)
gen aux1="0"+number1 if number<10
replace aux1=number1 if number>=10 & number!=.
gen aux2=folio+aux1
drop number1 aux1
destring folio, generate(folio1)
format folio1 %14.0g
drop folio
rename folio1 folio
destring aux2, gen(id)
format id %14.0g
drop aux2
label variable id	"Unique person's ID"


*Ordering variables
order folio number id gender age area bdate_dd bdate_mm bdate_yy maritalstatus birthcertificate ///
id_possession rel_head rel_wife_partner rel_father rel_stepfather rel_mother rel_stepmother language_childhood language_childhood_e ///
 languagespoken_a languagespoken_b languagespoken_e verification1 ind_belonging ind_belonging_e mgt_placeofbirth ///
 mgt_placeofbirth_depto mgt_placeofbirth_province mgt_placeofbirth_mun mgt_reasontomove mgt_reasontomove_e ///
 mgt_lenghtplaceliving_a mgt_lenghtplaceliving_b verification2 edu_literacy edu_everenrolled edu_schooldecision ///
 edu_reasnoteverenrolled edu_reasnoteverenrolled_e edu_ageschoolstarted edu_lastgradeapproved_a edu_lastgradeapproved_b ///
 edu_attendance edu_gradeacurrenattendance_a edu_gradeacurrenattendance_b edu_shift edu_typeschool edu_skipschool ///
 edu_returntoschooldecis edu_attend_reasnot edu_attend_reasnot_e edu_trainprogram edu_trainprogram_e edu_trainprogram_cod ///
 verification3 wrk_workedlastweek wrk_dedicateonehour wrk_impediment_a wrk_impediment_b wrk_occupation_e ///
 wrk_occupation_cod wrk_tasks_e wrk_ecoactivity_e wrk_ecoactivity_cod wrk_joblocation wrk_joblocation_e ///
 wrk_jobposition wrk_amountworkers wrk_hrs_aa wrk_hrs_ab wrk_hrs_ba wrk_hrs_bb wrk_hrs_ca wrk_hrs_cb wrk_hrs_da ///
 wrk_hrs_db wrk_hrs_ea wrk_hrs_eb wrk_hrs_fa wrk_hrs_fb wrk_hrs_ga wrk_hrs_gb wrk_typepayment verification4 ///
 wrk_mainylab_a wrk_mainylab_b wrk_contract wrk_mainyinkind_a wrk_mainyinkind_b wrk_bonus_a wrk_bonus_b ///
 wrk_mainytotal_a wrk_mainytotal_b wrk_mainyafobligations_a wrk_mainyafobligations_b ///
 wrk_availability wrk_jobsearch wrk_jobsearch_a wrk_jobsearch_b wrk_jobsearch_c ///
 wrk_jobsearch_e wrk_everworkbefore_a wrk_everworkbefore_b wrk_everworkbefore_e wrk_timenotwork_a wrk_timenotwork_b   ///
 wrk_reasnotlookjob wrk_reasnotlookjob_e wrk_workedlastyear wrk_dedicateonehour2 wrk_occupation2_e ///
 wrk_occupation2_cod wrk_ecoactivity2_e wrk_ecoactivity2_cod wrk_jobposition2 wrk_monthsworked_1 ///
 wrk_monthsworked_2 wrk_monthsworked_3 wrk_monthsworked_4 wrk_monthsworked_5 wrk_monthsworked_6 ///
 wrk_monthsworked_7 wrk_monthsworked_8 wrk_monthsworked_9 wrk_monthsworked_10 wrk_monthsworked_11 ///
 wrk_monthsworked_12 wrk_monthsworked_13 verification5 wrk_agestarwork wrk_mainjobimportance ///
 secnd_worklastweek ///
 secnd_occupation_e secnd_occupation_cod secnd_ecoactivity_e secnd_ecoactivity_cod secnd_hrs_aa secnd_hrs_ab ///
 secnd_hrs_ba secnd_hrs_bb secnd_hrs_ca secnd_hrs_cb secnd_hrs_da secnd_hrs_db secnd_hrs_ea secnd_hrs_eb ///
 secnd_hrs_fa secnd_hrs_fb secnd_hrs_ga secnd_hrs_gb trd_worklastweek trd_hrs  ///
  hse_groceries hse_cook hse_cleaning hse_laundry ///
 hse_takecare hse_repair hse_woodwater hse_none hse_hrs_aa hse_hrs_ab hse_hrs_ba hse_hrs_bb hse_hrs_ca ///
 hse_hrs_cb hse_hrs_da hse_hrs_db hse_hrs_ea hse_hrs_eb hse_hrs_fa hse_hrs_fb hse_hrs_ga hse_hrs_gb ///
 verification6 par_idealsituation par_wrkeffects_a par_wrkeffects_b par_wrkeffects_c par_wrkeffects_e ///
 par_reastowork_a par_reastowork_b par_reastowork_c par_reastowork_e par_stopworkharm par_stopworkharm_e ///
 occ_cat ecoactivity  workcondition members upm  factor surveyresult 

 
drop verification*
 
save "${relabeled_dataCS}/household_2008.dta", replace
