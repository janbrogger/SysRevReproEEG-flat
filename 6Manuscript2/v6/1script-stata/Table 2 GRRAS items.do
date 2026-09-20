* Table 2: GRRAS Quality Items for Manuscript 2 - Epileptiform Discharges
* Adapted from Manuscript 1's Table 2 GRRAS items.do
* This script creates Table 2 showing individual study quality items

version 18
clear all
set more off

* Set working directory - adjust path as needed for your system
* The script assumes working directory is 6Manuscript2/v6/

cap log close
cd "C:\Midlertidig_Lagring\SysRevReproEeg\6Manuscript2\v6"
local logfile "3log/Table2_GRRAS"
log using "`logfile'.smcl", replace

pwd
di "Script expects working directory to be 6Manuscript2/v6/"

*==============================================================================
* Load design-level data filtered to IED studies
*==============================================================================

use "2data/data_short_design.dta", clear

count
local totalstudies = `r(N)'
di "Total IED studies: `totalstudies'"

*==============================================================================
* Calculate mean GRRAS points for each item
*==============================================================================

* Find all GRRAS item variables
* They should be named like Gras01_*, Gras02_*, etc.

preserve

* Get list of GRRAS variables
ds Gras*
local grras_vars `r(varlist)'
di "GRRAS variables found: `grras_vars'"

* Collapse to get means
collapse (mean) `grras_vars'

* Transpose to get one row per GRRAS item
xpose, clear varname
rename v1 Mean
replace Mean = Mean * 100  // Convert to percentage
rename _varname GRRASPoint

* Sort by item number
sort GRRASPoint

* Display results
format Mean %3.0f
list, sep(0) noobs

restore

*==============================================================================
* Create Excel output
*==============================================================================

local excelfile "4output/Table 2 Study quality GRRAS items.xlsx"

* Peer review revision 1: start from an empty template that has landscape page
* orientation (A4, fit to width) already set, and write into it with
* sheet(..., modify) so the page setup survives. putexcel/export excel cannot
* set page orientation directly.
copy "1script-stata/Table2-template.xlsx" "`excelfile'", replace

* First export the collapsed data
preserve
ds Gras*
local grras_vars `r(varlist)'
collapse (mean) `grras_vars'
xpose, clear varname
rename v1 Mean
replace Mean = Mean * 100
rename _varname GRRASPoint
sort GRRASPoint
export excel using "`excelfile'", sheet("Sheet1", modify) firstrow(varlabels) cell("A2")
restore

* Now add formatted headers
putexcel set "`excelfile'", sheet("Sheet1") modify

putexcel A1=("Table 2: Individual study quality items according to the GRRAS checklist for epileptiform discharge detection studies"), txtwrap
putexcel (A1:B1), merge
putexcel A2=("GRRAS item")
putexcel B2=("% of studies"), txtwrap

* Add descriptive labels for each GRRAS item
putexcel A3=("1. Reliability mentioned in title or abstract")
putexcel A4=("2. EEG is described to allow replication")
putexcel A5=("3. Subject population described to allow replication")
putexcel A6=("4. Target rater described")
putexcel A7=("5. Rationale given and describes what is already known")
putexcel A8=("6. Sample size explained")
putexcel A9=("7. Recruitment method described")
putexcel A10=("8. Rating process described")
putexcel A11=("9. Independent raters")
putexcel A12=("10. Statistical analysis described")
putexcel A13=("11. Actual number of raters and EEGs")
putexcel A14=("12. Rater characteristics described")
putexcel A15=("13. Statistical uncertainty given")
putexcel A16=("14. Practical consequences discussed")
putexcel A17=("15. Detailed results given")

* Add borders
putexcel (A2:B2), border(bottom)
putexcel (A1:B1), border(top)
putexcel (A1:A17), border(left)
putexcel (B1:B17), border(right)
putexcel (A17:B17), border(bottom)

* Calculate percentages for each GRRAS item and add to column B
local row = 3
forvalues i = 1/15 {
    local varname = "Gras"
    if `i' < 10 {
        local varname = "`varname'0`i'"
    }
    else {
        local varname = "`varname'`i'"
    }

    * Find variables matching this pattern
    cap ds `varname'*
    if _rc == 0 {
        local grras_var = word("`r(varlist)'", 1)
        summ `grras_var', meanonly
        local pct = `r(mean)' * 100
        putexcel B`row' = `pct', nformat("0")
    }
    local row = `row' + 1
}

* Format column widths using mata
cap {
    mata: b = xl()
    mata: b.load_book("`excelfile'")
    mata: b.set_sheet("Sheet1")
    mata: b.set_column_width(1, 1, 50)
    mata: b.set_column_width(2, 2, 15)
    mata: b.close_book()
}

di _n "Table 2 saved to: `excelfile'"

cap log close
cap translate "`logfile'.smcl" "`logfile'.pdf"

/********************************************************************
GRRAS – Rater experience reporting
********************************************************************/

* Locate experience-related variables
lookfor exper

* Target rater population / experience level
tab Q040Targetraterpopulationof

* Were rater/subject characteristics described?
tab Q400

* Self-described as expert
tab Q402

* Self-described as experienced
tab Q403

* Minimum years of rater experience (including missing)
tab RaterExpLengthMin, missing

* Maximum years of rater experience (including missing)
tab RaterExpLengthMax, missing

* Descriptive statistics for quantitative experience (non-missing only)
tabstat RaterExpLengthMin RaterExpLengthMax, ///
    statistics(n median iqr min max)

* Proportion with quantitative experience reported (min years)
count if RaterExpLengthMin < .
display "Proportion with minimum years reported: " r(N)/_N

* Proportion with quantitative experience reported (max years)
count if RaterExpLengthMax < .
display "Proportion with maximum years reported: " r(N)/_N

* Proportion with any quantitative experience reported 
count if RaterExpLengthMin < . | RaterExpLengthMax <.
display "Proportion with any years reported: " r(N)/_N


di _n "Done!"
