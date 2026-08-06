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

/* This .do file takes the compiled demographic and employment data and makes a final clean to the dataset */

/*==================================================
            0: Program set up
==================================================*/
*Written on STATA 17
drop _all

/*==================================================
            1: Compiled data
==================================================*/

use "${relabeled_data}/Persona/EH_compiled_persona", clear

/*==================================================
            2: Data working
==================================================*/

recast str id folio

*****(a) Definicion Provincias y Municipios

*Codigo de provinciabr 
gen aux=0
egen aux1=concat(depto aux provincia) if provincia<10 & inrange(t,2012,2013)
egen aux2=concat(depto provincia) if provincia>=10 & inrange(t,2012,2013)
egen aux3=concat(depto provincia15) if t==2015 & provincia15!=""
egen aux5=concat(depto provincia16) if t==2016
gen cod_prov=" "
replace cod_prov=aux1 if provincia<10 & inrange(t,2012,2013)
replace cod_prov=aux2 if provincia>=10 & inrange(t,2012,2013)
replace cod_prov=aux3 if t==2015 
replace cod_prov=aux5 if t==2016
replace cod_prov=prov if t==2014 
drop aux1 aux2 aux3 aux5

*Codigo de seccion
egen aux1=concat(cod_prov aux seccion) if seccion<10 & inrange(t,2012,2013)
egen aux2=concat(cod_prov seccion) if seccion>=10  & inrange(t,2012,2013)
egen aux3=concat(cod_prov seccion15) if t==2015 & seccion15!=""
egen aux5=concat(cod_prov seccion16) if t==2016
gen cod_secc=" "
replace cod_secc=aux1 if seccion<10 & inrange(t,2012,2013)
replace cod_secc=aux2 if seccion>=10   & inrange(t,2012,2013)
replace cod_secc=aux3 if t==2015 
replace cod_secc=aux5 if t==2016
replace cod_secc=mun if t==2014 
drop aux aux1 aux2 aux3 aux5 
drop provincia15 seccion15 mun prov provincia seccion prov_name secc_name I02_DEPTO provincia16 seccion16
destring cod_secc cod_prov depto, replace

******(b) Work Variables

**(1) Work2 (1 if work, 0 otherwise)
gen work2=work
replace work2=0 if age>=7 & work==.

**(2) Participation
gen participa=1 if work==1 
replace participa=0 if age>=7 & work==.

**(3) Wages & Incomes

*(i)Ytrabajo
gen ytrabajo2=ytrabajo
replace ytrabajo2=0 if ytrabajo==.

*(ii)Ytotal
gen ytotal2=ytotal
replace ytotal2=0 if ytotal2==.

*(iii)Receive Wage 
gen wage_worker=1 if inlist(ocu_cat2,1,3)
replace wage_worker=0 if inlist(ocu_cat2,2,4) | work2==0

*(iv) Hours  at week
rename hours_worked_day hours_day
rename days_worked_week days_week
gen hours_week=hours_day*days_week
replace hours_week=0 if hours_day==. & age>=7
replace hours_week=0 if work2==0

*(v) Hourly wage
gen wage_hour=ytrabajo/(hours_week*4.33)

*(vi) Unpaid worker
gen unpaid_worker=1 if inlist(ocu_cat2,4)
replace unpaid_worker=0 if work2==0 | inlist(ocu_cat2,1,2,3)

*(vii) self employed
gen self_employed=1 if ocu_cat2==2
replace self_employed=0 if work2==0 | inlist(ocu_cat2,1,3,4)

*(viii) contract
label drop contract
label define contract 1 "Signed a fixed-term contract" 2 "Did not sign but has an agreement" 3 "Long term/staff contract" 4 "Did not sign a contract/does not have a agreement" 5 "Self-employed" 6 "Other"
label values contract contract

*(ix) number of workers
gen number_workers_cat=.
replace number_workers_cat=1 if number_workers==1 & number_workers_cat==.
replace number_workers_cat=2 if inrange(number_workers,2,4) & number_workers_cat==.
replace number_workers_cat=3 if inrange(number_workers,5,9) & number_workers_cat==.
replace number_workers_cat=4 if inrange(number_workers,10,14) & number_workers_cat==.
replace number_workers_cat=5 if inrange(number_workers,15,19) & number_workers_cat==.
replace number_workers_cat=6 if inrange(number_workers,20,49) & number_workers_cat==.
replace number_workers_cat=7 if inrange(number_workers,50,99) & number_workers_cat==.
replace number_workers_cat=8 if inrange(number_workers,100,500000) & number_workers!=. & number_workers_cat==.
replace number_workers_cat=9 if number_workers==888888 & number_workers_cat==.

