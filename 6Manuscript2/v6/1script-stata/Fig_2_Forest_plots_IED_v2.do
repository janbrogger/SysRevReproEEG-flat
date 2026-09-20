* Figure 2: Forest plots for Manuscript 2 - Epileptiform Discharges
* Version 2: Short Clips / Per-EEG separation within each panel
* Creates forest plots for IED reproducibility by rater type and agreement type
*
* KEY CHANGE from v1: Each subpanel separates Short Clips studies (top)
* from Per-EEG studies (bottom), with a dashed separator line and group labels.

version 18
clear all
set more off
set scheme stcolor, permanently

* Set working directory - adjust path as needed for your system
* The script assumes working directory is 6Manuscript2/v6/

cap log close


cd "C:\Midlertidig_Lagring\SysRevReproEeg\6Manuscript2\v6"
local logfile "3log/Fig2_ForestPlots_v2"
log using "`logfile'.smcl", replace
pwd

di "Script expects working directory to be 6Manuscript2/v6/"

*==============================================================================
* Load filtered data
*==============================================================================

use "2data/data_long_feature.dta", clear

count
local totalobs = `r(N)'
di "Total observations: `totalobs'"


*==============================================================================
* gShortClips variable
*==============================================================================

di _n "=== gShortClips classification ==="
tab gShortClips
tab Author gShortClips if gShortClips == 1, mis

*==============================================================================
* Keep only Agreement and Kappa-type statistics
*==============================================================================

tab agreementType3
keep if agreementType3 == "Agreement" | agreementType3 == "Kappa-type"

* Report counts per panel with Short Clips breakdown
di _n "=== Observation counts per panel ==="
foreach atype in "Agreement" "Kappa-type" {
    foreach intra in "Yes" "No" {
        local lab = cond("`intra'" == "Yes", "Intra", "Inter")
        qui count if agreementType3 == "`atype'" & intra_or_inter == "`intra'"
        local n = r(N)
        qui count if agreementType3 == "`atype'" & intra_or_inter == "`intra'" & gShortClips == 1
        local nsc = r(N)
        qui count if agreementType3 == "`atype'" & intra_or_inter == "`intra'" & gShortClips == 0
        local npe = r(N)
        di "`lab'rater `atype': Total=`n' (Short Clips=`nsc', Per-EEG=`npe')"
    }
}

*==============================================================================
* Define the forest plot program
*==============================================================================

