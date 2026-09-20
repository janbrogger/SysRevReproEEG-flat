* Table 3: Summary statistics for Manuscript 2 - Epileptiform Discharges yes/no
* Based on Table 4 from Manuscript 1 (seizures yes/no) - Aanestad et al. 2024
*
* Produces ONE table with rows for each stratum. Statistics are study-level:
* first collapse to one median per REFID within each stratum, then compute
* median, min, max across studies. More defensible than data-point-level
* medians given Zijlmans (28 pts) and Tjepkema-Cloostermans (23 pts)
* contributing ~45% of interrater kappa points.
*
* Stratified by:
*   - Agreement type (Agreement / Kappa-type)
*   - Rater comparison (Intrarater / Interrater)
*   - Study design (Short Clips / Per-EEG)
*   - Subgroup: Overall, Clinical setting (Epilepsy / Acute Brain / Other)
*
* Output: single Excel file with one sheet, formatted with caption, merged
*         header groups, N studies, 2-decimal numbers, and (min-max) range
*         columns.
* Uses same filtered_data.dta as Figure 1 forest plots.

version 18
clear all
set more off

cap log close
cd "C:\Midlertidig_Lagring\SysRevReproEeg\6Manuscript2\v6"
local logfile "3log/Table3"
log using "`logfile'.smcl", replace

pwd

*==============================================================================
* Load filtered data (same as Figure 1)
*==============================================================================

use "2data/data_long_feature.dta", clear
count
local totalobs = `r(N)'
di "Total observations loaded: `totalobs'"

*==============================================================================
* Create EEG Setting variable (same as Figure 1)
*==============================================================================


*==============================================================================
* gShortClips variable (same as Figure 1)
*==============================================================================

di _n "=== gShortClips classification ==="
tab gShortClips
tab Author gShortClips if gShortClips == 1, mis

*==============================================================================
* Keep only Agreement and Kappa-type statistics (same as Figure 1)
*==============================================================================

tab agreementType3
keep if agreementType3 == "Agreement" | agreementType3 == "Kappa-type"
count
di "Observations after filtering to Agreement/Kappa-type: `r(N)'"

*==============================================================================
* Diagnostics to log
*==============================================================================

di _n "=== Cross-tabulation: Agreement type x Rating type ==="
tab agreementType3 intra_or_inter

di _n "=== Cross-tabulation: Agreement type x Short clips ==="
tab agreementType3 gShortClips

di _n "=== Cross-tabulation: Agreement type x Clinical setting ==="
tab agreementType3 gEEGSetting

di _n "=== Data points per study (REFID) - interrater kappa ==="
tab Author if agreementType3 == "Kappa-type" & intra_or_inter == "No"

*==============================================================================
* Build unified results table using postfile
*==============================================================================

di _n(3) "============================================================"
di "Building unified Table 3"
di "============================================================"

tempname handle
tempfile resultsfile
postfile `handle' ///
	str12 agreement_type ///
	str12 rater_type ///
	str12 study_design ///
	str20 subgroup ///
	int n_studies int n_datapoints ///
	double(median_study min_study max_study) ///
	using `resultsfile'

* Loop over all strata
foreach atype in "Agreement" "Kappa-type" {
	foreach rtype in "Yes" "No" {
		if "`rtype'" == "Yes" local rlabel "Intrarater"
		if "`rtype'" == "No"  local rlabel "Interrater"

		foreach sdesign in 1 0 {
			if `sdesign' == 1 local slabel "Short Clips"
			if `sdesign' == 0  local slabel "Per-EEG"

			* Build base selection
			cap drop _sel
			gen byte _sel = (agreementType3 == "`atype'" & intra_or_inter == "`rtype'" & gShortClips == `sdesign')

			* ---- By clinical setting ----
			foreach setting in "Epilepsy" "Acute Brain" "Other" "First seizure" {
				cap drop _subsel
				gen byte _subsel = _sel * (gEEGSetting == "`setting'")

				qui count if _subsel
				local n_dp = `r(N)'

				if `n_dp' == 0 {
					post `handle' ("`atype'") ("`rlabel'") ("`slabel'") ("`setting'") ///
						(0) (0) (.) (.) (.)
				}
				else {
					preserve
					qui keep if _subsel
					collapse (median) med_agr = agreementvalue, by(REFID)
					local n_st = _N
					qui summ med_agr, det
					local sl_med = `r(p50)'
					local sl_min = `r(min)'
					local sl_max = `r(max)'
					restore

					post `handle' ("`atype'") ("`rlabel'") ("`slabel'") ("`setting'") ///
						(`n_st') (`n_dp') (`sl_med') (`sl_min') (`sl_max')
				}
				cap drop _subsel
			}

			cap drop _sel
		}
	}
}

postclose `handle'

*==============================================================================
* Load results, reshape wide (intrarater beside interrater), and export
*==============================================================================

use `resultsfile', clear