replace number_workers=. if number_workers==888888

*(x) Whether the worker works in a place that is eligible for taxes 

rename places_taxes place_taxes
replace place_taxes=places_taxes2

label define place_taxes 1 "yes" 2 "no/in process" 3 "don't know'"
label values place_taxes place_taxes

drop places_taxes*

*(xi) type of est
label drop type_est
label define type_est 1 "private" 2 "public" 3 "NGO" 
label values type_est type_est

*(xii) Participation
replace participa=1 if work==0

*(xiiii) Dolares
local dolar12 6.91  //by 2 diciembre 2012
local dolar13 6.91  //by 2 diciembre 2013
local dolar14 6.91  //by 1 diciembre 2014
local dolar15 6.91  //by 1 diciembre 2015
local dolar16 6.91  //by 1 diciembre 2016
local dolar17 6.92  //by 1 diciembre 2017
local dolar18 6.91  //by 2 diciembre 2018
local dolar19 6.91  //by 2 diciembre 2019


*****(4) Ocupational category
replace ocu_cat=9 if work2==0  & age>=7
replace ocu_cat2=5 if work2==0 & age>=7

*****(c) Household characteristics

**(1) Head of schooling is self employed
gen aux_cpropia=1 if ocu_cat==2 & rel_jefe==1
bys folio t: egen aux_cpropia2=total(aux_cpropia)
gen head_selfemp=1 if aux_cpropia2>0
replace head_selfemp=0 if aux_cpropia2==0
drop aux_cpropia aux_cpropia2

**(2) Total adult earnings in household
bys folio t: gen aux_w=ytotal2 if age>=18
bys folio t: egen adult_earnings=total(aux_w)
drop aux_w

**(3) Head of househoold's years of schoolling 
bys folio t: gen aux_esc=esc if rel_jefe==1
bys folio t: egen head_schooling=total(aux_esc)
drop aux_esc

**(4) Numper
bys folio t: gen aux_per=1
bys folio t: egen n_household=total(aux_per)
drop aux_per

**(5) Q of women in household
bys folio t: gen aux_women=1 if sex==2
bys folio t: egen n_female=total(aux_women)
drop aux_women

**(6) Q of Men in household
bys folio t: gen aux_men=1 if sex==1
bys folio t: egen n_male=total(aux_men)
drop aux_men

**(7) Q of Age Range
local a5 0 
local a13 6 
local a17 14
local a25 18
local a35 26
local a45 36
local a55 46
local a65 56