capture program drop IEDForestPlot
program define IEDForestPlot
    preserve
    syntax [if] [, TITle(string) NAMe(string) XTItle(string) YTItle(string) NOTE(string)]

    if `"`if'"' != `""' {
        qui keep `if'
    }

    qui count
    if `r(N)' == 0 {
        di as err "No observations for this subset"
        restore
        exit
    }

    *------------------------------------------------------------------
    * Create author-year labels
    *------------------------------------------------------------------
    local maxAuthorLen = 12
    local clipLength = `maxAuthorLen' - 1

    cap drop AuthorPlot
    gen AuthorPlot = Author

    * Clip long author names
    qui replace AuthorPlot = substr(AuthorPlot, 1, `clipLength') + "." if strlen(AuthorPlot) > `maxAuthorLen'

    * Add year
    qui replace AuthorPlot = AuthorPlot + " " + string(Year, "%4.0f")

    * Add number of EEG electrodes if available
	qui replace AuthorPlot = AuthorPlot + " ("
    //qui replace AuthorPlot = AuthorPlot + string(NumPatientsIncluded, "%4.0f") if NumPatientsIncluded != .
    //qui replace AuthorPlot = AuthorPlot + "-" if NumPatientsIncluded == .
	//qui replace AuthorPlot = AuthorPlot + "/"
	qui replace AuthorPlot = AuthorPlot + string(NumberOfEegsIncluded, "%4.0f") if NumberOfEegsIncluded != .
    qui replace AuthorPlot = AuthorPlot + "-" if NumberOfEegsIncluded == .
    //qui replace AuthorPlot = AuthorPlot + "/"
	//qui replace AuthorPlot = AuthorPlot + string(NumberOfEegElectFromDesign , "%4.0f") if NumberOfEegElectFromDesign != .
    //qui replace AuthorPlot = AuthorPlot + "-" if NumberOfEegElectFromDesign  == .

    qui replace AuthorPlot = AuthorPlot + ")"

    format agreementvalue %3.2f

    *------------------------------------------------------------------
    * Sort into two groups: Short Clips first, then Per-EEG
    * Within each group, sort by year then author
    *------------------------------------------------------------------
    cap drop _sortgroup
    gen _sortgroup = 0 if gShortClips == 1
    replace _sortgroup = 1 if gShortClips == 0

    gsort _sortgroup Year +Author REFID -gNumberOfEegElectrodes +isaverage +substudy

    *------------------------------------------------------------------
    * Build y-index with hierarchical spacing:
    *   - Small step (within_step) between data points in same study
    *   - Larger step (between_step) between different studies
    *   - Gap between Short Clips and Per-EEG groups
    *
    * This prevents studies with many data points (e.g. Zijlmans 28,
    * Tjepkema-Cloostermans 23) from consuming all vertical space.
    *------------------------------------------------------------------
    qui count if _sortgroup == 0
    local n_clips = `r(N)'
    qui count if _sortgroup == 1
    local n_pereeg = `r(N)'

    * Spacing parameters (adjust to taste)
    local within_step  = 0.2   // between points in same study
    local between_step = 1.1   // between last point of study N and first of N+1
    local group_gap    = 1.0   // empty space between Short Clips and Per-EEG

    cap drop yindex
    gen yindex = .

    * --- Assign positions for Short Clips group ---
    local y = 1
    local prev_refid = .
    forvalues i = 1/`=_N' {
        if _sortgroup[`i'] == 0 {
            local this_refid = REFID[`i']
            if `prev_refid' != . & `this_refid' == `prev_refid' {
                * Same study: small step
                local y = `y' + `within_step'
            }
            else if `prev_refid' != . {
                * New study: larger step
                local y = `y' + `between_step'
            }
            qui replace yindex = `y' in `i'
            local prev_refid = `this_refid'
        }
    }
    local clips_last_y = `y'

    * --- Assign positions for Per-EEG group ---
    local y = `clips_last_y' + `group_gap' + `between_step'
    local pereeg_first_y = `y'
    local prev_refid = .
    forvalues i = 1/`=_N' {
        if _sortgroup[`i'] == 1 {
            local this_refid = REFID[`i']
            if `prev_refid' != . & `this_refid' == `prev_refid' {
                local y = `y' + `within_step'
            }
            else if `prev_refid' != . {
                local y = `y' + `between_step'
            }
            qui replace yindex = `y' in `i'
            local prev_refid = `this_refid'
        }
    }
    local pereeg_last_y = `y'

    * Separator line at midpoint of gap
    local sep_y = `clips_last_y' + (`group_gap' / 2) + (`between_step' / 2)

    * Y-axis range (tight: half-step padding above and below data)
    local ymin = 0.5
    local ymax = `pereeg_last_y' + 0.5

    *------------------------------------------------------------------
    * Handle duplicate author-year labels
    *------------------------------------------------------------------
    qui count
    local N = `r(N)'
    if `N' > 1 {
        * Tag different papers with same author-year
        local previousAuthorPlot = AuthorPlot[1]
        local previousREFID = REFID[1]
        local suffix = 0

        forvalues i = 2/`N' {
            local thisAuthorPlot = AuthorPlot[`i']
            local thisREFID = REFID[`i']

            if "`thisAuthorPlot'" == "`previousAuthorPlot'" & `previousREFID' != `thisREFID' {
                local suffix = `suffix' + 1
                qui replace AuthorPlot = AuthorPlot + " [" + string(`suffix') + "]" if _n == `i'
            }

            local previousAuthorPlot = "`thisAuthorPlot'"
            local previousREFID = `thisREFID'
        }

        * Suppress duplicate labels within same study (keep first only)
        local previousAuthorPlot = AuthorPlot[1]
        local previousREFID = REFID[1]

        forvalues i = 2/`N' {
            local thisAuthorPlot = AuthorPlot[`i']
            local thisREFID = REFID[`i']

            if "`thisAuthorPlot'" == "`previousAuthorPlot'" & `previousREFID' == `thisREFID' {
                qui replace AuthorPlot = "" if _n == `i'
            }
            else {
                local previousAuthorPlot = "`thisAuthorPlot'"
                local previousREFID = `thisREFID'
            }
        }
    }

    *------------------------------------------------------------------
    * Hardcoded deduplication of specific overlapping author-year labels
    *
    * Some studies have several rows that share an author-year but differ
    * only by patient/snippet count, which prints multiple labels on top of
    * each other. For these (hardcoded) studies we show a single label:
    * the two counts are combined as (n1/n2), or shown once as (n) when the
    * counts are identical. The label is placed on the topmost matching row
    * and the remaining matching rows are blanked.
    *------------------------------------------------------------------
    local dd_n = 6
    local dd_auth1 "Jing"
    local dd_year1 2020
    local dd_lab1  "Jing 2020 (13262/1051)"
    local dd_auth2 "Yuan"
    local dd_year2 2025
    local dd_lab2  "Yuan 2025 (200/100)"
    local dd_auth3 "Azuma"
    local dd_year3 2003
    local dd_lab3  "Azuma 2003 (50/100)"
    local dd_auth4 "Stroink"
    local dd_year4 2006
    local dd_lab4  "Stroink 2006 (72/39)"
    local dd_auth5 "van Donselaar"
    local dd_year5 1992
    local dd_lab5  "van Donsela. 1992 (25/50)"
    local dd_auth6 "Kural"
    local dd_year6 2020
    local dd_lab6  "Kural 2020 (100)"

    forvalues k = 1/`dd_n' {
        local a  "`dd_auth`k''"
        local yr `dd_year`k''
        local lb "`dd_lab`k''"
        local placed = 0
        forvalues i = 1/`=_N' {
            if Author[`i'] == "`a'" & Year[`i'] == `yr' {
                if `placed' == 0 {
                    qui replace AuthorPlot = "`lb'" in `i'
                    local placed = 1
                }
                else {
                    qui replace AuthorPlot = "" in `i'
                }
            }
        }
    }

    *------------------------------------------------------------------
    * Author label x-position
    *------------------------------------------------------------------
    cap drop authorx
    gen authorx = -0.40

    *------------------------------------------------------------------
    * Build graph options
    *------------------------------------------------------------------
    if "`name'" != "" {
        cap graph drop `name'
        local name_opt " name(`name') "
    }
    else {
        local name_opt ""
    }

    * Build gridline list at study-level positions (first point of each study)
    * This avoids cluttered gridlines within multi-point studies
    cap drop _study_first
    gen _study_first = 0
    local prev_refid = .
    forvalues i = 1/`=_N' {
        if yindex[`i'] != . {
            local this_refid = REFID[`i']
            if `this_refid' != `prev_refid' {
                qui replace _study_first = 1 in `i'
            }
            local prev_refid = `this_refid'
        }
    }

    local ylines ""
    forvalues i = 1/`=_N' {
        if _study_first[`i'] == 1 {
            local this_y = yindex[`i']
            local ylines "`ylines' `this_y'"
        }
    }

    * Separator line and group labels (separate locals for clean expansion)
    local sep_line ""
    local grp_label1 ""
    local grp_label2 ""

    if `n_clips' > 0 & `n_pereeg' > 0 {
        * Dashed separator line
        local sep_line "yline(`sep_y', lw(medthin) lcol(cranberry) lp(dash))"

        * Group labels placed near right edge, just above each group
        local clips_label_y = 0.55
        local pereeg_label_y = `pereeg_first_y' - 0.4
        local label_x = 0.95

        local grp_label1 `"text(`clips_label_y' `label_x' "Short Clips", size(vsmall) color(cranberry) placement(w))"'
        local grp_label2 `"text(`pereeg_label_y' `label_x' "Per-EEG", size(vsmall) color(cranberry) placement(w))"'
    }

    *------------------------------------------------------------------
    * Draw the forest plot
    *------------------------------------------------------------------
	local msiz 1.0
    twoway ///
        (scatter yindex agreementvalue if gEEGSetting == "Epilepsy", ///
            msiz(`msiz') ysc(rev) mcol(navy) msym(circle)) ///
        (scatter yindex agreementvalue if gEEGSetting == "Acute Brain", ///
            msiz(`msiz') ysc(rev) mcol(forest_green) msym(triangle)) ///
        (scatter yindex agreementvalue if gEEGSetting == "Other", ///
            msiz(`msiz') ysc(rev) mcol(dkorange) msym(square)) ///
		(scatter yindex agreementvalue if gEEGSetting == "First seizure", ///
            msiz(`msiz') ysc(rev) mcol(red) msym(diamond)) ///
        (rcap agreementConfidenceIntervalLower agreementConfidenceIntervalUpper yindex ///
            if gEEGSetting == "Epilepsy" ///
            & agreementConfidenceIntervalLower != . ///
            & agreementConfidenceIntervalUpper != ., ///
            horizontal ysc(rev) lcol(navy)) ///
        (rcap agreementConfidenceIntervalLower agreementConfidenceIntervalUpper yindex ///
            if gEEGSetting == "Acute Brain" ///
            & agreementConfidenceIntervalLower != . ///
            & agreementConfidenceIntervalUpper != ., ///
            horizontal ysc(rev) lcol(forest_green)) ///
        (rcap agreementConfidenceIntervalLower agreementConfidenceIntervalUpper yindex ///
            if gEEGSetting == "Other" ///
            & agreementConfidenceIntervalLower != . ///
            & agreementConfidenceIntervalUpper != ., ///
            horizontal ysc(rev) lcol(dkorange)) ///
        (rcap agreementConfidenceIntervalLower agreementConfidenceIntervalUpper yindex ///
            if gEEGSetting == "First seizure" ///
            & agreementConfidenceIntervalLower != . ///
            & agreementConfidenceIntervalUpper != ., ///
            horizontal ysc(rev) lcol(red)) ///
		(scatter yindex authorx, ///
            mlab(AuthorPlot) mlabsize(1.45) mlabcol(black) ms(none) ysc(rev)) ///
        , legend(off) ///
        ylab(, nolab notick) ///
        yscale(lstyle(none) range(`ymin' `ymax')) ///
        yline(`ylines', lw(vvvthin) lcol(gs14)) ///
        `sep_line' ///
        `grp_label1' ///
        `grp_label2' ///
        title("`title'", size(small) margin(b=1)) `name_opt' ///
        xtitle("`xtitle'", size(small) margin(t=1)) ///
        ytitle("") ///
        note("`note'") ///
        xlab(0 0.25 0.5 0.75 1.0, format(%3.2f) labsize(vsmall)) ///
        xline(0 1, lcol(black) lw(vthin)) ///
        plotregion(margin(t=1 b=1)) ///
        graphregion(margin(t=2 b=2 l=0 r=0))

    restore
end

*==============================================================================
* Create the four forest plots
*==============================================================================

set graphics off

IEDForestPlot if agreementType3 == "Agreement" & intra_or_inter == "Yes", ///
    title("Intrarater Agreement") name(agree_intra) xtitle("Agreement") ytitle("")

IEDForestPlot if agreementType3 == "Agreement" & intra_or_inter == "No", ///
    title("Interrater Agreement") name(agree_inter) xtitle("Agreement") ytitle("")

IEDForestPlot if agreementType3 == "Kappa-type" & intra_or_inter == "Yes", ///
    title("Intrarater Kappa") name(kappa_intra) xtitle("Kappa") ytitle("")

IEDForestPlot if agreementType3 == "Kappa-type" & intra_or_inter == "No", ///
    title("Interrater Kappa") name(kappa_inter) xtitle("Kappa") ytitle("")

set graphics on

*==============================================================================
* Combine plots into 2x2 figure
*==============================================================================

graph combine agree_intra agree_inter kappa_intra kappa_inter, ///
    cols(2) ///
    imargin(vsmall) ///
    graphregion(margin(l=0 r=0 t=1 b=1)) ///
    xsize(7.5) ysize(10) ///
    name(combined_forest)

* Export in multiple formats
graph export "4output/Fig2_ForestPlots_IED.png", replace width(2400) height(2000)
graph export "4output/Fig2_ForestPlots_IED.pdf", replace
cap graph export "4output/Fig1_combined_forest.ps", replace
cap graph export "4output/Fig1_combined_forest.svg", replace
*cap graph export "4output/Fig1_ForestPlots_IED.tif", replace width(5784) height(4820)

di _n "Combined forest plot saved to 4output/"

*==============================================================================
* Summary statistics by Short Clips status
*==============================================================================

di _n(3) _dup(70) "="
di "SUMMARY STATISTICS"
di _dup(70) "="

use "2data/data_long_feature.dta", clear
keep if agreementType3 == "Agreement" | agreementType3 == "Kappa-type"

capture program drop DisplayMeanCI
program define DisplayMeanCI
    syntax [if], label(string)

    preserve
    if `"`if'"' != `""' {
        qui keep `if'
    }

    qui count
    if `r(N)' == 0 {
        di "  `label': -- no observations --"
        restore
        exit
    }

    qui summ agreementvalue, detail
    local n = `r(N)'
    local mean = `r(mean)'
    local sd = `r(sd)'
    local med = `r(p50)'
    local p25 = `r(p25)'
    local p75 = `r(p75)'

    if `n' > 1 {
        local se = `sd' / sqrt(`n')
        local t = invttail(`n' - 1, 0.025)
        local ci_lo = `mean' - `t' * `se'
        local ci_hi = `mean' + `t' * `se'
        di "  `label':"
        di "    n=`n'  Mean=" %5.3f `mean' " (95%CI " %5.3f `ci_lo' " to " %5.3f `ci_hi' ")"
        di "    Median=" %5.3f `med' " (IQR " %5.3f `p25' " to " %5.3f `p75' ")"
    }
    else {
        di "  `label': n=1, value=" %5.3f `mean'
    }

    restore
end

di _n "--- ALL DATA ---"
DisplayMeanCI if agreementType3 == "Kappa-type" & intra_or_inter == "No", ///
    label("Interrater Kappa (all)")
DisplayMeanCI if agreementType3 == "Kappa-type" & intra_or_inter == "Yes", ///
    label("Intrarater Kappa (all)")
DisplayMeanCI if agreementType3 == "Agreement" & intra_or_inter == "No", ///
    label("Interrater Agreement (all)")
DisplayMeanCI if agreementType3 == "Agreement" & intra_or_inter == "Yes", ///
    label("Intrarater Agreement (all)")

di _n "--- SHORT CLIPS ---"
DisplayMeanCI if agreementType3 == "Kappa-type" & intra_or_inter == "No" & gShortClips == 1, ///
    label("Interrater Kappa - Short Clips")
DisplayMeanCI if agreementType3 == "Kappa-type" & intra_or_inter == "Yes" & gShortClips == 1, ///
    label("Intrarater Kappa - Short Clips")
DisplayMeanCI if agreementType3 == "Agreement" & intra_or_inter == "No" & gShortClips == 1, ///
    label("Interrater Agreement - Short Clips")
DisplayMeanCI if agreementType3 == "Agreement" & intra_or_inter == "Yes" & gShortClips == 1, ///
    label("Intrarater Agreement - Short Clips")

di _n "--- PER-EEG ---"
DisplayMeanCI if agreementType3 == "Kappa-type" & intra_or_inter == "No" & gShortClips == 0, ///
    label("Interrater Kappa - Per-EEG")
DisplayMeanCI if agreementType3 == "Kappa-type" & intra_or_inter == "Yes" & gShortClips == 0, ///
    label("Intrarater Kappa - Per-EEG")
DisplayMeanCI if agreementType3 == "Agreement" & intra_or_inter == "No" & gShortClips == 0, ///
    label("Interrater Agreement - Per-EEG")
DisplayMeanCI if agreementType3 == "Agreement" & intra_or_inter == "Yes" & gShortClips == 0, ///
    label("Intrarater Agreement - Per-EEG")

*==============================================================================
* Clean up
*==============================================================================

cap graph drop agree_intra agree_inter kappa_intra kappa_inter

cap log close
cap translate "`logfile'.smcl" "`logfile'.pdf"

di _n "Done!"
