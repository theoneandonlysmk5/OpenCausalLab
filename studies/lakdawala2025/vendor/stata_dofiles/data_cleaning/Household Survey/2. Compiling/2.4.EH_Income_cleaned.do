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

/* This .do file takes the compiled income data and makes a final clean to the dataset */

/*==================================================
            0: Program set up
==================================================*/
*Written on STATA 17
drop _all

/*==================================================
            1: Compiled data
==================================================*/

use "${relabeled_data}/Income/EH_compiled_income", clear

*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
egen id_year=concat(year id)
egen folio_year=concat(year folio)
*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

***2. Income variables

*2.1 Winzorize Variables
global wages  wage_monthly_main wage_monthly_sec extra_wages_main/*
*/ extra_wages_sec inkind_payments_main inkind_payments_sec y_wl_bonus_main /*
*/ y_wl_bonus_sec

global incomes rev_nw_labor_main_monthly rev_nw_labor_sec_monthly operational_cost_main operational_cost_sec /*
*/  y_nw_labormain_sr_m y_nw_laborsec_sr_m

global nolabor_income retirement transfer_veterans transfer_disability transfer_widows y_elderly_transfer /*
*/ family_asistance_monthly people_incountry_monthly y_foreign_remittances remittances_currency /*
*/ revenues_interest revenues_renting revenues_other revenues_rental_agric /*
*/ revenues_dividends revenues_rental_equip revenues_indemnization revenues_insurance revenues_other_nr 


local vars $wages $incomes $nolabor_income
foreach x in `vars'{
qui sum `x', det
gen `x'_w=`x'
replace `x'_w=`r(p99)' if `x'>`r(p99)' & `x'!=.
}

*2.1.2 Wages
egen wage_total_w=rowtotal(wage_monthly_main_w wage_monthly_sec_w)
gen extra_wages_w=extra_wages_main_w+extra_wages_sec_w
gen inkind_payments_w=inkind_payments_main_w+inkind_payments_sec_w
gen y_wl_bonus_w=y_wl_bonus_main_w+y_wl_bonus_sec_w
gen y_earnings_main_w=wage_monthly_main_w+y_wl_bonus_main_w
gen y_earnings_sec_w=wage_monthly_sec_w+y_wl_bonus_sec_w
gen y_earnings_w=wage_total_w+y_wl_bonus_w

*2.1.2 Incomes
egen rev_nw_labor_w=rowtotal(rev_nw_labor_main_monthly_w rev_nw_labor_sec_monthly_w)
egen operational_cost_w=rowtotal(operational_cost_main_w operational_cost_sec_w)
egen y_nw_labor_sr_w=rowtotal(y_nw_labormain_sr_m_w y_nw_laborsec_sr_m_w)
gen y_nw_labor_main_w=rev_nw_labor_main_monthly_w-operational_cost_main_w
gen y_nw_labor_sec_w=rev_nw_labor_sec_monthly_w-operational_cost_sec_w
gen y_nw_labor_w=rev_nw_labor_w-operational_cost_w
egen y_labor_w=rowtotal(y_earnings_w y_nw_labor_w)
egen y_labor_main_w=rowtotal(y_earnings_main_w y_nw_labor_w)
egen y_labor_sec_w=rowtotal(y_earnings_sec_w y_nw_labor_sec_w)

*2.1.3 nolabor_income
egen y_social_security_w=rowtotal(retirement_w transfer_veterans_w transfer_disability_w transfer_widows_w) 
egen y_government_w=rowtotal(y_social_security_w y_elderly_transfer_w)
egen y_local_transfers_w=rowtotal(family_asistance_monthly_w people_incountry_monthly_w)
egen y_private_transfers_w=rowtotal(y_foreign_remittances_w y_local_transfers_w)
egen y_int_assets_regular_w=rowtotal(revenues_interest_w revenues_renting_w revenues_other_w)
egen y_non_regular_w=rowtotal(revenues_rental_agric_w revenues_dividends_w revenues_rental_equip_w /*
*/ revenues_indemnization_w revenues_insurance_w revenues_other_nr_w)
egen y_int_assets_total_w=rowtotal(y_int_assets_regular_w y_non_regular_w)
egen y_nonlabor_w=rowtotal(y_int_assets_total_w y_private_transfers_w y_government_w)
egen y_person_w=rowtotal(y_labor_w y_nonlabor_w)

