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

/* This .do file takes the compiled expenses data and makes a final clean to the dataset */

/*==================================================
            0: Program set up
==================================================*/
*Written on STATA 17
drop _all

/*==================================================
            1: Compiled data
==================================================*/

use "${relabeled_data}/Expenses/EH_compiled_expenses", clear

global variables expend_al expend_noal expend expend_compras expend_autoconsumo expend_otros exp_education exp_transport exp_financial exp_health /*
*/ exp_cr_hipot exp_cr_consume exp_cr_card exp_noal_other expend_dur_t cost_living cost_stove cost_fridge cost_pc cost_radio cost_minicomponent cost_tv cost_moto /*
*/ cost_car durable cost_microwave

*Sort variables
order $variables

foreach x in $variables{
qui sum `x', det
gen `x'_w=`x'
replace `x'_w=`r(p99)' if `x'>`r(p99)' & `x'!=.
}

local abr " " "_w"
local tag "" " winzorized"
forval i=1/2{
local x: word `i' of `abr'
local j: word `i' of `tag'

label var expend_al`x' "Food inside the HH Expenditure`j'"
label var expend_noal`x' "Non-Food inside the HH Expenditure`j'"
label var expend`x' "Total Expend`j'"
label var expend_compras`x' "Food bought expenditure`j'"
label var expend_autoconsumo`x' "Food self-produced`j'"
label var expend_otros`x' "Food adquired by other sources`j'"
label var exp_education`x' "Education expenditure`j'"
label var exp_transport`x' "Transport expenditure`j'"
label var exp_financial`x' "Financial expenditure`j'"
label var exp_health`x' "Health expenditure`j'"
label var exp_cr_hipot`x' "Mortgage credit expenditure`j'"
label var exp_cr_consume`x' "Consume credit expenditure`j'"
label var exp_cr_card`x' "Credit Card expenditure`j'"
label var exp_noal_other`x' "Other non-Food expenditure`j'"
label var expend_dur_t`x' "Durable goods expenditure`j'"
label var cost_living`x' "Living Room stock`j'"
label var cost_stove`x' "Stove stock`j'"
label var cost_fridge`x' "Fridge stock`j'"
label var cost_pc`x' "PC stock`j'"
label var cost_radio`x' "Radio stock`j'"
label var cost_minicomponent`x' "Minicomponent stock`j'"
label var cost_tv`x' "TV stock`j'"
label var cost_moto`x' "Motorcycle stock`j'"
label var cost_car`x' "Car stock`j'"
label var durable`x' "Durable goods stock`j'"
label var cost_microwave`x' "Microwave stock`j'"
}

label var folio "HH ID"
label var year "Year"
label var depto "Departamento administrativo"


foreach x in living stove fridge pc radio minicomponent tv washer moto car microwave{
label var have_`x' "=1 have `x'"
}

save "${relabeled_data}/Expenses/EH_cleaned_expenses", replace
