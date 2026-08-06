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

/* This .do file cleans 2017 Household Survey income data for indviduals */

/*==================================================
            0: Program set up
==================================================*/
*Written on STATA 17
drop _all

/*==================================================
            1: Manage Dataset
==================================================*/

use "${raw_data}/2017/EH2017_Persona.dta", clear

*Ano
gen t=2017

*Define ID by person

rename ïfolio folio
tostring folio nro, replace
egen id=concat(folio nro)  //ifolio is a house folio and nro is the intrahousehold id, so concat both makes an unique ID. 

***********************
********Wages**********
***********************

destring s06c_25a s06c_25b s06g_47a s06g_47b s06c_26a s06c_26b s06c_27aa s06c_27ab s06c_27ba /*
*/ s06c_27bb s06g_48a1 s06c_30a1 s06c_30a2 s06c_30b1 s06c_30b2 s06c_30c1 s06c_30c2  /*
*/ s06c_30d1 s06c_30d2 s06c_30e1 s06c_30e2 s06g_48a1 s06g_48b1 s06g_48c1 s06d_33a s06d_33b,  replace dpcomma

*(i) Wages 

gen aux_main_income=s06c_25a
gen aux_main_wage_period=s06c_25b

gen aux_sec_income=s06g_47a
gen aux_sec_wage_period=s06g_47b


foreach i in "main" "sec"{

gen wage_`i'=aux_`i'_income
gen wage_period_`i'=aux_`i'_wage_period

gen wage_monthly_`i'=.
replace wage_monthly_`i'=wage_`i'*20 if wage_period_`i'==1
replace wage_monthly_`i'=wage_`i'*4 if wage_period_`i'==2
replace wage_monthly_`i'=wage_`i'*2 if wage_period_`i'==3
replace wage_monthly_`i'=wage_`i' if wage_period_`i'==4
replace wage_monthly_`i'=wage_`i'/2 if wage_period_`i'==5
replace wage_monthly_`i'=wage_`i'/3 if wage_period_`i'==6
replace wage_monthly_`i'=wage_`i'/6 if wage_period_`i'==7
replace wage_monthly_`i'=wage_`i'/12 if wage_period_`i'==8
}

egen wage_total=rowtotal(wage_monthly_main wage_monthly_sec)

drop aux_*

*(ii) production bonus 
gen bonus_monthly_main=s06c_26a/12

*(iii) aguinaldos
gen aguinaldo_monthly_main=s06c_26b/12
gen aguinaldo_yearly_main=s06c_26b

*(iv) Comisiones
gen comision_main=s06c_27aa
gen comision_period_main=s06c_27ab

gen comision_monthly_main=.
replace comision_monthly_main=comision_main*20 if comision_period_main==1
replace comision_monthly_main=comision_main*4 if comision_period_main==2
replace comision_monthly_main=comision_main*2 if comision_period_main==3
replace comision_monthly_main=comision_main if comision_period_main==4
replace comision_monthly_main=comision_main/2 if comision_period_main==5
replace comision_monthly_main=comision_main/3 if comision_period_main==6
replace comision_monthly_main=comision_main/6 if comision_period_main==7
replace comision_monthly_main=comision_main/12 if comision_period_main==8

drop comision_main comision_period_main

*(v) Overtime
gen overtime_main=s06c_27ba
gen overtime_period_main=s06c_27bb

gen overtime_monthly_main=.
replace overtime_monthly_main=overtime_main*20 if overtime_period_main==1
replace overtime_monthly_main=overtime_main*4 if overtime_period_main==2
replace overtime_monthly_main=overtime_main*2 if overtime_period_main==3
replace overtime_monthly_main=overtime_main if overtime_period_main==4
replace overtime_monthly_main=overtime_main/2 if overtime_period_main==5
replace overtime_monthly_main=overtime_main/3 if overtime_period_main==6
replace overtime_monthly_main=overtime_main/6 if overtime_period_main==7
replace overtime_monthly_main=overtime_main/12 if overtime_period_main==8

drop overtime_main overtime_period_main

*(vi) extra wages (bonus+aguinaldo+comisiones+overtime)
egen extra_wages_main=rowtotal(bonus_monthly_main aguinaldo_monthly_main comision_monthly_main overtime_monthly_main) 
gen extra_wages_sec=s06g_48a1/12
replace extra_wages_sec=0 if extra_wages_sec==.

gen extra_wages=extra_wages_main+extra_wages_sec

*(vii) In Kind payments

local kind "food trans clothing lodging others"
local text "a b c d e"

forvalues j=1/5{

local i: word `j' of `kind'
local b: word `j' of `text'

gen inkind_`i'_period_main=s06c_30`b'1 
gen inkind_`i'_main=s06c_30`b'2

gen inkind_`i'_monthly_main=.
replace inkind_`i'_monthly_main=inkind_`i'_main*20 if inkind_`i'_period_main==1
replace inkind_`i'_monthly_main=inkind_`i'_main*4 if inkind_`i'_period_main==2
replace inkind_`i'_monthly_main=inkind_`i'_main*2 if inkind_`i'_period_main==3
replace inkind_`i'_monthly_main=inkind_`i'_main if inkind_`i'_period_main==4
replace inkind_`i'_monthly_main=inkind_`i'_main/2 if inkind_`i'_period_main==5
replace inkind_`i'_monthly_main=inkind_`i'_main/3 if inkind_`i'_period_main==6
replace inkind_`i'_monthly_main=inkind_`i'_main/6 if inkind_`i'_period_main==7
replace inkind_`i'_monthly_main=inkind_`i'_main/12 if inkind_`i'_period_main==8
replace inkind_`i'_monthly_main=0 if inkind_`i'_monthly_main==.
}

