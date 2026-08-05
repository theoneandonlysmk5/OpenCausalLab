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

/* This .do file cleans 2012 Household Survey demographic and employment data for individuals */

/*==================================================
            0: Program set up
==================================================*/
*Written on STATA 17
drop _all

/*==================================================
            1: Manage Dataset
==================================================*/

use "${raw_data}/2012/EH2012_Persona.dta", clear


*Define ID by person
tostring folio nro1a, replace
egen id=concat(folio nro1a)  //ifolio is a house folio and nro is the intrahousehold id, so concat both makes an unique ID. 

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
rename s1_03 sex
rename s1_04 age
rename s1_13 civil_status
rename e esc

*Define Working
gen work=.
replace work=1 if s5_01==1   //If the person was looking for a job last week, then is working.
replace work=1 if inrange(s5_02,1,6) //If the person work in a unwaged or familiar job, then is working.
replace work=1 if inrange(s5_03,1,6)  // If the person didn't work last week because have free week (by holidays, health, or other conditions), then is working.
replace work=0 if pet==1 & (s5_05==1 | s5_15==1) //If the person look for a job (or have a job, but it isn't started yet), then is working. 

gen work_lastweek=s5_01
recode work_lastweek 2=0

*Occupational category
gen ocu_cat=.
replace ocu_cat=s5_21

label define ocu_cat 1 "Obrero(a)" 2 "Empleado(a)" 3 "Trabajador(a) por cuenta propia" 4 "Patron, socio o empleador con salario" 5 "Patron socio o empleador sin salario" 6 "Cooperativista" 7 "Tra. familiar o aprendiz sin w" 8 "Empleado(a) del hogar"
label values ocu_cat ocu_cat

gen ocu_cat2=1 if inlist(ocu_cat,1,2,6,8)
replace ocu_cat2=2 if inlist(ocu_cat,3,5)
replace ocu_cat2=3 if ocu_cat==4
replace ocu_cat2=4 if ocu_cat==7

label define ocu_cat2 1 "Obrero/empleado o cooperativista" 2 "Cuenta propia o patron sin w" 3 "Patron con w" 4 "Tra. familiar o aprendiz sin w"
label values ocu_cat2 ocu_cat2

*hours worked at day
gen hours_worked_day=s5_29h+s5_29m/60

*day worked at week
gen days_worked_week=s5_29

*Job location
gen job_location=1 if s5_26==1 
replace job_location=2 if s5_26==2
replace job_location=3 if inlist(s5_26,3,4,5,6,7)
replace job_location=4 if inlist(s5_26,8)
replace job_location=5 if age>=7 & job_location==.

label define job_location 1 "Works from home" 2 "Works in an exclusive, fixed location outside home" 3 "Works in a roaming location" 4 "Other" 5 "Does not work"
label values job_location job_location

*Enrollment
gen enrollment=.
replace enrollment=1 if s4_04==1
replace enrollment=0 if s4_04==2

gen level_enrolled=1 if s4_05a==19 & s4_05b==1
forvalues i=2(1)6{
replace level_enrolled=`i' if s4_05a==19 & s4_05b==`i'
}
forvalues i=1(1)6{
replace level_enrolled=6+`i' if s4_05a==20 & s4_05b==`i'
}
label var level_enrolled "Grade in which child is enrolled"

gen enrolled_public= (s4_10==1|s4_10==2) if s4_10!=.
label var enrolled_public "Enrolled in public school"

*Departamentos
gen depto=departamento

label define depto 1 "Chuquisaca" 2 "La Paz" 3 "Cochabamba" 4 "Oruro" 5 "Potosi" 6 "Tarija" 7 "Santa Cruz" 8 "Beni" 9 "Pando"
label values depto depto

*Ano
gen t=2012

*Estudia
gen estudia=0
replace estudia=1 if s4_12==1
replace estudia=1 if s4_13==1 

*leer y escribir
gen lee_escribe=1 if s4_01==1
replace lee_escribe=0 if s4_01==2

*recibe desayuno
gen recibe_desayuno=1 if inlist(s4_07,1,2)
replace recibe_desayuno=0 if s4_07==3

*bono juancito pinto
gen recibe_bono_juancito=1 if s4_08==1
replace recibe_bono_juancito=0 if s4_08==2

*educacion nocturna
gen nocturna=(inlist(s4_05a,12,61,62,63,64))

*Upm
rename upm upm2
tostring upm2, replace
gen upm=substr(upm2,1,5)
destring upm upm2, replace

*Relación jefe hogar
gen rel_jefe=s1_08 if s1_08<=4 
replace rel_jefe=5 if s1_08==8
replace rel_jefe=6 if s1_08==5
replace rel_jefe=7 if inlist(s1_08,6,7)
replace rel_jefe=8 if s1_08>8

label define rel_jefe 1 "jefe o jefa de hogar" 2 "esposa(o) o conviviente" 3 "hijo(a) o entenado(a)" 4 "yerno o nuera" 5 "nieto o nieta" /*
*/ 6 "hermano o cunado" 7 "padres o suegros" 8 "otro"
label values rel_jefe rel_jefe

