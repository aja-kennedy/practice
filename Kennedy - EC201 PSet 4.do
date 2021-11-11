// Aja Kennedy
// EC 201 Statistics
// PSet 5 Due Nov 10

clear all // clear stata memory
set obs 10000 // create 10,000 observations
set seed 10232013 // generate a random(ish) sequence for the observations
capture log close
log using "/Users/ajakennedy/Box/Git Folder/Kennedy_EC201PSet4.log", replace


//PART A

gen health_cost = rnormal(9000,3000) // healthcare costs distributed normally (9000, 3000)

// PART B - WHO OPTS INTO INSURANCE IN ROUND ONE?

scalar penalty = 0

qui sum health_cost
scalar mean1 = r(mean) // health insurance premium in round one
gen optin_round1 = cond(health_cost + penalty > mean1,1,0) // binary variable indicating whether someone opts into insurance in round 1
qui sum optin_round1
scalar share1 = r(mean) // share of population who opts into health insurance in round one

di mean1 // health insurance premium in round one
di share1 // share of population opting into insurance in round one

//PART C - WHO OPTS INTO INSURANCE IN ROUNDS TWO AND THREE?

foreach i in 1 2 {
	
	qui summ health_cost if optin_round`i'==1 // summarize health costs of people insured in the previous round
	local i =`i'+1 // redefine i, add one
	scalar mean`i' = r(mean) // health insurance premium this round
	gen optin_round`i' = cond(health_cost + penalty > mean`i',1,0) // indicator for opting into insurance this round
	qui sum optin_round`i'
	scalar share`i' = r(mean) // share of population opting into insurance this round
	
}

di mean2 // health insurance premium round 2
di mean3 // health insurance premium round 3

di share2 // share of population opting into insurance in round 2
di share3 // share of population opting into insurance in round 3


//PART D,E - WHAT IF THERE IS A $500 PENALTY FOR NOT HAVING HEALTH INSURANCE?
//Same code as above, rerun with $500 penalty applied:

scalar penalty = 500
drop optin_round1 optin_round2 optin_round3

gen optin_round1 = cond(health_cost + penalty > mean1,1,0) // binary variable indicating whether someone opts into insurance in round 1
qui sum optin_round1
scalar share1 = r(mean) // share of population who opts into health insurance in round 1

foreach i in 1 2 {
	
	qui summ health_cost if optin_round`i'==1 // summarize health costs of people insured in the previous round
	local i =`i'+1 // redefine i, add one
	scalar mean`i' = r(mean) // health insurance premium this round
	gen optin_round`i' = cond(health_cost + penalty > mean`i',1,0) // indicator for opting into insurance this round
	qui sum optin_round`i'
	scalar share`i' = r(mean) // share of population opting into insurance this round
	
}


di share1 // share of population opting into insurance in round 1
di share2 // share of population opting into insurance in round 2
di share3 // share of population opting into insurance in round 3

di mean2 // insurance premium round 2

*In order to maintain the same number of insured individuals in rounds 1 and 2:

di mean2 - mean1 + penalty // penalty needed in year 2 to maintain same level of participation as year 1

//PART F - IN WRITE-UP


// PART G - WHAT IF THE PENALTY STAYED CONSTANT AT $500?

di mean2 // health insurance premium round 2
di mean3 // health insurance premium round 3

di share2 // share of population opting into insurance in round 2
di share3 // share of population opting into insurance in round 3

// PART H - WHAT IF THE PENALTY WAS $1000?

scalar penalty = 1000
drop optin_round1 optin_round2 optin_round3


gen optin_round1 = cond(health_cost + penalty > mean1,1,0) // binary variable indicating whether someone opts into insurance in round 1
qui sum optin_round1
scalar share1 = r(mean) // share of population who opts into health insurance in round 1

foreach i in 1 2 {
	
	qui summ health_cost if optin_round`i'==1 // summarize health costs of people insured in the previous round
	local i =`i'+1 // redefine i, add one
	scalar mean`i' = r(mean) // health insurance premium this round
	gen optin_round`i' = cond(health_cost + penalty > mean`i',1,0) // indicator for opting into insurance this round
	qui sum optin_round`i'
	scalar share`i' = r(mean) // share of population opting into insurance this round
	
}

di mean1 // health insurance premium round 1
di mean2 // health insurance premium round 2
di mean3 // health insurance premium round 3

di share1 // share of population opting into insurance in round 1
di share2 // share of population opting into insurance in round 2
di share3 // share of population opting into insurance in round 3

di mean2 - mean1 + penalty // penalty needed in year 2 to maintain the same level of insurance participation as year 1

log close
