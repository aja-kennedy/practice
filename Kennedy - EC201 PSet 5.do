/*
Aja Kennedy
EC201 Statistics
Fall 2021
PSet 5
*/

*WHY CAN'T I AUTOMATE SAMPLE SIZE? BOOOO

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

*save the population mean as a scalar (to use later)
qui sum income
scalar income_mean_pop = r(mean)

*save a scalar to easily change sample size in program we will run
*local sample_size 500

**PART A - generate parameter estimates and 95% confidence intervials for:
*proportion of female-headed families
*average number of children per family
*proportion of households that did not recieve HS diploma
*average family income

program define part_a, rclass

	use families, clear
	sample 500, count

	foreach x in female_fam children no_hs income {
		qui sum `x', detail
		scalar `x'_mean = r(mean) // parameter estimate
		scalar `x'_ci_95_l = r(mean)-z95*sqrt(r(Var)/r(N)) // lower bound of 95% confidence interval
		scalar `x'_ci_95_h = r(mean)+z95*sqrt(r(Var)/r(N)) // upper bound of 95% confidence interval
		scalar `x'_sd = r(sd) // standard deviation
	
	}
	
end

simulate ///
	female_fam_mean=female_fam_mean	female_fam_ci_95_l=female_fam_ci_95_l	female_fam_ci_95_h=female_fam_ci_95_h ///
	children_mean=children_mean		children_ci_95_l=children_ci_95_l		children_ci_95_h=children_ci_95_h ///
	no_hs_mean=no_hs_mean			no_hs_ci_95_l=no_hs_ci_95_l 			no_hs_ci_95_h=no_hs_ci_95_h ///
	income_mean=income_mean 		income_ci_95_l=income_ci_95_l			income_ci_95_h=income_ci_95_h ///
	, reps(5): part_a


**PART B - 100 samples of size 400

program define part_b, rclass

	use families, clear
	sample 400, count
	qui sum income, detail
	scalar income_mean = r(mean) // parameter estimate
	scalar income_95_l = r(mean)-z95*sqrt(r(Var)/r(N)) // lower bound of 95% confidence interval
	scalar income_ci_95_h = r(mean)+z95*sqrt(r(Var)/r(N)) // upper bound of 95% confidence interval
	scalar income_sd = sqrt(r(Var)/r(N)) // standard error
	
end

*simulate mean, standard error, 95% confidence intervals
simulate income_mean=income_mean income_sd=income_sd income_95_l income_ci_95_h, reps(100): part_b

*histogram of the 100 estimates, normal density plot superimposed
histogram income_mean, normal
histogram income_sd, normal

*empirical cumulative distribution function, normal density plot superimposed
ssc install cdfplot
cdfplot income_mean, norm

*find number of 95% confidence intervals that contain the population target
gen ci_dummy = income mean_pop >= income_ci_95_l & income_mean_pop <= income_ci_95_h
qui sum ci_dummy
di r(mean)*100 // number of confidence intervals that contain the population target

*repeat when sample size = 100

program define part_b2, rclass

	use families, clear
	sample 100, count
	qui sum income, detail
	scalar income_mean = r(mean) // parameter estimate
	scalar income_95_l = r(mean)-z95*sqrt(r(Var)/r(N)) // lower bound of 95% confidence interval
	scalar income_ci_95_h = r(mean)+z95*sqrt(r(Var)/r(N)) // upper bound of 95% confidence interval
	scalar income_sd = sqrt(r(Var)/r(N)) // standard error
	
end

simulate income_mean=income_mean income_sd=income_sd income_95_l income_ci_95_h, reps(100): part_b2

*histogram of the 100 estimates, normal density plot superimposed
histogram income_mean, normal
histogram income_sd, normal

*empirical cumulative distribution function, normal density plot superimposed
ssc install cdfplot
cdfplot income_mean, norm

*find number of 95% confidence intervals that contain the population target
count if income mean_pop >= income_ci_95_l & income_mean_pop <= income_ci_95_h

**PART C - sample size 500, compare incomes of the 3 family types by comparing histograms and boxplots

use families, clear
sample 500, count

graph box income, over(type)

foreach i of numlist 1/3 {
	histogram income if type==`i'
}

**PART D - sample size 400 from each of the four regions

use families, clear
sample 400, by(region) count

*parallel boxplots: income, family size, education level

foreach j in income persons education {
	graph box `j', over(region)
}

**PART E - simple random sample size 400

use families, clear
sample 400, count

*do households led by someone with no high school diploma earn less that households led by someone with a high school diploma?

graph box income, over(no_hs)

**PART F - stratification

qui sum income 
di r(mean) // point estimate
di sqrt(r(Var)/r(N)) // standard error of estimate
di r(mean)-z95*sqrt(r(Var)/r(N)) r(mean)+z95*sqrt(r(Var)/r(N)) // confidence interval

*sample
use families, clear
sample 100, by(region) count
scalar sample_size = 100

foreach i of numlist 1/4 {
	count if region == `i'
	scalar prop_`i' = r(N)/sample_size
	qui sum income if region == `i'
	scalar mean_`i' = r(mean)
	scalar se_`i' = sqrt(r(Var)/r(N))
	scalar c95_`i'_l = r(mean)-z95*sqrt(r(Var)/r(N))
	scalar c95_`i'_h = r(mean)+z95*sqrt(r(Var)/r(N))
	scalar sum_`i' = mean_`i'*prop_`i'
}

qui sum income 
di r(mean) // point estimate
di sqrt(r(Var)/r(N)) // standard error of estimate
di r(mean)-z95*sqrt(r(Var)/r(N)) r(mean)+z95*sqrt(r(Var)/r(N)) // confidence interval
