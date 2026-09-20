* Supplementary Table 2: Study characteristics for Manuscript 2 - Epileptiform Discharges
* Converted from R script 03suppltable_1.Rmd
* This script creates Supplementary Table 2 showing detailed characteristics of each study

version 18
clear all
set more off

* Set working directory - adjust path as needed for your system
cd C:\Midlertidig_Lagring\SysRevReproEeg\6Manuscript2\v6\

cap log close
local logfile "3log/Suppl_Table2"
log using "`logfile'.smcl", replace

pwd

*==============================================================================
* Load filtered data
*==============================================================================

* Check if filtered data exists
use "2data/data_long_feature.dta", clear

count
local totalobs = `r(N)'
di "Total observations: `totalobs'"

*==============================================================================
* Create derived variables for the table
*==============================================================================

* Intra-rater label
gen RaterType = ""
replace RaterType = "Intrarater" if intra_or_inter == "Yes"
replace RaterType = "Interrater" if intra_or_inter == "No"

*------------------------------------------------------------------------------
* Derive broad agreement category from narrow type (agreementtype).
* Replaces direct use of agreementType3 from source data, which was blank for
* some rows (e.g. Halford 2013 intrarater: "mean Cohen's kappa").
* Mapping must stay in sync with Block B of 05-abstract-features-on-design-level-v2.do
*------------------------------------------------------------------------------
gen agreementType3_derived = ""

* Agreement (non-aggregate)
replace agreementType3_derived = "Agreement" if agreementtype == "Unadjusted agreement"
replace agreementType3_derived = "Agreement" if agreementtype == "Weighted unadjusted agreement"
replace agreementType3_derived = "Agreement" if agreementtype == "Median agreement"
replace agreementType3_derived = "Agreement" if agreementtype == "Median majority perfect agreement"
replace agreementType3_derived = "Agreement" if agreementtype == "Median pairwise perfect agreement"
replace agreementType3_derived = "Agreement" if agreementtype == "Percent agreement 5 pairs median"

* Kappa-type (non-aggregate)
replace agreementType3_derived = "Kappa-type" if agreementtype == "Cohen's kappa"
replace agreementType3_derived = "Kappa-type" if agreementtype == "Cohen's quadratically weighted kappa"
replace agreementType3_derived = "Kappa-type" if agreementtype == "Fleiss' kappa"
replace agreementType3_derived = "Kappa-type" if agreementtype == "Gwet's AC1"
replace agreementType3_derived = "Kappa-type" if agreementtype == "Gwet's AC2"
replace agreementType3_derived = "Kappa-type" if agreementtype == "Unweighted kappa"
replace agreementType3_derived = "Kappa-type" if agreementtype == "Weighted kappa - quadratic weights"
replace agreementType3_derived = "Kappa-type" if agreementtype == "Weighted kappa - unknown weights"
replace agreementType3_derived = "Kappa-type" if agreementtype == "Weighted kappa - unspecified weights"
replace agreementType3_derived = "Kappa-type" if agreementtype == "Weighted kappa, unknown average method"
replace agreementType3_derived = "Kappa-type" if agreementtype == "Brennan and Prediger kappa"
replace agreementType3_derived = "Kappa-type" if agreementtype == "ICC"
replace agreementType3_derived = "Kappa-type" if agreementtype == "Cronbach's alpha"
replace agreementType3_derived = "Kappa-type" if agreementtype == "Krippendorff's alpha"
replace agreementType3_derived = "Kappa-type" if agreementtype == "Free-Marginal Multirater Kappa (kFree)"
replace agreementType3_derived = "Kappa-type" if agreementtype == "Kappa 5 pairs median"
replace agreementType3_derived = "Kappa-type" if agreementtype == "Spearman-Brown prophecy reliability coefficient"
replace agreementType3_derived = "Kappa-type" if agreementtype == "Median 3-rater kappa"
replace agreementType3_derived = "Kappa-type" if agreementtype == "Median Cohen's kappa"
replace agreementType3_derived = "Kappa-type" if agreementtype == "Median majority kappa"
replace agreementType3_derived = "Kappa-type" if agreementtype == "Median pairwise kappa"
replace agreementType3_derived = "Kappa-type" if agreementtype == "Mean kappa"
replace agreementType3_derived = "Kappa-type" if agreementtype == "Mean or median Kappa 2 raters across neonates"
replace agreementType3_derived = "Kappa-type" if agreementtype == "Mean pairwise Cohen's kappa"

