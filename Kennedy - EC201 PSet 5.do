/*
Aja Kennedy
EC201 Statistics
Fall 2021
PSet 5
*/

clear
set more off
set memory 10m
set seed 11162021
program drop _all

cd "/Users/ajakennedy/Box/Git Folder"
insheet using "families.txt", clear

*commands: sample, simulate

*PART A - parameter estimates, standard error, 95% confidence interval

*generate binary variables
gen female_fam = type==3 // female-headed families
gen no_hs = education <39 // head of household without hs diploma

*save as a temp file to recall later
save "families.dta", replace

*save this t score as a scalar:
scalar z95 = invnormal(0.975)

*save a scalar to easily change sample size in program we will run
*local sample_size 500

**PART A - generate parameter estimates and 95% confidence intervials for:
*proportion of female-headed families
*average number of children per family
*proportion of households that did not recieve HS diploma
*average family income

program define mysum, rclass

use families, clear
sample 500, count

	foreach x in female_fam children no_hs income {
		qui sum `x', detail
		scalar `x'_mean = r(mean) // parameter estimate
		scalar `x'_ci_95_l = r(mean)-z95*sqrt(r(Var)/r(N)) // lower bound of 95% confidence interval
		scalar `x'_ci_95_h = r(mean)+z95*sqrt(r(Var)/r(N)) // upper bound of 95% confidence interval
		scalar `x'_se = sqrt(r(Var)/r(N)) // standard error
	
	}
	
end

simulate ///
	female_fam_mean=female_fam_mean	female_fam_ci_95_l=female_fam_ci_95_l	female_fam_ci_95_h=female_fam_ci_95_h ///
	children_mean=children_mean		children_ci_95_l=children_ci_95_l		children_ci_95_h=children_ci_95_h ///
	no_hs_mean=no_hs_mean			no_hs_ci_95_l=no_hs_ci_95_l 			no_hs_ci_95_h=no_hs_ci_95_h ///
	income_mean=income_mean 		income_ci_95_l=income_ci_95_l			income_ci_95_h=income_ci_95_h ///
	, reps(5): mysum


/*
**PART B - 100 samples of size 400

local sample_size 400 // change sample size to 400
simulate income_mean income_se, reps(100): mysum // simulate mean and standard error

*histogram of the 100 estimates