*2.1.4 Global Variables
bys folio year: egen nper=count(id)

global var "" "_w"
foreach i in $var{
bys folio year: egen y_household`i'=total(y_person`i')
gen y_percapita`i'=y_household`i'/nper
}

drop nper
recast str id folio

*2.2 Rename Variables
global var " " "_w"
foreach i in $var{
rename wage_monthly_main`i' y_wl_gross_main`i'
rename wage_monthly_sec`i' y_wl_gross_sec`i'
rename wage_total`i' y_wl_gross`i'
rename extra_wages_main`i' y_wl_cash_extra_main`i'
rename extra_wages`i' y_wl_cash_extra`i'
rename extra_wages_sec`i' y_wl_cash_extra_sec`i'
rename inkind_payments_main`i' y_wl_inkind_extra_main`i'
rename inkind_payments_sec`i' y_wl_inkind_extra_sec`i'
rename inkind_payments`i' y_wl_inkind_extra`i'
rename y_earnings_main`i' y_wl_earnings_main`i'
rename y_earnings_sec`i' y_wl_earnings_sec`i'
rename y_earnings`i' y_wl_earnings`i'
rename rev_nw_labor`i' y_nwl_rev`i' 
rename rev_nw_labor_main_monthly`i' y_nwl_rev_main`i'
rename rev_nw_labor_sec_monthly`i' y_nwl_rev_sec`i'
rename operational_cost_main`i' cost_nwl_main`i'
rename operational_cost_sec`i' cost_nwl_sec`i'
rename operational_cost`i' cost_nwl`i'
rename y_nw_labor_main`i' y_nwl_income_main`i'
rename y_nw_labor`i' y_nwl_income`i'
rename y_nw_labor_sec`i' y_nwl_income_sec`i'
rename y_nw_labor_sr`i' y_nwl_income_sr`i'
rename y_nw_labormain_sr_m`i' y_nwl_income_sr_main`i'
rename y_nw_laborsec_sr_m`i' y_nwl_income_sr_sec`i'
rename retirement`i' y_nl_ret`i'
rename transfer_veterans`i' y_nl_vet`i'
rename transfer_disability`i' y_nl_dis`i'
rename transfer_widows`i' y_nl_widow`i'
rename y_social_security`i' y_nl_ss`i'
rename y_elderly_transfer`i' y_nl_elderly_transfer`i'
rename y_government`i' y_nl_gov`i'
rename y_local_transfers`i' y_nl_domestic`i'
rename family_asistance_monthly`i' y_nl_famassist_transfers`i'
rename people_incountry_monthly`i' y_nl_hhdom_transfers`i'
rename y_foreign_remittances`i' y_nl_remittances`i'
rename remittances_currency`i' remittances_currency`i'
rename y_private_transfers`i' y_nl_hhtrans`i'
rename y_int_assets_regular`i' y_rents_reg`i'
rename revenues_interest`i' y_rents_reg_int`i'
rename revenues_renting`i' y_rents_reg_rent`i'
rename revenues_other`i' y_rents_reg_oth`i'
rename y_non_regular`i' y_rents_o`i'
rename revenues_rental_agric`i' y_rents_o_agrrent`i'
rename revenues_dividends`i' y_rents_o_div`i'
rename revenues_rental_equip`i' y_rents_o_equip`i'
rename revenues_indemnization`i' y_rent_o_indem`i'
rename revenues_insurance`i' y_rent_o_insurance`i'
rename revenues_other_nr`i' y_rent_o_oth`i'
rename y_int_assets_total`i' y_rents`i'
rename y_person`i' y_personal`i'
}
rename aguinaldo_yearly_main y_wl_aguinaldo_main_year


***(z) relabeled
label var folio "Household ID"
label var id "Personal ID"
label var year "Survey wave year"
label var id_year "Year and Personal ID"
label var area "Urban/rural area" 
label var y_wl_aguinaldo_main_year "Aguinaldo (Annual ammount)"