* Drop datapoint counts -- not needed in final table (keep n_studies)
drop n_datapoints

* Create numeric rater_type for reshape
gen rtype = 1 if rater_type == "Interrater"
replace rtype = 2 if rater_type == "Intrarater"
drop rater_type

* Reshape wide: interrater and intrarater columns side by side
reshape wide n_studies median_study min_study max_study, ///
	i(agreement_type study_design subgroup) j(rtype)

* Rename for readable variable names
rename n_studies1    inter_n
rename median_study1 inter_median
rename min_study1    inter_min
rename max_study1    inter_max
rename n_studies2    intra_n
rename median_study2 intra_median
rename min_study2    intra_min
rename max_study2    intra_max

* Sort into readable order
gen _s1 = (agreement_type == "Kappa-type")
gen _s2 = (study_design == "Per-EEG")
gen _s3 = cond(subgroup == "Epilepsy", 0, ///
	cond(subgroup == "Acute Brain", 1, 2))
sort _s1 _s2 _s3
drop _s1 _s2 _s3

* Peer review revision 1: display label "Known epilepsy" (internal category
* value stays "Epilepsy" throughout the data and scripts)
replace subgroup = "Known epilepsy" if subgroup == "Epilepsy"

*==============================================================================
* Create formatted string columns
*==============================================================================

* en-dash character for range separator
local endash = uchar(8211)

* N studies: show as integer string, blank if 0
gen str4 inter_n_fmt = ""
replace inter_n_fmt = string(inter_n, "%3.0f") if inter_n > 0

gen str4 intra_n_fmt = ""
replace intra_n_fmt = string(intra_n, "%3.0f") if intra_n > 0

* Interrater: formatted median
gen str8 inter_med_fmt = ""
replace inter_med_fmt = string(inter_median, "%5.2f") if !missing(inter_median)

* Interrater: formatted (min-max) range
gen str20 inter_range = ""
replace inter_range = "(" + string(inter_min, "%5.2f") + "`endash'" ///
	+ string(inter_max, "%5.2f") + ")" if !missing(inter_min)

* Intrarater: formatted median
gen str8 intra_med_fmt = ""
replace intra_med_fmt = string(intra_median, "%5.2f") if !missing(intra_median)

* Intrarater: formatted (min-max) range
gen str20 intra_range = ""
replace intra_range = "(" + string(intra_min, "%5.2f") + "`endash'" ///
	+ string(intra_max, "%5.2f") + ")" if !missing(intra_min)

* Display full table in log
di _n(2) "=== COMPLETE TABLE 3 ==="
list agreement_type study_design subgroup ///
	inter_n_fmt inter_med_fmt inter_range ///
	intra_n_fmt intra_med_fmt intra_range, ///
	sep(4) abbreviate(22) noobs

*==============================================================================
* Detailed per-study listing for the 4 main cells (log only)
*==============================================================================

di _n(3) "============================================================"
di "Per-study data point counts (for log reference)"
di "============================================================"

* Save the results dataset before reloading analysis data
tempfile final_results
save `final_results'

use "2data/data_long_feature.dta", clear
keep if agreementType3 == "Agreement" | agreementType3 == "Kappa-type"

foreach atype in "Agreement" "Kappa-type" {
	foreach rtype in "Yes" "No" {
		if "`rtype'" == "Yes" local rlabel "Intrarater"
		if "`rtype'" == "No"  local rlabel "Interrater"

		di _n "--- `atype' / `rlabel' ---"

		preserve
		keep if agreementType3 == "`atype'" & intra_or_inter == "`rtype'"
		collapse (median) med_agr = agreementvalue ///
			(count) n_dp = agreementvalue, by(REFID Author)
		gsort -n_dp
		list Author REFID n_dp med_agr, sep(0) noobs
		restore
	}
}

*==============================================================================
* Export formatted table to Excel using putexcel
*==============================================================================

use `final_results', clear

local outexcel "4output/Table 3 IED Summary Statistics.xlsx"
* Peer review revision 1: start from an empty template that has landscape page
* orientation (A4, fit to width) already set, and open it with -modify- so the
* page setup survives. putexcel/mata xl() cannot set page orientation directly.
copy "1script-stata/Table3-template.xlsx" "`outexcel'", replace

local caption "Table 3: Interictal epileptiform detection aggregate reproducibility measures Median (range) agreement- and kappa-type reproducibility, interrater and intrarater, by clinical setting and EEG length in a systematic review of the reproducibility of visual analysis of clinical EEG."

putexcel set "`outexcel'", sheet("Table 3") modify open

*----------------------------------------------------------------------
* Row 1: Caption (merged A1:I1)
*----------------------------------------------------------------------

putexcel A1:I1 = "`caption'", merge ///
	font("Arial", 10, black) italic bold ///
	txtwrap

