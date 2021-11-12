/***************************************************************************
*Title: TargetSmart Descriptive tables
*Created by: Aja Kennedy
*Created on: 11/11/2021
*Last modified on: 11/11/2021
*Last modified by: Aja Kennedy
*Purpose: Early exploration of TargetSmart dataset for RQ2
*Notes: Dataset created in rq2_data_prep.do


***************************************************************************/
* set paths, filenames, and dates
do "E:\METCO\programs\headers\RQ2_header_and_paths.do"

/*
local mcasdate "20200820" // "062818"
local simsdate "08_20_2020" //" 04_08_2019"
local epims_date "10_27_2020"
local analysisfile "rq2_outcomes_controls_baselines_cohortspace"
local combined     "E:\METCO\data\intermediary_data\combined_data"
local graphs       "E:\METCO\tables\Graphs"

local tablesfile   "RQ2_Table_Deck_v16_clivepractice_raw"

sysdir set PLUS "E:\METCO\ado\plus"

* Box Export
local box_export "C:\Users\skochi02\Box\METCO\Presentations\Presentation_figures\RQ2_modern"
*/

*if `desc_dist_SIMS'==1 { // can embed this code in a switch later if needed.

*Use data set that appears to be the best current SIMS-TS match
use "E:\METCO\data\intermediary_data\targetsmart\SIMS\exact_merge_matches\SIMS_merged.dta", clear
*This doesn't have the whole SIMS data set on it. . .should I find another data set that has been merged?

mat results = J(400,400,.)
local row=1
local col=1
 
*use  "${analysisdata}/`analysisfile'.dta", clear

foreach loc in `locations' {
	foreach dist in `desc_district_categ' {
	di "DIST TYPE: `dist'" // display the name of the district type
		foreach cov in `bline_chars' bline_3rd_mcas_c_ela bline_3rd_mcas_c_math bline_mg_mcas_c_ela bline_mg_mcas_c_math mcas_c_ela mcas_c_math {
			sum `cov' if `loc'_`dist' == 1 & `sample_c3'
			matrix results[`row',`col']=`r(mean)'
			local ++row
		} // end cov
		* Get N for each district type - test takers
		local ++row
		matrix results[`row',`col']=`r(N)'
		
		* Get N for each district type - all students
		local ++row
		count if `loc'_`dist' == 1 
		matrix results[`row',`col']=`r(N)'
		local ++row
		
		*Get # unique students - all students
		distinct sasid  if `loc'_`dist' == 1 
		matrix results[`row',`col']=`r(ndistinct)'
		local ++row
		*Get # years 
		inspect year if `loc'_`dist' == 1 
		matrix results[`row',`col']=`r(N_unique)'
		local ++row
		*Get # schools 
		distinct school_for_fes if `loc'_`dist' == 1
		matrix results[`row',`col']=`r(ndistinct)'
		local ++col
		local row=1
		
	} // end dist categories
	local ++col
*} // end location types

* Export
clear
svmat results
export excel using "/Users/ajakennedy/Box/Git Folder/TargetSmart.xlsx", sheet(desc_r) sheetreplace cell(C4)
*export excel using "${tables}/`tablesfile'.xlsx", sheet("desc_r") sheetreplace cell(C4)
