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

local create_simsts = 0 // = 1 recreates SIMS-TS file that matches the merge file to SIMS data.
*we need to fix this match and also pull in the non-sasid unique data as well!
local simsts_table = 1 // =1 creates summary table of SIMS-TS matched data

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

STOP (to create error message)

*Compare to original SIMS descriptive stats to see if this lines up or if there are major changes
*(Review with Dr. Setren)

/*********************
For exploration of TS data:
voterbase_id is the unique identifier in TargetSmart data
there is only one observation per individual in TS data
*******************/
*Do we want summary status of all raw TargetSmart data as well?

*create some locals categorizing different variables of interest:
local ts_demog "vbtsmart_dob vbvoterbase_age vbvoterbase_dob vbvoterbase_gender vbvoterbase_race vbvoterbase_marital_status vbvf_race vbvf_dob vbvf_yob vbvf_age vbvoterbase_deceased_flag"
local ts_address "vbtsmart_city vbtsmart_zip vbtsmart_state vbtsmart_address_usps_addre vbvf_source_state vbvf_county_code vbvf_county_name"
local ts_votinginfo "vbvoterbase_registration_status vbvf_voter_status vbvf_registration_date vbvf_earliest_registration_date vbvf_party"
local ts_votinginfo "`ts_voting info' vbvf_pp2008 vbvf_pp2012 vbvf_pp2016 vbvf_pp2020 vbvf_pp2008_party vbvf_pp2012_party vbvf_pp2016_party vbvf_pp2020_party"

*TargetSmart raw data:
use E:\METCO\data\raw_data\targetsmart\tsmart_nber_ma_analytic_install_prev_addresses_20191004\tsmart_nber_ma_analytic_install_prev_addresses_20191004.dta, clear
*Why does this data have zero observations for many variables?
*I think I need to destring the variables or something.

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