*----------------------------------------------------------------------
* Row 2: blank separator (thin row)
*----------------------------------------------------------------------

putexcel A2 = ""

*----------------------------------------------------------------------
* Row 3: Grouped headers -- Interrater / Intrarater
*----------------------------------------------------------------------

putexcel D3:F3 = "Interrater", merge ///
	font("Arial", 10, black) bold ///
	hcenter vcenter border(bottom, thin)
putexcel G3:I3 = "Intrarater", merge ///
	font("Arial", 10, black) bold ///
	hcenter vcenter border(bottom, thin)

*----------------------------------------------------------------------
* Row 4: Column sub-headers with bottom border
*----------------------------------------------------------------------

local hdropts `"font("Arial", 10, black) bold hcenter vcenter border(bottom, medium)"'

putexcel A4 = "Agreement type",   `hdropts'
putexcel B4 = "Study design",     `hdropts'
putexcel C4 = "Clinical setting", `hdropts'
putexcel D4 = "N",                `hdropts'
putexcel E4 = "Median",           `hdropts'
putexcel F4 = "(Range)",          `hdropts'
putexcel G4 = "N",                `hdropts'
putexcel H4 = "Median",           `hdropts'
putexcel I4 = "(Range)",          `hdropts'

*----------------------------------------------------------------------
* Data rows (starting at Excel row 5)
*----------------------------------------------------------------------

local N = _N
local datacellstyle `"font("Arial", 10, black) hcenter vcenter"'
local textcellstyle `"font("Arial", 10, black) left vcenter"'

forvalues i = 1/`N' {
	local exrow = `i' + 4

	* Text columns (left-aligned)
	local val_atype = agreement_type[`i']
	local val_sdes  = study_design[`i']
	local val_subgr = subgroup[`i']
	putexcel A`exrow' = "`val_atype'", `textcellstyle'
	putexcel B`exrow' = "`val_sdes'",  `textcellstyle'
	putexcel C`exrow' = "`val_subgr'", `textcellstyle'

	* Interrater: N, median, range (center-aligned)
	local val_in   = inter_n_fmt[`i']
	local val_imed = inter_med_fmt[`i']
	local val_iran = inter_range[`i']
	putexcel D`exrow' = "`val_in'",   `datacellstyle'
	putexcel E`exrow' = "`val_imed'", `datacellstyle'
	putexcel F`exrow' = "`val_iran'", `datacellstyle'

	* Intrarater: N, median, range (center-aligned)
	local val_an   = intra_n_fmt[`i']
	local val_amed = intra_med_fmt[`i']
	local val_aran = intra_range[`i']
	putexcel G`exrow' = "`val_an'",   `datacellstyle'
	putexcel H`exrow' = "`val_amed'", `datacellstyle'
	putexcel I`exrow' = "`val_aran'", `datacellstyle'

	* Bottom border on last data row
	if `i' == `N' {
		putexcel A`exrow' = "`val_atype'", `textcellstyle' border(bottom, thin)
		putexcel B`exrow' = "`val_sdes'",  `textcellstyle' border(bottom, thin)
		putexcel C`exrow' = "`val_subgr'", `textcellstyle' border(bottom, thin)
		putexcel D`exrow' = "`val_in'",    `datacellstyle' border(bottom, thin)
		putexcel E`exrow' = "`val_imed'",  `datacellstyle' border(bottom, thin)
		putexcel F`exrow' = "`val_iran'",  `datacellstyle' border(bottom, thin)
		putexcel G`exrow' = "`val_an'",    `datacellstyle' border(bottom, thin)
		putexcel H`exrow' = "`val_amed'",  `datacellstyle' border(bottom, thin)
		putexcel I`exrow' = "`val_aran'",  `datacellstyle' border(bottom, thin)
	}
}

putexcel save

*----------------------------------------------------------------------
* Column widths and row heights via Mata
*----------------------------------------------------------------------

cap {
	mata: b = xl()
	mata: b.load_book("`outexcel'")
	mata: b.set_sheet("Table 3")
	mata: b.set_column_width(1, 1, 16)
	mata: b.set_column_width(2, 2, 14)
	mata: b.set_column_width(3, 3, 16)
	mata: b.set_column_width(4, 4, 6)
	mata: b.set_column_width(5, 5, 12)
	mata: b.set_column_width(6, 6, 16)
	mata: b.set_column_width(7, 7, 6)
	mata: b.set_column_width(8, 8, 12)
	mata: b.set_column_width(9, 9, 16)
	mata: b.set_row_height(1, 1, 50)
	mata: b.set_row_height(2, 2, 6)
	mata: b.close_book()
}

di _n "Table 3 saved to: `outexcel'"

*==============================================================================
* Finish
*==============================================================================

count
cap log close
cap translate "`logfile'.smcl" "`logfile'.pdf"

di _n "Done!"
