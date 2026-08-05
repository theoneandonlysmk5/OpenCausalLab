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

/* This .do file cleans 2011 Household Survey demographic and employment data for individuals */

/*==================================================
            0: Program set up
==================================================*/
*Written on STATA 17
drop _all

/*==================================================
            1: Manage Dataset
==================================================*/

use "${raw_data}/2014/EH2014_vivienda.dta", clear
keep folio ano mes dia 

rename ano encuesta_ano
rename mes encuesta_mes
rename dia encuesta_dia

merge 1:m folio using "${raw_data}/2014/EH2014_Persona"

drop _merge

*Define ID by person
egen id=concat(folio nro)  //ifolio is a house folio and nro is the intrahousehold id, so concat both makes an unique ID. 

*Destring variables
destring yper ylab yhog, replace dpcomma force

*Incomes
gen ytotal=yper
replace ytotal=. if ytotal==0
gen ytrabajo=ylab
replace ytrabajo=. if ytrabajo==0
gen yhogar=yhog
gen yhogarpc=yhogpc

*Variables Name
rename s2a_02 sex
rename s2a_03 age
rename e esc

*Civil Status
gen civil_status=s2a_10 
replace civil_status=. if s2a_10==9

label define civil_status 1 "Soltero(a)" 2 "Casado(a)" 3 "Conviviente(a)" 4 "Separado(a)" 5 "Divorciado(a)" 6 "Viudo(a)"
label values civil_status civil_status


*Define Working
gen work=.
replace work=1 if s6a_01==1   //If the person was looking for a job last week, then is working.
replace work=1 if inrange(s6a_02,1,6) //If the person work in a unwaged or familiar job, then is working.
replace work=1 if inrange(s6a_03,1,6)  // If the person didn't work last week because have free week (by holidays, health, or other conditions), then is working.
replace work=0 if pet==1 & (s6a_05==1 | s6a_10==1) //If the person look for a job (or have a job, but it isn't started yet), then is working. 

gen work_lastweek=s6a_01
recode work_lastweek 2=0

*Occupational category
gen ocu_cat=.
replace ocu_cat=s6b_16

label define ocu_cat 1 "Obrero(a)" 2 "Empleado(a)" 3 "Trabajador(a) por cuenta propia" 4 "Patron, socio o empleador con salario" 5 "Patron socio o empleador sin salario" 6 "Cooperativista" 7 "Tra. familiar o aprendiz sin w" 8 "Empleado(a) del hogar"
label values ocu_cat ocu_cat

gen ocu_cat2=1 if inlist(ocu_cat,1,2,6,8)
replace ocu_cat2=2 if inlist(ocu_cat,3,5)
replace ocu_cat2=3 if ocu_cat==4
replace ocu_cat2=4 if ocu_cat==7

label define ocu_cat2 1 "Obrero/empleado o cooperativista" 2 "Cuenta propia o patron sin w" 3 "Patron con w" 4 "Tra. familiar o aprendiz sin w"
label values ocu_cat2 ocu_cat2

*hours worked at day
replace s6b_23m=0 if s6b_23m==.
gen hours_worked_day=s6b_23h+s6b_23m/60

*day worked at week
gen days_worked_week=s6b_22

*Job location
gen job_location=1 if s6b_19==1 
replace job_location=2 if s6b_19==2
replace job_location=3 if inlist(s6b_19,3,4,5,6,7,8)
replace job_location=4 if inlist(s6b_19,0,9)
replace job_location=5 if age>=7 & job_location==.

label define job_location 1 "Works from home" 2 "Works in an exclusive, fixed location outside home" 3 "Works in a roaming location" 4 "Other" 5 "Does not work"
label values job_location job_location


*Enrollment
gen enrollment=.
replace enrollment=1 if s5a_04==1
replace enrollment=0 if s5a_04==2

gen level_enrolled=1 if s5a_05==41 & s5a_05a==1
forvalues i=2(1)6{
replace level_enrolled=`i' if s5a_05==41 & s5a_05a==`i'
}
forvalues i=1(1)6{
replace level_enrolled=6+`i' if s5a_05==42 & s5a_05a==`i'
}
label var level_enrolled "Grade in which child is enrolled"

gen enrolled_public= (s5a_09==1) if s5a_09!=.
label var enrolled_public "Enrolled in public school"

*Departamentos
label define depto 1 "Chuquisaca" 2 "La Paz" 3 "Cochabamba" 4 "Oruro" 5 "Potosi" 6 "Tarija" 7 "Santa Cruz" 8 "Beni" 9 "Pando"
label values depto depto

*Ano
gen t=2014

*Estudia
gen estudia=0
replace estudia=1 if s5b_10==1
replace estudia=1 if s5b_11==1 

*leer y escribir
gen lee_escribe=1 if s5a_01==1
replace lee_escribe=0 if s5a_01==2

*recibe desayuno
gen recibe_desayuno=1 if inlist(s5a_07,1,2)
replace recibe_desayuno=0 if s5a_07==3