foreach i in "5" "13" "17" "25" "35" "45" "55" "65"{

gen aux_`a`i''_`i'=1 if inrange(age,`a`i'',`i')
bys folio t: egen n_`a`i''_`i'=total(aux_`a`i''_`i')
drop aux_`a`i''_`i'
}
gen aux_65_mas=1 if age>65
bys t folio: egen n_65_more=total(aux_65_mas) 
drop aux*


*(8) head_works
gen aux=1 if rel_jefe==1 & work==1
bys folio t: egen head_works=total(aux)
drop aux

*(9) any business
gen aux=1 if ocu_cat2==2
bys folio t: egen any_business=total(aux)
replace any_business=0 if any_business==.
replace any_business=1 if any_business>0 & any_business!=.
drop aux

*(10) head gender
gen aux=1 if sex==1 & rel_jefe==1
replace aux=0 if sex==2 & rel_jefe==1
bys folio t: egen head_male=total(aux)
drop aux

*(11) head age
gen aux=age if rel_jefe==1
bys folio t: egen head_age=total(aux)
drop aux

*(12) head spanish
gen aux=1 if rel_jefe==1 & idioma==3
bys folio t: egen head_spanish=total(aux)
drop aux

*****(d) Personal characteristics

*(1) Age range
gen age_cat=.
replace age_cat=1 if inrange(age,0,5)
replace age_cat=2 if inrange(age,6,13)
replace age_cat=3 if inrange(age,14,17)
replace age_cat=4 if inrange(age,18,25)
replace age_cat=5 if inrange(age,26,35)
replace age_cat=6 if inrange(age,36,45)
replace age_cat=7 if inrange(age,46,55)
replace age_cat=8 if inrange(age,56,65)
replace age_cat=9 if age>65

label define age_cat 1 "5 or less" 2 "6 to 13" 3 "14 to 17" 4 "18 to 25" 5 "26 to 35" 6 "36 to 45" /*
*/ 7 "46 to 55" 8 "56 to 65" 9  "More than 65"
label values age_cat age_cat

*(2) Language of childhood
rename idioma language_childhood

*(3) indigenous
gen indigenous=1 if inlist(pueblo,1,2,3)
replace indigenous=0 if pueblo==0
replace pueblo=. if inlist(t,2017,2015,2014) 
drop pueblo

*(4) spanish
gen spanish=1 if language_childhood==3
replace spanish=0 if inlist(language_childhood,0,1,2,4,5,6,7)
replace language_childhood=. if language_childhood==0

*(5) male
gen male=1 if sex==1
replace male=0 if sex==2
label define male 0 "female" 1 "male"
label values male male
drop sex

*(5) Urban
gen urban=1 if area==1
replace urban=0 if area==2
drop area

*(6) birth
replace birth_year=. if birth_year>2100
replace birth_month=. if birth_month>12
replace birth_day=. if birth_month>31

*(7) Bono Juancito
replace recibe_bono_juancito=0 if recibe_bono_juancito==. & inrange(t,2007,2018)

*(8) Educ
replace recibe_desayuno=0 if recibe_desayuno==. & (inrange(t,2008,2018) | t==2004)
replace enrollment=0 if enrollment==.
replace lee_escribe=0 if lee_escribe==.
replace suma_multiplica=0 if suma_multiplica==. & inrange(t,2016,2018)

*****(x) rename
rename esc schooling
rename factor f_weight
rename ytrabajo ylabor
rename ytrabajo2 ylabor2
rename yhogar yhousehold
rename yhogarpc ypc
rename work employed
rename work2 works
rename participa lf_participation
rename estudia attendance
rename lee_escribe reads
rename rel_jefe rel_head
rename idioma_nativo native_language
rename enrollment enrolled
rename suma_multiplica basic_math
rename nocturna night_education
rename recibe_desayuno receives_breakfast
rename recibe_bono_juancito receives_cct_juancito

*****(Xe) Winsorized

foreach x in hours_day days_week hours_week ytotal ylabor yhousehold ypc wage_hour{
winsor `x', gen(`x'_w) p(0.01) high
}

*(Y) Other

gen aux=""
replace aux="10,16,2012"	if t==2012
replace aux="11,21,2013"	if t==2013
replace aux="11,1,2014"	if t==2014
replace aux="11,21,2015"	if t==2015
replace aux="11,1,2016"	if t==2016

gen date_collection2=date(aux,"MDY")
format date_collection2 %td

label var date_collection2 "Data collection date aprox"
drop aux

g date_collection=mdy(encuesta_mes,encuesta_dia,encuesta_ano)
format date_collection %td
label var date_collection "Data collection date"


*Year2
gen year=t
gen year2=year

*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
egen id_year=concat(year id)
egen folio_year=concat(year folio)
rename place_taxes firm_taxes
*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