local var " " "_w"
local text "" " winzorized"
forvalues i=1/2{
local j: word `i' of `var'
local x: word `i' of `text'

label var y_wl_gross_main`j' "Gross wage-labor earnings - Main occ.`x'"
label var y_wl_gross_sec`j' "Gross wage-labor earnings - Sec occ.`x'"
label var y_wl_gross`j' "Gross wage-labor earnings (y_wl_gross_main+y_wl_gross_sec)`x'"
label var y_wl_cash_extra_main`j' "Wage-labor cash extra  payments (bonus+comision+aguinaldo+overtime) -Main occ.`x'"
label var y_wl_cash_extra_sec`j' "Wage-labor cash extra  payments (bonus+comision+aguinaldo+overtime) -Sec occ.`x'"
label var y_wl_cash_extra`j' "Total Wage-labor extra cash payments (bonus+comision+aguinaldo+overtime)`x'"
label var y_wl_inkind_extra_main`j' "Wage-Labor in-kind extra payments (food+clothing+transport+lodging+others) - Main occ.`x'"
label var y_wl_inkind_extra_sec`j' "Wage-labor in-kind extra payments (food+clothing+transport+lodging+others)  -Sec occ.`x'"
label var y_wl_inkind_extra`j' "Total wage-labor in-kind extra payments  (y_wl_inkind_extra_main+y_wl_inkind_extra_sec)`x'"
label var y_wl_bonus_main`j' "Wage-labor extra payments (y_wl_inkind_extra_main+y_wl_cash_extra_main) - Main occ.`x'"
label var y_wl_bonus_sec`j' "Wage-labor extra payments (y_wl_inkind_extra_sec+y_wl_cash_extra_sec) -Sec. occ.`x'"
label var y_wl_bonus`j' "Total wage-labor extra payments (y_wl_inkind_extra+y_wl_cash_extra)`x'"
label var y_wl_earnings_main`j' "Wage-labor earnings (y_wl_gross_main+y_wl_bonus_sec)-Main oc.`x'"
label var y_wl_earnings_sec`j' "Wage-labor earnings (y_wl_gross_sec+y_wl_bonus_sec) -Sec occ.`x'"
label var y_wl_earnings`j' "Total wage-labor earnings (y_wl_gross+y_wl_bonus)`x'"
label var y_nwl_rev`j' "Total self-employment gross revenues (y_nwl_rev_main+y_nw_rev_sec)`x'"
label var y_nwl_rev_main`j' "Self-employment gross revenues-Main occupation`x'"
label var y_nwl_rev_sec`j' "Self-employment gross revenues-Sec occupation`x'"
label var cost_nwl_main`j' "Self-employment operations cost (inputs+wage+rent+interest+taxes+others) -Main occupation`x'"
label var cost_nwl_sec`j' "Self-employment operations cost (inputs+wage+rent+interest+taxes+others) -Sec occupation`x'"
label var cost_nwl`j' "Total self-employment operations cost (inputs+wage+rent+interest+taxes+others)`x'"
label var y_nwl_income_main`j' "Net self-employment income-Main occ. (y_wnl_rev_main-cost_nwl_main)`x'"
label var y_nwl_income_sec`j' "Net self-employment income-Sec occ. (y_wnl_rev_sec-cost_nwl_sec)`x'"
label var y_nwl_income`j' "Total Net self-employment Income  (y_wnl_rev-cost_nwl)`x'"
label var y_nwl_income_sr`j' "Total Net self-employment Income  (Self reported)`x'"
label var y_nwl_income_sr_main`j' "Net self-employment Income  (Self reported)-Main`x'"
label var y_nwl_income_sr_sec`j' "Net self-employment Income  (Self reported)-Sec.`x'"
label var y_labor`j' "Total labor income  (y_nw_income+y_wl_earnings)`x'"
label var y_labor_main`j' "Labor income - Main Occ. (y_nw_income_main+y_wl_earnings-main)`x'"
label var y_labor_sec`j' "Labor income - Main Occ. (y_nw_income_main+y_wl_earnings-main)`x'"
label var y_nl_ret`j'  "Retirement income`x'"
label var y_nl_vet`j' "Veterans transfers`x'"
label var y_nl_dis`j' "Disability transfers`x'"
label var y_nl_widow`j' "Widows/orphans transfers`x'"
label var y_nl_ss`j' "Total transfers from Social Security (y_nl_ret + y_nl_vet+y_nl_widow+y_nl_SS)`x'"
label var y_nl_elderly_transfer`j' "Non-contributory cash transfers for the elderly`x'"
label var y_nl_gov`j' "Non-contributory elderly cash-transfers and social security transfers (y_nl_ss+y_nl_elderly_transfer)`x'"
label var y_nl_domestic`j' "Total domestic transfers from other households  (y_nl_hhdom_transfers+y_nl_famassist_transfers)`x'"
label var y_nl_famassist_transfers`j' "Family assitance transfers`x'"
label var y_nl_hhdom_transfers`j' "Transfers from other households (Bolivia)`x'"
label var y_nl_remittances`j' "Foreign remittances in $BOL`x'"
label var remittances_currency`j' "Remittances original currency`x'"
label var y_nl_hhtrans`j' "Total  transfers from other households (y_nl_remittances+y_nl_domestic)`x'"
label var y_rents_reg`j' "Regular rents (y_rents_reg_int+y_rents_reg_rent+y_rents_reg_oth)`x'"
label var y_rents_reg_int`j' "Regular revenues from interest`x'"
label var y_rents_reg_rent`j' "Regular revenues from renting`x'"
label var y_rents_reg_oth`j' "Regular revenues from other sources`x'"
label var y_rents_o`j' "Occasional rents (y_rents_o_: agrrent+div+equip+indem+insurance+other)`x'"
label var y_rents_o_agrrent`j' "Occasional revenues from agricultural rental`x'"
label var y_rents_o_div`j' "Occasional revenues from dividends`x'"
label var y_rents_o_equip`j' "Occasional revenues from equipment rental`x'"
label var y_rent_o_indem`j' "Occasional revenues from indeminization`x'"
label var y_rent_o_insurance`j' "Occasional income from insurance`x'"
label var y_rent_o_oth`j' "Occasional revenues from other sources`x'"
label var y_rents`j' "Incomes from regular and non regular sources (y_rents_o+y_rents_reg)`x'"
label var y_nonlabor`j' "Non labor income (y_rents+y_nl_hhtrans+y_nl_gov)`x'"
label var y_personal`j' "Total pesonal income (y_nonlabor+y_labor)`x'"
label var y_household`j' "Total household income`x'"
label var y_percapita`j' "Total per-capita household income`x'"
}