*Idioma Ninez
gen idioma=1 if c1_11=="QUECHUA"
replace idioma=2 if c1_11=="AYMARA"
replace idioma=3 if c1_11=="CASTELLANO"
replace idioma=4 if c1_11=="GUARAN"
replace idioma=6 if c1_11=="IDIOMA EXTRANJERO"
replace idioma=7 if c1_11=="99"
replace idioma=5 if c1_11!="" & idioma==.

label define idioma 1 "quechua" 2 "aymara" 3 "castellano" 4 "guarani" 5 "otro nativo" /*
*/ 6 "extranjero" 7 "no puede hablar"
label values idioma idioma

*Sabe hablar idioma nativo
gen idioma_nativo=1 if inlist(idioma,1,2,4,5) 
replace idioma_nativo=1 if c1_10a!="" & c1_10a!="CASTELLANO" & c1_10a!="IDIOMA EXTRANJERO" 
replace idioma_nativo=1 if c1_10b!="" & c1_10b!="CASTELLANO" & c1_10b!="IDIOMA EXTRANJERO"
replace idioma_nativo=1 if c1_10b!="" & c1_10b!="CASTELLANO" & c1_10b!="IDIOMA EXTRANJERO"
replace idioma_nativo=0 if idioma_nativo==.

*fecha nacimiento
gen birth_day=s1_05a 
gen birth_month=s1_05b 
gen birth_year=s1_05c

*pueblo originario
gen pueblo=1 if s2_05b=="QUECHUA"
replace pueblo=2 if s2_05b=="AYMARA"
replace pueblo=3 if s2_05a==1 & pueblo==.
replace pueblo=0 if s2_05a!=1

label define pueblo 1 "quechua" 2 "aymara" 3 "otro" 0 "Ninguna"
label values pueblo pueblo

*sectores
gen sector=.
replace sector=1 if inlist(caeb_op1,0)
replace sector=2 if inlist(caeb_op1,1)
replace sector=3 if inlist(caeb_op1,2)
replace sector=4 if inlist(caeb_op1,3,4)
replace sector=5 if inlist(caeb_op1,5)
replace sector=6 if inlist(caeb_op1,6)
replace sector=7 if inlist(caeb_op1,7,9)
replace sector=8 if inlist(caeb_op1,10,11)
replace sector=9 if inlist(caeb_op1,12,13,15,16,17,18,19)
replace sector=10 if inlist(caeb_op1,8)
replace sector=11 if inlist(caeb_op1,14,20)

label define sector 1 "Agricultura, silvicultura, caza y pesca" 2 "Extraccion de minas y canteras" 3 "Industrias manuifactureras" 4 "Electricidad, gas y agua" /*
*/ 5 "Construccion" 6 "Comercio" 7 "Transporte, almacenamiento y comunicaciones" 8 "Establecimientos financieros" /*
*/ 9 "Servicios comunales, sociales, personales y domesticos" 10 "Restaurantes y hoteles" 11 "Servicios de la Adm. Publica"
label values sector sector

*Number of employees in the establishment in which a worker works
gen number_workers=s5_27 

*Type of establishment 
gen type_est=1 if s5_22==2 
replace type_est=2 if s5_22 ==1
replace type_est=3 if s5_22==3

label define type_est 1 "private" 2 "public" 3 "NGO"
label values type_est type_est

*Whether the worker works is eligible for taxes
gen places_taxes=1 if inlist(s5_25,1,2)
replace places_taxes=2 if inlist(s5_25,3)
replace places_taxes=3 if inlist(s5_25,4,5)
replace places_taxes=4 if inlist(s5_25,6)

label define places_taxes 1 "si" 2 "no" 3 "en proceso" 4 "no sabe"
label values places_taxes places_taxes

gen places_taxes2=1 if inlist(s5_25,1,2) 
replace places_taxes2=2 if inlist(s5_25,3,4,5)
replace places_taxes2=3 if inlist(s5_25,6)

label define places_taxes2 1 "si" 2 "no/en proceso" 3 "no sabe"
label values places_taxes2 places_taxes2

*Whether the worker signed a contract
gen contract=s5_28

label define contract 1 "si firmo, fecha vencimiento" 2 "no firmo, pero compromiso por obra" 3 "es personal de planta con item" 4 "no firmo contrato"
label values contract contract

*Pobreza
gen poor=(p0==1)
gen pov_line=z
gen poor_xtr=(pext0==1)
gen pov_xtr_line=zext

global poverty poor* pov*

*Main Activity
rename  s5_16a   job_main_ocupation
rename s5_16b job_specifics_tasks

*Health insurance
recode s5_35b 2=0
rename s5_35b health_insurance

/*==================================================
            3: Save new dataset
==================================================*/

*Saved variables
keep id folio depto area sex age civil_status estudia lee_escribe esc enrollment level_enrolled enrolled_public work work_lastweek ocu_cat sector hours_worked_day days_worked_week ytotal ytrabajo yhogar yhogarpc factor t upm rel_jefe idioma idioma_nativo /*
*/ birth_day birth_month birth_year pueblo ocu_cat2 job_location number_workers places_taxes places_taxes2 contract type_est $poverty recibe_desayuno recibe_bono_juancito nocturna health_insurance job*

*Save
save "${relabeled_data}/Persona/EH2012_Persona_relabel", replace