*bono juancito pinto
gen recibe_bono_juancito=1 if s5a_08==1
replace recibe_bono_juancito=0 if s5a_08==2

*educacion nocturna
gen nocturna=(inlist(s5a_05,12,61,62,63,64))

*rural
gen area=1 if urbrur==1
replace area=2 if urbrur==2

*prov
destring prov, replace
tostring prov, replace

*Relación jefe hogar
gen rel_jefe=s2a_05 if s2a_05<=4 
replace rel_jefe=5 if s2a_05==8
replace rel_jefe=6 if s2a_05==5
replace rel_jefe=7 if inlist(s2a_05,6,7)
replace rel_jefe=8 if s2a_05>8

label define rel_jefe 1 "jefe o jefa de hogar" 2 "esposa(o) o conviviente" 3 "hijo(a) o entenado(a)" 4 "yerno o nuera" 5 "nieto o nieta" /*
*/ 6 "hermano o cunado" 7 "padres o suegros" 8 "otro"
label values rel_jefe rel_jefe

*Idioma Ninez
gen idioma=1 if s2a_08=="QUECHUA"
replace idioma=2 if s2a_08=="AYMARA"
replace idioma=3 if s2a_08=="CASTELLANO"
replace idioma=4 if s2a_08=="GUARAN"
replace idioma=6 if s2a_08=="IDIOMA EXTRANJERO"
replace idioma=7 if s2a_08=="99"
replace idioma=5 if s2a_08!="" & idioma==.

label define idioma 1 "quechua" 2 "aymara" 3 "castellano" 4 "guarani" 5 "otro nativo" /*
*/ 6 "extranjero" 7 "no puede hablar"
label values idioma idioma

*Sabe hablar idioma nativo
encode s2a_07a, gen(cods2_07a)
encode s2a_07b, gen(cods2_07b)
encode s2a_07c, gen(cods2_07c)

gen idioma_nativo=1 if inlist(idioma,1,2,4,5) 
replace idioma_nativo=1 if inlist(cods2_07a,3,5,8,10,11,14,15,16,19,20,22,23)
replace idioma_nativo=1 if inlist(cods2_07b,3,5,8,10,11,14,15,16,19,20,22,23)
replace idioma_nativo=1 if inlist(cods2_07c,3,5,8,10,11,14,15,16,19,20,22,23)
replace idioma_nativo=0 if idioma_nativo==.

*fecha nacimiento
gen birth_day=s2a_04a 
gen birth_month=s2a_04b 
gen birth_year=s2a_04c

*pueblo originario
gen pueblo=.
replace pueblo=1 if s3a_02a==1
replace pueblo=0 if s3a_02a==2

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
gen number_workers=s6b_20

*Type of establishment 
gen type_est=1 if inlist(s6b_17,3,4)  
replace type_est=2 if inlist(s6b_17,1,2)
replace type_est=3 if inlist(s6b_17,5,6)

label define type_est 1 "private" 2 "public" 3 "NGO" 
label values type_est type_est

*Whether the worker works is eligible for taxes
gen places_taxes2=1 if inlist(s6b_18,1,2)
replace places_taxes2=2 if inlist(s6b_18,3)
replace places_taxes2=3 if inlist(s6b_18,4)

label define places_taxes2 1 "si" 2 "no/en proceso" 3 "no sabe"
label values places_taxes2 places_taxes2

*Whether the worker signed a contract
gen contract=s6b_21 if inlist(s6b_21 ,1,2,3)
replace contract=4 if s6b_21 ==5
replace contract=5 if s6b_21 ==4

label define contract 1 "si firmo, fecha vencimiento" 2 "no firmo, pero compromiso por obra" 3 "es personal de planta con item" 4 "no firmo contrato" 5 "es independiente"
label values contract contract

*Pobreza
gen poor=(p0==1)
gen pov_line=z
gen poor_xtr=(pext0==1)
gen pov_xtr_line=zext

global poverty poor* pov*

*Main Activity
rename s6b_11ad  job_main_ocupation
rename s6b_11b job_specifics_tasks

*Health insurance
recode s6c_29b 2=0
rename s6c_29b health_insurance

/*==================================================
            3: Save new dataset
==================================================*/

*Saved variables
keep id folio depto area sex age civil_status estudia lee_escribe esc enrollment level_enrolled enrolled_public work work_lastweek ocu_cat sector hours_worked_day days_worked_week ytotal ytrabajo yhogar yhogarpc factor t upm rel_jefe idioma idioma_nativo /*
*/ birth_day birth_month birth_year pueblo ocu_cat2 mun prov job_location number_workers places_taxes2 contract type_est encuesta_* $poverty recibe_desayuno recibe_bono_juancito nocturna health_insurance job* s5c_16 s5c_13 s5c_14 s5c_15 s5c_16

*Save
save "${relabeled_data}/Persona/EH2014_Persona_relabel", replace

