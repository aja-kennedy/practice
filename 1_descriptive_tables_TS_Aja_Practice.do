/***************************************************************************
*Title: TargetSmart and SIMS Descriptive tables
*Created by: Aja Kennedy
*Created on: 11/11/2021
*Last modified on: 11/23/2021
*Last modified by: Aja Kennedy
*Purpose: Early exploration of TargetSmart dataset and TS/SIMS merge for RQ2
*Notes: Dataset created in rq2_data_prep.do

*First, this file merges SIMS raw data (variables of interest) with an abriged SIMS/TS merge file.
*Second, this file (re)creates descriptive tables of SIMS variables of interest using SIMS/TS merged data.
*Third, this file merges TS raw data with an abridged SIMS/TS merge file.
*Finally, this file creates outcome variables of interest using TS data and provides descriptive stats of those outcomes.

***************************************************************************/

* set paths, filenames, and dates, set some locals copied from SIMS descriptive table code:
do "E:\METCO\programs\headers\RQ2_header_and_paths.do"

local mcasdate "20200820" // "062818"
local simsdate "08_20_2020" //" 04_08_2019"
local epims_date "10_27_2020"
local analysisfile "rq2_outcomes_controls_baselines_cohortspace"
local combined     "E:\METCO\data\intermediary_data\combined_data"
local graphs       "E:\METCO\tables\Graphs"
local tablesfile   "RQ2_Table_Deck_v16_clivepractice_raw"

sysdir set PLUS "E:\METCO\ado\plus"

local locations "ma boston springfield"
local desc_district_categ "receive partic send chart nonmetco"
local desc_demogs "female black hisp asian white frl sped lep immig inclu_subsep inclu_partial inclu_full begin_ell interm_ell transition_ell" 
*Student baselines
	local bline_chars ""
		foreach v in `desc_demogs' {
			local bline_chars "`bline_chars' bline_`v'"
		}
local bline_chars "`bline_chars'" // bline_3rd_mcas_c_ela bline_3rd_mcas_c_math bline_mg_mcas_c_ela bline_mg_mcas_c_math "
di "`bline_chars'"

local desc_nontest_demogs "female black hisp asian white frl sped lep"
*Student baselines
	local bline_nontest_chars ""
		foreach v in `desc_nontest_demogs' {
			local bline_nontest_chars "`bline_nontest_chars' bline_`v'"
		}
di "`bline_nontest_chars'"

local sample_c3	"proj_grad4>=2006 & proj_grad4<=2019" // SIMS
local temp "E:\METCO\data\temp\"

* Box Export
*local box_export "C:\Users\skochi02\Box\METCO\Presentations\Presentation_figures\RQ2_modern"

*if `desc_dist_SIMS'==1 { // can embed this code in a switch later if needed.

********************************************************************************
***REPLICATION OF SIMS DESCRIPTIVE STATS USING TS-SIMS MATCHED DATA**
********************************************************************************

*SWITCHES
local create_simsts = 0 // = 1 recreates SIMS-TS file that matches the merge file to SIMS data.
*we need to fix this match and also pull in the non-sasid unique data as well!
local simsts_table = 0 // =1 creates summary table of SIMS-TS matched data
local ts_outcomes = 1 // run code to generate ts outcome variables

if `create_simsts' == 1 {

*code modeled on E:\METCO\programs\data_cleaning\9_target_smart\1b_match_to_sims\SIMS_tsmart_exactmerge.do

*Use TS-SIMS abridged file to match
use "E:\METCO\data\intermediary_data\targetsmart\SIMS\exact_merge_matches\SIMS_merged.dta", clear

*sasid is the SIMS data set's identifier for unique individuals
duplicates report sasid // there appear to be duplicate sasids here; the duplicates were intended to be dropped when this file was created?
duplicates drop sasid, force // drop duplicates for now (will need to fix merge later)
duplicates report sasid // sasid now unique

sort sasid

*save this as a temp file that has the sorted sasid
save "`temp'SIMS_merged_sasidsort", replace

*SIMS data used for analysis:
use  "${analysisdata}/`analysisfile'.dta", clear
sort sasid

* Merge SIMS names with TS-SIMS merge file

capture merge m:1 sasid using "`temp'SIMS_merged_sasidsort", assert(match)
*Might do a little work checking out this merge, but we need to go further back to clean this up.
*This merge is throwing an error, but I think it's still doing what we asked?

*when the merge is cleaned up and ready to go, merge using the line below
*merge m:1 sasid using "E:\METCO\data\intermediary_data\targetsmart\SIMS\exact_merge_matches\SIMS_merged_sasidsort", assert(match)

