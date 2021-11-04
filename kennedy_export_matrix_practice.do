*Practice Exporting Matrices
*Aja Kennedy
*10/27/2021

clear all
set more off

local excel_date "11_03_2021" //to later name files with today's date
local excel "/Users/ajakennedy/Box/Git Folder" //to save in my Git Folder on Box

sysuse auto, clear //read in example data set

local col=1
local row=1 //we'll use these for loops later

matrix results=J(150,400,.) //create a matrix. . .why the "."?

*For purposes of the exercise, we'll run a regression just to practice exporting the beta coefficients and standard errors into a matrix later.

local indepvars mpg weight length //creating a macro with independent variables for the regression

reg price `indepvars' //We're not concerned about theoretical underpinnings here (leave the collinearity alone), just wanting to export results.

return list //so we can see how STATA prints the results

foreach var in `indepvars' {
	matrix results[`row',`col']=_b[`var']
	matrix results[`row'+1,`col']=_se[`var']
	local row=`row'+2

}

clear //what exactly are we clearing here?
svmat results //understand more about what this line is doing?
br //take a look at results

*exporting the matrix
export excel using "`excel'/kennedy_export_matrix_practice_`excel_date'.xlsx", sheet("sheet 1") cell (B2) sheetmodify

*Now let's practice splitting these up by automobile type (foreign v. domestic):

sysuse auto, clear //get our data set back into stata's active memory
reg price `indepvars' if foreign==0
reg price mpg weight length if foreign==0

local row=1 //resetting row back to 1

foreach cartype in 0 1 {
	reg price `indepvars' if foreign==`cartype'
	foreach var in `indepvars' {
	matrix results[`row',`col']=_b[`var']
	matrix results[`row'+1,`col']=_se[`var']
	local row=`row'+2
	}
	local row=1
	local col=`col'+1
}

clear
svmat results
br
	
export excel using "`excel'/kennedy_export_matrix_practice_`excel_date'.xlsx", sheet("sheet 2") cell(B2) sheetmodify
