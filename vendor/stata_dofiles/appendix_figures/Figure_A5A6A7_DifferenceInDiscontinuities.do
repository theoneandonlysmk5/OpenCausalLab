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
					McCrary Tests
==================================================*/

clear all

*=1 to make plots for individual densities
local indiv_densities=0
*= range of graphs
local grbw=12
*= bw for discontinuity and SE
local bwdisc=12
*= bw for density calculation 
local bwdens=12
*= polynomial degree 1-3
local deg=1

global poly_1 "X post Xpost"
global poly_2 "$poly_1  X2   X2post "
global poly_3 "$poly_2 X3 X3post"

global oneside_1 "X"
global oneside_2 "X X2"
global oneside_3 "X X2 X3"
*_______________________________________________________________________________

*									HH survey
*_______________________________________________________________________________

foreach n in 1 2 3  {
*HH Survey
use "${relabeled_data}/HHsurvey.dta", clear

*Post Law
keep if year>=2014 & year<=2017
    
local c=`n'*2+8

drop if running`c'>200 | running`c'<-200

*** compute bins
local binsize = 1
gen bin = .
foreach X of num 0(1)100 {
	di "`X'"
	replace bin=-`X' if (running`c'>=-`X' & running`c'<=(-`X'+ `binsize') & running`c'<0)
	replace bin=`X' if (running`c'>=`X' & running`c'<=(`X'+`binsize'))
}
tab bin
	
* Take the average of the outcome variable within each bin
capture drop dens
sum running`c'
local obs=r(N)
bysort bin: egen fr = count(bin)
gen dens = fr/`obs'

* Take the average of the running variable within each bin (for graphical purposes only; this makes the dots being centered within each bean)
capture drop mbin
bysort bin : egen X = mean(running`c') 
drop bin

keep X dens 
duplicates drop X dens, force

if `indiv_densities'==1{

gen X2=X^2
gen X3=X^3
gen post=X>=0
gen Xpost=X*post
gen X2post=X2*post
gen X3post=X3*post

preserve
keep if inrange(X,-`bwdisc',`bwdisc') 
capture gen kernel_tri = ((`bwdisc' - abs(X)) /`bwdisc') * (abs(X) < `bwdisc')

reg dens ${poly_`deg'} [aw=kernel_tri] , robust
local disc=round(_b[post], 0.0001)
local b=_b[post]
local disc_se=round(_se[post], 0.0001)
local se=_se[post]
local pv=round((2 * ttail(e(df_r)*2, abs(`b'/`se'))),0.001)
local pval=substr("`pv'",1,4)
restore