* Kappa-type, aggregate
replace agreementType3_derived = "Kappa-type, aggregate" if agreementtype == "Fleiss' kappa, aggregate"
replace agreementType3_derived = "Kappa-type, aggregate" if agreementtype == "mean Cohen's kappa"

* Unadjusted agreement, aggregate
replace agreementType3_derived = "Unadjusted agreement, aggregate" if agreementtype == "Unadjusted agreement, aggregate"

* Sanity check: any unmapped rows will show here.
count if agreementType3_derived == ""
if `r(N)' > 0 {
    di as error "WARNING: `r(N)' rows have an unmapped agreementtype — fix the mapping above:"
    tab agreementtype if agreementType3_derived == ""
}

* Replace the source variable with the derived one.
drop agreementType3
rename agreementType3_derived agreementType3

* Age group labels
gen AgeGroup = ""
replace AgeGroup = "Neonatal" if gAgeString == "N"
replace AgeGroup = "Pediatric" if gAgeString == "P"
replace AgeGroup = "Adult" if gAgeString == "A"
replace AgeGroup = "Adult+" if inlist(gAgeString, "AG", "PA", "NPA", "NPAG")
replace AgeGroup = gAgeString if AgeGroup == ""

* Format agreement value as string with 2 decimal places
gen AgreementValueRounded = string(round(agreementvalue, 0.01), "%9.2f")

* Combine confidence intervals into single string
gen CI_95 = ""
replace CI_95 = string(agreementConfidenceIntervalLower, "%4.2f") + " - " + string(agreementConfidenceIntervalUpper, "%4.2f") ///
    if agreementConfidenceIntervalLower != . & agreementConfidenceIntervalUpper != .

* Convert LengthEEG to float, then format as string:
*   >= 1 minute: show as integer (e.g. "20")
*   <  1 minute: show with 2 decimals (e.g. "0.17", locale renders as "0,17")
destring LengthEEG, replace force
gen length_eeg_display = ""
replace length_eeg_display = string(LengthEEG, "%9.0f") if LengthEEG != . & LengthEEG >= 1
replace length_eeg_display = string(LengthEEG, "%9.2f") if LengthEEG != . & LengthEEG < 1

* Convert LL08 (clip length in seconds) to float, then format as string:
*   >= 1 second: show as integer (e.g. "20")
*   <  1 second: show with 2 decimals
destring LL08, replace force
gen length_clip_display = ""
replace length_clip_display = string(LL08, "%9.0f") if LL08 != . & LL08 >= 1
replace length_clip_display = string(LL08, "%9.2f") if LL08 != . & LL08 < 1

*==============================================================================
* Sort the data
*==============================================================================

* Sort by: Rater type, Agreement type, Age group, Author, Year
gsort RaterType agreementType3 AgeGroup Author Year

*==============================================================================
* Select and rename variables for export
*==============================================================================

* Keep only needed variables
keep REFID RaterType AgeGroup gAgeString2 Author Year agreementType3 agreementtype ///
     AgreementValueRounded CI_95 gNumberOfEegElectrodes NumberOfEegsIncluded ///
     isaverage D112Howmanyraterswerethere length_eeg_display length_clip_display gShortClips ///
     GrrasSum RaterExperience NumPatientsIncluded ///
     substudy SS*

