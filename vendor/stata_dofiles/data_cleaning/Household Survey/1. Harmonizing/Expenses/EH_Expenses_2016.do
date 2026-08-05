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

/* This .do file cleans 2016 Household Survey expenses data for households */

/*==================================================
            0: Program set up
==================================================*/
*Written on STATA 17
drop _all

/*==================================================
            1: Manage Dataset
==================================================*/

global year 2016

*I. ALIMENTARY AND NON ALIMENTARY DATA

*1.Alimentary expenses
use "${raw_data}/2016/EH2016_Persona.dta", clear

keep folio
duplicates drop 

*1.4 Save data
save "${relabeled_data}/Expenses/EH2016_gasto_al", replace

*2.Non Alimentary expenses

use "${raw_data}/2016/EH2016_Persona.dta", clear

keep folio
duplicates drop

*2.4 Save data
save "${relabeled_data}/Expenses/EH2016_gasto_noal", replace

*3. Durable goods
use "${raw_data}/2016/EH2016_equipamiento", clear

*3.1 Rename+destring key variables

*3.2 Expenditure construction
g expend_dur_t=s10a_04 if s10a_03<=1
g durable=s10a_04

foreach x in expend_dur_t durable{
replace `x'=. if `x'>999990 
}

global art living stove fridge pc radio minicomponent tv washer moto car
forvalues i=1/10{
local x: word `i' of $art
g aux_have_`x'=(s10a_01==1) if item==`i'
bys folio: egen have_`x'=total(aux_have_`x') 
g aux_cost_`x'=s10a_04 if item==`i'
replace aux_cost_`x'=. if s10a_04>999990
bys folio: egen cost_`x'=total(aux_cost_`x')
}
drop aux*

*3.3 Collapse by folio 
collapse (sum) expend_dur_t durable (mean) have* cost*, by(folio)

*3.3 Collapse by folio 
collapse (sum) expend_dur_t durable (mean) have* cost*, by(folio)

*3.4 Save data
save "${relabeled_data}/Expenses/EH2016_gasto_durable", replace

*II. MERGE DATA
use "${relabeled_data}/Expenses/EH2016_gasto_al", clear

merge 1:1 folio using "${relabeled_data}/Expenses/EH2016_gasto_noal"
drop _merge

merge 1:1 folio using "${relabeled_data}/Expenses/EH2016_gasto_durable"
drop _merge

*egen expend=rowtotal(expend_al expend_noal)

save "${relabeled_data}/Expenses/EH2016_expenses_relabel", replace