egen inkind_payments_main=rowtotal(inkind_food_monthly_main inkind_trans_monthly_main /*
*/ inkind_clothing_monthly_main inkind_lodging_monthly_main inkind_others_monthly_main)

egen inkind_payments_sec=rowtotal(s06g_48b1 s06g_48c1)
replace inkind_payments_sec=inkind_payments_sec/12 

gen inkind_payments=inkind_payments_main+inkind_payments_sec

*(viii) Wage + bonus
egen y_wl_bonus_main=rowtotal(extra_wages_main inkind_payments_main)
egen y_wl_bonus_sec=rowtotal(extra_wages_sec inkind_payments_sec)
gen y_wl_bonus=y_wl_bonus_main+y_wl_bonus_sec

gen y_earnings_main=wage_monthly_main+y_wl_bonus_main
gen y_earnings_sec=wage_monthly_sec+y_wl_bonus_sec

gen y_earnings=wage_total+y_wl_bonus

***********************
*******INCOMES*********
***********************

destring s06d_31a s06d_31b s06d_32aa s06d_32ab s06d_32ba s06d_32bb s06d_32ca s06d_32cb /*
*/ s06d_32da s06d_32db s06d_32ea s06d_32eb  s06d_32fa s06d_32fb s06d_33a s06d_33b /*
*/ s06f_45* s06g_50aa s06g_50ab s06g_50ba s06g_50bb s06g_50ca s06g_50cb s06g_50da /*
*/ s06g_50db s06g_50ea s06g_50eb s06g_50fa s06g_50fb s06g_50ga s06g_50gb s06g_49a s06g_49b /*
*/ s06g_51*, replace dpcomma

*(i) Revenue

local kind "main sec"
local text "d_31 g_49"

