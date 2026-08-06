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

/* This .do file cleans 2018 Household Survey demographic and employment data for individuals */

/*==================================================
            0: Program set up
==================================================*/
*Written on STATA 17
drop _all

/*==================================================
            1: Manage Dataset
==================================================*/

use "${raw_data}/2018/EH2018_persona.dta", clear

*Define ID by person
tostring folio nro, replace
egen id=concat(folio nro)  //folio is a house folio and nro is the intrahousehold id, so concat both makes an unique ID. 


*Incomes
gen ytotal=yper
replace ytotal=. if ytotal==0
gen ytrabajo=ylab
replace ytrabajo=. if ytrabajo==0
gen yhogar=yhog
gen yhogarpc=yhogpc

*Variables Name
gen sex=1 if (s02a_02==1)
replace sex=2 if (s02a_02==2)
rename s02a_03 age
rename s02a_10 civil_status
rename aestudio esc

gen work=.
replace work=1 if s06a_01==1   //If the person was looking for a job last week, then is working.
replace work=1 if inrange(s06a_02,1,7) //If the person work in a unwaged or familiar job, then is working.
replace work=1 if inrange(s06a_03,1,9)  // If the person didn't work last week because have free week (by holidays, health, or other conditions), then is working.
replace work=0 if pet==1 & (s06a_05==1 | s06a_10==1) //If the person look for a job (or have a job, but it isn't started yet), then is working. 

gen work_lastweek=s06a_01
recode work_lastweek 2=0

*Occupational category
gen ocu_cat=.
replace ocu_cat=s06b_16
replace ocu_cat=s06b_16-1 if s06b_16>7

label define ocu_cat 1 "Obrero(a)" 2 "Empleado(a)" 3 "Trabajador(a) por cuenta propia" 4 "Patron, socio o empleador con salario" 5 "Patron socio o empleador sin salario" 6 "Cooperativista" 7 "Tra. familiar o aprendiz sin w" 8 "Empleado(a) del hogar"
label values ocu_cat ocu_cat

gen ocu_cat2=1 if inlist(ocu_cat,1,2,6,8)
replace ocu_cat2=2 if inlist(ocu_cat,3,5)
replace ocu_cat2=3 if ocu_cat==4
replace ocu_cat2=4 if ocu_cat==7

label define ocu_cat2 1 "Obrero/empleado o cooperativista" 2 "Cuenta propia o patron sin w" 3 "Patron con w" 4 "Tra. familiar o aprendiz sin w"
label values ocu_cat2 ocu_cat2

*hours worked at day
gen hours_worked_day=s06b_23aa+s06b_23ab/60 if s06b_23a1==3
replace hours_worked_day=s06b_23aa+s06b_23ab/60+s06b_23a2/7 if s06b_23a1==2
replace hours_worked_day=s06b_23aa+s06b_23ab/60-s06b_23a2/7 if s06b_23a1==1

*day worked at week
gen days_worked_week=s06b_22

*Job location
gen job_location=1 if s06b_20==1 
replace job_location=2 if s06b_20==2
replace job_location=3 if inlist(s06b_20,3,4,5,6,7,8)
replace job_location=4 if inlist(s06b_20,9)
replace job_location=5 if age>=7 & job_location==.

label define job_location 1 "Works from home" 2 "Works in an exclusive, fixed location outside home" 3 "Works in a roaming location" 4 "Other" 5 "Does not work"
label values job_location job_location


*Enrollment
gen enrollment=.
replace enrollment=1 if s05a_05==1
replace enrollment=0 if s05a_05==2

gen level_enrolled=1 if s05a_06a==41 & s05a_06c==1
forvalues i=2(1)6{
replace level_enrolled=`i' if s05a_06a==41 & s05a_06c==`i'
}
forvalues i=1(1)6{
replace level_enrolled=6+`i' if s05a_06a==42 & s05a_06c==`i'
}
label var level_enrolled "Grade in which child is enrolled"

gen enrolled_public= (s05a_09==1) if s05a_09!=.
label var enrolled_public "Enrolled in public school"

*Ano
gen t=2018

*Estudia
gen estudia=0
replace estudia=1 if s05b_10==1
replace estudia=1 if s05b_11==1 | s05b_11a==1 

*leer y escribir
gen lee_escribe=1 if s05a_01==1
replace lee_escribe=0 if s05a_01==2

*sumar y multiplicar
gen suma_multiplica=1 if s05a_01a==1
replace suma_multiplica=0 if s05a_01a==2

*recibe desayuno
gen recibe_desayuno=1 if s05a_07a==1
replace recibe_desayuno=0 if s05a_07a==2

*bono juancito pinto
gen recibe_bono_juancito=1 if s05a_08==1
replace recibe_bono_juancito=0 if s05a_08==2

*educacion nocturna
gen nocturna=(inlist(s05a_06a,12,61,62,63,64))

*Relación jefe hogar
gen rel_jefe=s02a_05  if s02a_05 <=4 
replace rel_jefe=5 if s02a_05 ==8
replace rel_jefe=6 if s02a_05 ==5
replace rel_jefe=7 if inlist(s02a_05 ,6,7)
replace rel_jefe=8 if s02a_05 >8

