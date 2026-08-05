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

/* This .do file cleans 2013 Household Survey expenses data for households */

/*==================================================
            0: Program set up
==================================================*/
*Written on STATA 17
drop _all

/*==================================================
            1: Manage Dataset
==================================================*/

global year 2013

*I. ALIMENTARY AND NON ALIMENTARY DATA

*1.Alimentary expenses
use "${raw_data}/2013/EH2013_GastosAlimentarios.dta", clear

*1.1 Rename+destring key variables
destring s8*, replace dpcomma

*1.2 Expenditure
foreach x in compras autoconsumo{
local i_compras 07
local i_autoconsumo 10
local var 8

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

local j_compras 08a
local j_autoconsumo 11a
local j2_compras 09
local j2_autoconsumo 12

local var 8

replace s`var'_`j2_`x''=. if s`var'_`j2_`x''>=9999
replace s`var'_14=. if s`var'_14>=9999

gen expend_`x'=.
replace expend_`x'=freq_`x'*s`var'_`j2_`x'' if s`var'_06==1
replace expend_`x'=0 if s`var'_06==2
}
gen expend_otros=s`var'_14 if s`var'_13==1
replace expend_otros=0 if s`var'_13==2
egen expend_al=rowtotal(expend_compras expend_autoconsumo expend_otros)

*1.3 Collapse by folio 
collapse (sum) expend*, by(folio factor)

*1.4 Save data
save "${relabeled_data}/Expenses/EH2013_gasto_al", replace

*2.Non Alimentary expenses

*2.0 Recode gastos educ and food outside hh
use "${raw_data}/2013/EH2013_Persona.dta", clear

keep folio s8*

drop s8_03ee

global var1 s8_01*2 s8_03* s8_04* 
foreach x of varlist $var1{
replace `x'=. if `x'>9999
}

egen exp_outside_hh=rowtotal(s8_01*2)
egen educ_mensual=rowtotal(s8_03*)
egen educ_anual=rowtotal(s8_04*)
gen exp_education=educ_mensual+educ_anual/12

collapse (sum) exp*, by(folio)

save "${relabeled_data}/Expenses/EH2013_GastosNoAlimentarios_educ", replace

use "${raw_data}/2013/EH2013_GastosNoAlimentarios.dta", clear

merge 1:1 folio using "${relabeled_data}/Expenses/EH2013_GastosNoAlimentarios_educ"
drop _merge

*2.1 Rename+destring key variables
local var 8

destring s`var'*, replace dpcomma

*2.2 Expenditure construction
forvalues i=15/17{
foreach x in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24{
capture replace s`var'_`i'_`x'=. if s`var'_`i'_`x'>=99999
}
}

egen aux_month=rowtotal(s`var'_15*)
egen aux_quart=rowtotal(s`var'_16*)
replace aux_quart=aux_quart/3
egen aux_year=rowtotal(s`var'_17*)
replace aux_year=aux_year/12

egen expend_noal=rowtotal(aux*)
replace expend_noal=expend_noal+exp_education+exp_outside_hh
drop aux*

*2.2.1 Expenditure detail (transport education transport financial & health)
global detalle exp_transport+exp_education+exp_transport+exp_financial+exp_health

egen exp_transport=rowtotal(s8_15_02 s8_15_03 s8_15_15)  
egen exp_financial=rowtotal(s8_17_14 s8_17_15 s8_17_16)
replace exp_financial=exp_financial/12
egen exp_health=rowtotal(s8_17_01 s8_17_02 s8_17_03 s8_17_04 s8_17_05)
replace exp_health=exp_health/12
replace exp_health=exp_health+s8_16_08/3 if  s8_16_08!=.

gen exp_cr_hipot=s8_17_14/12
gen exp_cr_consume=s8_17_15/12
gen exp_cr_card=s8_17_16/12

gen exp_noal_other=expend_noal-$detalle

*2.3 Collapse by folio 
collapse (sum) exp*, by(folio factor)

*2.4 Save data
save "${relabeled_data}/Expenses/EH2013_gasto_noal", replace

*3. Durable goods
use "${raw_data}/2013/EH2013_equipamiento", clear

*3.1 Rename+destring key variables
rename s8_18cod item

*3.2 Expenditure construction
g expend_dur_t=s8_21 if s8_20<=1
g durable=s8_21

foreach x in expend_dur_t durable{
replace `x'=. if `x'==99999
}

global art living stove fridge pc radio minicomponent tv washer moto car
forvalues i=1/10{
local x: word `i' of $art
g aux_have_`x'=(s8_18==1) if item==`i'
bys folio: egen have_`x'=total(aux_have_`x') 
g aux_cost_`x'=s8_21 if item==`i'
replace aux_cost_`x'=. if s8_21==99999
bys folio: egen cost_`x'=total(aux_cost_`x')
}
drop aux*

*3.3 Collapse by folio 
collapse (sum) expend_dur_t durable (mean) have* cost*, by(folio)

*3.3 Collapse by folio 
collapse (sum) expend_dur_t durable (mean) have* cost*, by(folio)

*3.4 Save data
save "${relabeled_data}/Expenses/EH2013_gasto_durable", replace

*II. MERGE DATA
use "${relabeled_data}/Expenses/EH2013_gasto_al", clear

merge 1:1 folio using "${relabeled_data}/Expenses/EH2013_gasto_noal"
drop _merge

merge 1:1 folio using "${relabeled_data}/Expenses/EH2013_gasto_durable"
drop _merge

egen expend=rowtotal(expend_al expend_noal)

save "${relabeled_data}/Expenses/EH2013_expenses_relabel", replace
