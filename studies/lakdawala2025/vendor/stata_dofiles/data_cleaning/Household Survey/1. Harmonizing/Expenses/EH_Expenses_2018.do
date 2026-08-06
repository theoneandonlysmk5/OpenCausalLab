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

/* This .do file cleans 2018 Household Survey expenses data for households */

/*==================================================
            0: Program set up
==================================================*/
*Written on STATA 17
drop _all

/*==================================================
            1: Manage Dataset
==================================================*/

global year 2018

*I. ALIMENTARY AND NON ALIMENTARY DATA

*1.Alimentary expenses
use "${raw_data}/2018/EH2018_GastosAlimentarios.dta", clear

*1.1 Rename+destring key variables
rename s09a_03b unidades
rename s09a_06b unidades2
encode unidades, gen(s09a_03b)
encode unidades2, gen(s09a_06b)
drop unidades*

*1.2 Consume
foreach x in compras autoconsumo{
local i_compras 02
local i_autoconsumo 05

gen freq_`x'=.
replace freq_`x'=31 if s09a_`i_`x''==1
replace freq_`x'=31/2 if s09a_`i_`x''==2
replace freq_`x'=31/4 if s09a_`i_`x''==3
replace freq_`x'=31/7 if s09a_`i_`x''==4
replace freq_`x'=31/15 if s09a_`i_`x''==5
replace freq_`x'=1 if s09a_`i_`x''==6
replace freq_`x'=1/4 if s09a_`i_`x''==7
replace freq_`x'=1/6 if s09a_`i_`x''==8
replace freq_`x'=1/12 if s09a_`i_`x''==9
}

foreach x in compras autoconsumo{

local j_compras 3
local j_autoconsumo 6
local j2_`x'=`j_`x''+1

gen expend_`x'=.
replace expend_`x'=freq_`x'*s09a_0`j2_`x'' if s09a_01==1
replace expend_`x'=0 if s09a_01==2
}
gen expend_otros=s09a_09 if s09a_08==1
replace expend_otros=0 if s09a_08==2
egen expend_al=rowtotal(expend_compras expend_autoconsumo expend_otros)

*1.3 Collapse by folio 
collapse (sum) exp*, by(folio depto area estrato factor)

*1.4 Save data
save "${relabeled_data}/Expenses/EH2018_gasto_al", replace

*2.Non Alimentary expenses

use "${raw_data}/2018/EH2018_GastosNoAlimentarios.dta", clear


*2.1 Rename+destring key variables

*2.2 Expenditure construction
egen aux_month=rowtotal(s09b_10*)
egen aux_quart=rowtotal(s09b_11*)
replace aux_quart=aux_quart/3
egen aux_sem=rowtotal(s09b_12*)
replace aux_sem=aux_sem/6
egen aux_year=rowtotal(s09b_13*)
replace aux_year=aux_year/12

egen expend_noal=rowtotal(aux*)
drop aux*

*2.2.1 Expenditure detail (transport education transport financial & health)
global detalle exp_transport+exp_education+exp_transport+exp_financial+exp_health

egen exp_transport=rowtotal(s09b_10_02 s09b_10_03) 
egen exp_education=rowtotal(s09b_10_11 s09b_10_12 s09b_10_13) 
replace exp_education=exp_education+s09b_12_01/6
replace exp_transport=exp_transport+s09b_12_02/6
egen exp_financial=rowtotal(s09b_13_05 s09b_13_06 s09b_13_07)
replace exp_financial=exp_financial/12
replace exp_education=exp_education+(s09b_13_08+s09b_13_09+s09b_13_10+s09b_13_11+s09b_13_12)/12
gen exp_health=s09b_13_14/12

gen exp_cr_hipot=s09b_13_05/12
gen exp_cr_consume=s09b_13_06/12
gen exp_cr_card=s09b_13_07/12

gen exp_noal_other=expend_noal-$detalle

*2.3 Collapse by folio 
collapse (sum) exp*, by(folio depto area estrato factor)

*2.4 Save data
save "${relabeled_data}/Expenses/EH2018_gasto_noal", replace

*3. Durable goods
use "${raw_data}/2018/EH2018_equipamiento", clear

*3.1 Rename+destring key variables

*3.2 Expenditure construction
g expend_dur_t=s09c_17 if s09c_16<=1 & s09c_14==1 & s09c_15>0
g durable=s09c_17 if s09c_14==1 & s09c_15>0

global art living stove microwave fridge pc radio minicomponent tv washer moto car
forvalues i=1/11{
local x: word `i' of $art
g aux_have_`x'=(s09c_14==1) if item==`i'
bys folio: egen have_`x'=total(aux_have_`x') 
g aux_cost_`x'=s09c_17 if item==`i'
replace aux_cost_`x'=. if s09c_17>99999
bys folio: egen cost_`x'=total(aux_cost_`x')
}
drop aux*

*3.3 Collapse by folio 
collapse (sum) expend_dur_t durable s09c_17 (mean) have* cost*, by(folio)

*3.4 Save data
save "${relabeled_data}/Expenses/EH2018_gasto_durable", replace

*II. MERGE DATA
use "${relabeled_data}/Expenses/EH2018_gasto_al", clear

merge 1:1 folio using "${relabeled_data}/Expenses/EH2018_gasto_noal"
drop _merge

merge 1:1 folio using "${relabeled_data}/Expenses/EH2018_gasto_durable"
drop _merge

egen expend=rowtotal(expend_al expend_noal)

tostring folio, replace

save "${relabeled_data}/Expenses/EH2018_expenses_relabel", replace
