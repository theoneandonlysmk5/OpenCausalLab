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

/*==================================================
Note that the list of newspapers included can be found in "Bolivian Newspaper List - 122421.xls"
==================================================*/

clear all

use "${other_raw}/articledata.dta" , clear


* Collapse data to quarterly level

	* 1A. Mark articles that mention the CNNA and child labor

	gen cnna=1		if (keyword=="Código Niña, Niño y Adolescente" | keyword=="CNNA" | keyword=="Ley 548") 

	gen kidwork=1	if (keyword=="trabajo de las niñas" | keyword=="trabajo de los niños" ///
					| keyword=="trabajo de los adolescents" ///
					| keyword=="trabajo infantil")

	* 1B. Keep only unique articles that mention the CNNA and child labor
					
	collapse		(max) cnna kidwork (first) title, by(website link date)
	keep			if cnna==1 & kidwork==1


	* 2A. Generate quarter

	generate 		yq = qofd(date)
	format 			%tq yq
	label var		yq "Quarter"

	* 2B. Keep only articles between Q1 2012 and Q1 2020

	keep			if yq>=tq(2012q1) & yq<=tq(2020q1)
	drop 			if date == .
	
	*3. Collapse to quarterly level

	gen				article = 1 
	collapse 		(sum) article, by(yq)
	label var		article "Number of Articles"

	tab				yq
	set 			obs `=_N+1'
	replace 		article = 0 if _n == _N
	replace 		yq = tq(2012q1) if _n == _N
	set 			obs `=_N+1'
	replace 		article = 0 if _n == _N
	replace 		yq = tq(2020q1) if _n == _N
			
	tsset			yq
	tsfill
	replace			article = 0 if article==.

	
* Display national time series trends	


local color1="89 172 203"
local color2="16 120 149"
local color3="0 71 98"
graph set print fontface "Garamond"
graph set window fontface "Garamond"

	local			law=tq(2014q3)
	di				`law'	
	local			reversal_announced=tq(2018q1)
	di				`reversal_announced'	
	local			reversal=tq(2018q4)
	di				`reversal'	
	sort 			yq
	twoway 			(connected article yq, mcolor("`color2'".6) lcolor("`color2'") ///
					text(19 `law' "Initial Implementation (July2014)", size(small)) ///
					text(19 `reversal_announced' "Reversal Announced (Feb2018)", size(small)) ///
					text(18 `reversal' "Reversal Implemented (Dec2018)", size(small)) ///
					title("Articles on the 2014 Law over time") graphregion(color(white)) ///
					yscale(range(0,15.5)) xsize(10) ysize(5) legend(off) ///
					xtitle("Quarter") ytitle("Number of Articles")) ///
					(scatteri 0 `law' 18 `law', recast(line) lwidth(medthick)) ///
					(scatteri 0 `reversal_announced' 17.5 `reversal_announced', recast(line) lwidth(medthick)) ///
					(scatteri 0 `reversal' 17.5 `reversal', recast(line) lwidth(medthick))
					
	graph export "${figuredir}/articles.png", replace
	