***3. Replacing by 0
replace y_wl_gross_main=0 if y_wl_gross_main==.
replace y_wl_gross_sec=0 if y_wl_gross_sec==.
replace y_wl_cash_extra_sec=0 if y_wl_cash_extra_sec==. & inrange(year,2015,2017)
replace y_wl_aguinaldo_main_year=0 if y_wl_aguinaldo_main_year==. & year!=2004
replace y_wl_earnings_main=0 if y_wl_earnings_main==. 
replace y_wl_earnings_sec=0 if y_wl_earnings_sec==.
replace y_nwl_rev_sec=0 if y_nwl_rev_sec==. & inrange(year,2005,2017)
replace cost_nwl_sec=0 if cost_nwl_sec==. & inrange(year,2012,2017)
replace y_nwl_income_main=0 if y_nwl_income_main==.
replace y_nwl_income_sec=0 if y_nwl_income_sec==. & inrange(year,2012,2017)
replace y_nwl_income_sr_main=0 if y_nwl_income_sr_main==.
replace y_nwl_income_sr_sec=0 if y_nwl_income_sr_sec==. & inrange(year,2005,2017)
replace y_labor_sec=0 if y_labor_sec==. & inrange(year,2012,2017)
replace y_nl_ret=0 if y_nl_ret==.
replace y_nl_vet=0 if y_nl_vet==.
replace y_nl_dis=0 if y_nl_dis==.
replace y_nl_widow=0 if y_nl_widow==.
replace y_nl_ss=0 if y_nl_ss==.
replace y_rent_o_insurance=0 if y_rent_o_insurance==. & inrange(year,2004,2017)


***4. Save Data
** Save
save "${relabeled_data}/Income/EH_cleaned_income", replace