* Rename for export (Stata variable names can't have spaces, but labels can)
rename RaterType rater_type
rename AgeGroup age_group
rename gAgeString2 age_categories
rename agreementType3 agreement_type_general
rename agreementtype agreement_type_subgroup
rename AgreementValueRounded agreement_value
rename CI_95 ci_95
rename gNumberOfEegElectrodes num_eeg_electrodes
rename NumberOfEegsIncluded num_eegs
rename isaverage is_average
rename D112Howmanyraterswerethere num_raters
rename length_eeg_display length_eeg_min
rename length_clip_display length_clip_sec
rename gShortClips short_clips
rename GrrasSum grras_score
rename RaterExperience rater_exp_self
rename SS001 preselection_patient_eeg
rename SS002A preselection_epileptiform
rename SS002B preselection_other
rename SS002C preselection_casemix
rename SS003 preselection_weighting_explicit
rename SS004 preselection_backweighted
rename SS005 clinical_setting

gen short_clips_str = cond(short_clips == 1, "Yes", cond(short_clips == 0, "No", ""))
drop short_clips
rename short_clips_str short_clips

* Set column order for Excel export:
*  Col  1: REFID
*  Col  2: Year
*  Col  3: Author
*  Col  4: num_eegs
*  Col  5: NumPatientsIncluded
*  Col  6: num_raters
*  Col  7: length_clip_sec
*  Col  8: short_clips
*  Col  9: rater_type
*  Col 10: clinical_setting
*  Col 11: length_eeg_min
*  Col 12: preselection_patient_eeg
*  Col 13: preselection_epileptiform
*  Col 14: preselection_weighting_explicit
*  Col 15: preselection_backweighted
*  Col 16: age_categories
*  Col 17+: remaining vars in original relative order:
*           age_group, agreement_type_general, agreement_type_subgroup,
*           agreement_value, ci_95, num_eeg_electrodes, is_average,
*           grras_score, rater_exp_self, substudy
order REFID Year Author num_eegs NumPatientsIncluded num_raters length_clip_sec short_clips ///
      rater_type clinical_setting length_eeg_min ///
      preselection_patient_eeg preselection_epileptiform ///
      preselection_weighting_explicit preselection_backweighted ///
      age_categories

* Apply variable labels for nice Excel headers
label variable REFID "REFID"
label variable rater_type "Intra-rater?"
label variable age_group "Age group"
label variable age_categories "Ages: Neonatal, Pediatric, Adult"
label variable Author "Author"
label variable Year "Year"
label variable agreement_type_general "Agreement type (general)"
label variable agreement_type_subgroup "Agreement type (subgroup)"
label variable agreement_value "Agreement value"
label variable ci_95 "95% CI"
label variable NumPatientsIncluded "# of patients"
label variable num_eeg_electrodes "# of EEG electrodes"
label variable num_eegs "# of EEGs"
label variable is_average "Average of raters?"
label variable num_raters "# of raters"
label variable length_eeg_min "Length of EEG per patient (minutes)"
label variable length_clip_sec "Length of EEG clip rated (seconds)"
label variable short_clips "Short Clips?"
label variable grras_score "GRRAS Quality sum score"
label variable rater_exp_self "Self-reported experience level"
label variable substudy "Substudy in paper"
label variable preselection_patient_eeg "Preselected known pathology patient or EEG"
label variable preselection_epileptiform "Preselected epileptiform IEDs in EEG"
label variable preselection_other "Preselected other pathology EEG"
label variable preselection_casemix "Synthetic case mix"
label variable preselection_weighting_explicit "Preselected explicit weighted sampling"
label variable preselection_backweighted "Preselected explicit weighted backweighted in analysis"
label variable clinical_setting "Clinical setting"


*==============================================================================
* Export to Excel
*==============================================================================

local outexcelfile "4output/SupplementaryTable3-EEG_Study_Characteristics.xlsx"

* Peer review revision 1: start from an empty template that has landscape page
* orientation (A4, fit to width) already set, and write into it with
* sheet(..., modify) so the page setup survives. putexcel/export excel cannot
* set page orientation directly.
copy "1script-stata/SupplTable3-template.xlsx" "`outexcelfile'", replace

* Export with variable labels as headers
export excel using "`outexcelfile'", sheet("Sheet1", modify) firstrow(varlabels)

di _n "Supplementary Table 3 saved to: `outexcelfile'"
di "Total rows exported: `totalobs'"

mata: b = xl()
mata: b.load_book(st_local("outexcelfile"))
mata: b.set_sheet("Sheet1")
mata: b.set_mode("open")
mata: b.set_text_wrap((1,1), (1,25), "on")
mata: b.set_column_width(7,  7,  11)   // length_clip_sec
mata: b.set_column_width(8,  8,  11)   // short_clips
mata: b.set_column_width(10,  10,  24)   // clinical setting
mata: b.set_column_width(11,  15,  12)   // Preselected known pathology patient or EEG
mata: b.set_column_width(18, 18, 11)   // agreement_type_general
mata: b.set_column_width(20, 20, 11)   // agreement_value
mata: b.set_column_width(24, 24, 11)   // grras_score
mata: b.set_column_width(25, 25, 11)   // rater_exp_self
mata: b.set_column_width(26, 26, 24)   // substudy
mata: b.close_book()

cap log close
cap translate "`logfile'.smcl" "`logfile'.pdf"

di _n "Done!"