***(z) relabeled
label var folio "Household ID"
label var id "Personal ID"
label var year "Survey wave year"
label var year2 "Interview year (includes 2003 and 2004)"
label var id_year "Year and Personal ID"
label var depto "Department (Region)"
label var cod_prov "Province code"
label var cod_secc "Municipal code"
label var schooling "Years of schooling"
label var f_weight "Inverse survey weights"
label var male "Gender (1 if male, 0 female)"
label var age "Age"
label var civil_status "Civil status of the person"
label var upm "PSU code"
label var ytotal "Total personal income"
label var ylabor "Earnings"
label var yhousehold "Household income"
label var ypc "Percapita household income"
label var ytotal2 "Total personal income (have a 0 if not)"
label var ylabor2 "Work income of the person (have a 0 if not)"
label var employed "Indicator of whether a person is employed (0 if not and looks for a job)"
label var works "Indicator of whether a person reports working (0 if not working, regardless of whether they looked for a job or not)"
label var work_lastweek "Worked at least one hour last week"
label var lf_participation "Indicator of whether a person participates in the labor force ( 1 if works or looked for a job, 0 otherwise)"
label var hours_day "Average # of hours worked per day"
label var days_week "Average # of days worked per week"
label var hours_week "Average # of hours worked per week"
label var wage_hour "Hourly wage ($BS/hour)"
label var ocu_cat "Occupational categories (8 cat)"
label var ocu_cat2 "Occupational categories (4 cat)"
label var wage_worker "Indicator of whether a person works for a wage"
label var self_employed "Indicator of whether a person is self-employed (own account)"
label var sector "Economic sector based on main occupation"
label var age_cat "Age categories"
label var enrolled "Indicator of whether the person is enrolled in school/educational institution"
label var attendance "Indicator describing attendance to school"
label var reads "Indicator of whether interviewee reads and writes"
label var rel_head "Relationship with the head of household"
label var head_selfemp "Indicator of whether the head of household is self employed"
label var language_childhood "Mother tongue"
label var native_language "Indicator if  interviewee speaks a native language"
label var spanish "Main language is Spanish"
label var birth_day "Birth day"
label var birth_month "Birth month"
label var birth_year "Birth year"
label var indigenous "Self-reported identification with indigenous groups"
label var head_works "Indicator of wether the hh head works"
label var any_business "Indicator of whether the any household member owns a business"
label var adult_earnings "Total earnigns of adults in the household)"
label var head_schooling "Years of schooling (head )"
label var adult_earnings "Total earnigns of adults in the household"
label var n_household "Number of people in the household"
label var n_male "Number of females in the household"
label var n_female "Number of females in the household"
label var n_0_5 "Number oh hh members - 0 and 5"
label var n_6_13 "Number oh hh members - 6 and 13"
label var n_14_17 "Number oh hh members - 14 and 17"
label var n_18_25 "Number oh hh members - 18 and 25"
label var n_26_35 "Number oh hh members - 26 and 35"
label var n_36_45 "Number oh hh members - 36 and 45"
label var n_46_55 "Number oh hh members - 46 and 55"
label var n_56_65 "Number oh hh members - 56 and 65"
label var n_65_more "Number oh hh members - more than 65 years"
label var urban "1=urban area, 0=rural  area"
label var job_location "Job location"
label var head_male "Indicator of wether the hh head is male"
label var head_age "HH head age"
label var head_spanish "Indicator of wether the hh head main language is spanish"


label var hours_day_w "Average # of hours worked per day (winsorized)"
label var days_week_w "Average # of days worked per week (winsorized)"
label var hours_week_w "Average # of hours worked per week (winsorized)"
label var ytotal_w "Total personal income (winsorized)"
label var ylabor_w "Earnings (winsorized)"
label var yhousehold_w "Household income (winsorized)"
label var ypc_w "Percapita household income (winsorized)"
label var wage_hour_w "Hourly wage ($BS/hour) - (winsorized)"

label var hired_recruiters "Child was hired through recruiters"
label var work_conditions "Knowledge and Agreement with employer's conditions"
label var main_reason_work "Reasons for working"
label var firm_taxes "Employer's firm pays taxes (=1 yes, 0=not/not aware"
label var number_workers "Number of workers in the firm"
label var contract "Contract/Agreement type"
label var type_est "Type of establishment Public(=1), private (=2)or NGO/non-profit (=3)"

label var poor "1=Income poverty"
label var poor_xtr "1=Extreme Income poverty"
label var pov_line "Income poverty line"
label var pov_xtr_line "Extreme Income poverty line"

label var type_est "Type of establishment Public(=1), private (=2)or NGO/non-profit (=3)"

label var night_education "Studies at night school"
label var receives_breakfast "Receives breakfast at school"
label var receives_cct_juancito "Receives the cct Juancito Pinto"
label var basic_math  "Is able to add and multiply" 
 
label var job_main_ocupation "Main ocupation at work"
label var  job_specifics_tasks "Main tasks at work"

*****(zi) english values variable label

