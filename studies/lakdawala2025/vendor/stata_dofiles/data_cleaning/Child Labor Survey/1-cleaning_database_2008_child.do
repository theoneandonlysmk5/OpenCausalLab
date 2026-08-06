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
            1: Initial Data
==================================================*/

use "${raw_dataCS}/ETI_2008/ETI_2008.dta", clear


*Renaming variables

rename nro_niad		nbr_children 
rename resfinal		surveyresult
rename id_person	number
rename s1_02		gender
rename s1_03		age
rename s1_04 		indbelonging
rename s1_04b		indbelonging_e
rename s1_05		edu_literacy
rename s1_06 		edu_everenrolled
rename s1_07		edu_reasnoteverenrolled
rename s1_07b 		edu_reasnoteverenrolled_e
rename s1_081		edu_lastgradeapproved_a
rename s1_082		edu_lastgradeapproved_b
rename s1_09 		edu_attendance 
rename s1_101		edu_lastgradeenrol_a
rename s1_102		edu_lastgradeenrol_b
rename s1_11		edu_shift
rename s1_12 		edu_missedschool
rename s1_13 		edu_missedschool_days
rename s1_14 		edu_missedschool_reason
rename s1_14b 		edu_missedschool_reason_e
rename s1_15 		edu_attend_reasnot
rename s1_15b 		edu_attend_reasnot_e
rename s1_16		verification1
rename s1_171		edu_repetition_a
rename s1_172		edu_repetition_b
rename s1_18		edu_repetition_reas
rename s1_18b		edu_repetition_reas_e
rename s1_19		edu_ageschoolattend
rename s1_20		verification2
rename s1_21 		edu_trainprogram
rename s1_22 		edu_trainprogram_e
rename codofici		edu_trainprogram_cod
rename s2_23		wrk_workedlastweek
rename s2_24		wrk_dedicateonehour
rename s2_251		wrk_impediment_a
rename s2_252		wrk_impediment_b
rename s2_26		wrk_occupation_e
rename codocp3		wrk_occupation_cod
rename s2_27		wrk_tasks_e
rename s2_28		wrk_ecoactivity_e
rename codacp3 		wrk_ecoactivity_cod
rename s2_29 		wrk_joblocation
rename s2_29b		wrk_joblocation_e
rename s2_30		wrk_jobposition
rename s2_31		wrk_typepayment 
rename s2_32		verification3
rename s2_331		wrk_mainylab_a
rename s2_332		wrk_mainylab_b
rename s2_34 		wrk_contract
rename s2_35a1		wrk_mainyinkind_a
rename s2_35a2 		wrk_mainyinkind_b
rename s2_35b1		wrk_bonus_a
rename s2_35b2		wrk_bonus_b
rename s2_361 		wrk_mainytotal_a
rename s2_362 		wrk_mainytotal_b
rename s2_371		wrk_mainyafobligations_a 
rename s2_372		wrk_mainyafobligations_b
rename s2_38		wrk_keepincome
rename s2_39 		wrk_whokeepsincome
rename s2_39b 		wrk_whokeepsincome_e
rename s2_40		verification4
rename s2_41		wrk_incomeuse
rename s2_41b		wrk_incomeuse_e
rename s2_42a		wrk_hrs_aa
rename s2_42b		wrk_hrs_ab
rename s2_42c		wrk_hrs_ba
rename s2_42d		wrk_hrs_bb
rename s2_42e		wrk_hrs_ca
rename s2_42f		wrk_hrs_cb
rename s2_42g		wrk_hrs_da
rename s2_42h		wrk_hrs_db
rename s2_42i		wrk_hrs_ea
rename s2_42j		wrk_hrs_eb
rename s2_42k		wrk_hrs_fa
rename s2_42l		wrk_hrs_fb
rename s2_42m		wrk_hrs_ga
rename s2_42n		wrk_hrs_gb
rename s2_43		wrk_employer
rename s2_43b		wrk_employer_e
rename s2_44 		wrk_ablechangeemployer
rename s2_44b		wrk_ablechangeemployer_e
rename s2_45		verification5
rename s2_46		wrk_feelingaboutjob
rename s2_471		wrk_lowincome
rename s2_472		wrk_extrahours
rename s2_473		wrk_wrkingtime
rename s2_474		wrk_extrawork
rename s2_475		wrk_laborstability
rename s2_476		wrk_unsafe
rename s2_477		wrk_streetwork
rename s2_478		wrk_dangerequipment
rename s2_479		wrk_tasks
rename s2_4710		wrk_noimproves
rename s2_4711		wrk_wrkenviroment

rename s2_48 		secnd_worklastweek
rename s2_49		secnd_occupation_e
rename codocs3 		secnd_occupation_cod
rename s2_50		secnd_ecoactivity_e
rename codacs3		secnd_ecoactivity_cod
rename s2_51a		secnd_hrs_aa
rename s2_51b		secnd_hrs_ab
rename s2_51c		secnd_hrs_ba
rename s2_51d		secnd_hrs_bb
rename s2_51e		secnd_hrs_ca
rename s2_51f		secnd_hrs_cb	
rename s2_51g		secnd_hrs_da	
rename s2_51h		secnd_hrs_db	
rename s2_51i		secnd_hrs_ea	
rename s2_51j		secnd_hrs_eb	
rename s2_51k		secnd_hrs_fa	
rename s2_51l		secnd_hrs_fb	
rename s2_51m		secnd_hrs_ga
rename s2_51n		secnd_hrs_gb