preserve
keep if inrange(X,-`bwdens',`bwdens') 
capture gen kernel_tri = ((`bwdens' - abs(X)) /`bwdens') * (abs(X) < `bwdens')

reg dens ${oneside_`deg'} if post==0 [aw=kernel_tri] , robust
predict fhatl, xb
predict se_fhatl, stdp
gen r0l=X if post==0

reg dens ${oneside_`deg'} if post==1 [aw=kernel_tri] , robust
predict fhatr, xb
predict se_fhatr, stdp
gen r0r=X if post==1

local breakpoint 0
local cellmpname X
local cellvalname dens
local evalnamel r0l
local evalnamer r0r
local cellsmnamel fhatl
local cellsmnamer fhatr
local cellsmsenamel se_fhatl
local cellsmsenamer se_fhatr

tempvar hil
quietly gen `hil' = `cellsmnamel' + 1.96*`cellsmsenamel'
tempvar lol
quietly gen `lol' = `cellsmnamel' - 1.96*`cellsmsenamel'

tempvar hir
quietly gen `hir' = `cellsmnamer' + 1.96*`cellsmsenamer'
tempvar lor
quietly gen `lor' = `cellsmnamer' - 1.96*`cellsmsenamer'

gr twoway (scatter `cellvalname' `cellmpname' if `cellmpname'<`grbw' & `cellmpname'>=-`grbw', msymbol(circle_hollow) mcolor(gray))             ///
  (line `cellsmnamel' `evalnamel' if  `evalnamel'>=-`grbw', lcolor(black) lwidth(medthick))   ///
  (line `cellsmnamer' `evalnamer' if  `evalnamer'<`grbw', lcolor(black) lwidth(medthick))   ///
  (line `hil' `evalnamel' if `evalnamel'>=-`grbw', lcolor(black) lwidth(vthin))              ///
  (line `lol' `evalnamel' if  `evalnamel'>=-`grbw', lcolor(black) lwidth(vthin))              ///
  (line `hir' `evalnamer' if  `evalnamer'<`grbw', lcolor(black) lwidth(vthin))              ///
  (line `lor' `evalnamer' if `evalnamer'<`grbw', lcolor(black) lwidth(vthin)),   /// 
   note("Disc. = `disc', P-val of Disc. = `pval'")  ylabel( , labs(vsmall) ) xlabel(, labs(vsmall) ) /// 
  xline(`breakpoint', lcolor(black)) legend(off) saving(McCrary_HSpost_`c', replace) ///
  graphregion(color(white))  xtitle("Normalized months to threshold", size(small))   ytitle("Density", size(small))  title("Post Law" , size( medsmall))  yscale(titlegap(*10))
restore
  }

tempfile densitypost`n'
rename dens Yj_post  
keep X Yj_post
 save `densitypost`n'', replace
 
 
 
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

 
*HH Survey data 
use "${relabeled_data}/HHsurvey.dta", clear

*Pre-law data
keep if year==2012 | year==2013

drop if running`c'>200 | running`c'<-200

*** compute bins
local binsize = 1
gen bin = .
foreach X of num 0(1)100 {
	di "`X'"
	replace bin=-`X' if (running`c'>=-`X' & running`c'<=(-`X'+ `binsize') & running`c'<0)
	replace bin=`X' if (running`c'>=`X' & running`c'<=(`X'+`binsize'))
}
tab bin
	
* Take the average of the outcome variable within each bin
capture drop dens
sum running`c'
local obs=r(N)
bysort bin : egen fr = count(bin)
gen dens = fr/`obs'

* Take the average of the running variable within each bin (for graphical purposes only; this makes the dots being centered within each bean)
capture drop mbin
bysort bin : egen X = mean(running`c') 
drop bin

keep X dens
duplicates drop X dens, force

if `indiv_densities'==1{

gen X2=X^2
gen X3=X^3
gen post=X>=0
gen Xpost=X*post
gen X2post=X2*post
gen X3post=X3*post

preserve
keep if inrange(X,-`bwdisc',`bwdisc') 
capture gen kernel_tri = ((`bwdisc' - abs(X)) /`bwdisc') * (abs(X) < `bwdisc')

reg dens ${poly_`deg'} [aw=kernel_tri] , robust
local disc=round(_b[post], 0.0001)
local b=_b[post]
local disc_se=round(_se[post], 0.0001)
local se=_se[post]
local pv=round((2 * ttail(e(df_r)*2, abs(`b'/`se'))),0.001)
local pval=substr("`pv'",1,4)
restore


preserve
keep if inrange(X,-`bwdens',`bwdens') 
capture gen kernel_tri = ((`bwdens' - abs(X)) /`bwdens') * (abs(X) < `bwdens')

reg dens ${oneside_`deg'} if post==0 [aw=kernel_tri] , robust
predict fhatl, xb
predict se_fhatl, stdp
gen r0l=X if post==0

reg dens ${oneside_`deg'} if post==1 [aw=kernel_tri] , robust
predict fhatr, xb
predict se_fhatr, stdp
gen r0r=X if post==1

local breakpoint 0
local cellmpname X
local cellvalname dens
local evalnamel r0l
local evalnamer r0r
local cellsmnamel fhatl
local cellsmnamer fhatr
local cellsmsenamel se_fhatl
local cellsmsenamer se_fhatr

tempvar hil
quietly gen `hil' = `cellsmnamel' + 1.96*`cellsmsenamel'
tempvar lol
quietly gen `lol' = `cellsmnamel' - 1.96*`cellsmsenamel'

tempvar hir
quietly gen `hir' = `cellsmnamer' + 1.96*`cellsmsenamer'
tempvar lor
quietly gen `lor' = `cellsmnamer' - 1.96*`cellsmsenamer'

gr twoway (scatter `cellvalname' `cellmpname' if `cellmpname'<`grbw' & `cellmpname'>=-`grbw', msymbol(circle_hollow) mcolor(gray))             ///
  (line `cellsmnamel' `evalnamel' if  `evalnamel'>=-`grbw', lcolor(black) lwidth(medthick))   ///
  (line `cellsmnamer' `evalnamer' if  `evalnamer'<`grbw', lcolor(black) lwidth(medthick))   ///
  (line `hil' `evalnamel' if `evalnamel'>=-`grbw', lcolor(black) lwidth(vthin))              ///
  (line `lol' `evalnamel' if  `evalnamel'>=-`grbw', lcolor(black) lwidth(vthin))              ///
  (line `hir' `evalnamer' if  `evalnamer'<`grbw', lcolor(black) lwidth(vthin))              ///
  (line `lor' `evalnamer' if `evalnamer'<`grbw', lcolor(black) lwidth(vthin)),    /// 
   note("Disc. = `disc', P-val of Disc. = `pval'")  ylabel( , labs(vsmall) ) xlabel(, labs(vsmall) ) /// 
  xline(`breakpoint', lcolor(black)) legend(off) saving(McCrary_HSpre_`c', replace) ///
  graphregion(color(white))  xtitle("Normalized months to threshold", size(small)) ytitle("Density", size(small)) title("Pre Law" , size( medsmall))  yscale(titlegap(*10))
restore
  }

tempfile densitypre`n'
rename dens Yj_pre  
keep X Yj_pre
 save `densitypre`n'', replace
 

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

*HH Survey data 
use "${relabeled_data}/HHsurvey.dta", clear

*Pre-law data
keep if year==2018 | year==2019

drop if running`c'>200 | running`c'<-200

*** compute bins
local binsize = 1
gen bin = .
foreach X of num 0(1)100 {
	di "`X'"
	replace bin=-`X' if (running`c'>=-`X' & running`c'<=(-`X'+ `binsize') & running`c'<0)
	replace bin=`X' if (running`c'>=`X' & running`c'<=(`X'+`binsize'))
}
tab bin
	
* Take the average of the outcome variable within each bin
capture drop dens
sum running`c'
local obs=r(N)
bysort bin : egen fr = count(bin)
gen dens = fr/`obs'

* Take the average of the running variable within each bin (for graphical purposes only; this makes the dots being centered within each bean)
capture drop mbin
bysort bin : egen X = mean(running`c') 
drop bin

keep X dens
duplicates drop X dens, force

if `indiv_densities'==1{

gen X2=X^2
gen X3=X^3
gen post=X>=0
gen Xpost=X*post
gen X2post=X2*post
gen X3post=X3*post

preserve
keep if inrange(X,-`bwdisc',`bwdisc') 
capture gen kernel_tri = ((`bwdisc' - abs(X)) /`bwdisc') * (abs(X) < `bwdisc')

reg dens ${poly_`deg'} [aw=kernel_tri] , robust
local disc=round(_b[post], 0.0001)
local b=_b[post]
local disc_se=round(_se[post], 0.0001)
local se=_se[post]
local pv=round((2 * ttail(e(df_r)*2, abs(`b'/`se'))),0.001)
local pval=substr("`pv'",1,4)
restore


preserve
keep if inrange(X,-`bwdens',`bwdens') 
capture gen kernel_tri = ((`bwdens' - abs(X)) /`bwdens') * (abs(X) < `bwdens')

reg dens ${oneside_`deg'} if post==0 [aw=kernel_tri] , robust
predict fhatl, xb
predict se_fhatl, stdp
gen r0l=X if post==0

reg dens ${oneside_`deg'} if post==1 [aw=kernel_tri] , robust
predict fhatr, xb
predict se_fhatr, stdp
gen r0r=X if post==1

local breakpoint 0
local cellmpname X
local cellvalname dens
local evalnamel r0l
local evalnamer r0r
local cellsmnamel fhatl
local cellsmnamer fhatr
local cellsmsenamel se_fhatl
local cellsmsenamer se_fhatr

tempvar hil
quietly gen `hil' = `cellsmnamel' + 1.96*`cellsmsenamel'
tempvar lol
quietly gen `lol' = `cellsmnamel' - 1.96*`cellsmsenamel'

tempvar hir
quietly gen `hir' = `cellsmnamer' + 1.96*`cellsmsenamer'
tempvar lor
quietly gen `lor' = `cellsmnamer' - 1.96*`cellsmsenamer'

gr twoway (scatter `cellvalname' `cellmpname' if `cellmpname'<`grbw' & `cellmpname'>=-`grbw', msymbol(circle_hollow) mcolor(gray))             ///
  (line `cellsmnamel' `evalnamel' if  `evalnamel'>=-`grbw', lcolor(black) lwidth(medthick))   ///
  (line `cellsmnamer' `evalnamer' if  `evalnamer'<`grbw', lcolor(black) lwidth(medthick))   ///
  (line `hil' `evalnamel' if `evalnamel'>=-`grbw', lcolor(black) lwidth(vthin))              ///
  (line `lol' `evalnamel' if  `evalnamel'>=-`grbw', lcolor(black) lwidth(vthin))              ///
  (line `hir' `evalnamer' if  `evalnamer'<`grbw', lcolor(black) lwidth(vthin))              ///
  (line `lor' `evalnamer' if `evalnamer'<`grbw', lcolor(black) lwidth(vthin)),    /// 
   note("Disc. = `disc', P-val of Disc. = `pval'")  ylabel( , labs(vsmall) ) xlabel(, labs(vsmall) ) ///       
  xline(`breakpoint', lcolor(black)) legend(off) saving(McCrary_HSrev_`c', replace) ///
  graphregion(color(white))  xtitle("Normalized months to threshold", size(small))   ytitle("Density", size(small))  title("Post Reversal" , size( medsmall))   yscale(titlegap(*10))
restore
  }

tempfile densityrev`n'
rename dens Yj_rev  
keep X Yj_rev
 save `densityrev`n'', replace


* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 
*Difference in densities: pre vs post
 
use `densitypre`n'', clear
merge 1:1 X  using `densitypost`n''
keep if _merge==3    
drop _merge
gen Y_diff=Yj_post- Yj_pre

gen X2=X^2
gen X3=X^3
gen post=X>=0
gen Xpost=X*post
gen X2post=X2*post
gen X3post=X3*post

preserve
keep if inrange(X,-`bwdisc',`bwdisc') 
capture gen kernel_tri = ((`bwdisc' - abs(X)) /`bwdisc') * (abs(X) < `bwdisc')

reg Y_diff ${poly_`deg'}  [aw=kernel_tri] , robust
local disc=round(_b[post], 0.0001)
local b=_b[post]
local disc_se=round(_se[post], 0.0001)
local se=_se[post]
test post
local pv=r(p)
local pval=substr("`pv'",1,4)
restore


preserve
keep if inrange(X,-`bwdens',`bwdens') 
capture gen kernel_tri = ((`bwdens' - abs(X)) /`bwdens') * (abs(X) < `bwdens')

reg Y_diff ${oneside_`deg'} if post==0 [aw=kernel_tri] , robust
predict fhatl, xb
predict se_fhatl, stdp
gen r0l=X if post==0

reg Y_diff ${oneside_`deg'} if post==1 [aw=kernel_tri] , robust
predict fhatr, xb
predict se_fhatr, stdp
gen r0r=X if post==1

local breakpoint 0
local cellmpname X
local cellvalname Y_diff
local evalnamel r0l
local evalnamer r0r
local cellsmnamel fhatl
local cellsmnamer fhatr
local cellsmsenamel se_fhatl
local cellsmsenamer se_fhatr

tempvar hil
quietly gen `hil' = `cellsmnamel' + 1.96*`cellsmsenamel'
tempvar lol
quietly gen `lol' = `cellsmnamel' - 1.96*`cellsmsenamel'

tempvar hir
quietly gen `hir' = `cellsmnamer' + 1.96*`cellsmsenamer'
tempvar lor
quietly gen `lor' = `cellsmnamer' - 1.96*`cellsmsenamer'

gr twoway (scatter `cellvalname' `cellmpname' if `cellmpname'<`grbw' & `cellmpname'>=-`grbw', msymbol(circle_hollow) mcolor(gray))      ///
  (line `cellsmnamel' `evalnamel' if  `evalnamel'>=-`grbw', lcolor(black) lwidth(medthick))   ///
  (line `cellsmnamer' `evalnamer' if  `evalnamer'<`grbw', lcolor(black) lwidth(medthick))   ///
  (line `hil' `evalnamel' if `evalnamel'>=-`grbw', lcolor(black) lwidth(vthin))              ///
  (line `lol' `evalnamel' if  `evalnamel'>=-`grbw', lcolor(black) lwidth(vthin))              ///
  (line `hir' `evalnamer' if  `evalnamer'<`grbw', lcolor(black) lwidth(vthin))              ///
  (line `lor' `evalnamer' if `evalnamer'<`grbw', lcolor(black) lwidth(vthin)),             ///
  note("Disc. = `disc', P-value of Disc. = `pval'") ylabel( , labs(vsmall) ) xlabel(, labs(vsmall) ) ///
  xline(`breakpoint', lcolor(black)) legend(off) saving(McCrary_HSdiff1_`c', replace) ///
  graphregion(color(white))  xtitle("Normalized months to threshold", size(small)) ytitle("Difference in Density", size(small)) title("Pre Law vs. Post Law" , size( medsmall))  yscale(titlegap(*10))

  restore


* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 
*Difference in densities: post vs reversal

use `densitypost`n'', clear
merge 1:1 X  using `densityrev`n''
keep if _merge==3    
drop _merge
gen Y_diff=Yj_rev- Yj_post

gen X2=X^2
gen X3=X^3
gen post=X>=0
gen Xpost=X*post
gen X2post=X2*post
gen X3post=X3*post

preserve
keep if inrange(X,-`bwdisc',`bwdisc') 
capture gen kernel_tri = ((`bwdisc' - abs(X)) /`bwdisc') * (abs(X) < `bwdisc')

reg Y_diff ${poly_`deg'}  [aw=kernel_tri] , robust
local disc=round(_b[post], 0.0001)
local b=_b[post]
local disc_se=round(_se[post], 0.0001)
local se=_se[post]
test post
local pv=r(p)
local pval=substr("`pv'",1,4)
restore


preserve
keep if inrange(X,-`bwdens',`bwdens') 
capture gen kernel_tri = ((`bwdens' - abs(X)) /`bwdens') * (abs(X) < `bwdens')

reg Y_diff ${oneside_`deg'} if post==0 [aw=kernel_tri] , robust
predict fhatl, xb
predict se_fhatl, stdp
gen r0l=X if post==0

reg Y_diff ${oneside_`deg'} if post==1 [aw=kernel_tri] , robust
predict fhatr, xb
predict se_fhatr, stdp
gen r0r=X if post==1

local breakpoint 0
local cellmpname X
local cellvalname Y_diff
local evalnamel r0l
local evalnamer r0r
local cellsmnamel fhatl
local cellsmnamer fhatr
local cellsmsenamel se_fhatl
local cellsmsenamer se_fhatr

tempvar hil
quietly gen `hil' = `cellsmnamel' + 1.96*`cellsmsenamel'
tempvar lol
quietly gen `lol' = `cellsmnamel' - 1.96*`cellsmsenamel'

tempvar hir
quietly gen `hir' = `cellsmnamer' + 1.96*`cellsmsenamer'
tempvar lor
quietly gen `lor' = `cellsmnamer' - 1.96*`cellsmsenamer'

gr twoway (scatter `cellvalname' `cellmpname' if `cellmpname'<`grbw' & `cellmpname'>=-`grbw', msymbol(circle_hollow) mcolor(gray))             ///
  (line `cellsmnamel' `evalnamel' if  `evalnamel'>=-`grbw', lcolor(black) lwidth(medthick))   ///
  (line `cellsmnamer' `evalnamer' if  `evalnamer'<`grbw', lcolor(black) lwidth(medthick))   ///
  (line `hil' `evalnamel' if `evalnamel'>=-`grbw', lcolor(black) lwidth(vthin))              ///
  (line `lol' `evalnamel' if  `evalnamel'>=-`grbw', lcolor(black) lwidth(vthin))              ///
  (line `hir' `evalnamer' if  `evalnamer'<`grbw', lcolor(black) lwidth(vthin))              ///
  (line `lor' `evalnamer' if `evalnamer'<`grbw', lcolor(black) lwidth(vthin)),             ///
    note("Disc. = `disc', P-value of Disc. = `pval'")  ylabel( , labs(vsmall) )  xlabel(, labs(vsmall) )  ///
  xline(`breakpoint', lcolor(black)) legend(off) saving(McCrary_HSdiff2_`c', replace)   ///
  graphregion(color(white))  xtitle("Normalized months to threshold", size(small))   ytitle("Difference in Density", size(small))  title("Post Law vs. Reversal", size( medsmall))  yscale(titlegap(*10))

restore
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*Graphs
 if `indiv_densities'==1{
	gr combine McCrary_HSpre_`c'.gph McCrary_HSpost_`c'.gph McCrary_HSrev_`c'.gph, ycommon graphregion(color(white)) rows(1) saving(McCrary_HSprepostrev_`c', replace)
    gr combine McCrary_HSdiff1_`c'.gph McCrary_HSdiff2_`c'.gph, ycommon graphregion(color(white)) rows(1) saving(McCrary_HSdiffs_`c', replace)
    gr combine McCrary_HSprepostrev_`c'.gph McCrary_HSdiffs_`c'.gph, ycommon graphregion(color(white)) rows(2) 
 }
 else{
 	    gr combine McCrary_HSdiff1_`c'.gph McCrary_HSdiff2_`c'.gph, ycommon graphregion(color(white)) rows(1) 
 }
graph export "${figuredir}/McCrary_HS_`c'.png", replace
di `pv'
di `pval'	
}