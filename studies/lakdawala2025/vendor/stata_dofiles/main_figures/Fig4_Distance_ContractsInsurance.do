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

/*==================================================
            0: Program set up
==================================================*/
*Written on STATA 17
drop _all
clear all
/*==================================================
            The Role of Enforcement
==================================================*/

use "${relabeled_data}/HHsurvey_ad.dta", clear

drop if mtepsoffices==1

preserve
drop if year<2012
keep if works==1 & age>=18

winsor ttime, generate(wtime) p(0.05) 

global vartoplot "wtime"

global controls "capital urban age male schooling agriculture_a mining_a manufacture_a construction_a sales_a transportation_a other_a firm_taxes"
*controlling for formality, 50 quantiles

reg formal_contract $vartoplot $controls [w=f_weight] if year<2014
local slope=round(_b[${vartoplot}],0.00001)
local pval =round(2*ttail(e(df_r),abs(_b[${vartoplot}]/_se[${vartoplot}])),0.001)
binscatter formal_contract $vartoplot [w=f_weight] if year<2014,  controls($controls)  lcolor(maroon) mcolor(maroon) linetype(lfit) msymbols(T) xtitle(Driving time to closest MTEPS office (minutes, winsorized 5%)) ytitle(Proportion) name(binscatter2, replace) nquantiles(50) graphregion(color(white)) note("Slope = `slope', P-value = `pval'") saving(contract_dist, replace)
graph export "${figuredir}/contract_dist.png", replace

*controlling for formality, 50 quantiles
reg health_insurance $vartoplot $controls [w=f_weight] if year<2014
local slope=round(_b[${vartoplot}],0.00001)
local pval =round(2*ttail(e(df_r),abs(_b[${vartoplot}]/_se[${vartoplot}])),0.001)
binscatter health_insurance $vartoplot [w=f_weight] if year<2014,  controls($controls)  lcolor(maroon) mcolor(maroon) linetype(lfit) msymbols(S) xtitle(Driving time to closest MTEPS office (minutes, winsorized 5%)) ytitle(Proportion) name(binscatter4, replace) nquantiles(50) graphregion(color(white)) note("Slope = `slope', P-value = `pval'") saving(insurance_dist, replace)
graph export "${figuredir}/insurance_dist.png", replace

gr combine contract_dist.gph insurance_dist.gph, graphregion(color(white)) row(1) xsize(6) ysize(2) iscale(*1.3)
graph export "${figuredir}/contract_insurance_dist.png", replace


restore