rename codoc_3r 	trd_occupation_code
rename s2_52 		trd_worklastweek
rename nroper_3		trd_nroper_3
rename s2_521		trd_animals
local animals s2_521lh s2_521lm s2_521mh s2_521mm0 s2_521nh s2_521nm s2_521jh s2_521jm s2_521vh s2_521vm s2_521sh s2_521sm s2_521dh s2_521dm
rename (`animals') _=
rename _* trd_animals_#, renumber

rename s2_522		trd_helperagricultur
rename s2_522*		trd_helperagricultur_#, renumber
rename s2_523		trd_commerce
rename s2_523*		trd_commerce_#, renumber
rename s2_524		trd_food
rename s2_524*		trd_food_#, renumber
rename s2_525		trd_announcer
rename s2_525*		trd_announcer_#, renumber
rename s2_526		trd_builder
rename s2_526*		trd_builder_#, renumber
rename s2_527		trd_bagcarrier
rename s2_527*		trd_bagcarrier_#, renumber
rename s2_528		trd_craftsman
rename s2_528*		trd_craftsman_#, renumber
rename s2_529		trd_peddler
rename s2_529*		trd_peddler_#, renumber

rename s2_5210		trd_minning

local mining s2_5210l s2_521_a s2_5210m s2_521_b s2_5210n s2_521_c s2_5210j s2_521_d s2_5210v s2_521_e s2_5210s s2_521_f s2_5210d s2_521_g
rename (`mining') _=
rename _* trd_minning_#, renumber

rename s2_52110 trd_workshop
local workshop s2_5211l s2_521_h s2_5211m s2_521_i s2_5211n s2_521_j s2_5211j s2_521_k s2_5211v s2_521_l s2_5211s s2_521_m s2_5211d s2_521_n
rename (`workshop') _=
rename _* trd_workshop_#, renumber

rename s2_5212 trd_agriculturalactivities
local agriact s2_5212l s2_521_o s2_5212m s2_521_p s2_5212n s2_521_q s2_5212j s2_521_r s2_5212v s2_521_s s2_5212s s2_521_t s2_5212d s2_521_u
rename (`agriact') _=
rename _* trd_agriculturalactivities_#, renumber

rename s2_5213 trd_carcaregiver
local car s2_5213l s2_521_v s2_5213m s2_521_w s2_5213n s2_521_x s2_5213j s2_521_y s2_5213v s2_521_z s2_5213s s2_52_aa s2_5213d s2_52_ab
rename (`car') _=
rename _* trd_carcaregiver_#, renumber

rename s2_5214 trd_juggler
local juggler s2_5214l s2_52_ac s2_5214m s2_52_ad s2_5214n s2_52_ae s2_5214j s2_52_af s2_5214v s2_52_ag s2_5214s s2_52_ah s2_5214d s2_52_ai
rename (`juggler') _=
rename _* trd_juggler_#, renumber

rename s2_5215 trd_workshop_b
local wrks s2_5215l s2_52_aj s2_5215m s2_52_ak s2_5215n s2_52_al s2_5215j s2_52_am s2_5215v s2_52_an s2_5215s s2_52_ao s2_5215d s2_52_ap
rename (`wrks') _=
rename _* trd_workshop_b#, renumber

rename s2_5216 trd_other
local other s2_5216l s2_52_aq s2_5216m s2_52_ar s2_5216n s2_52_as s2_5216j s2_52_at s2_5216v s2_52_au s2_5216s s2_52_av s2_5216d0 s2_52_aw s2_5216b
rename (`other') _=
rename _* trd_other_#, renumber


rename s2_53	wrk_shift
rename s2_54 	verification6
rename s2_55 	wrk_shift2
rename s2_56 	wrk_reastowork
rename s2_56b  	wrk_reastowork_e
rename s2_57 	wrk_stopworkharm
rename s2_57b 	wrk_stopworkharm_e
rename s2_581	rgh_syndic
rename s2_582	rgh_syndic_e
rename s2_59	wrk_availability
rename s2_60	wrk_familymemberjobsearch
rename s2_61	wrk_jobsearch
rename s2_621	wrk_jobsearch_a
rename s2_622	wrk_jobsearch_b
rename s2_623	wrk_jobsearch_c
rename s2_62b	wrk_jobsearch_e
rename s2_63	wrk_everworkbefore_a
rename s2_641	wrk_timenotwork_a
rename s2_642 	wrk_timenotwork_b
rename s2_65	wrk_everworkbefore_b
rename s2_65b	wrk_everworkbefore_e
rename s2_66	wrk_reasnotlookjob
rename s2_66b	wrk_reasnotlookjob_e
rename s2_67	wrk_workedlastyear
rename s2_681	wrk_jobinjury_a
rename s2_682	wrk_jobinjury_b
rename s2_683	wrk_jobinjury_c
rename s2_68b	wrk_jobinjury_e
rename s2_69	wrk_injuryeffects 
rename s2_69b	wrk_injuryeffects_e 
rename s2_70	wrk_injurecause
rename s2_70b 	wrk_injurecause_e
rename s2_71	wrk_heavylift 
rename s2_72	wrk_heavyequipment
rename s2_731	wrk_heavyequipment_e1
rename s2_732	wrk_heavyequipment_e2
rename s2_741	wrk_risks_a
rename s2_742	wrk_risks_b
rename s2_743	wrk_risks_c
rename s2_74b	wrk_risks_e
rename s2_751	wrk_violence_a
rename s2_752	wrk_violence_b
rename s2_753	wrk_violence_c
rename s2_75b	wrk_violence_e


rename s3_761 	hse_groceries
rename s3_762 	hse_repair
rename s3_763  	hse_cook
rename s3_764  	hse_dishes
rename s3_765  	hse_laundry
rename s3_766  	hse_babysitting
rename s3_767  	hse_woodwater
rename s3_768  	hse_other
rename s3_769 	hse_none
rename s3_771	hse_risks_a
rename s3_772	hse_risks_b
rename s3_773	hse_risks_c
rename s3_77b	hse_risks_e
rename s3_78a 	hse_hrs_aa
rename s3_78b  	hse_hrs_ab
rename s3_78c  	hse_hrs_ba
rename s3_78d  	hse_hrs_bb
rename s3_78e 	hse_hrs_ca
rename s3_78f  	hse_hrs_cb
rename s3_78g  	hse_hrs_da
rename s3_78h  	hse_hrs_db
rename s3_78i  	hse_hrs_ea
rename s3_78j  	hse_hrs_eb
rename s3_78k  	hse_hrs_fa
rename s3_78l  	hse_hrs_fb
rename s3_78m  	hse_hrs_ga
rename s3_78n 	hse_hrs_gb
rename s3_79	hse_shift
rename s3_80	verification7
rename s3_81	hse_shift2


rename s3_82	inadultcompany
rename s3_831 	adultinterference_1
rename s3_832	adultinterference_2
rename cpaeb	ecoactivity
rename ceob		occ_cat
rename urb_rur	area
rename miembros members
rename teco		wrk_status
rename condnh 	catchild

*Binary variables

local binary 	edu_everenrolled edu_attendance edu_missedschool edu_repetition_a edu_trainprogram ///
				wrk_workedlastweek wrk_impediment_a wrk_mainyinkind_a wrk_bonus_a wrk_lowincome wrk_extrahours ///
				wrk_wrkingtime wrk_extrawork wrk_laborstability wrk_unsafe wrk_streetwork wrk_dangerequipment ///
				wrk_tasks wrk_noimproves wrk_wrkenviroment secnd_worklastweek trd_worklastweek ///
				trd_animals trd_helperagricultur trd_commerce trd_food trd_announcer trd_builder ///
				trd_bagcarrier trd_craftsman trd_peddler trd_minning trd_workshop trd_agriculturalactivities ///
				trd_carcaregiver trd_juggler trd_workshop_b trd_other rgh_syndic wrk_availability wrk_familymemberjobsearch ///
				wrk_jobsearch wrk_everworkbefore_a wrk_workedlastyear wrk_heavylift wrk_heavyequipment hse_groceries ///
				hse_repair hse_cook hse_dishes hse_laundry hse_babysitting hse_woodwater hse_other ///
				hse_none inadultcompany adultinterference_1
recode `binary' (2=0)
label define binaria  0 "No" 1 "Yes"
label value `binary' binaria

recode edu_literacy (8=99) (2=0)
label define edu_literacy 0 "No" 1 "Yes" 99 "Missing"
label value edu_literacy edu_literacy

recode gender (2=0)
label define gender 0 "Female" 1 "Male" 
label value gender gender


recode area (2=0)
label define area 0 "Rural" 1 "Urban"
label value area area



*Labeling variables

label variable folio 		"Household ID"
label variable nbr_children		"Number of children and teenagers"
label variable number				"Personal number in household"
label variable surveyresult 			"Final survey results"
label variable gender				"Gender"
label variable age					"How old are you?"
label variable indbelonging			"Do you consider yourself as part of the following indigenous groups?"
label variable indbelonging_e		"Do you consider yourself as part of the following indigenous groups?"
label variable edu_literacy			"Can you read and write?"
label variable edu_everenrolled 		"Have you ever enrolled in preschool, primary or an alternative school?"
label variable edu_reasnoteverenrolled 	"Why have you never been to school?"
label variable edu_reasnoteverenrolled_e "Why have you never been to school?"
label variable edu_lastgradeapproved_a	"What was the last level or grade higher that you approved? (Level)"
label variable edu_lastgradeapproved_b	"What was the last level or grade higher that you approved? (Grade)"
label variable edu_attendance 			"Are you currently attending to preshool, school, an institute or university?" 
label variable edu_lastgradeenrol_a		"In which grade or level you have enrolled this year (2008)(Level)?"
label variable edu_lastgradeenrol_b		"In which grade or level you have enrolled this year (2008)(Grade)?"
label variable edu_shift 				"School shift"
label variable edu_missedschool 					"Did you miss any day of school last week?"
label variable edu_missedschool_days				"How many days did you miss clases the previous week?"
label variable edu_missedschool_reason				"Why did you miss classes?"
label variable edu_missedschool_reason_e			"Why did you miss classes? (Specify)"
label variable edu_attend_reasnot 				"Reasons why you do not attend to school"
label variable edu_attend_reasnot_e				"Reasons why you do not attend to school. Specify"
label variable verification1					"Check question edu_lastgradeapproved"
label variable edu_repetition_a					"Did you ever repeat primary or secondary school?"
label variable edu_repetition_b 				"How many times have you repeated a course"	
label variable edu_repetition_reas				"Reasons why you repeated a course"
label variable edu_repetition_reas_e			"Reasons why you repeated a course. Specify"
label variable edu_ageschoolattend				"At what age did you start attending to primary/alternative school?"
label variable verification2					"Group age"
label variable edu_trainprogram 				"Have you ever attend a job training program? (Carpentry, Hairdressing) "
label variable edu_trainprogram_e 				"Have you ever attend a job training program? (Carpentry, Hairdressing) Specify"
label variable edu_trainprogram_cod 			"Have you ever attend a job training program? (Carpentry, Hadressing) Cod"
label variable wrk_workedlastweek				"During last week, did you work at least an hour?"
label variable wrk_dedicateonehour 				"During last week, did you dedicate at least one hour to:"
label variable wrk_impediment_a 					"Last week, did you have any work or activity that you could not do?"
label variable wrk_impediment_b					"What was the impediment?"
label variable wrk_occupation_e			"Last week, what was you main occupation. Specify"
label variable wrk_occupation_cod		"Main occupation code"
label variable wrk_tasks_e				"What are your tasks? Specify"
label variable wrk_ecoactivity_e		"What is the main economic activity of your company? Specify"
label variable wrk_ecoactivity_cod		"Main economic activity code"
label variable wrk_joblocation			"Where do you do this job?"
label variable wrk_joblocation_e		"Where do you do this job? Specify"
label variable wrk_jobposition			"In this job, you are:"
label variable wrk_typepayment			"For the job that you do, how do you get paid?"
label variable verification3			"Check question wrk_jobposition"
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
label variable wrk_keepincome			"Can you keep what you earn?"
label variable wrk_whokeepsincome		"To whom do you give what you earn?"
label variable wrk_whokeepsincome_e 	"To whom do you give what you earn? Specify"
label variable verification4 			"Check questions wrk_typepayment wrk_keepincome"
label variable wrk_incomeuse			"What do you spend your income into:"
label variable wrk_incomeuse_e			"What do you spend your income into: Specify"
foreach x of varlist wrk_hrs_* {
	label variable `x' "Last week, how many hours and minutes a day did you dedicate to this job"
}
label variable wrk_employer 			"Who do you work for?"
label variable wrk_employer_e 			"Who do you work for? Specify"
label variable wrk_ablechangeemployer	"Are you able to change employer?"
label variable wrk_ablechangeemployer_e	"Are you able to change employer? Specify"
label variable verification5 			"Group age"
label variable wrk_feelingaboutjob 		"How do you feel at work?"
label variable wrk_lowincome			"Dissatisfaction: having low income"
label variable wrk_extrahours 			"Dissatisfaction: working many hours"
label variable wrk_wrkingtime 			"Dissatisfaction: Inconvenient working hours"
label variable wrk_extrawork 			"Dissatisfaction: Excessive workload"
label variable wrk_laborstability		"Dissatisfaction: Not having labor stability"
label variable wrk_unsafe 				"Dissatisfaction: Working in an unsafe and an healthy environment"
label variable wrk_streetwork 			"Dissatisfaction: Working in the street"
label variable wrk_dangerequipment 		"Dissatisfaction: working with dangerous equipment"
label variable wrk_tasks 				"Dissatisfaction: Due to the tasks I do"
label variable wrk_noimproves 			"Dissatisfaction: Few possibilities of job improvement"
label variable wrk_wrkenviroment		"Dissatisfaction: Due to the work environment"
label variable secnd_worklastweek		"Besides the mentioned job, did you have another job last week?"
label variable secnd_occupation_e		"Last week, what was your secondary occupation. Specify"
label variable secnd_occupation_cod		"Last week, what was your secondary occupation. Cod"
label variable secnd_ecoactivity_e 		"What in the main economic activity of your secondary work enterprise? Specify"
label variable secnd_ecoactivity_cod	"What in the main economic activity of your secondary work enterprise? Cod"
foreach x of varlist secnd_hrs_* {
	label variable `x' "Last week, how many hours and minutes a day did you dedicate to this job"
}
label variable trd_occupation_code		"What was your third occupation. Code"
label variable trd_worklastweek			"Besides the main and secondary activities you mentioned, did you have another job last week?"
label variable trd_nroper_3 			"People's number. Third occupation"


label variable trd_animals				"Assistance animal husbandry"
label variable trd_helperagricultur 	"Assistance agricultural activities"
label variable trd_commerce 			"Assistance in commercial activities"
label variable trd_food 				"Kitchen assistance"
label variable trd_announcer 			"Working as an announcer"
label variable trd_builder 				"Builder assistance"
label variable trd_bagcarrier			"Bag carrier"
label variable trd_craftsman 			"Craftsman"
label variable trd_peddler 				"Peddler"
label variable trd_minning 				"Assistance in mining activities"
label variable trd_workshop 			"Assistance in workshops"
label variable trd_agriculturalactivities "Working in agricultural activities"
label variable trd_carcaregiver 		"Car caregiver"
label variable trd_juggler 				"Juggler"
label variable trd_workshop_b 			"Working in agricultural activities"
label variable trd_other				"Other"

foreach var of varlist trd_animals_* {
label variable `var' "Assistance Animal husbandry"
}
foreach var of varlist trd_helperagricultur_*{
label variable `var' "Assistance agricultural activities"
}
foreach var of varlist trd_commerce_* {
label variable `var' "Assistance in commercial activities"
}
foreach var of varlist trd_food_* {
label variable `var' "Kitchen assistance"
}
foreach var of varlist trd_announcer_* {
label variable `var' "Working as an announcer"
}
foreach var of varlist trd_builder_* {
label variable `var' "Builder assistance"
}
foreach var of varlist  trd_bagcarrier_* {
label variable `var' "Bag carrier"
}
foreach var of varlist  trd_craftsman_*  {
label variable `var' "Craftsman"
}
foreach var of varlist trd_peddler_*  {
label variable `var' "Peddler"
}
foreach var of varlist trd_minning_* {
label variable `var' "Assistance in mining activities"
}
foreach var of varlist trd_workshop_* {
label variable `var' "Assistance in workshops"
}
foreach var of varlist trd_agriculturalactivities_* {
label variable `var' "Working in agricultural activities"
}
foreach var of varlist trd_carcaregiver_* {
label variable `var' "Car caregiver"
}
foreach var of varlist trd_juggler_*  {
label variable `var' "Juggler" 
}
foreach var of varlist trd_workshop_b* {
label variable `var' "Working in agricultural activities"
}
foreach var of varlist trd_other_* {
label variable `var' "Other"
}

label variable wrk_shift 			"Last week, your shift was:"
label variable verification6		"Check edu_attendance"
label variable wrk_shift2			"Last week, your shift was:"
label variable wrk_reastowork 		"Main reasons you do this job:"
label variable wrk_reastowork_e		"Main reasons you do this job:"
label variable wrk_stopworkharm		"If you had to leave this job, who would it harm the most?"
label variable wrk_stopworkharm_e	"If you had to leave this job, who would it harm the most?"
label variable rgh_syndic 			"Do you belong to any labor union?"
label variable rgh_syndic_e			"Do you belong to any labor union? Specify"
label variable wrk_availability		"Last week, did you want to work and were you available?"
label variable wrk_familymemberjobsearch "Last week, did any family member searched a job for you?"
label variable wrk_jobsearch		"Last week, did you search for a job or try to open a business"
label variable wrk_jobsearch_a 		"What did you do?"
label variable wrk_jobsearch_b 		"What did you do?"
label variable wrk_jobsearch_c 		"What did you do?"
label variable wrk_jobsearch_e 		"What did you do? Specify"
label variable wrk_everworkbefore_a "Have you ever worked or done an activity to earn money before?"
label variable wrk_timenotwork_a	"How long have you not worked? (time)"
label variable wrk_everworkbefore_b	"If you have not, you are:"
label variable wrk_everworkbefore_e	"If you have not, you are:"
label variable wrk_reasnotlookjob	"Why have you not looked for a job?"
label variable wrk_reasnotlookjob_e	"Why have you not looked for a job? Specify"
label variable wrk_workedlastyear	"Have you worked in the last 12 months"
label variable wrk_jobinjury_a 		"Did you have any of the following injuries in your job?"
label variable wrk_jobinjury_b 		"Did you have any of the following injuries in your job?"
label variable wrk_jobinjury_c 		"Did you have any of the following injuries in your job?"
label variable wrk_jobinjury_e 		"Did you have any of the following injuries in your job? Specify"
label variable wrk_injuryeffects	"How were you affected by the worst injury?"
label variable wrk_injuryeffects_e 	"How were you affected by the worst injury? Specify"
label variable wrk_injurecause		"What were you doing when you had your most serious injury?"
label variable wrk_injurecause_e	"What were you doing when you had your most serious injury? Specify"
label variable wrk_heavylift		"Do you lift heavy loads in this job?"
label variable wrk_heavyequipment	"Do you consider that the machines or equipment you use at work are dangerous?"
label variable wrk_heavyequipment_e1 "Do you consider that the machines or equipment you use at work are dangerous?"
label variable wrk_heavyequipment_e2 "Do you consider that the machines or equipment you use at work are dangerous?"
label variable wrk_risks_a			"Are you exposed to any of the following elements:"
label variable wrk_risks_b			"Are you exposed to any of the following elements:"
label variable wrk_risks_c			"Are you exposed to any of the following elements:"
label variable wrk_risks_e			"Are you exposed to any of the following elements:"
label variable wrk_violence_a		"While working, has this happened to you?"
label variable wrk_violence_b		"While working, has this happened to you?"
label variable wrk_violence_c		"While working, has this happened to you?"
label variable wrk_violence_e		"While working, has this happened to you? Specify"
label variable hse_groceries		"For this home, did you buy groceries"
label variable hse_repair  			"For this home, did you did you repair any equipment"
label variable hse_cook  			"For this home, did you did you	cook?"
label variable hse_dishes  			"For this home, did you did you do the dishes or clean the house?"
label variable hse_laundry  		"For this home, did you did you do laundry?"
label variable hse_babysitting  	"For this home, did you babysit or take care of elderly or sick?"
label variable hse_woodwater  		"For this home, did you pick up wood or water?"
label variable hse_other 			"For this home, did you do any other task"
label variable hse_none				"None"		
label variable hse_risks_a 			"Are you exposed to any of the following elements:"
label variable hse_risks_b 			"Are you exposed to any of the following elements:"
label variable hse_risks_c 			"Are you exposed to any of the following elements:"
label variable hse_risks_e 			"Are you exposed to any of the following elements:"
foreach x of varlist hse_hrs_* {
	label variable `x' "Last week, how many hours and minutes a day did you dedicate to this job"
}
label variable hse_shift			"Last week, when did you do your activities?"
label variable hse_shift2			"Last week, when did you do your activities?"
label variable verification7		"Check question edu_attendance"
label variable inadultcompany		"Pollster: was this survey done in company of an adult?"
label variable adultinterference_1 	"Pollster: Do you think the presence of another person caused interference in the survey?"
label variable ecoactivity 			"Economic Activity Classification code"
label variable catchild 			"Child working condition"
label variable codh1				"Type of tool code"
label variable codh2				"Type of tool code"
label variable occ_cat 				"Occupation Classification Code"
label variable upm 					"Primary unit sample"
label variable area					"Urban rural"
label variable factor 				"Expansion factor"
label variable members				"Members"
label variable wrk_status			"Child/Teenager working condition"


*Categorical variables

label define surveyresult 1 "Complete interview" 2 "Incomplete interview" 3 "Temporaly absent" 4 "Unqualified respondent" ///
				5  "Lack of contact" 6 "Rejection" 7 "Unnocupied house" 8 "Father and mother refused" ///
				9 "Lack of data from one of the children"
label value surveyresult surveyresult

recode indbelonging (8=99)
label define indbelonging 1 "Quechua" 2 "Aymara" 3 "Guarani" 4 "Chiquitano" 5 "Mojeño" ///
				6 "Other (specify)" 7 "None" 99 "Incomplete information"
label value indbelonging indbelonging

label define edu_reasnoteverenrolled 1 "Not old enough" 2 "Disease/accident/disability" ///
				3 "School far away" 4 "Lack of money" 5 "Lack of interest" 6 "Family thinks education is not important" ///
				7 "School is unsafe" 8 "To learn a job occupation" 9 "For work" ///
				10 "To help in family business" 11 "House tasks/Taking care of children" 12 "Other"
label value edu_reasnoteverenrolled edu_reasnoteverenrolled

recode edu_lastgradeapproved_a (88=99)
label define edu_lastgradeapproved_a 1 "Preschool" 2 "Primary" 3 "Secondary" 4 "Higher Education, University" ///
			5 "Higher Education, non university" 6 "Alternative Youth Education" 7 "Primary Adult Education" ///
			8 "Secondary Adult Education" 9 "None" 99 "Missing"
label value edu_lastgradeapproved_a edu_lastgradeapproved_a

recode edu_lastgradeapproved_b (88=99)

recode edu_lastgradeenrol_a (99=99)
label define edu_lastgradeenrol_a 1 "Preschool" 2 "Primary" 3 "Secondary" 4 "Higher Education, University" ///
			5 "Higher Education, non university" 6 "Alternative Youth Education" 7 "Primary Adult Education" ///
			8 "Secondary Adult Education" 9 "None" 99 "Missing"
label value edu_lastgradeenrol_a edu_lastgradeenrol_a

label define edu_shift 1 "Morning" 2 "Afternoon" 3 "Night"
label values edu_shift edu_shift

label define edu_missedschool_reason 1 "School break" 2 "Teacher missed classes" ///
		3 "Bad weather" 4 "To work or assist in family business" 5 "To work or assist outside of family business" ///
		6 "To help with house tasks" 7 "Disease/Injury/Disability" 8 "Other"
		
label value edu_missedschool_reason edu_missedschool_reason

recode edu_attend_reasnot (88=99)
label define edu_attend_reasnot 1 "Vacation" 2 "Disease/accident/disability" 3 "School far away" ///
		4 "Lack of money" 5 "Lack of interest" 6 "Family thinks education is not important" ///
		7 "School is unsafe" 8 "To learn a job occupation" 9 "For work" 10 "To help in family business" ///
		11 "House tasks/Taking care of children" 12 "Other" 99 "Missing"
label value edu_attend_reasnot edu_attend_reasnot

label define edu_repetition_reas 1 "Lack of time to study, for working in family business" 2 "Lack of time to study, for working outside of home" ///
		3 "Health issues" 4 "I do not understand the teacher" 5 "To do home tasks" 6 "Other" 
label value edu_repetition_reas edu_repetition_reas

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

label define wrk_joblocation 1 "Private land" 2 "In the rooms of my house" ///
			3 "Mobile store" 4 "Store" 5 "Peddler" 6 "Home services" 7 "Transport vehicle" ///
			8 "Farmland" 9 "Construction area" 10 "In a private house" 11 "Other"
label value wrk_joblocation wrk_joblocation

label define wrk_jobposition 1 "Worker" 2 "Employee" 3 "Self employed" 4 "Housemaid" ///
			5 "Employer with salary" 6 "Employer without salary" 7 "Production cooperative" ///
			8 "Apprentice without remuneration"
label value wrk_jobposition wrk_jobposition

label define wrk_typepayment 1 "Cash" 2 "Cash and payment in kind" 3 "Payment in kind only" 4 "I do not get paid"
label value wrk_typepayment wrk_typepayment

label define wrk_mainylab_b 1 "Daily" 2 "Weekly" 3 "Biweekly" 4 "Monthly" 
label value wrk_mainylab_b wrk_mainylab_b

label define wrk_contract 1 "You signed a contract with an expiration date" ///
			2 "Not signed a contract but you have a work for a product" ///
			3 "Fixed term" 4 "Not signed a contract"
label value wrk_contract wrk_contract

recode wrk_mainytotal_b (8=99)
label define wrk_mainytotal_b 1 "Daily" 2 "Weekly" 3 "Biweekly" 4 "Monthly" 5 "Annually" 99 "Missing"
label value wrk_mainytotal_b wrk_mainytotal_b

recode wrk_mainyafobligations_b (8=99)
label define wrk_mainyafobligations_b 1 "Daily" 2 "Weekly" 3 "Biweekly" 4 "Monthly" 5 "Annually" 99 "Missing"
label value wrk_mainyafobligations_b wrk_mainyafobligations_b

label define wrk_keepincome 1 "Yes, with everything" 2 "I keep a small part" 3 "I do not keep anything"
label value wrk_keepincome wrk_keepincome

label define wrk_whokeepsincome 1 "To my parents" 2 "To the person I work with" ///
			3 "to an intermediary" 4 "Other (specify)"
label value wrk_whokeepsincome wrk_whokeepsincome


label define wrk_incomeuse 1 "School payments" 2 "Buy things for my home" 3 "Buy things for myself" ///
			4 "Savings" 5 "Other (specify)"
label value wrk_incomeuse wrk_incomeuse

foreach x of varlist wrk_hrs_* {
	label variable `x' "Last week, how many hours and minutes a day did you dedicate to this job"
	recode `x' (88=99)
	
}


label define wrk_employer 1 "For my parents or members of my house" 2 "For a family member of another home" ///
			3 "For a family friend" 4 "For an employer" 5 "Other (specify)"
labe value wrk_employer wrk_employer

recode wrk_ablechangeemployer (8=99)
label define wrk_ablechangeemployer 1 "Yes, at any moment" 2 "Yes, as long as the terms of the contract are respected" ///
			3 "It is difficult, there is a lack of opportunities" 4 "Imposible, the employer would not agree" 5 "Other (specify)" 99 "Missing"
label value wrk_ablechangeemployer wrk_ablechangeemployer
label define wrk_feelingaboutjob 1 "Very satisfied" 2 "Satisfied" 3 "unsatisfied" 
label value wrk_feelingaboutjob wrk_feelingaboutjob

label define wrk_shift 1 "Daytime Between 6 a.m. to 7 p.m" 2 "At night (Between 7 p.m. to 6 a.m." ///
			3 "Mixed shift, including night shift"
label value wrk_shift wrk_shift

recode wrk_shift2 (8=99)
label define wrk_shift2 1 "After school/university/institute" 2 "Before school/university/institute" ///
			3 "Before and after school/university/institute" 4 "Weekends" 5 "During the missing days of attendance" ///
			6 "In vacation" 99 "Missing"
label value wrk_shift2 wrk_shift2

label define wrk_reastowork 1 "To generate and fulfill home income" 2 "To help pay a family debt" ///
			3 "To help in family business" 4 "To acquire skills" 5 "Education is not useful for the future" ///
			6 "There is not a school/is far away" 7 "I can not afford to pay school" 8 "I am not interested" ///
			9 "To replace someone who temporarily can not work" 10 "Other"
label value wrk_reastowork wrk_reastowork

recode wrk_stopworkharm (8=99)
label define wrk_stopworkharm 1 "The standard of living would be reduced" 2 "My home would no be able to survive" ///
			3 "They would have to hire someone else to do my tasks" 4 "I would have to stop studying" 5 "Nothing" ///
			6 "Other (specify)" 99 "Missing"
label value wrk_stopworkharm wrk_stopworkharm

label define wrk_jobsearch_a 1 "Asking employers" 2 "Answering or posting ads" ///
			3 "Job agency" 4 "Help from family or friends to find a job" 5 "Obtaining resources or clients" ///
			6 "Continuous queries in newspapers" 7 "Other (specify)"
label value wrk_jobsearch_a wrk_jobsearch_a

label define wrk_jobsearch_b 0 "No second action" 1 "Asking employers" 2 "Answering or posting ads" ///
			3 "Job agency" 4 "Help from family or friends to find a job" 5 "Obtaining resources or clients" ///
			6 "Continuous queries to newspapers" 7 "Other (specify)"
label value wrk_jobsearch_b wrk_jobsearch_b

label define wrk_jobsearch_c 0 "No thrid action" 1 "Asking employers" 2 "Answering or posting ads" ///
			3 "Job agency" 4 "Help from family or friends to find a job" 5 "Obtaining resources or clients" ///
			6 "Continuous queries to newspapers" 7 "Other (specify)"
label value wrk_jobsearch_c wrk_jobsearch_c

label define wrk_everworkbefore_b 1 "Student" 2 "Housewife or responsible of house tasks" 3 "Sick or disable" 4 "Other"
label value wrk_everworkbefore_b wrk_everworkbefore_b

label define wrk_timenotwork_a 88 "Missing"
label value wrk_timenotwork_a wrk_timenotwork_a

encode wrk_timenotwork_b, gen(aux1)
drop wrk_timenotwork_b 
gen wrk_timenotwork_b= aux1
recode wrk_timenotwork_b (1 2=99)(3=1)(4=2)(5=3)
label define wrk_timenotwork_b 1 "Week" 2 "Month" 3 "Year" 99 "Missing"
label value wrk_timenotwork_b wrk_timenotwork_b
label variable wrk_timenotwork_b	"How long have you not worked? (Period)"


label define wrk_reasnotlookjob 1 "Secure job, I will start in less than 4 weeks" ///
	2 "Has a temporary job" 3 "I do not have enough qualifications required by the market" 4 "Tired of looking for a job" ///
	5 "Because I am studying" 6 "Not old enough" 7 "Strong disease" 8 "I do not need to work" ///
	9 "My family does not allow it" 10 "Home duties/taking care of children" 11 "Other"
label value wrk_reasnotlookjob wrk_reasnotlookjob

label define wrk_jobinjury_a 1 "Superficial injuries or bites, blisters, etc" ///
			2 "Fractures or mutilations" 3 "Dislocation or distention" 4 "Burns, scalds or freezing" ///
			5 "Respiratory problems" 6 "Sight problems" 7 "Skin injuries" 8 "Stomach problems, diarrhea or chemical poisoning" ///
			9 "Fever" 10 "Exhaustion for tasks intensity" 11 "Other" 12 "None"
labe value wrk_jobinjury_a wrk_jobinjury_a

label define wrk_jobinjury_b 0 "No second injury" 1 "Superficial injuries or bites, blisters, etc" ///
			2 "Fractures or mutilations" 3 "Dislocation or distention" 4 "Burns, scalds or freezing" ///
			5 "Respiratory problems" 6 "Sight problems" 7 "Skin injuries" 8 "Stomach problems, diarrhea or chemical poisoning" ///
			9 "Fever" 10 "Exhaustion for tasks intensity" 11 "Other" 12 "None"
label value wrk_jobinjury_b wrk_jobinjury_b

label define wrk_jobinjury_c 0 "No third injury" 1 "Superficial injuries or bites, blisters, etc" ///
			2 "Fractures or mutilations" 3 "Dislocation or distention" 4 "Burns, scalds or freezing" ///
			5 "Respiratory problems" 6 "Sight problems" 7 "Skin injuries" 8 "Stomach problems, diarrhea or chemical poisoning" ///
			9 "Fever" 10 "Exhaustion for tasks intensity" 11 "Other" 12 "None"
label value wrk_jobinjury_c wrk_jobinjury_c



label define wrk_injuryeffects 1 "Permanently disabled" 2 "Impeded me from doing regular work" ///
			3 "I stopped working temporarily" 4 "I had to change job" 5 "Left school temporarily" ///
			6 "Left school permanently" 7 "It was not serious" 8 "Other (specify)"
label value wrk_injuryeffects wrk_injuryeffects

label define wrk_injurecause 1 "Working" 2 "Helping in family business" 3 "Car caregiver/shoeshine" ///
			4 "Plowing, harvesting or caring for cattle" 5 "Picking up wood or water for home use" ///
			6 "Playing in school or in the street" 7 "Doing home tasks" 8 "Other (specify)"
label value wrk_injurecause wrk_injurecause

label define wrk_risks_a 1 "Dirt or dust" 2 "Fire, gas, flames" ///
			3 "Loud noise or vibrations" 4 "Extreme heat or cold" 5 "Dangerous instruments (knives, explosives, etc)" ///
			6 "Underground work" 7 "Work at height" 8 "Work in water" 9 "Darkness or confinement" ///
			10 "Insufficient ventilation" 11 "Chemical products (pesticide, glue)" 12 "Explosives" 13 "Other" 14 "None"
label value wrk_risks_a wrk_risks_a

label define wrk_risks_b 0 "No second risks" 1 "Dirt or dust" 2 "Fire, gas, flames" ///
			3 "Loud noise or vibrations" 4 "Extreme heat or cold" 5 "Dangerous instruments (knives, explosives, etc)" ///
			6 "Underground work" 7 "Work at height" 8 "Work in water" 9 "Darkness or confinement" ///
			10 "Insufficient ventilation" 11 "Chemical products (pesticide, glue)" 12 "Explosives" 13 "Other" 14 "None" 13 "Other" 14 "None"
label value wrk_risks_b wrk_risks_b


label define wrk_risks_c 0 "No third risks" 1 "Dirt or dust" 2 "Fire, gas, flames" ///
			3 "Loud noise or vibrations" 4 "Extreme heat or cold" 5 "Dangerous 	instruments (knives, explosives, etc)" ///
			6 "Underground work" 7 "Work at height" 8 "Work in water" 9 "Darkness or confinement" ///
			10 "Insufficient ventilation" 11 "Quimic products (pesticide, glue)" 12 "Explosives" 13 "Other" 14 "None"
label value wrk_risks_c wrk_risks_c

label define wrk_violence_a	1 "Being yelled often" 2 "Being insulted often" ///
			3 "Being physically abused (beaten, hurt)" 4 "Impeded from eaten" 5 "Impeded from getting paid" ///
			6 "Being forbidden to leave" 7 "Sexual abused or molested" ///
			8 "Other" 9 "None"
label value wrk_violence_a wrk_violence_a

label define wrk_violence_b	0 "No second option" 1 "Being yelled often" 2 "Being insulted often" ///
			3 "Being physically abused (beaten, hurt)" 4 "Impeded from eaten" 5 "Impeded from getting paid" ///
			6 "Being forbidden to leave" 7 "Sexual abused or molested" ///
			8 "Other" 9 "None"
label value wrk_violence_b wrk_violence_b

label define wrk_violence_c	0 "No second option" 1 "Being yelled often" 2 "Being insulted often" ///
			3 "Being physically abused (beaten, hurt)" 4 "Impeded from eaten" 5 "Impeded from getting paid" ///
			6 "Being forbidden to leave" 7 "Sexual abused or molested" ///
			8 "Other" 9 "None"
label value wrk_violence_c wrk_violence_c

foreach x of varlist secnd_hrs_* {
	label variable `x' "Last week, how many hours and minutes a day did you dedicate to this job"
	recode `x' (88=99)
	
}

foreach x of varlist hse_hrs_* {
	label variable `x' "Last week, how many hours and minutes a day did you dedicate to this job"
	recode `x' (88=99)
	
}


recode hse_risks_a (88=99)
recode hse_risks_b (88=99)
recode hse_risks_c (88=99)

label define hse_risks_a 1 "Dirt or dust" 2 "Fire, gas, flames" ///
			3 "Extreme cold" 4 "Dangerous instruments (knives, explosives, etc)" 5 "Work at heigh" ///
			6 "Work in water" 7 "Darkness or confinement" 8 "Insufficient ventilation" 9 "Quimic products (pesticide, glue)" ///
			10 "Diseases" 11 "Other" 12 "None" 99 "Missing"
label value hse_risks_a hse_risks_a

label define hse_risks_b 0 "No second option "1 "Dirt or contaminated dust" 2 "Fire, gas, flames" ///
			3 "Extreme cold" 4 "Dangerous instruments (knives, explosives, etc)" 5 "Work at heigh" ///
			6 "Work in water" 7 "Darkness or confinement" 8 "Insufficient ventilation" 9 "Quimic products (pesticide, glue)" ///
			10 "Diseases" 11 "Other" 12 "None" 99 "Missing"
label value hse_risks_b hse_risks_b

label define hse_risks_c 0 "No third option" 1 "Dirt or contaminated dust" 2 "Fire, gas, flames" ///
			3 "Extreme cold" 4 "Dangerous instruments (knives, explosives, etc)" 5 "Work at heigh" ///
			6 "Work in water" 7 "Darkness or confinement" 8 "Insufficient ventilation" 9 "Quimic products (pesticide, glue)" ///
			10 "Diseases" 11 "Other" 12 "None" 99 "Missing"
label value hse_risks_c hse_risks_c

label define hse_shift 1 "Daytime Between 6 a.m. to 7 p.m" 2 "At night (Between 7 p.m. to 6 a.m." ///
			3 "Mixed shift, including night shift"
label value hse_shift hse_shift
			
recode hse_shift2 (8=99)
label define hse_shift2 1 "After school/university/institute" 2 "Before school/university/institute" ///
			3 "Before and after school/university/institute" 4 "Weekends" 5 "During the missing attendance days" ///
			6 "In vacation" 99 "Missing"
label value hse_shift2 hse_shift2

encode adultinterference_2, gen(aux2)
drop adultinterference_2 
gen adultinterference_2= aux2

recode adultinterference_2 (1 4=99)(2=1)(3=2)
label define adultinterference_2 1 "High" 2 "Low" 99 "Missing"
label value adultinterference_2 adultinterference_2
label variable adultinterference_2	"Pollster: In which degree"

recode catchild (10=1)(11=2)(12=3)
label define catchild 1 "Child who works, in a home of working children" ///
		2 "Child who does not work, in a home of working children" ///
		3 "Child who does not work, in a home of non working children"
label value catchild catchild


recode ecoactivity (99=99)
label define  ecoactivity 1 "Agriculture, forestry, hunting and forestry" 2 "Fishing" ///
			3 "Mines and quarries" 4 "Manufacturing industry" 5 "Water, enegry and gas supply and distribution" ///
			6 "Construction" 7 "Wholesale and retail trade; vehicle repair" 8 "Accomodation services and food services" ///
			9 "Transport and storage" 10 "Financial services" 11 "Real estate activities" ///
			12 "Public Administration, defense and Social Security" 13 "Education" ///
			14 "Health and social services" 15 "Personal, social and comunitarian services" ///
			16 "Private homes service that hire domestic service" 17 "Organizational services and Extraterritorial" ///
			99 "Missing"
label value ecoactivity ecoactivity	

label define occ_cat 1 "Managers" 2 "Professionals" 3 "Medium level technicians" ///
			4 "Clerical support workers" 5 "Service and sales workers" 6 "Agricultural, forestry and fishery workers" ///
			7 "Officers, Operators and Craftsmen" 8 "Plant and machine operators, assemblers" ///
			9 "Uneskilled workers"
label value occ_cat occ_cat

label define wrk_status 0 "Without labor activity o work" 1 "With labor activity o work"
label value wrk_status wrk_status


drop aux*

*Creating a variable for child id identificator

tostring number , gen (number1)
gen aux1="0"+number1 if number<10
replace aux1=number1 if number>=10 & number!=.
tostring folio , gen (folio1)
gen aux2=folio1+aux1
drop number1 aux1 folio1
format folio %14.0g
destring aux2, gen(id)
format id %14.0g
drop aux2

label variable id	"Unique person's ID"





*Ordering variables		

order folio nbr_children id number gender age area indbelonging* edu_literacy edu_everenrolled edu_reasnoteverenrolled ///
edu_reasnoteverenrolled_e edu_lastgradeapproved_a edu_lastgradeapproved_b edu_attendance edu_lastgradeenrol_a ///
edu_lastgradeenrol_b edu_shift edu_missedschool edu_missedschool_days edu_missedschool_reason edu_missedschool_reason_e ///
edu_attend_reasnot edu_attend_reasnot_e verification1 edu_repetition_a edu_repetition_b edu_repetition_reas ///
edu_repetition_reas_e edu_ageschoolattend verification2 edu_trainprogram edu_trainprogram_e edu_trainprogram_cod ///
wrk_workedlastweek wrk_dedicateonehour wrk_impediment_a wrk_impediment_b wrk_occupation_e wrk_occupation_cod wrk_tasks_e ///
wrk_ecoactivity_e wrk_ecoactivity_cod wrk_joblocation wrk_joblocation_e wrk_jobposition wrk_typepayment verification3 ///
wrk_mainylab_a wrk_mainylab_b wrk_contract wrk_mainyinkind_a wrk_mainyinkind_b wrk_bonus_a wrk_bonus_b wrk_mainytotal_a ///
wrk_mainytotal_b wrk_mainyafobligations_a wrk_mainyafobligations_b wrk_keepincome wrk_whokeepsincome wrk_whokeepsincome_e ///
verification4 wrk_incomeuse wrk_incomeuse_e wrk_hrs_* wrk_employer wrk_employer_e wrk_ablechangeemployer wrk_ablechangeemployer_e ///
verification5 wrk_feelingaboutjob wrk_lowincome wrk_extrahours wrk_wrkingtime wrk_extrawork wrk_laborstability wrk_unsafe ///
wrk_streetwork wrk_dangerequipment wrk_tasks wrk_noimproves wrk_wrkenviroment wrk_shift wrk_shift2  verification6 ///
wrk_reastowork wrk_reastowork_e wrk_stopworkharm wrk_stopworkharm_e wrk_availability wrk_familymemberjobsearch ///
wrk_jobsearch wrk_jobsearch_a wrk_jobsearch_b wrk_jobsearch_c wrk_jobsearch_e wrk_everworkbefore_a wrk_everworkbefore_b wrk_everworkbefore_e ///
wrk_timenotwork_a wrk_timenotwork_b wrk_reasnotlookjob wrk_reasnotlookjob_e wrk_workedlastyear ///
wrk_jobinjury_a wrk_jobinjury_b wrk_jobinjury_c wrk_jobinjury_e wrk_injuryeffects wrk_injuryeffects_e wrk_injurecause /// 
wrk_injurecause_e wrk_heavylift wrk_heavyequipment wrk_heavyequipment_e1 codh1 wrk_heavyequipment_e2 codh2 wrk_risks_a ///
wrk_risks_b wrk_risks_c wrk_risks_e wrk_violence_a wrk_violence_b wrk_violence_c wrk_violence_e  ///
secnd_worklastweek secnd_occupation_e secnd_occupation_cod secnd_ecoactivity_e secnd_ecoactivity_cod secnd_hrs_* trd_*  ///
hse_* verification7 rgh_syndic rgh_syndic_e inadultcompany adultinterference_1 adultinterference_2 ecoactivity occ_cat upm  factor members wrk_status wrk_timenotwork_b ///
 surveyresult catchild

drop verification*
drop trd_animals-trd_other_15

gen child_survey=333

save "${relabeled_dataCS}/childworkbo_2008.dta", replace