label drop ocu_cat ocu_cat2 rel_jefe idioma sector

label define ocu_cat 1 "Worker" 2 "Employee" 3 "Self Employed" 4 "Business owner with salary" 5 "Unpaid business owner" 6 "Works for a cooperative" 7 "Unpaid family worker/apprentinceship" 8 "Household worker (maid)" 9 "Does not work"
label values ocu_cat ocu_cat

label drop work_conditions
label define work_conditions 1 "Child knows and approves employer conditions" 2 "Child neither knows nor approves employer conditions" 3 "Child knows but disapproves employer conditions"
label values work_conditions work_conditions

label drop main_reason_work
label define main_reason_work 1 "to generate own income" 2 "to suplement family income" 3 "to temporarily support family" 4 "Learning/training" 5 "traditions" 6 "Other"
label values main_reason_work main_reason_work

label define ocu_cat2 1 "Paid worker" 2 "Self-employed or unpaid business worker" 3 "Paid business owner" 4 "Unpaid Family worker or apprentice" 5 "Does not work"
label values ocu_cat2 ocu_cat2

label define rel_head 1 "Head" 2 "Spouse or partner" 3 "Daughter/son" 4 "Grand children" 5 "Siblings or brother/sister in law" 6 "Siblings or brother/sister in law" 7 "Parents or in parents in law" 8 "Other"
label values rel_head rel_head

label define language_childhood  1 "quechua" 2 "aymara" 3 "castellano" 4 "guarani" 5 "otro nativo" 6 "extranjero" 7 "no puede hablar"
label values language_childhood language_childhood

label define sector 1 "Agriculture, forestry, livestock and fishing" 2 "Mining and hydrocarbons" 3 "Manufacturing" 4 "Electricity, natural gas and water" /*
*/ 5 "Infrastructure/Construction" 6 "Commerce and retail" 7 "Distributive trade, transportation and communication" 8 "Financial and insurance activities" /*
*/ 9 "Other comunal, social, personal and domestic services" 10 "Accomodation and food services" 11 "Public administration, education and health"
label values sector sector

label define civil_status 1 "Single" 2 "Maried" 3 "Co-habiting/domestic partner" 4 "Separated" 5 "Divorced" 6 "Widow(er)"
label values civil_status civil_status 

rename ytotal ytotal_c
rename ylabor ylabor_c
rename yhousehold yhousehold_c
rename ypc ypc_c
rename ytotal2 ytotal2_c
rename ylabor2 ylabor2_c

drop date_collection*

rename encuesta_dia collection_day
rename encuesta_mes collection_month
rename encuesta_ano collection_year

******(zii) New collection data
gen collection_month_start=.
gen collection_month_end=.

replace collection_month=12 if inlist(collection_month,1,2)

bys collection_year: egen aux_min=min(collection_month)
bys collection_year: egen aux_max=max(collection_month)

replace collection_month_start=aux_min if aux_min!=.
replace collection_month_end=aux_max if aux_max!=.
replace collection_month_start=12 if inlist(year,2078)

replace collection_month_start=11 if inlist(year,2015)
replace collection_month_start=10 if inlist(year,2012,2017,2019)


replace collection_month_end=11 if inlist(year,2012,2015)
replace collection_month_end=12 if inlist(year,2017,2018,2019)

/*==================================================
            3: Save Data
==================================================*/

** Database order
global identificacion id folio t year id_year depto cod_prov cod_secc urban f_weight upm
global caracteristicas male age schooling civil_status attendance enrolled  level_enrolled enrolled_public night_education receives_breakfast receives_cct_juancito basic_math age_cat reads native_language language_childhood spanish birth_day birth_month birth_year indigenous 
global household rel_head head_schooling head_male head_age head_spanish adult_earnings head_selfemp head_works any_business n_household n_*
global work ocu_cat ocu_cat2 employed hours_day* days_week* sector works work_lastweek wage_worker/*
*/ lf_participation hours_week* unpaid_worker self_employed job_location firm_taxes number_workers number_workers_cat contract type_est health_insurance job*
global incomes ylabor* ytotal* yhousehold* ypc* wage_hour* poor* pov*

order $identificacion $caracteristicas $household $work $incomes , first

** Save
save "${relabeled_data}/Persona/EH_cleaned_persona", replace
