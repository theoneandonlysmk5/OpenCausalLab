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

/* This .do file compilates all Household Survey expenses data and merges them */

/*==================================================
            0: Program set up
==================================================*/
*Written on STATA 17
drop _all

/*==================================================
            1: Initial Data
==================================================*/

use "${relabeled_data}/Expenses/EH2012_expenses_relabel", clear

local years 2013 2014 2015 2016 2017 2018 2019

local year_b 2012

gen year=`year_b'
foreach y in `years'{
append using "${relabeled_data}/Expenses/EH`y'_expenses_relabel", force
replace year=`y' if year==.
}

table year, stat(mean expend_al expend_noal expend) 

drop exp_outside_hh

global variables expend_al expend_noal expend expend_compras expend_autoconsumo expend_otros exp_education exp_transport exp_financial exp_health /*
*/ exp_cr_hipot exp_cr_consume exp_cr_card exp_noal_other expend_dur_t cost_living cost_stove cost_fridge cost_pc cost_radio cost_minicomponent cost_tv cost_moto /*
*/ cost_car durable cost_microwave

*Sort variables
order $variables

save "${relabeled_data}/Expenses/EH_compiled_expenses", replace
