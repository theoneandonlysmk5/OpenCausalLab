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

/* This .do file cleans 2012 Household Survey expenses data for households */

/*==================================================
            0: Program set up
==================================================*/
*Written on STATA 17
drop _all

/*==================================================
            1: Manage Dataset
==================================================*/

global year 2012

*I. ALIMENTARY AND NON ALIMENTARY DATA

*1.Alimentary expenses
use "${raw_data}/2012/EH2012_GastosAlimentarios.dta", clear

*1.1 Rename+destring key variables
destring s7*, replace dpcomma

*1.2 Expenditure
foreach x in compras autoconsumo{
local i_compras 05
local i_autoconsumo 08
local var 7

gen freq_`x'=.
replace freq_`x'=31 if s`var'_`i_`x''==1
replace freq_`x'=31/2 if s`var'_`i_`x''==2
replace freq_`x'=31/4 if s`var'_`i_`x''==3
replace freq_`x'=31/7 if s`var'_`i_`x''==4
replace freq_`x'=31/15 if s`var'_`i_`x''==5
replace freq_`x'=1 if s`var'_`i_`x''==6
replace freq_`x'=1/4 if s`var'_`i_`x''==7
replace freq_`x'=1/6 if s`var'_`i_`x''==8
replace freq_`x'=1/12 if s`var'_`i_`x''==9
}

foreach x in compras autoconsumo{

local j_compras 06a
local j_autoconsumo 09a
local j2_compras 07
local j2_autoconsumo 10
local no_compras 04

local var 7

replace s`var'_`j2_`x''=. if s`var'_`j2_`x''>=99999


gen expend_`x'=.
replace expend_`x'=freq_`x'*s`var'_`j2_`x'' if s`var'_`no_compras'==1
replace expend_`x'=0 if s`var'_`no_compras'==2
}
gen expend_otros=s`var'_12 if s`var'_11==1
replace expend_otros=0 if s`var'_11==2
egen expend_al=rowtotal(expend_compras expend_autoconsumo expend_otros)

*1.3 Collapse by folio 
collapse (sum) expend*, by(folio factor)

*1.4 Save data
save "${relabeled_data}/Expenses/EH2012_gasto_al", replace

*2.Non Alimentary expenses

*2.0 Recode gastos educ and food outside hh
use "${raw_data}/2012/EH2012_Persona.dta", clear

keep folio s7*

drop s7_02ee

global var1 s7_01*2 s7_02* s7_03* 
foreach x of varlist $var1{
replace `x'=. if `x'>9999
}

egen exp_outside_hh=rowtotal(s7_01*2)
egen educ_mensual=rowtotal(s7_02*)
egen educ_anual=rowtotal(s7_03*)
gen exp_education=educ_mensual+educ_anual/12

collapse (sum) exp*, by(folio)

save "${relabeled_data}/Expenses/EH2012_GastosNoAlimentarios_educ", replace

use "${raw_data}/2012/EH2012_GastosNoAlimentarios.dta", clear

merge 1:1 folio using "${relabeled_data}/Expenses/EH2012_GastosNoAlimentarios_educ"
drop _merge

*2.1 Rename+destring key variables
local var 7

destring s`var'*, replace dpcomma

*2.2 Expenditure construction
forvalues i=13/15{
foreach x in 01 02 03 04 05 06 07 08 09 10 12 13 14 15 16 17 18 19 20 21 22 23 24{
capture replace s`var'_`i'_`x'=. if s`var'_`i'_`x'>=99999
}
}

egen aux_month=rowtotal(s`var'_13*)
egen aux_quart=rowtotal(s`var'_14*)
replace aux_quart=aux_quart/3
egen aux_year=rowtotal(s`var'_15*)
replace aux_year=aux_year/12

egen expend_noal=rowtotal(aux*)
replace expend_noal=expend_noal+exp_education+exp_outside_hh
drop aux*

*2.2.1 Expenditure detail (transport education transport financial & health)
global detalle exp_transport+exp_education+exp_transport+exp_financial+exp_health

egen exp_transport=rowtotal(s7_13_02 s7_13_03 s7_13_15)  
egen exp_financial=rowtotal(s7_15_13 s7_15_14 s7_15_15)
replace exp_financial=exp_financial/12
egen exp_health=rowtotal(s7_14_01 s7_14_02 s7_14_03 s7_14_04)
replace exp_health=exp_health/12
replace exp_health=exp_health+s7_14_08/3 if  s7_14_08!=.

gen exp_cr_hipot=s7_15_13/12
gen exp_cr_consume=s7_15_14/12
gen exp_cr_card=s7_15_15/12

gen exp_noal_other=expend_noal-$detalle

*2.3 Collapse by folio 
collapse (sum) exp*, by(folio factor)

*2.4 Save data
save "${relabeled_data}/Expenses/EH2012_gasto_noal", replace

*3. Durable goods
use "${raw_data}/2012/EH2012_equipamiento", clear

*3.1 Rename+destring key variables
rename d_equip item

*3.2 Expenditure construction
g expend_dur_t=s7_19 if s7_18<=1
g durable=s7_19

foreach x in expend_dur_t durable{
replace `x'=. if `x'>999990
}

global art living stove fridge pc radio minicomponent tv washer moto car
forvalues i=1/10{
local x: word `i' of $art
g aux_have_`x'=(s7_16==1) if item==`i'
bys folio: egen have_`x'=total(aux_have_`x') 
g aux_cost_`x'=s7_19 if item==`i'
replace aux_cost_`x'=. if s7_19>999990
bys folio: egen cost_`x'=total(aux_cost_`x')
}
drop aux*

*3.3 Collapse by folio 
collapse (sum) expend_dur_t durable (mean) have* cost*, by(folio)

*3.3 Collapse by folio 
collapse (sum) expend_dur_t durable (mean) have* cost*, by(folio)

*3.4 Save data
save "${relabeled_data}/Expenses/EH2012_gasto_durable", replace

*II. MERGE DATA
use "${relabeled_data}/Expenses/EH2012_gasto_al", clear

merge 1:1 folio using "${relabeled_data}/Expenses/EH2012_gasto_noal"
drop _merge

merge 1:1 folio using "${relabeled_data}/Expenses/EH2012_gasto_durable"
drop _merge

egen expend=rowtotal(expend_al expend_noal)

save "${relabeled_data}/Expenses/EH2012_expenses_relabel", replace
