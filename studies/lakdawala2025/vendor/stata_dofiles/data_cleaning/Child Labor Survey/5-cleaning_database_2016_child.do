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
            1: Initial Data
==================================================*/

use "${raw_dataCS}/ENNA_2016/ENNA_2016.dta", clear

***Renaming variables
rename folio 		folio
rename nro			number
rename ns001a_02 	gender
rename ns001a_03 	age
rename ns001a_04aa 	bdate_dd
rename ns001a_04ab 	bdate_mm
rename ns001a_04ac 	bdate_yy
rename ns01a_01 	edu_literacy
rename ns01a_02a 	edu_lastgradeapproved_a
rename ns01a_02b 	edu_lastgradeapproved_b
rename ns01a_03 	edu_enrol
rename ns01a_04		edu_reasnotenrol
rename ns01a_04e	edu_reasnotenrol_e
rename ns01a_05a	edu_lastgradeenrol_a
rename ns01a_05b	edu_lastgradeenrol_b
rename ns01a_05c	edu_shift
rename ns01a_05ae	edu_shift_e
rename ns01a_06		edu_attendance
rename ns01a_07		edu_attend_reasnot
rename ns01a_07e	edu_attend_reasnot_e

rename ns02a_01		wrk_workedlastweek
rename ns02a_02		wrk_dedicateonehour
rename ns02a_03		wrk_impediment_a
rename ns02a_03a	wrk_impediment_b
rename ns02a_04		wrk_availability
rename ns02a_05		wrk_jobsearch
rename ns02a_06a	wrk_jobsearch_a
rename ns02a_06b	wrk_jobsearch_b
rename ns02a_06c	wrk_jobsearch_c
rename ns02a_06e	wrk_jobsearch_e
rename ns02a_07		wrk_everworkbefore
rename ns02a_08a	wrk_timenotwork_a
rename ns02a_08b	wrk_timenotwork_b
rename ns02a_09		wrk_reasnotlookjob
rename ns02a_10a	wrk_reaslookjob_a
rename ns02a_10b	wrk_reaslookjob_b
rename ns02a_10e	wrk_reaslookjob_e
rename ns02b_11a1	wrk_occupation_a
rename ns02b_11a2	wrk_occupation_e
rename ns02b_11a2cod wrk_occupation_cod
rename ns02b_11b   	wrk_tasks_e
rename ns02b_12a 	wrk_ecoactivity_e
rename ns02b_12acod wrk_ecoactivity_cod
rename ns02b_12b	wrk_output_e
rename ns02b_13a	wrk_joblength_a
rename ns02b_13b	wrk_joblength_b
rename ns02b_14		wrk_jobposition
rename ns02b_14a	wrk_jobfamcommunity
rename ns02b_15		wrk_joblocation
rename ns02b_15e	wrk_joblocation_e
rename ns02b_16aa	wrk_hrs_aa
rename ns02b_16ab	wrk_hrs_ab
rename ns02b_16ba	wrk_hrs_ba
rename ns02b_16bb	wrk_hrs_bb
rename ns02b_16ca	wrk_hrs_ca
rename ns02b_16cb	wrk_hrs_cb
rename ns02b_16da	wrk_hrs_da
rename ns02b_16db	wrk_hrs_db
rename ns02b_16ea	wrk_hrs_ea
rename ns02b_16eb	wrk_hrs_eb
rename ns02b_16fa	wrk_hrs_fa
rename ns02b_16fb	wrk_hrs_fb
rename ns02b_16ga	wrk_hrs_ga
rename ns02b_16gb	wrk_hrs_gb
rename ns02b_17		wrk_mtimeworksimilar
rename ns02b_17a	wrk_mtimeworksimilar_1
rename ns02b_17b	wrk_mtimeworksimilar_2
rename ns02b_17c	wrk_mtimeworksimilar_3
rename ns02b_17d	wrk_mtimeworksimilar_4
rename ns02b_17e	wrk_mtimeworksimilar_5
rename ns02b_17f	wrk_mtimeworksimilar_6
rename ns02b_17g	wrk_mtimeworksimilar_7
rename ns02b_17h	wrk_mtimeworksimilar_8
rename ns02b_17i	wrk_mtimeworksimilar_9
rename ns02b_17j	wrk_mtimeworksimilar_10
rename ns02b_17k	wrk_mtimeworksimilar_11
rename ns02b_17l	wrk_mtimeworksimilar_12
rename ns02b_18		wrk_shift
rename ns02b_19_1a	wrk_reastowork_a
rename ns02b_19_1b	wrk_reastowork_b
rename ns02b_19_1e	wrk_reastowork_e
rename ns02b_19_2a	wrk_stopworkharm

rename ns02b_20		wrk_agreejob
rename ns02c_22		wrk_studypermit
rename ns02c_23		wrk_jobthroughagency
rename ns02c_24		wrk_typecontract
rename ns02c_25		wrk_vacations
rename ns02c_26		wrk_typepayment
rename ns02c_27a 	wrk_mainylab_a
rename ns02c_27b 	wrk_mainylab_b
rename ns02c_28		wrk_aguinaldo
rename ns02c_29a	wrk_mainytotal_a
rename ns02c_29b	wrk_mainytotal_b
rename ns02c_30a	wrk_mainyafobligations_a
rename ns02c_30b	wrk_mainyafobligations_b
rename ns02c_31a	wrk_incomeuse_a
rename ns02c_31b	wrk_incomeuse_b
rename ns02c_31e	wrk_incomeuse_e
rename ns02c_32		wrk_permission
rename ns02d_33a	wrk_risks_a
rename ns02d_33b	wrk_risks_b
rename ns02d_33c	wrk_risks_c
rename ns02d_33e	wrk_risks_e
rename ns02d_34		wrk_heavylift
rename ns02d_35		wrk_dangerequipment_a
rename ns02d_35a1	wrk_dangerequipment_e
rename ns02d_35a2	wrk_dangerequipment_e1
rename ns02d_36a	wrk_jobinjury_a
rename ns02d_36b	wrk_jobinjury_b
rename ns02d_36c	wrk_jobinjury_c
rename ns02d_36e	wrk_jobinjury_e
rename ns02d_37		wrk_injuryeffects
rename ns02d_37e	wrk_injuryeffects_e
rename ns02d_38a	wrk_violence_a
rename ns02d_38b	wrk_violence_b
rename ns02d_38c	wrk_violence_c
rename ns02d_38e	wrk_violence_e