forvalues j=1/2{

local i: word `j' of `kind'
local x: word `j' of `text'

gen rev_nw_labor_`i'=s06`x'a
gen rev_nw_labor_`i'_period=s06`x'b

gen rev_nw_labor_`i'_monthly=.
replace rev_nw_labor_`i'_monthly=rev_nw_labor_`i'*30 if rev_nw_labor_`i'_period==1
replace rev_nw_labor_`i'_monthly=rev_nw_labor_`i'*4 if rev_nw_labor_`i'_period==2
replace rev_nw_labor_`i'_monthly=rev_nw_labor_`i'*2 if rev_nw_labor_`i'_period==3
replace rev_nw_labor_`i'_monthly=rev_nw_labor_`i' if rev_nw_labor_`i'_period==4
replace rev_nw_labor_`i'_monthly=rev_nw_labor_`i'/2 if rev_nw_labor_`i'_period==5
replace rev_nw_labor_`i'_monthly=rev_nw_labor_`i'/3 if rev_nw_labor_`i'_period==6
replace rev_nw_labor_`i'_monthly=rev_nw_labor_`i'/6 if rev_nw_labor_`i'_period==7
replace rev_nw_labor_`i'_monthly=rev_nw_labor_`i'/12 if rev_nw_labor_`i'_period==8
replace rev_nw_labor_`i'_monthly=0 if rev_nw_labor_`i'_monthly==.
}

egen rev_nw_labor=rowtotal(rev_nw_labor_main_monthly rev_nw_labor_sec_monthly)

*(ii) Costs (inputs, wage, rent, interest, taxes and others)

local kind "main sec"
local text "d_32 g_50"
local word "a b c d e f"
local name "inputs wage rent interest taxes other"