*we pulled in the whole SIMS analysis dataset, but here are variables of interest listed just in case:
*pull in: `locations'_`dist' (may need to loop here to keep all) `sample_c3' `bline_chars' school_for_fes bline_chars' bline_3rd_mcas_c_ela bline_3rd_mcas_c_math bline_mg_mcas_c_ela bline_mg_mcas_c_math mcas_c_ela mcas_c_math

/*

WHAT ARE THESE LINES OF CODE SUPPOSED TO DO? (FROM SALLY HUDSON NOTES:)

foreach v of local covariates {
assert !missing(‘v’) if sample_table
}

*/

* Keep matched observations
keep if _merge == 3

* Drop the _merge variable
drop _merge

* Generate variable indicating which stage of merging these matches occured in (should I keep an indicator here?)
*gen merge_stage = 1
	
* Save this as an intermediate dataset. This dataset contains all SIMS observations that are a match to TS data.
capture save "`temp'SIMS_merged_full", replace
*when the merge is clean, save using the line below
*save "E:\METCO\data\intermediary_data\targetsmart\SIMS\exact_merge_matches\SIMS_merged_full",replace
}

// we need to pull in the rest of the (non-sasid unique) SIMS data to do this. for now export with unique sasid, then we'll pull in the rest of the data

//somehow my loop below isn't taking means. fix this. we've almost got it.

if `simsts_table' == 1 {

use "`temp'SIMS_merged_full"

mat results = J(400,400,.)
local row=1
local col=1

foreach dist in receive partic { // METCO Suburban Districts and METCO Urban Students, respectively
	*di "DIST TYPE: `dist'" // display the name of the district type
	foreach cov in `bline_nontest_chars' immig bline_3rd_mcas_c_ela bline_3rd_mcas_c_math {
		sum `cov' if `dist'== 1 & `sample_c3'
		matrix results[`row',`col']=`r(mean)'
		local ++row
	} // end cov
	
	*Get N for each district type - test takers
	local ++row // skip an extra line after covariate summaries
	matrix results[`row',`col']=`r(N)'
		
	*Get N for each district type - all students
	local ++row
	count if `dist' == 1 
	matrix results[`row',`col']=`r(N)'
	local ++row
	
	*Get # unique students - all students
	distinct sasid  if `dist' == 1 // don't have to include & `sample_c3'?
	matrix results[`row',`col']=`r(ndistinct)'
	local ++row
	
	*Get # years 
	inspect year if `dist' == 1 
	matrix results[`row',`col']=`r(N_unique)'
	local ++row
	
	*Get # schools 
	distinct school_for_fes if `dist' == 1
	matrix results[`row',`col']=`r(ndistinct)'
	local ++col
	local row=1
		
} // end dist categories

* Export
clear
svmat results
export excel using "${tables}/`tablesfile'.xlsx", sheet("desc_r_SIMSTSmatch") sheetreplace cell(C4)

} // end simsts_table switch

di "`bline_nontest_chars'"

*Compare to original SIMS descriptive stats to see if this lines up or if there are major changes
*(Review with Dr. Setren)

/*********************
For exploration of TS data:
voterbase_id is the unique identifier in TargetSmart data
there is only one observation per individual in TS data
*******************/

/*
TS OUTCOMES OF INTEREST:

Political affiliation (i.e., Democrat or Republican)
Likelihood of registering to vote
Voter participation (i.e., frequency of voting, voting in local elections)
Likelihood of donating to candidates of color and/or PACs focused on issues/policies affecting people of color - FEC but we also have TS data for this and we might want to check it for accuracy

Likelihood of living in a diverse neighborhood as an adult ---- neighborhood traits come from Census, may need to be merged in but are already merged to SIMS - we’re going to be able to do this much finer by addresses

Occupational diversity - TS but we need to merge in occupational information data
Wages and income - TS and labor data - Evan going to work on labor data

Renting/buying a home - in TS
Housing value - in TS

Credit worthiness - in TS
Student loan debt - in TS - I don't see this info in TS
*/

/*
*CREATING LOCALS TO CATEGORIZE DIFFERENT VARIABLES OF INTEREST:

local ts_demog "vbtsmart_dob vbvoterbase_age vbvoterbase_dob vbvoterbase_gender vbvoterbase_race vbvoterbase_marital_status vbvf_race vbvf_dob vbvf_yob vbvf_age vbvoterbase_deceased_flag"
local ts_address "vbtsmart_city vbtsmart_zip vbtsmart_state vbtsmart_address_usps_addre vbvf_source_state vbvf_county_code vbvf_county_name"
local ts_votinginfo "vbvoterbase_registration_status vbvf_voter_status vbvf_registration_date vbvf_earliest_registration_date vbvf_party"

*voting locals -- If we need to create these for some reason we can use a loop to name them
local general_elections "vbvf_g2000 vbvf_g2001 vbvf_g2002 vbvf_g2003 vbvf_g2004 vbvf_g2005 vbvf_g2006 vbvf_g2007 vbvf_g2008 vbvf_g2009 vbvf_g2010 vbvf_g2011 vbvf_g2012 vbvf_g2013"
local primary_elections "vbvf_p2000
local municipal_elections "vbvf_m2000
local presidential_primary "vbvf_pp2000 vbvf_pp2004 vbvf_pp2008 vbvf_pp2012 vbvf_pp2016 vbvf_pp2020"
local presidential_primary_party "vbvf_pp2000_party vbvf_pp2004_party vbvf_pp2008_party vbvf_pp2012_party vbvf_pp2016_party vbvf_pp2020_party"
*/

