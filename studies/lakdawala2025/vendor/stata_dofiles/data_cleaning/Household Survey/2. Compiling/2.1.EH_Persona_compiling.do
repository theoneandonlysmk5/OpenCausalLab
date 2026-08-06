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

/* This .do file compilates all Household Survey demographic and employment data and merges them */

/*==================================================
            0: Program set up
==================================================*/
*Written on STATA 17
drop _all

/*==================================================
            1: Initial Data
==================================================*/

use "${relabeled_data}/Persona/EH2012_Persona_relabel", clear


append using "${relabeled_data}/Persona/EH2013_Persona_relabel", force


tostring upm, replace

forvalues i=2014(1)2019 {
append using "${relabeled_data}/Persona/EH`i'_Persona_relabel", force

}

** Add municipality and provincial section
merge m:m upm using "${raw_data}/upm_2001-2013_relabeled", force
drop if _merge==2
drop _merge

merge m:m upm using "${raw_data}/upm_2015-2017_relabeled", force
drop if _merge==2
drop _merge

merge m:m upm using "${raw_data}/upm_2016_relabeled", force
drop if _merge==2
drop _merge

recast strL folio id

/*==================================================
            2: Save Compiled data
==================================================*/

save "${relabeled_data}/Persona/EH_compiled_persona", replace