rename condac		work_status
rename ncaeb_op		ecoactivity
rename htot_op 		wrk_timededi
rename catactlab	wrk_category


rename ns02e_39		secnd_worklastweek
rename ns02e_40a1	secnd_occupation
rename ns02e_40a2	secnd_occupation_e
rename ns02e_40a2cod secnd_occupation_cod
rename ns02e_40b 	secnd_tasks_e
rename ns02e_41aa	secnd_hrs_aa
rename ns02e_41ab	secnd_hrs_ab
rename ns02e_41ba	secnd_hrs_ba
rename ns02e_41bb	secnd_hrs_bb
rename ns02e_41ca	secnd_hrs_ca
rename ns02e_41cb	secnd_hrs_cb
rename ns02e_41da	secnd_hrs_da
rename ns02e_41db	secnd_hrs_db
rename ns02e_41ea	secnd_hrs_ea
rename ns02e_41eb	secnd_hrs_eb
rename ns02e_41fa	secnd_hrs_fa
rename ns02e_41fb	secnd_hrs_fb
rename ns02e_41ga	secnd_hrs_ga
rename ns02e_41gb	secnd_hrs_gb
rename ns02e_42		secnd_shift
rename ns02e_43		secnd_position
rename ns02e_43a	secnd_jobfamcommunity
rename ns02e_44		secnd_typepayment
rename ns02e_45a	secnd_incomeuse_a
rename ns02e_45b	secnd_incomeuse_b
rename ns02e_45e	secnd_incomeuse_e
rename ns02e_46a	secnd_reastowork_a
rename ns02e_46b	secnd_reastowork_b
rename ns02e_46e	secnd_reastowork_e
rename ns02e_47		secnd_comformable

rename ns03a_01a	hse_groceries
rename ns03a_01b	hse_repair
rename ns03a_01c	hse_cook
rename ns03a_01d	hse_dishes
rename ns03a_01e	hse_laundry
rename ns03a_01f	hse_babysitting
rename ns03a_01g	hse_woodwater
rename ns03a_01h	hse_other
rename ns03a_02aa	hse_hrs_groceries_h
rename ns03a_02ab	hse_hrs_groceries_m
rename ns03a_02ba	hse_hrs_repair_h
rename ns03a_02bb	hse_hrs_repair_m
rename ns03a_02ca	hse_hrs_cook_h
rename ns03a_02cb	hse_hrs_cook_m
rename ns03a_02da	hse_hrs_dishes_h
rename ns03a_02db	hse_hrs_dishes_m
rename ns03a_02ea	hse_hrs_laundry_h
rename ns03a_02eb	hse_hrs_laundry_m
rename ns03a_02fa	hse_hrs_babysitting_h
rename ns03a_02fb	hse_hrs_babysitting_m
rename ns03a_02ga	hse_hrs_woodwater_h
rename ns03a_02gb	hse_hrs_woodwater_m
rename ns03a_03a	hse_shift
rename ns03a_04		hse_agree
rename ns03b_05a	hse_risks_a
rename ns03b_05b	hse_risks_b
rename ns03b_05c	hse_risks_c
rename ns03b_05e	hse_risks_e
rename ns03b_06		hse_heavylift
rename ns03b_07		hse_dangerequipment_a
rename ns03b_08a1	hse_dangerequipment_e
rename ns03b_08a2	hse_dangerequipment_e1
rename ns03b_09a	hse_injure_a
rename ns03b_09b	hse_injure_b
rename ns03b_09c	hse_injure_c
rename ns03b_09e	hse_injure_e
rename ns03b_10		hse_injureeffects
rename ns03b_10e	hse_injureeffects_e
rename ns03b_11aa	hse_violence_a
rename ns03b_11ab	hse_violence_b
rename ns03b_11ac	hse_violence_c
rename ns03b_11e	hse_violence_e
rename ns04a_01		rgh_syndic
rename ns04a_02		rgh_rest
rename ns04a_03		rgh_restreasnot
rename ns04a_04a	rgh_selfbenefit_a
rename ns04a_04b	rgh_selfbenefit_b
rename ns04a_04e	rgh_selfbenefit_e
rename estrato 		stratum
rename ncob_op 			occ_cat
rename catactlab_pd1ab	occ_danger1
rename catactlab_pd2 	occ_minage
rename catactlab_pd3 	occ_wrktime
rename catactlab_pd4  	occ_nightshift
rename catactlab_pd5 	occ_riskedu
rename catactlab_pd1_5	occ_danger2



*Binary variables
			
global binary	edu_literacy edu_enrol edu_attendance wrk_workedlastweek wrk_impediment_a			///
				wrk_availability wrk_jobsearch wrk_everworkbefore wrk_mtimeworksimilar wrk_agreejob	///
				wrk_jobthroughagency wrk_vacations wrk_aguinaldo wrk_heavylift wrk_dangerequipment_a	///
				secnd_worklastweek secnd_comformable hse_repair hse_cook hse_dishes						///
				hse_laundry hse_babysitting hse_woodwater hse_other hse_agree hse_heavylift				///
				hse_dangerequipment_a rgh_syndic rgh_rest hse_groceries 