*TargetSmart raw data:

if `ts_outcomes'==1 {

use E:\METCO\data\raw_data\targetsmart\tsmart_nber_ma_analytic_install_prev_addresses_20191004\tsmart_nber_ma_analytic_install_prev_addresses_20191004.dta, clear

**VOTING OUTCOMES**
*outcomes for 2020 are missing

*Indicator for registered voter
gen registered_voter=vbvoterbase_registration_status=="Registered" // no missing values

*Indicator for active voter
gen active_voter=vbvf_voter_status=="Active"
replace active_voter=. if missing(vbvf_voter_status) // should I replace missing values?

*Frequency of voting

*generating indicators for voting in general, primary, municipal, and presidential primary elections
*raw data codes various outcomes for individuals who voted, the rest are blank

forvalues i = 2000/2020 {
	gen voted_general`i' = vbvf_g`i'!="" // voting history for general elections
	gen voted_primary`i' = vbvf_p`i'!="" // voting history for primary elections
	gen voted_municipal`i' = vbvf_m`i'!="" // voting history for municipal elections
}

**this loop throws an error, but it seems to be working
forvalues i = 2000(4)2020 { // presidential election years
	gen voted_presidential_primary`i' = vbvf_pp`i'!="" // voting history for presidential primary
}

*number of each type of election in which the individual voted
foreach name in general primary municipal presidential_primary{
	egen `name'_frequency = rowtotal(voted_`name'*)
}

*variable that records number of elections in which someone voted
egen all_elections_frequency = rowtotal(voted_general* voted_primary* voted_municipal* voted_presidential_primary*) 

*generating indicators for voting in a particular party in a presidential primary election
*party outcomes are D(Democrat), R(Republican), G(Green), I(Independent), L(Libertarian), N(No Party Preference), O(Other Party), U(Unknown)
forvalues i = 2000(4)2020 {
	gen dem_`i' = vbvf_pp`i'_party=="D" // outcomes are D,R,G,I,L, many observations are blank
	gen rep_`i' = vbvf_pp`i'_party=="R"
	gen other_`i' = vbvf_pp`i'_party!="D" & vbvf_pp`i'_party!="R" vbvf_pp`i'_party!=""
}


*Indicators for party affiliation
gen registered_dem = vbvf_party=="Democrat"
gen registered_rep = vbvf_party == "Republican"
gen registered_other = vbvf_party!="Democrat" & vbvf_party!="Republican" & vbvf_party!=""

*donations
*tbpol_cons_high_val_dd_hh//demi decile conservative high value donor

*HOUSING AND CREDIT OUTCOMES
gen homeowner = vbhomeowner_indicator=="Y" // codebook doesn't define outcomes (Y,N,U)

*tbira_keogh_decile - propensity to have IRA/401K retirement plan (scale of 1-10)
*tbbusiness_owner_flg - 1 or missing
*vbhome_purchase_price - in $1k increments 
*vbmortgage_amount - in $1k increments
*vbloan_to_value_ratio - mortgage/home value ratio
*vbhome_value_amount - in $1k increments
*vbhome_equity_amount - in $1k increments
*vbhousehold_net_worth - outcomes are letters, each assigned to a dollar range in ascending order, defined in codebook
*vbhousehold_income_amount - in $1k increments
*tbita_index - credit worthiness, 1-350

*EDUCATION AND LABOR

*vboccupation
*vbeducation // this and variable below intend to record the same info. this one has fewer missing values
*tbeducation_cd

} // end ts_outcomes switch

STOP to generate error message

*keep variables of interest
keep voterbase_id `ts_demog' `ts_address' `ts_votinginfo'
*I think my variables are not named correctly
sort voterbase_id

merge 1:1 voterbase_id using "E:\METCO\data\intermediary_data\targetsmart\SIMS\exact_merge_matches\SIMS_merged.dta", assert(match) force
keep if _merge==3
drop _merge

*save; these should be TargetSmart observations that are a match for SIMS data.
*they are unique at the voterbase_id level. there are several copies of sasid
*duplicates report sasid
*duplicates report voterbase_id
save "E:\METCO\data\temp\TS_abridged_with_sasid", replace


tab vbvoterbase_race // Afr-Am, Asian, Caucasian, Hispanic, Native American, Uncoded
tab vbvoterbase_gender // Female, Male, Unknown
tab vbvoterbase_marital status // Married, Unknown, Unmarried
tab vb.tsmart_state // 97.39 percent MA
tab vb.voterbase_age // ages 18-41
tab vbvf_pp2008_party // 78% Dem, 22% Rep

*next steps:
*look through and see how we want to summarize
*create shell of excel file
*export some summary status to excel
*could also add some intellibase stats to summarize  
