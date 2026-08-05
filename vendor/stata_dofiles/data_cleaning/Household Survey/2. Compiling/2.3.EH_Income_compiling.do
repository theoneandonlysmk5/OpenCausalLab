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

/* This .do file compilates all Household Survey income data and merges them */

/*==================================================
            0: Program set up
==================================================*/
*Written on STATA 17
drop _all

/*==================================================
            1: Initial Data
==================================================*/

use "${relabeled_data}/Income/EH2012_Income_relabel", clear

tostring folio, replace

local years "2013 2014 2015 2016 2017"

forvalues i=2013(1)2017{
append using "${relabeled_data}/Income/EH`i'_Income_relabel", force

}

*2. Rename
rename t year

*3. Save Compiled data

global ident id folio depto area year

global wages wage_total wage_monthly_main wage_monthly_sec extra_wages extra_wages_main/*
*/ extra_wages_sec aguinaldo_yearly_main inkind_payments inkind_payments_main inkind_payments_sec y_wl_bonus_main /*
*/ y_wl_bonus_sec y_wl_bonus y_earnings_main y_earnings_sec y_earnings

global incomes rev_nw_labor rev_nw_labor_main_monthly rev_nw_labor_sec_monthly operational_cost_main operational_cost_sec /*
*/ operational_cost y_nw_labor_main y_nw_labor_sec y_nw_labor y_nw_labor_sr y_nw_labormain_sr_m y_nw_laborsec_sr_m y_labor /*
*/ y_labor_main y_labor_sec

global nolabor_income retirement transfer_veterans transfer_disability transfer_widows y_social_security y_elderly_transfer /*
*/ y_government y_local_transfers family_asistance_monthly people_incountry_monthly y_private_transfers remittances_currency /*
*/ y_foreign_remittances y_int_assets_regular revenues_interest revenues_renting revenues_other y_non_regular revenues_rental_agric /*
*/ revenues_dividends revenues_rental_equip revenues_indemnization revenues_insurance revenues_other_nr y_int_assets_total /*
*/ y_int_assets_regular y_nonlabor y_person

*Sort variables
order $ident $wages $incomes $nolabor_income

save "${relabeled_data}/Income/EH_compiled_income", replace