foreach x of varlist $binary {
	recode `x' (2=0)
	}
label define aux1 0 "No" 1 "Yes"
	foreach x of varlist $binary {
	label values `x' aux1
	}
	
recode gender (2=0)
label define gender 0 "Female" 1 "Male"
label values gender gender

recode wrk_jobfamcommunity (2=0)
recode secnd_jobfamcommunity (2=0)
label define wrk_jobfamcommunity 0 "Activities in benefit for the community" 1 "Activities in benefit for home"
label define secnd_jobfamcommunity 0 "Activities in benefit for the community" 1 "Activities in benefit for home"

label values wrk_jobfamcommunity wrk_jobfamcommunity
label values secnd_jobfamcommunity secnd_jobfamcommunity

recode wrk_permission (2=0) (3=99)
label values wrk_permission aux1



*Continuous variables

global continuos 	id nro age bdate_dd bdate_mm bdate_yy edu_lastgradeapproved_b				///	
					edu_lastgradeapproved_b wrk_timenotwork_a wrk_joblength_a wrk_hours_*		///
					wrk_mainylab* wrk_mainytotal_a wrk_mainyafobligations_a  secnd_hours*	///
					hse_hrs_*



*Labeling variables
label variable folio 			"Household ID"
label variable number 				"Person's ID for each Household"			
label variable depto 			"Department"	
label variable area 			"Urban rural"
label variable gender			"Gender"
label variable age				"How old are you?"
label variable bdate_dd			"Date of birth? Day"
label variable bdate_mm			"Date of birth? Month"
label variable bdate_yy			"Date of birth? Year"
label variable edu_literacy		"Can you read and write?" 
label variable edu_lastgradeapproved_a 	"Which was the last highest level or grade that you approved? (Level)"
label variable edu_lastgradeapproved_b 	"Which was the last highest level or grade that you approved? (Grade)"				
label variable edu_enrol		"Have you enrolled in any grade or level this year?"
label variable edu_reasnotenrol		"Why were you not enrolled this year (2016)?"
label variable edu_reasnotenrol_e 	"Why were you not enrolled this year (2016)? Specify"
label variable edu_lastgradeenrol_a		"In which grade or level you have enrolled this year(2016)? (Grade)"
label variable edu_lastgradeenrol_b		"In which grade or level you have enrolled this year(2016)? (Level)"
label variable edu_shift			"School shift"
label variable edu_shift_e			"School shift. Specify"
label variable edu_attendance 		"Do you attend regularly to the level that you have enrolled this year?(2016)"
label variable edu_attend_reasnot	"Reasons to not attend to the level you enrolled?"
label variable edu_attend_reasnot_e "Reasons to not attend to the level you enrolled?"
label variable wrk_workedlastweek	"During last week, did you work at least an hour?"
label variable wrk_dedicateonehour	"During last week, did you dedicate at least one hour to:"
label variable wrk_impediment_a		"Last week, did you have any work or activity that you could not do?"
label variable wrk_impediment_b 	"What was the impediment?"
label variable wrk_availability 	"Last week, did you want to work and were you available?"
label variable wrk_jobsearch		"During the last 4 weeks did you look for a job?"
label variable wrk_jobsearch_a  	"What did you do?"
label variable wrk_jobsearch_b  	"What did you do?"
label variable wrk_jobsearch_c  	"What did you do?"
label variable wrk_jobsearch_e	 	"What did you do? Specify"
label variable wrk_everworkbefore	"Have you ever worked before?"
label variable wrk_timenotwork_a	"How long have you not worked?"
label variable wrk_timenotwork_b	"How long have you not worked?"
label variable wrk_reasnotlookjob 	" Why have you not looked for a job?"
label variable wrk_reaslookjob_a 	"Why do you want to work?"
label variable wrk_reaslookjob_b 	"Why do you want to work?"
label variable wrk_reaslookjob_e 	"Why do you want to work?"
label variable wrk_occupation_a		"The work you did last week, was:"
label variable wrk_occupation_e		"Last week, what was your main job? Specify"
label variable wrk_occupation_cod 		"Last week, what was your main job? cod"
label variable wrk_tasks_e			"What are your tasks? Specify"
label variable wrk_ecoactivity_e	"What is the main economic activity of your work establishment? Specify"
label variable wrk_ecoactivity_cod	"What is the main economic activity of your work establishment? cod"
label variable wrk_output_e			"Mainly, what your company produces? Specify"
label variable wrk_joblength_a 		"How long have you been doing this task?"
label variable wrk_joblength_b 		"How long have you been doing this task?"
label variable wrk_jobposition		"In this job, you are:"
label variable wrk_jobfamcommunity 	"You have done this job for: "
label variable wrk_joblocation 		"Where do you do this job?"
label variable wrk_joblocation_e 	"Where do you do this job?. Specify"
foreach x of varlist wrk_hrs_* {
	label variable `x' "Last week, how many hours and minutes a day did you dedicate to this job"
}
label variable wrk_mtimeworksimilar 	"The time dedicated to this job, is similar every month?"
label variable wrk_mtimeworksimilar_1 "During the months of the year and comparing to this month (January), do you?"
label variable wrk_mtimeworksimilar_2 "During the months of the year and comparing to this month (February), do you?"
label variable wrk_mtimeworksimilar_3 "During the months of the year and comparing to this month (March), do you?"
label variable wrk_mtimeworksimilar_4 "During the months of the year and comparing to this month (April), do you?"
label variable wrk_mtimeworksimilar_5 "During the months of the year and comparing to this month (May), do you?"
label variable wrk_mtimeworksimilar_6 "During the months of the year and comparing to this month (March), do you?"
label variable wrk_mtimeworksimilar_7 "During the months of the year and comparing to this month (June), do you?"
label variable wrk_mtimeworksimilar_8 "During the months of the year and comparing to this month (July), do you?"
label variable wrk_mtimeworksimilar_9 "During the months of the year and comparing to this month (August), do you?"
label variable wrk_mtimeworksimilar_10 "During the months of the year and comparing to this month (September), do you?"
label variable wrk_mtimeworksimilar_11 "During the months of the year and comparing to this month (November), do you?"
label variable wrk_mtimeworksimilar_12 "During the months of the year and comparing to this month (December), do you?"
label variable wrk_shift 			"Last week, your shift was:"
label variable wrk_reastowork_a 	"Main reasons you do this job:"
label variable wrk_reastowork_b 	"Main reasons you do this job:"
label variable wrk_reastowork_e 	"Main reasons you do this job. Specify: "
label variable wrk_stopworkharm 	"If you had to leave this job, who would it harm the most?"
label variable wrk_agreejob			"Do you agree to have this job?"
label variable wrk_studypermit		"During work hours, does your employer give you time to study?"
label variable wrk_jobthroughagency	"Were you hired by a job agency?"
label variable wrk_typecontract 	"Do you work:"
label variable wrk_vacations		"In this job, did you or will you have vacations (Days without working but paid)?"
label variable wrk_typepayment		"For the job that you do, how do you get paid?"
label variable wrk_mainylab_a		"How much is your liquid salary, without law reductions"
label variable wrk_mainylab_b		"How much is your liquid salary, without law reductions"
label variable wrk_aguinaldo		"In this last few months, did you receive aguinaldo (christmas bonus)"
label variable wrk_mainytotal_a		"How much is your labor total income in you main job?"
label variable wrk_mainytotal_b  	"How much is your labor total income in you main job? Frequency"
label variable wrk_mainyafobligations_a 	"Once all your duties are paid (wages, inputs) how much income is left?"
label variable wrk_mainyafobligations_b 	"Once all your duties are paid (wages, inputs) how much income is left? Frequency"
label variable wrk_incomeuse_a		"What do you spend your income into:"
label variable wrk_incomeuse_b		"What do you spend your income into:"
label variable wrk_incomeuse_e		"What do you spend your income into:"
label variable wrk_permission 		"Did your parents or tutor acquire legal permission?"
label variable wrk_risks_a 			"Are you exposed to any of the following elements:"
label variable wrk_risks_b 			"Are you exposed to any of the following elements:"
label variable wrk_risks_c 			"Are you exposed to any of the following elements:"
label variable wrk_risks_e 			"Are you exposed to any of the following elements:"
label variable wrk_heavylift		"Do you lift heavy loads in this job?"
label variable wrk_dangerequipment_a	"Do you consider that the machines or equipment you use at work are dangerous?"
label variable wrk_dangerequipment_e	"Which tools or equipment are dangerous?"
label variable wrk_dangerequipment_e1	"Which tools or equipment are dangerous?"
label variable wrk_jobinjury_a 		"Did you have any of the following injuries in your job?"
label variable wrk_jobinjury_b 		"Did you have any of the following injuries in your job?"
label variable wrk_jobinjury_c 		"Did you have any of the following injuries in your job?"
label variable wrk_jobinjury_e 		"Did you have any of the following injuries in your job?"
label variable wrk_injuryeffects	"How were you affected by the worst injury"
label variable wrk_injuryeffects_e "How were you affected by the worst injury (Specify)"
label variable wrk_violence_a 		"While working, has this happened to you?"
label variable wrk_violence_b 		"While working, has this happened to you?"
label variable wrk_violence_c 		"While working, has this happened to you?"
label variable wrk_violence_e 		"While working, has this happened to you?"
label variable secnd_worklastweek	"Besides the mentioned job, did you have another job last week?"
label variable secnd_occupation		"The secondary job corresponded to:"		
label variable secnd_occupation_e		"The secondary job corresponded to:"		
label variable secnd_occupation_cod	"The secondary job corresponded to:"		
label variable secnd_tasks_e		"What are your job tasks?"
foreach x of varlist secnd_hrs_* {
	label variable `x' "Last week, how many hours and minutes a day did you dedicate to this job"
}
label variable secnd_shift 			"Last week, your shift was:"
label variable secnd_position		"In this job you are:"
label variable secnd_jobfamcommunity	"You have done this job for: "
label variable secnd_typepayment	"For the job that you do, how do you get paid?"
label variable secnd_incomeuse_a	"How do you spend your income into?"
label variable secnd_incomeuse_b	"How do you spend your income into? Frequency"
label variable secnd_incomeuse_e	"How do you spend your income into? Specify"
label variable secnd_reastowork_a	"Main reasons you do this job: "
label variable secnd_reastowork_b	"Main reasons you do this job: "
label variable secnd_reastowork_e	"Main reasons you do this job: Specify "
label variable secnd_comformable	"Are you comfortable having this job"
label variable hse_groceries		"For this home, did you bought groceries? "
label variable hse_repair		"For this home, did you repair any equipment?"
label variable hse_cook			"For this home, did you	cook?"
label variable hse_dishes		"For this home, did you do the dishes or clean the house?"
label variable hse_laundry		"For this home, did you do laundry?"
label variable hse_babysitting	"For this home, did you babysit or taken care of elderly or sick?"
label variable hse_woodwater	"For this home, did you pick up wood or water?"
label variable hse_other		"For this home, did you do any other house task?"
foreach x of varlist hse_hrs_* {
	label variable `x' "Last week, how many hours and minutes a day did you dedicate to this home task"
}
label variable hse_shift 		"Last week, your shift was:"
label variable hse_agree		"Do you agree to do house work?"
label variable hse_risks_a 	"Are you exposed to any of the following elements:"
label variable hse_risks_b 	"Are you exposed to any of the following elements:"
label variable hse_risks_c 	"Are you exposed to any of the following elements:"
label variable hse_risks_e 	"Are you exposed to any of the following elements:"
label variable hse_heavylift 	"Do you lift heavy loads in this job?"
label variable hse_dangerequipment_a	"Do you consider that the machines or equipment you use at work are dangerous?"
label variable hse_dangerequipment_e	"Which tools or equipment are dangerous?"
label variable hse_dangerequipment_e1	"Which tools or equipment are dangerous?"
label variable hse_injure_a  		"Did you have any of the following injuries in your job?"
label variable hse_injure_b  		"Did you have any of the following injuries in your job?"
label variable hse_injure_c  		"Did you have any of the following injuries in your job?"
label variable hse_injure_e  		"Did you have any of the following injuries in your job?"
label variable hse_injureeffects 	"How were you affected by the worst injury"
label variable hse_injureeffects_e 	"How were you affected by the worst injury?"
label variable hse_violence_a 		"While working, has this happened to you?"
label variable hse_violence_b 		"While working, has this happened to you?"
label variable hse_violence_c 		"While working, has this happened to you?"
label variable hse_violence_e 		"While working, has this happened to you?"
label variable rgh_syndic 			"Do you belong to any labor union?"
label variable rgh_rest 			"Last week, did you have time to rest o recreate?" //see original question important*
label variable rgh_restreasnot 		"Reasons you did not have time to rest:"
label variable rgh_selfbenefit_a 	"How do you benefit from doing this job?"
label variable rgh_selfbenefit_b 	"How do you benefit from doing this job?"
label variable rgh_selfbenefit_e 	"How do you benefit from doing this job?? Specify"
label variable upm 				"Primary unit sample"
label variable stratum			"Stratum"
label variable factor 			"Expansion factor"
label variable work_status	 	"Work status"
label variable occ_cat 			"Main job occupation group"
label variable ecoactivity	"Main job economic activity classification"
label variable wrk_timededi 	"Main job weekly hours worked"
label variable htot_tdh 		"House work weekly hours worked"
label variable wrk_category		"Category job activity"
label variable occ_danger1	"A: Dangerous job or labor activity for nature or condition"
label variable occ_minage 	"B: Job or labor activity under the minimum age"
label variable occ_wrktime	"C: Job or labor activity working more than 40 weekly hours"
label variable occ_nightshift	"D: Job or labor activity in night shifts"
label variable occ_riskedu	"E: Job or labor activity that risks education"
label variable occ_danger2 	"Job or labor activity dangerous, forbidden or unhealthy that harms development" 

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

label variable id 	"Personal ID"



*Categorical variables
*drop $continuos $binary gender wrk_jobfamcomunity secnd_jobfamcomunity wrk_permission
label drop depto
label define depto 1 "Chuquisaca" 2 "La Paz" 3 "Cochabamba" 4 "Oruro" 5 "Potosi" 6 "Tarija" ///
			7 "Santa Cruz" 8 "Beni" 9 "Pando"
label values depto depto

label drop area
recode area (2=0)
label define area 0 "Rural" 1 "Urban" 
label values area area

recode edu_lastgradeapproved_a (11=1) (12=2) (13=3) (21=4) (22=5) (23=6) (31=7) (32=8) (41=9) (42=10) 
recode edu_lastgradeapproved_a (51=11) (52=12) (61=13) (62=14) (63=15) (64=16) (65=17) (71=18) (72=19) (73=20) (74=21) (75=22) (76=23) (77=24) (78=25) (79=26) (80=27)
				

label define edu_lastgradeapproved_a 1 "1.None" 2 "2.Literacy course" 3 "3.Initial education or pre-escolar" ///
			4 "4.Basic (1 to 5 years)" 5 "5.Intermediate (1 to 3 years)" 6 "6.Medium (1 to 4 years)" ///
			7 "7.Primary (1 to 8 years)" 8 "8.Secondary (1 to 4 years)" 9 "9.Primary (1 to 6 years)" 10 "10.Secondary (1 to 6 years)"	///
			11 "11.Basic Education for Adults" 12 "12.Center of Adults Medium Education" 13 "13.Youth Alternative Education" 14 "14.Primary Adult Education" ///
			15 "15.Adult Secondary Education" 16 "16.National Post Literacy Program" 17 "17.Especial education" ///
			18 "18.Teacher Superior School (Normal)" 19 "19.University" 20 "20.Post-graduate diploma" 21 "21.Masters Degree" ///
			22 "22.Doctorate Degree" 23 "23.University technician" 24 "24.Technical institute(More or equal to 2 years)" ///
			25 "25.Military and Police school" 26 "26.Adult Technician school" 27 "27.Other - Superior education (less than 2 years)"
label value edu_lastgradeapproved_a edu_lastgradeapproved_a

 
label define edu_reasnotenrol 1 "Disease/accident" 2 "Disability" 3 "Pregnancy" 4 "Lack of money to pay for enrolment" ///
				5 "No school or far away" 6 "I am not interest in studying" 7 "To help in family agricultural job" ///
				8 "To help in my family business" 9 "For work (excluding 7 and 8)" 10 "To help house work tasks" ///
				11 "To learn a job occupation" 12 "Family thinks edu places are unsave" 13 "Family thinks teaching is bad" ///
				14 "Family thi. edu is not important" 15 "Other" 16 "Not enough age"
label values edu_reasnotenrol edu_reasnotenrol

				
label define edu_attend_reasnot 1 "Disease/accident" 2 "Disability" 3 "Pregnancy" 4 "No school or far away" ///
				5 "Lack of money to pay for enrolment" 6 "I am not interest in studying" 7 "To help in family agricultural job" ///
				8 "To help in my family business" 9 "For work (excluding 7 and 8)" 10 "To help house work tasks" ///
				11 "To learn a job occupation" 12 "Family thi. edu places are unsafe" 13 "Family thinks teaching is bad" ///
				14 "Family thinks edu is not important" 15 "Other" 16 "Not enough age"

label values edu_attend_reasnot edu_attend_reasnot


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
label values edu_lastgradeenrol_a edu_lastgradeenrol_a


label define edu_shift 1 "Morning" 2 "Afternoon" 3 "Night" 4 "Mixed"
labe values edu_shift edu_shift

label define wrk_dedicateonehour 1 "Agricultural activities or animal husbandry" ///
			2 "Forest harvest, fishing or hunting activities" 3 "Familiar or own business activities" ///
			4 "Sell on the street, or in any other moving market stall" 5 "Craft, food preparing, knitting activities" ///
			6 "Paid services (home tasks, watching cars, shoeshine, carrying bags)" ///
			7 "Any other activity in which you earned money or payment in kind"  ///
			8 "Jobs for other people without remuneration" 9 "No activity"
			
label values wrk_dedicateonehour wrk_dedicateonehour

label define wrk_impediment_b 1 "Vacation or permission" 2 "Disease or accident" ///
			3 "Lack of materials, commodities or clients" 4 "Strike or labor conflict" ///
			5 "Bad weather" 6 "Being suspended" 7 "Personal o family problems" 8 "Studying"
label values wrk_impediment_b wrk_impediment_b

label define wrk_jobsearch_a 1 "Answering or posting ads" 2 "Obtaining resources or clients" ///
			3 "Job agency or other" 4 "Help from family or friends to find a job" 5 "Other"
 
label values wrk_jobsearch_a wrk_jobsearch_b wrk_jobsearch_c wrk_jobsearch_a

recode wrk_timenotwork_b (2=1) (4=2) (8=3)
label define wrk_timenotwork_b  1 "Week" 2 "Month" 3 "Year"
label values wrk_timenotwork_b wrk_timenotwork_b

label define wrk_reasnotlookjob 1 "I do not need to, not want to" 2 "Short age" ///
			3 "Because I go to school" 4 "Disease or accident" 5 "Disability" ///
			6 "Pregnancy" 7 "Secure job, I will start in less than 4 weeks" ///
			8 "Looked before, waiting for an answer" 9 "Waiting for a better availabilitity period" ///
			10 "Tired of looking" 11 "My family does not want me to work"
		
label values wrk_reasnotlookjob wrk_reasnotlookjob

label define wrk_reaslookjob_a 1 "Generate income of my own" 2 "To help fulfill home income" ///
			3 "Learn, get experience and skills" 4 "Keep family or community habits" ///
			5 "Because I want to/ I like to" 6 "Other"
label values wrk_reaslookjob_a wrk_reaslookjob_b wrk_reaslookjob_a

label define wrk_occupation_a 1 "Harvest sugarcane" 2 "Harvest chestnut" 3 "Minning" 4 "Fishing" ///
			5 "Bricklayer" 6 "Alcohol salesperson" 7 "Collecting waste" 8 "Hospital cleaning person" ///
			9 "Security or protection services" 10 "Plasterer" 11 "Farmer" 12 "cattle breeder" ///
			13 "Attend urinals" 14 "Model" 15 "Stonecutter" 16 "Sound amplifier" ///
			17 "Builder" 18 "Car caregiver" 19 "None"
label values wrk_occupation_a wrk_occupation_a

recode wrk_joblength_b (2=1) (4=2) (8=3)
label define wrk_joblength_b 1 "Week" 2 "Month" 3 "Year"
label values wrk_joblength_b wrk_joblength_b

label define wrk_jobposition 1 "Worker or family assistant" 2 "Worker or employee" ///
			3 "Employer with salary" 4 "Self employed" 5 "Employer without salary" ///
			6 "Production cooperative" 7 "Apprentice without remuneration" 8 "Home worker living in employers home" ///
			9 "Home worker not living in employers home" 10 "Home worker"
label values wrk_jobposition wrk_jobposition

label define wrk_joblocation 1 "Private house" 2 "Orchard or family land" ///
			3 "Store or exclusive land (excluding 1 and 2)" 4 "Mobile store" ///
			5 "Fixed store" 6 "Transport vehicle" 7 "Home services" 8 "Moving job" ///
			9 "Presales moving job" 10 "Other place" 11 "Lake or river"
label values wrk_joblocation wrk_joblocation

label define wrk_mtimeworksimilar_1 1 "Worker more hours" 2 "Worked less hours" ///
			3 "Worked the same hours" 4 "Did not have a job this month" 5 "Did not start with the job this month" ///
			6 "Month of the interview"
			
label values wrk_mtimeworksimilar_1 - wrk_mtimeworksimilar_12 wrk_mtimeworksimilar_1
 
label define wrk_shift 1 "Between 6 a.m. to 9 p.m" 2 "Between 10 p.m. to 5 a.m." ///
			3 "Mixed shift, including night shift"
label values wrk_shift wrk_shift

label define wrk_reastowork_a 1 "Generate income of my own" 2 "To help fulfill home income" ///
			3 "Learn, get experience and skills" 4 "Keep family or community habits" ///
			5 "Because I want to/ I like to" 6 "Other"
label values wrk_reastowork_a wrk_reastowork_b wrk_reastowork_a

label define wrk_stopworkharm 1 "Myself, but not my home" 2 "Myself and my home" 3 "Would not cause harm"
label values wrk_stopworkharm wrk_stopworkharm

label define wrk_studypermit 1 "Yes, at least 2 hours a day" 2 "Yes, anytime I need and ask" ///
			3 "Yes, but not all the time I ask" 4 "No, even though I ask" 5 "I do not need to ask for permission"
label values wrk_studypermit wrk_studypermit

label define wrk_typecontract 1 "Permanently" 2 "Eventually" 3 "For product"
label values wrk_typecontract wrk_typecontract

label define wrk_typepayment 1 "Cash" 2 "Cash and payment in kind" 3 "Payment in kind only" 4 "I do not get paid"
label values wrk_typepayment wrk_typepayment

label define wrk_mainylab_b	1 "Daily" 2 "Weekly" 3 "Biweekly" 4 "Monthly" 5 "Bimonthy" 6 "Quarterly" 7 "Biannual" 8 "Annually"
label values wrk_mainylab_b wrk_mainylab_b
 
label define wrk_mainytotal_b 1 "Daily" 2 "Weekly" 3 "Biweekly" 4 "Monthly" 5 "Bimonthy" 6 "Quarterly" 7 "Biannual" 8 "Annually"
label values wrk_mainytotal_b wrk_mainytotal_b

recode wrk_mainyafobligations_b (9=99)
label define wrk_mainyafobligations_b 1 "Daily" 2 "Weekly" 3 "Biweekly" 4 "Monthly" 5 "Bimonthy" 6 "Quarterly" 7 "Biannual" 8 "Annually" 9 "Missing"
label values wrk_mainyafobligations_b wrk_mainyafobligations_b

label define wrk_incomeuse_a 1 "School payments" 2 "Self benefit (food, clothes, leisure)" ///
			3 "Home benefit (Food, electricity, water)" 4 "Savings" 5 "I do not keep what I earn" ///
			6 "Other"
label values wrk_incomeuse_a wrk_incomeuse_b wrk_incomeuse_a 

label define wrk_risks_a 1 "Dirt or dust contaminated" 2 "Fire, gas, flames in high quantities" ///
			3 "Loud noise or vibrations" 4 "Extreme heat or cold" 5 "Dangerous instruments (knives, explosives, etc)" ///
			6 "Underground work" 7 "Work at height" 8 "Work in water" 9 "Darkness, isolated or without ventilation" ///
			10 "Chemical products (pesticide, glue)" 11 "Other" 12 "None" 99 "Missing"
label values wrk_risks_a wrk_risks_b wrk_risks_c wrk_risks_a

label define wrk_jobinjury_a 1 "Superficial injuries or bites, blisters, etc" ///
			2 "Fractures or mutilations" 3 "Dislocation or distention" 4 "Burns, scalds or freezing" ///
			5 "Respiratory problems" 6 "Sight problems" 7 "Sking injuries" 8 "Stomach problems, diarrhea or chemical poisoning" ///
			9 "Exhaustion for tasks intensity" 10 "Other" 11 "None" 
label values wrk_jobinjury_a wrk_jobinjury_b wrk_jobinjury_c wrk_jobinjury_a

label define wrk_injuryeffects 1 "Permanently disabled" 2 "Impeded me from doing activities" ///
			3 "I left school" 4 "Other" 5 "It was not serious"
label values wrk_injuryeffects wrk_injuryeffects

label define wrk_violence_a	1 "Being yelled, insulted, threatened often" 2 "Discriminated" ///
			3 "Being physically abused (beaten, hurt)" 4 "Impeded from eaten" 5 "Impeded from getting paid" ///
			6 "Being isolated" 7 "Being forced to dress uncomfortably" ///
			8 "Sexual abused or molested" 9 "Other" 10 "None"
label values wrk_violence_a wrk_violence_b wrk_violence_c wrk_violence_a

label define secnd_occupation 1 "Harvest sugarcane" 2 "Harvest chestnut" 3 "Minning" 4 "Fishing" ///
			5 "Bricklayer" 6 "Alcohol salesperson" 7 "Collecting waste" 8 "Hospital cleaning person" ///
			9 "Security or protection services" 10 "Plasterer" 11 "Farmer" 12 "cattle breeder" ///
			13 "Attend urinals" 14 "Model" 15 "Stonecutter" 16 "Sound amplifier" ///
			17 "Builder" 18 "Car caregiver" 19 "None"
label values secnd_occupation secnd_occupation

label define secnd_shift 1 "Between 6 a.m. to 9 p.m" 2 "Between 10 p.m. to 5 a.m." ///
			3 "Mixed shift, including night shift"
label values secnd_shift secnd_shift

label define secnd_position 1 "Worker or family assistant" 2 "Worker or employee" ///
			3 "Employer with salary" 4 "Self employed" 5 "Employer without salary" ///
			6 "Production cooperative" 7 "Apprentice without remuneration" 8 "Home worker living in employers home" ///
			9 "Home worker not living in employers home" 10 "Home worker"
 
label values secnd_position secnd_position

label define secnd_typepayment 1 "Cash" 2 "Cash and payment in kind" 3 "Payment in kind only" 4 "I do not get paid"
label values secnd_typepayment secnd_typepayment

label define secnd_incomeuse_a 1 "School payments" 2 "Self benefit (food, clothes, leisure)" ///
			3 "Home benefit (Food, electricity, water)" 4 "Savings" 5 "I do not keep what I earn" ///
			6 "Other"
label values secnd_incomeuse_a secnd_incomeuse_b secnd_incomeuse_a

label define secnd_reastowork_a 1 "Generate income of my own" 2 "To help fulfill home income" ///
			3 "Learn, get experience and skills" 4 "Keep family or community habits" ///
			5 "Because I want to/ I like to" 6 "Other"
label values secnd_reastowork_a secnd_reastowork_b secnd_reastowork_a 

label define hse_shift 1 "Between 6 a.m. to 9 p.m" 2 "Between 10 p.m. to 5 a.m." ///
			3 "Mixed shift, including night shift"
label values hse_shift hse_shift

label define hse_risks_a 1 "Dirt or dust contaminated" 2 "Fire, gas, flames in high quantities" ///
			3 "Loud noise or vibrations" 4 "Extreme heat or cold" 5 "Dangerous instruments (knives, explosives, etc)" ///
			6 "Underground work" 7 "Work at height" 8 "Work in water" 9 "Darkness, isolated or without ventilation" ///
			10 "Chemical products (pesticide, glue)" 11 "Other" 12 "None"
label values hse_risks_a hse_risks_b hse_risks_c hse_risks_a

label define hse_injure_a 1 "Superficial injuries or bites, blisters, etc" ///
			2 "Fractures or mutilations" 3 "Dislocation or distention" 4 "Burns, scalds or freezing" ///
			5 "Respiratory problems" 6 "Sight problems" 7 "Skin injuries" 8 "Stomach problems, diarrhea or chemical poisoning" ///
			9 "Exhaustion for tasks intensity" 10 "Other" 11 "None"
label values hse_injure_a hse_injure_b hse_injure_c hse_injure_a

label define hse_injureeffects 1 "Permanently disabled" 2 "Impeded me from doing activities" ///
			3 "I left school" 4 "Other" 5 "It was not serious"
label values hse_injureeffects hse_injureeffects

label define hse_violence_a 1 "Being yelled, insulted, threatened often" 2 "Discriminated" ///
			3 "Being physically abused (beaten, hurt)" 4 "Impeded from eaten" 5 "Impeded from getting paid" ///
			6 "Being isolated" 7 "Being forced to dress uncomfortably" ///
			8 "Sexual abused or molested" 9 "Other" 10 "None"
label values hse_violence_a hse_violence_b hse_violence_c hse_violence_a

label define rgh_restreasnot 1 "I just work and do home tasks" 2 "I just do home tasks" ///
			3 "I just work" 4 "I just study" 5 "I just study and work" 6 "I just do home tasks and study"
label values rgh_restreasnot rgh_restreasnot

label define  rgh_selfbenefit_a 1 "Learn or have skills" 2 "Learn to socialize with other people / with environment" ///
			3 "Acquire responsibilities in my development stage" 4 "Freedom of expenditure" 5 "None" 6 "Other"
label values rgh_selfbenefit_a rgh_selfbenefit_b rgh_selfbenefit_a			
		
label define work_status 0 "Without labor activity or work" 1 "With labor activity or work"
label values work_status work_status

label define occ_cat 1 "Public administration and enterprise Managers" 2 "Scientific and intellectual professionals" 3 "Medium level technicians" ///
			4 "Clerical support workers" 5 "Service and sales workers" 6 "Agricultural, forestry and fishery workers" ///
			7 "Construction, manufacture workers and others" 8 "Plant and machine operators, assemblers" ///
			9 "Unskilled workers" 0 "Armed forces occupations" 99 "Unspecified"
label values occ_cat occ_cat 

label define  ecoactivity 0 "Agricultural, forestry and fishery" 1 "Mines and quarries" ///
			2 "Manufacturing industry" 3 "Electricity, gas, air conditioner supply" 4 "Water supply, waste management" 5 "Construction" ///
			6 "Wholesale and retail" 7 "Transport and storage" 8 "Accommodation services and food services" ///
			9 "Information and communication" 10 "Financial services and insurance" 11 "Real estate activities" ///
			12 "Professional and technical services" 13 "Administrative activity services" 14 "Public Administration, defense and Social Security" ///
			15 "Education services" 16 "Health and social assistance services" 17 "Artistic and entertaining activities" ///
			18 "Other activity services" 19 "Private home activities" 20 "Extraterritorial agency Service" ///
			99 "Unspecified"
label values ecoactivity ecoactivity


label define wrk_category	1 "Family frame" 2 "Comunity-familiar frame" 3 "Family assistant" 4 "Apprentice" ///
			5 "Employee" 6 "Employer" 7 "House wage earner"
label values wrk_category wrk_category

label define occ_danger1 0 "With labor activity and no dangerous job" 1 "With labor activity and dangerous job" 9 "Unspecified"
label values  occ_danger1 occ_danger1

label define occ_minage 0 "Labor activity over minimum age" 1 "Labor activity under minimum age "
label values occ_minage occ_minage

label define occ_wrktime 0 "Labor activity with less or equal to 40 weekly hours" 1 "Labor activity of more than 40 weekely hours" 9 "Unspecified"
label values occ_wrktime occ_wrktime

label define occ_nightshift 0 "Labor activity day shift" 1 "Labor activity night or mixed shift" 9 "Unspecified"
label values occ_nightshift occ_nightshift

label define occ_riskedu	0 "Enrolled and assist to school" 1 "Not enrolled and do not assist to school"
label values occ_riskedu occ_riskedu

label define occ_danger2 0 "No labor activity and not having a dangerous job" 1 "Labor activity and not having a dangerous job" 9 "Unspecified"
label values occ_danger2 occ_danger2




order folio number id



save "${relabeled_dataCS}/childworkbo_2016.dta", replace

