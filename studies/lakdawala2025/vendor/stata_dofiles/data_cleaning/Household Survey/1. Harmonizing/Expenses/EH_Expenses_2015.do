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

/* This .do file cleans 2015 Household Survey expenses data for households */

/*==================================================
            0: Program set up
==================================================*/
*Written on STATA 17
drop _all

/*==================================================
            1: Manage Dataset
==================================================*/

global year 2015

*I. ALIMENTARY AND NON ALIMENTARY DATA

*1.Alimentary expenses
use "${raw_data}/2015/EH2015_GastosAlimentarios.dta", clear

*1.1 Rename+destring key variables
destring s8*, replace dpcomma

*1.2 Expenditure
foreach x in compras autoconsumo{
local i_compras 02
local i_autoconsumo 05
local var 8

gen freq_`x'=.
replace freq_`x'=31 if s`var'a_`i_`x''==1
replace freq_`x'=31/2 if s`var'a_`i_`x''==2
replace freq_`x'=31/4 if s`var'a_`i_`x''==3
replace freq_`x'=31/7 if s`var'a_`i_`x''==4
replace freq_`x'=31/15 if s`var'a_`i_`x''==5
replace freq_`x'=1 if s`var'a_`i_`x''==6
replace freq_`x'=1/4 if s`var'a_`i_`x''==7
replace freq_`x'=1/6 if s`var'a_`i_`x''==8
replace freq_`x'=1/12 if s`var'a_`i_`x''==9
}

foreach x in compras autoconsumo{

local j_compras 3
local j_autoconsumo 6
local j2_`x'=`j_`x''+1
local var 8

gen expend_`x'=.
replace expend_`x'=freq_`x'*s`var'a_0`j2_`x'' if s`var'a_01==1
replace expend_`x'=0 if s`var'a_01==2
}
gen expend_otros=s`var'a_09 if s`var'a_08==1
replace expend_otros=0 if s`var'a_08==2
egen expend_al=rowtotal(expend_compras expend_autoconsumo expend_otros)

*1.3 Collapse by folio 
collapse (sum) expend*, by(folio departamento area estrato factor)

*1.4 Save data
save "${relabeled_data}/Expenses/EH2015_gasto_al", replace

*2.Non Alimentary expenses

use "${raw_data}/2015/EH2015_GastosNoAlimentarios.dta", clear


*2.1 Rename+destring key variables
local var 8

destring s`var'*, replace dpcomma

*2.2 Expenditure construction
forvalues i=10/12{
foreach x in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32{
capture replace s`var'b_`i'_`x'=. if s`var'b_`i'_`x'>=999999
}
}

egen aux_month=rowtotal(s`var'b_10*)
egen aux_quart=rowtotal(s`var'b_11*)
replace aux_quart=aux_quart/3
egen aux_year=rowtotal(s`var'b_12*)
replace aux_year=aux_year/12

egen expend_noal=rowtotal(aux*)
drop aux*

*2.2.1 Expenditure detail (transport education transport financial & health)
global detalle exp_transport+exp_education+exp_transport+exp_financial+exp_health

egen exp_transport=rowtotal(s8b_10_02 s8b_10_03 s8b_10_26) 
egen exp_education=rowtotal(s8b_10_12 s8b_10_13 s8b_10_14) 
egen exp_financial=rowtotal(s8b_12_10 s8b_12_11 s8b_12_12)
replace exp_financial=exp_financial/12
egen exp_ed_anual=rowtotal(s8b_12_13 s8b_12_14 s8b_12_15 s8b_12_16 s8b_12_17)
replace exp_education=exp_education+exp_ed_anual/12
drop exp_ed_anual
egen exp_health=rowtotal(s8b_12_01 s8b_12_02 s8b_12_03 s8b_12_04 s8b_12_05)
replace exp_health=exp_health/12
replace exp_health=exp_health+s8b_11_08/6 if  s8b_11_08!=.

gen exp_cr_hipot=s8b_12_10/12
gen exp_cr_consume=s8b_12_11/12
gen exp_cr_card=s8b_12_12/12

gen exp_noal_other=expend_noal-$detalle

*2.3 Collapse by folio 
collapse (sum) exp*, by(folio departamento area estrato factor)

*2.4 Save data
save "${relabeled_data}/Expenses/EH2015_gasto_noal", replace

*3. Durable goods
use "${raw_data}/2015/EH2015_equipamiento", clear

*3.1 Rename+destring key variables

*3.2 Expenditure construction
g expend_dur_t=s8_16 if s8_15<=1
g durable=s8_16

foreach x in expend_dur_t durable{
replace `x'=. if `x'>999990 
}

global art living stove fridge pc radio minicomponent tv washer moto car
forvalues i=1/10{
local x: word `i' of $art
g aux_have_`x'=(s8_13==1) if item==`i'
bys folio: egen have_`x'=total(aux_have_`x') 
g aux_cost_`x'=s8_16 if item==`i'
replace aux_cost_`x'=. if s8_16>999990
bys folio: egen cost_`x'=total(aux_cost_`x')
}
drop aux*

*3.3 Collapse by folio 
collapse (sum) expend_dur_t durable (mean) have* cost*, by(folio)

*3.4 Save data
*3.3 Collapse by folio 
collapse (sum) expend_dur_t durable (mean) have* cost*, by(folio)

*3.4 Save data
save "${relabeled_data}/Expenses/EH2015_gasto_durable", replace

*II. MERGE DATA
use "${relabeled_data}/Expenses/EH2015_gasto_al", clear

merge 1:1 folio using "${relabeled_data}/Expenses/EH2015_gasto_noal"
drop _merge

merge 1:1 folio using "${relabeled_data}/Expenses/EH2015_gasto_durable"
drop _merge

egen expend=rowtotal(expend_al expend_noal)

save "${relabeled_data}/Expenses/EH2015_expenses_relabel", replace