label define rel_jefe 1 "jefe o jefa de hogar" 2 "esposa(o) o conviviente" 3 "hijo(a) o entenado(a)" 4 "yerno o nuera" 5 "nieto o nieta" /*
*/ 6 "hermano o cunado" 7 "padres o suegros" 8 "otro"
label values rel_jefe rel_jefe

*Idioma Ninez
gen idioma=1 if s02a_08==27
replace idioma=2 if s02a_08==2
replace idioma=3 if s02a_08==6
replace idioma=4 if s02a_08==12
replace idioma=6 if inrange(s02a_08,38,71)
replace idioma=7 if inlist(s02a_08,995,996)
replace idioma=5 if inrange(s02a_08,1,37) & idioma==.

label define idioma 1 "quechua" 2 "aymara" 3 "castellano" 4 "guarani" 5 "otro nativo" /*
*/ 6 "extranjero" 7 "no puede hablar"
label values idioma idioma

*Sabe hablar idioma nativo
gen idioma_nativo=1 if inlist(idioma,1,2,4,5) 
replace idioma_nativo=1 if inrange(s02a_07_1,1,37)
replace idioma_nativo=1 if inrange(s02a_07_2,1,37)
replace idioma_nativo=1 if inrange(s02a_07_3,1,37)
replace idioma_nativo=0 if idioma_nativo==.

*fecha nacimiento
gen birth_day=s02a_04a 
gen birth_month=s02a_04b 
gen birth_year=s02a_04c

gen pueblo=.
replace pueblo=1 if s03a_04==1
replace pueblo=0 if s03a_04==2


*sectores
gen sector=.
replace sector=1 if inlist(caeb_op,0)
replace sector=2 if inlist(caeb_op,1)
replace sector=3 if inlist(caeb_op,2)
replace sector=4 if inlist(caeb_op,3,4)
replace sector=5 if inlist(caeb_op,5)
replace sector=6 if inlist(caeb_op,6)
replace sector=7 if inlist(caeb_op,7,9)
replace sector=8 if inlist(caeb_op,10,11)
replace sector=9 if inlist(caeb_op,12,13,15,16,17,18,19)
replace sector=10 if inlist(caeb_op,8)
replace sector=11 if inlist(caeb_op,14,20)

label define sector 1 "Agricultura, silvicultura, caza y pesca" 2 "Extraccion de minas y canteras" 3 "Industrias manuifactureras" 4 "Electricidad, gas y agua" /*
*/ 5 "Construccion" 6 "Comercio" 7 "Transporte, almacenamiento y comunicaciones" 8 "Establecimientos financieros" /*
*/ 9 "Servicios comunales, sociales, personales y domesticos" 10 "Restaurantes y hoteles" 11 "Servicios de la Adm. Publica"
label values sector sector

*Number of employees in the establishment in which a worker works
gen number_workers=s06b_21 

*Type of establishment 
gen type_est=1 if inlist(s06b_18 ,3,4)  
replace type_est=2 if inlist(s06b_18 ,1,2)
replace type_est=3 if inlist(s06b_18 ,5,6)

label define type_est 1 "private" 2 "public" 3 "NGO" 
label values type_est type_est

*Whether the worker works is eligible for taxes
gen places_taxes2=1 if inlist(s06b_19 ,1,2)
replace places_taxes2=2 if inlist(s06b_19 ,3)
replace places_taxes2=3 if inlist(s06b_19 ,4)

label define places_taxes2 1 "si" 2 "no/en proceso" 3 "no sabe"
label values places_taxes2 places_taxes2

*Whether the worker signed a contract
gen contract=s06b_17 if inlist(s06b_17 ,1,2)
replace contract=2 if s06b_17 ==3
replace contract=3 if s06b_17 ==4
replace contract=4 if s06b_17 ==5

label define contract 1 "si firmo, fecha vencimiento" 2 "no firmo, pero compromiso por obra" 3 "es personal de planta con item" 4 "no firmo contrato" 5 "es independiente"
label values contract contract

*Pobreza
destring p*, replace
gen poor=(p0==1)
gen pov_line=z
gen poor_xtr=(pext0==1)
gen pov_xtr_line=zext

global poverty poor* pov*

*Main Activity
rename s06b_11a job_main_ocupation
rename s06b_11b job_specifics_tasks

*Health insurance
recode s06c_29b 2=0
rename s06c_29b health_insurance

/*==================================================
            3: Save new dataset
==================================================*/

*Saved variables
keep id folio depto area sex age civil_status estudia lee_escribe esc enrollment enrollment level_enrolled enrolled_public work work_lastweek ocu_cat sector hours_worked_day days_worked_week ytotal ytrabajo yhogar yhogarpc factor t upm rel_jefe idioma idioma_nativo birth_day birth_month birth_year pueblo ocu_cat2 job_location  number_workers places_taxes2 contract type_est $poverty suma_multiplica recibe_desayuno recibe_bono_juancito nocturna health_insurance job*

*Save
save "${relabeled_data}/Persona/EH2018_Persona_relabel", replace

  