forvalues k=1/6{ 

local x: word `k' of `word'
local z: word `k' of `name'

forvalues j=1/2{

local i: word `j' of `kind'
local b: word `j' of `text'

gen `z'_cost_`i'=s06`b'`x'a
gen `z'_cost_`i'_period=s06`b'`x'b

gen `z'_cost_monthly_`i'=.
replace `z'_cost_monthly_`i'=`z'_cost_`i'*30 if `z'_cost_`i'_period==1
replace `z'_cost_monthly_`i'=`z'_cost_`i'*4 if `z'_cost_`i'_period==2
replace `z'_cost_monthly_`i'=`z'_cost_`i'*2 if `z'_cost_`i'_period==3
replace `z'_cost_monthly_`i'=`z'_cost_`i' if `z'_cost_`i'_period==4
replace `z'_cost_monthly_`i'=`z'_cost_`i'/2 if `z'_cost_`i'_period==5
replace `z'_cost_monthly_`i'=`z'_cost_`i'/3 if `z'_cost_`i'_period==6
replace `z'_cost_monthly_`i'=`z'_cost_`i'/6 if `z'_cost_`i'_period==7
replace `z'_cost_monthly_`i'=`z'_cost_`i'/12 if `z'_cost_`i'_period==8
replace `z'_cost_monthly_`i'=0 if `z'_cost_monthly_`i'==.
}
}

*(g) Operational cost
egen operational_cost_main=rowtotal(inputs_cost_monthly_main wage_cost_monthly_main rent_cost_monthly_main /*
*/ taxes_cost_monthly_main other_cost_monthly_main)

egen operational_cost_sec=rowtotal(inputs_cost_monthly_sec wage_cost_monthly_sec rent_cost_monthly_sec /*
*/ taxes_cost_monthly_sec other_cost_monthly_sec)

egen operational_cost=rowtotal(operational_cost_main operational_cost_sec)

*(iii) y nw labor
gen y_nw_labor_main=rev_nw_labor_main_monthly-operational_cost_main
gen y_nw_labor_sec=rev_nw_labor_sec_monthly-operational_cost_sec
gen y_nw_labor=rev_nw_labor-operational_cost

*(iv) self reported nw labor

local x "main sec"
local text "d_33 g_51"

forvalues j=1(1)2{

local i: word `j' of `x'
local b: word `j' of `text'

gen y_nw_labor`i'_sr=s06`b'a 
gen y_nw_labor`i'_sr_period=s06`b'b

gen y_nw_labor`i'_sr_m=.
replace y_nw_labor`i'_sr_m=y_nw_labor`i'_sr*30 if y_nw_labor`i'_sr_period==1
replace y_nw_labor`i'_sr_m=y_nw_labor`i'_sr*4 if y_nw_labor`i'_sr_period==2
replace y_nw_labor`i'_sr_m=y_nw_labor`i'_sr*2 if y_nw_labor`i'_sr_period==3
replace y_nw_labor`i'_sr_m=y_nw_labor`i'_sr if y_nw_labor`i'_sr_period==4
replace y_nw_labor`i'_sr_m=y_nw_labor`i'_sr/2 if y_nw_labor`i'_sr_period==5
replace y_nw_labor`i'_sr_m=y_nw_labor`i'_sr/3 if y_nw_labor`i'_sr_period==6
replace y_nw_labor`i'_sr_m=y_nw_labor`i'_sr/6 if y_nw_labor`i'_sr_period==7
replace y_nw_labor`i'_sr_m=y_nw_labor`i'_sr/12 if y_nw_labor`i'_sr_period==8
replace y_nw_labor`i'_sr_m=0 if y_nw_labor`i'_sr==.

}

egen y_nw_labor_sr=rowtotal(y_nw_labormain_sr_m y_nw_laborsec_sr_m)

*(v) ylabor
egen y_labor=rowtotal(y_earnings y_nw_labor)

egen y_labor_main=rowtotal(y_earnings_main y_nw_labor)
egen y_labor_sec=rowtotal(y_earnings_sec y_nw_labor_sec)

*****************************************
*****NO LABOR INCOME PUBLIC SOURCES******
*****************************************

destring s07a_01a s07a_01b s07a_01c s07a_01d s07a_01e s07a_01e0, replace dpcomma

*(i) Social security transfers
gen retirement=s07a_01a
gen transfer_veterans=s07a_01b
gen transfer_disability=s07a_01c
gen transfer_widows=s07a_01d

egen y_social_security=rowtotal(retirement transfer_veterans transfer_disability transfer_widows) 

*(ii) No contributy transfers
gen y_elderly_transfer=s07a_01e0
replace y_elderly_transfer=0 if y_elderly_transfer==.

*(iii) Income from goverment
egen y_government=rowtotal(y_social_security y_elderly_transfer)

******************************************
*****NO LABOR INCOME PRIVATE SOURCES******
******************************************

destring s07b_05aa s07b_05ab s07b_05ba s07b_05bb s07c_0* s07a_02* s07a_03* /*
*/ s07a_04*, replace force

*(i) Local transfers

local x "family_asistance people_incountry" 
local text "a b"

forvalues j=1(1)2{

local i: word `j' of `x'
local b: word `j' of `text'

gen `i'=s07b_05`b'a 
gen `i'_period=s07b_05`b'b

gen `i'_monthly =.
replace `i'_monthly=`i'*30 if `i'_period==1
replace `i'_monthly=`i'*4 if `i'_period==2
replace `i'_monthly=`i'*2 if `i'_period==3
replace `i'_monthly=`i' if `i'_period==4
replace `i'_monthly=`i'/2 if `i'_period==5
replace `i'_monthly=`i'/3 if `i'_period==6
replace `i'_monthly=`i'/6 if `i'_period==7
replace `i'_monthly=`i'/12 if `i'_period==8
replace `i'_monthly=0 if `i'_monthly==.

}

egen y_local_transfers=rowtotal(family_asistance_monthly people_incountry_monthly)

*(ii) Foreign remmitances
gen remittances_receive=(s07c_06==1)
gen remittances_amount=s07c_08a
gen remittances_period=s07c_07

gen remittances_currency=s07c_08b

label define remittances_currency 1 "Bolivianos" 2 "Euros" 3 "Dolares" 4 "Pesos Arg" /*
*/ 5 "Reales" 6 "Pesos Chilenos" 7 "Otros"
label values remittances_currency remittances_currency

gen remittances_monthly=remittances_amount*4 if remittances_period==2
replace remittances_monthly=remittances_amount*2 if remittances_period==3
replace remittances_monthly=remittances_amount if remittances_period==4
replace remittances_monthly=remittances_amount/2 if remittances_period==5
replace remittances_monthly=remittances_amount/3 if remittances_period==6
replace remittances_monthly=remittances_amount/6 if remittances_period==7
replace remittances_monthly=remittances_amount/12 if remittances_period==8

////Monedas extranjeras to bs (https://www.bcb.gob.bo/?q=cotizaciones_tc)
local boliviano 1
local euro 7.22425
local dolar (6.96+6.86)/2 
local arg 0.43199
local real 2.10740
local chile 0.01023

gen remittances_tc=.
replace remittances_tc=`boliviano' if remittances_currency==1
replace remittances_tc=`euro' if remittances_currency==2
replace remittances_tc=`dolar' if remittances_currency==3
replace remittances_tc=`arg' if remittances_currency==4
replace remittances_tc=`real' if remittances_currency==5
replace remittances_tc=`chile' if remittances_currency==6

gen y_foreign_remittances=remittances_monthly*remittances_tc
replace y_foreign_remittances=0 if y_foreign_remittances==.

*(iii) private transfer
egen y_private_transfers=rowtotal(y_foreign_remittances y_local_transfers)

*(iv) no-labor regular incomes

local word "interest renting other"
local kind "a b c"

forvalues j=1/3{

local i: word `j' of `word'
local x: word `j' of `kind'
 
gen revenues_`i'=s07a_02`x'
replace revenues_`i'=0 if revenues_`i'==.

}

egen y_int_assets_regular=rowtotal(revenues_interest revenues_renting revenues_other)

*(iv) no-labor incomes
local word "rental_agric dividends rental_equip indemnization insurance other_nr"
local kind "_03a _03b _03c _04a _04b _04c"

forvalues j=1/6{

local i: word `j' of `word'
local x: word `j' of `kind'
 
gen revenues_`i'=s07a`x'/12
replace revenues_`i'=0 if revenues_`i'==.

}

egen y_non_regular=rowtotal(revenues_rental_agric revenues_dividends revenues_rental_equip /*
*/ revenues_indemnization revenues_insurance revenues_other_nr)

*(v) incomes assets
egen y_int_assets_total=rowtotal(y_int_assets_regular y_non_regular)

*(vi) no labor income
egen y_nonlabor=rowtotal(y_int_assets_total y_private_transfers y_government)

*(vii) total income
egen y_person=rowtotal(y_labor y_nonlabor)

**ALL INCOME VARIABLES
global wages wage_total wage_monthly_main wage_monthly_sec extra_wages extra_wages_main/*
*/ extra_wages_sec aguinaldo_yearly_main inkind_payments inkind_payments_main inkind_payments_sec y_wl_bonus_main /*
*/ y_wl_bonus_sec y_wl_bonus y_earnings_main y_earnings_sec y_earnings

global incomes rev_nw_labor rev_nw_labor_main_monthly rev_nw_labor_sec_monthly operational_cost_main operational_cost_sec /*
*/ operational_cost y_nw_labor_main y_nw_labor_sec y_nw_labor y_nw_labor_sr y_nw_labormain_sr_m y_nw_laborsec_sr_m y_labor /*
*/ y_labor_main y_labor_sec

global nolabor_income retirement transfer_veterans transfer_disability transfer_widows y_social_security y_elderly_transfer /*
*/ y_government y_local_transfers family_asistance_monthly people_incountry_monthly y_foreign_remittances remittances_currency /*
*/ y_private_transfers y_int_assets_regular revenues_interest revenues_renting revenues_other y_non_regular revenues_rental_agric /*
*/ revenues_dividends revenues_rental_equip revenues_indemnization revenues_insurance revenues_other_nr y_int_assets_total /*
*/ y_int_assets_regular y_nonlabor y_person

***3. Save new dataset

*Saved variables
keep id folio depto area t $wages $incomes $nolabor_income

*Save
save "${relabeled_data}/Income/EH2017_Income_relabel", replace

