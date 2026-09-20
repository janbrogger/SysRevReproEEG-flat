* Table 1: Demographics for Manuscript 2 - Epileptiform Discharges
* Converted from R script 04table_1.Rmd
* This script creates Table 1 showing characteristics of included studies
* for the systematic review on reproducibility of epileptiform discharge detection

version 18
clear all
set more off


cap log close
cd "C:\Midlertidig_Lagring\SysRevReproEeg\6Manuscript2\v6"
local logfile "3log/Table1"
log using "`logfile'.smcl", replace

pwd

* Load already-filtered, study-level dataset (one row per REFID)
use "2data/data_short_design.dta", clear

* Verify we have the right number of studies
count
local totalstudies = `r(N)'
di "Total studies in analysis: `totalstudies'"

*==============================================================================
* Create derived variables (matching R script logic)
*==============================================================================

* EEG Channel Count categories
gen gEEGChannelCount = ""
replace gEEGChannelCount = "10-20+" if Q007DescriptionofEEGrecordin == "10-20 with inferior temporal chains"
replace gEEGChannelCount = "10-20" if Q007DescriptionofEEGrecordin == "10-20 with number of channels given"
replace gEEGChannelCount = "10-20" if Q007DescriptionofEEGrecordin == "10-20 without number of channels given"
replace gEEGChannelCount = "10-20+" if Q007DescriptionofEEGrecordin == "16 10-20 with additional 8 electrodes."
replace gEEGChannelCount = "Fewer than 10-20" if Q007DescriptionofEEGrecordin == "3 electrodes at specific locations (FT9, T7 and/or T9 and/or T11, nasopharyngeal)"
replace gEEGChannelCount = "10-20+" if Q007DescriptionofEEGrecordin == "EEG recordings included standard 10– 20 system electrode recording sites plus sub-temporal electrodes (F9/10, T9/10, P9/10)"
replace gEEGChannelCount = "Fewer than 10-20" if Q007DescriptionofEEGrecordin == "Fewer channels than 10-20"
replace gEEGChannelCount = "10-20" if Q007DescriptionofEEGrecordin == "Generic 10-20 without further specification"
replace gEEGChannelCount = "10-20+" if Q007DescriptionofEEGrecordin == "ipsilateral 10-10, contralateral 10-20"
replace gEEGChannelCount = "Not given" if Q007DescriptionofEEGrecordin == "Not given"
replace gEEGChannelCount = Q007DescriptionofEEGrecordin if gEEGChannelCount == ""


* Recruitment type consolidation
gen gRecruitmentType = Q105Typeofrecruitment
replace gRecruitmentType = "Convenience or synthetic mix" if Q105Typeofrecruitment == "Synthetic mix"
replace gRecruitmentType = "Convenience or synthetic mix" if Q105Typeofrecruitment == "Convenience"
replace gRecruitmentType = "Consecutive or random sample" if Q105Typeofrecruitment == "Consecutive"
replace gRecruitmentType = "Consecutive or random sample" if Q105Typeofrecruitment == "Random"
replace gRecruitmentType = "Consecutive or random sample" if Q105Typeofrecruitment == "Weighted sample"

* Single/Multi center
gen gSingleCenter = ""
replace gSingleCenter = "Single-center" if Q035Numberoflaboratoriesinvo == 1
replace gSingleCenter = "Multicenter" if Q035Numberoflaboratoriesinvo > 1 & Q035Numberoflaboratoriesinvo != .
replace gSingleCenter = "Multicenter-Multicountry" if gCountryMultiple == 1

* Continent
gen gContinent = ""
replace gContinent = "Europe" if gContinentEurope == 1
replace gContinent = "America" if gContinentAmerica == 1
replace gContinent = "Asia" if gContinentAsia == 1
replace gContinent = "Oceania" if gContinentOceania == 1


* Country - top 3 + other
* First find the top 3 countries
tab Q032CountrywhereEEGwasperfo, sort
gen gCountryTop = Q032CountrywhereEEGwasperfo
* Based on manuscript 1 pattern, top countries are typically USA, Netherlands, etc.
* We'll categorize as Other if not in top 3
replace gCountryTop = "Other" if !inlist(Q032CountrywhereEEGwasperfo, "USA", "The Netherlands", "Denmark")

* Convert numeric variables
destring LengthEEG, replace force
destring GrrasSum, replace force
destring NumPatientsIncluded, replace force

* Clinically relevant: not known epilepsy, no IED preselection, no other EEG-based preselection, no synthetic case mix, 
* no unaccounted weighted sampling
gen gHighRelevance = 1 ///
    if gEEGSetting != "Epilepsy" ///
    & SS002A == "No" ///
    & SS002B == "No" ///
    & SS002C == "No" ///
    & (SS003 == "No" | (SS003 == "Yes" & SS004 == "Yes"))
*==============================================================================
* Create Excel output
*==============================================================================

local outexcelfile "4output/Table 1 Demographics IED.xlsx"
* Peer review revision 1: start from an empty template that has landscape page
* orientation (A4, fit to width) already set, and open it with -modify- so the
* page setup survives. putexcel/mata xl() cannot set page orientation directly.
copy "1script-stata/Table1-template.xlsx" "`outexcelfile'", replace
putexcel set "`outexcelfile'", sheet("Table 1") modify

* Headers
* Peer review revision 1: IQR column removed to simplify the table layout
putexcel A1=("Table 1: Characteristics of included studies in a systematic review of the reproducibility of epileptiform discharge detection.")
putexcel A2=("Measure")
putexcel B2=("Statistics")
putexcel C2=("N or median")
putexcel D2=("Range or %")
putexcel E2=("Missing %")

* Row counter
local row = 3

*------------------------------------------------------------------------------
* Number of included studies
*------------------------------------------------------------------------------
putexcel A`row'=("Number of included studies")
putexcel B`row'=("(n)")
putexcel C`row' = `totalstudies', nformat("#")
local row = `row' + 1

*------------------------------------------------------------------------------
* Number of patients
*------------------------------------------------------------------------------
putexcel A`row'=("Number of patients")
putexcel B`row'=("(median, range)")
summ NumPatientsIncluded, det
putexcel C`row' = `r(p50)', nformat("#")
local range : display "" `r(min)' " - " `r(max)' ""
putexcel D`row' = ("`range'")
count if NumPatientsIncluded == .
putexcel E`row' = `r(N)'/`totalstudies'*100, nformat("0.0")
local row = `row' + 1

*------------------------------------------------------------------------------
* Number of EEGs
*------------------------------------------------------------------------------
putexcel A`row'=("Number of EEGs Included")
putexcel B`row'=("(median, range)")
summ NumberOfEegsIncluded, det
putexcel C`row' = `r(p50)', nformat("#")
local range : display "" `r(min)' " - " `r(max)' ""
putexcel D`row' = ("`range'")
count if NumberOfEegsIncluded == .
putexcel E`row' = `r(N)'/`totalstudies'*100, nformat("0.0")
local row = `row' + 1

*------------------------------------------------------------------------------
* Number of raters
*------------------------------------------------------------------------------
putexcel A`row'=("Number of raters")
putexcel B`row'=("(median, range)")
summ NumberOfRatersInvolved, det
putexcel C`row' = `r(p50)', nformat("#")
local range : display "" `r(min)' " - " `r(max)' ""
putexcel D`row' = ("`range'")
count if NumberOfRatersInvolved == .
putexcel E`row' = `r(N)'/`totalstudies'*100, nformat("0.0")
local row = `row' + 1

*------------------------------------------------------------------------------
* Number of EEG electrodes (categorical)
*------------------------------------------------------------------------------
putexcel A`row'=("Number of EEG electrodes")

* Count non-missing for denominator
count if gEEGChannelCount != "Not given" & gEEGChannelCount != ""
local denom = `r(N)'

putexcel B`row'=("10-20 (n, %)")
count if gEEGChannelCount == "10-20"
putexcel C`row' = `r(N)', nformat("#")
putexcel D`row' = `r(N)'/`totalstudies'*100, nformat("0")
count if gEEGChannelCount == "Not given" | gEEGChannelCount == ""
putexcel E`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1

putexcel B`row'=("More than 10-20 (n, %)")
count if gEEGChannelCount == "10-20+"
putexcel C`row' = `r(N)', nformat("#")
putexcel D`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1

*------------------------------------------------------------------------------
* Agreement Type - removed after peer review revision 1 (see change list)
*------------------------------------------------------------------------------

*------------------------------------------------------------------------------
* Length of EEG per patient (minutes) – re-abstracted
*------------------------------------------------------------------------------
putexcel A`row'=("Length of EEG per patient (minutes)")
putexcel B`row'=("(median, range)")
summ LengthEEG, det
if `r(N)' > 0 {
    putexcel C`row' = `r(p50)', nformat("#")
    local range : display "" %3.1f `r(min)' " - " %3.1f `r(max)' ""
    putexcel D`row' = ("`range'")
}
count if LengthEEG == .
putexcel E`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1

*------------------------------------------------------------------------------
* Length of EEG clip rated (seconds) – re-abstracted
*------------------------------------------------------------------------------
putexcel A`row'=("Length of EEG clip rated (seconds)")
putexcel B`row'=("(median, range)")
summ LL08, det
if `r(N)' > 0 {
    putexcel C`row' = `r(p50)', nformat("#")
    local range : display "" %3.1f `r(min)' " - " %3.1f `r(max)' ""
    putexcel D`row' = ("`range'")
}
count if LL08 == .
putexcel E`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1

*------------------------------------------------------------------------------
* High relevance
*------------------------------------------------------------------------------
putexcel A`row'=("High relevance")
putexcel B`row'=("Not known epilepsy, no IED or other EEG preselection, no unaccounted weighting (n, %)")
count if gHighRelevance == 1
putexcel C`row' = `r(N)', nformat("#")
putexcel D`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1

*------------------------------------------------------------------------------
* Study quality GRRAS
*------------------------------------------------------------------------------
putexcel A`row'=("Study quality GRRAS")
putexcel B`row'=("(median, range)")
summ GrrasSum, det
if `r(N)' > 0 {
    putexcel C`row' = `r(p50)', nformat("#")
    local range : display "" `r(min)' " - " `r(max)' ""
    putexcel D`row' = ("`range'")
}
count if GrrasSum == .
putexcel E`row' = `r(N)'/`totalstudies'*100, nformat("0.0")
local row = `row' + 1

*------------------------------------------------------------------------------
* Rater type (inter/intra)
*------------------------------------------------------------------------------
putexcel A`row'=("Rater type")

putexcel B`row'=("Interrater only (n, %)")
count if raterIntraType == "Interrater only"
putexcel C`row' = `r(N)', nformat("#")
putexcel D`row' = `r(N)'/`totalstudies'*100, nformat("0")
count if raterIntraType == "" | raterIntraType == "Missing"
putexcel E`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1

putexcel B`row'=("Inter- and intrarater (n, %)")
count if raterIntraType == "Inter- and intrarater"
putexcel C`row' = `r(N)', nformat("#")
putexcel D`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1

putexcel B`row'=("Intrarater only (n, %)")
count if raterIntraType == "Intrarater only"
putexcel C`row' = `r(N)', nformat("#")
putexcel D`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1

*------------------------------------------------------------------------------
* Rater experience
*------------------------------------------------------------------------------
putexcel A`row'=("Rater experience")

putexcel B`row'=("Expert (n, %)")
count if RaterExperience == "Expert"
putexcel C`row' = `r(N)', nformat("#")
putexcel D`row' = `r(N)'/`totalstudies'*100, nformat("0")
count if RaterExperience == "Missing" | RaterExperience == ""
putexcel E`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1

putexcel B`row'=("Experienced (n, %)")
count if RaterExperience == "Experienced"
putexcel C`row' = `r(N)', nformat("#")
putexcel D`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1

*------------------------------------------------------------------------------
* EEG setting
*------------------------------------------------------------------------------
putexcel A`row'=("EEG setting, categories")

putexcel B`row'=("Known epilepsy (n, %)")
count if gEEGSetting == "Epilepsy"
putexcel C`row' = `r(N)', nformat("#")
putexcel D`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1

putexcel B`row'=("Acute Brain (n, %)")
count if gEEGSetting == "Acute Brain"
putexcel C`row' = `r(N)', nformat("#")
putexcel D`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1

putexcel B`row'=("First seizure (n, %)")
count if gEEGSetting == "First seizure"
putexcel C`row' = `r(N)', nformat("#")
putexcel D`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1


putexcel B`row'=("Other (n, %)")
count if gEEGSetting == "Other"
putexcel C`row' = `r(N)', nformat("#")
putexcel D`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1

*------------------------------------------------------------------------------
* Study center
*------------------------------------------------------------------------------
putexcel A`row'=("Study center")

putexcel B`row'=("Single-center (n, %)")
count if gSingleCenter == "Single-center"
putexcel C`row' = `r(N)', nformat("#")
putexcel D`row' = `r(N)'/`totalstudies'*100, nformat("0")
count if gSingleCenter == ""
putexcel E`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1

putexcel B`row'=("Multi-center, single country (n, %)")
count if gSingleCenter == "Multicenter"
putexcel C`row' = `r(N)', nformat("#")
putexcel D`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1

putexcel B`row'=("Multi-center, multi-country (n, %)")
count if gSingleCenter == "Multicenter-Multicountry"
putexcel C`row' = `r(N)', nformat("#")
putexcel D`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1

*------------------------------------------------------------------------------
* Country
*------------------------------------------------------------------------------
/*
putexcel A`row'=("Country where EEG was performed")

putexcel B`row'=("USA (n, %)")
count if gCountryTop == "USA"
putexcel C`row' = `r(N)', nformat("#")
putexcel D`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1

putexcel B`row'=("The Netherlands (n, %)")
count if gCountryTop == "The Netherlands"
putexcel C`row' = `r(N)', nformat("#")
putexcel D`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1

putexcel B`row'=("Denmark (n, %)")
count if gCountryTop == "Denmark"
putexcel C`row' = `r(N)', nformat("#")
putexcel D`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1

putexcel B`row'=("Other (n, %)")
count if gCountryTop == "Other"
putexcel C`row' = `r(N)', nformat("#")
putexcel D`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1
*/

*------------------------------------------------------------------------------
* Continent - removed after peer review revision 1 (see change list)
*------------------------------------------------------------------------------

*------------------------------------------------------------------------------
* Type of recruitment
*------------------------------------------------------------------------------
putexcel A`row'=("Type of recruitment")

putexcel B`row'=("Consecutive or random sample (n, %)")
count if gRecruitmentType == "Consecutive or random sample"
putexcel C`row' = `r(N)', nformat("#")
putexcel D`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1

putexcel B`row'=("Convenience or synthetic mix (n, %)")
count if gRecruitmentType == "Convenience or synthetic mix"
putexcel C`row' = `r(N)', nformat("#")
putexcel D`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1

putexcel B`row'=("Unclear (n, %)")
count if gRecruitmentType == "Unclear"
putexcel C`row' = `r(N)', nformat("#")
putexcel D`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1

*------------------------------------------------------------------------------
* Study language
*------------------------------------------------------------------------------
/*
putexcel A`row'=("Study language")

putexcel B`row'=("English (n, %)")
count if Q701Q095Whatlanguagewasthis == "English"
putexcel C`row' = `r(N)', nformat("#")
putexcel D`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1

putexcel B`row'=("French (n, %)")
count if Q701Q095Whatlanguagewasthis == "French"
putexcel C`row' = `r(N)', nformat("#")
putexcel D`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1


*------------------------------------------------------------------------------
* Indexed in
*------------------------------------------------------------------------------
putexcel A`row'=("Indexed in")

putexcel B`row'=("PubMED (n, %)")
count if Q703WasthisstudyindexedinO == "Yes"
putexcel C`row' = `r(N)', nformat("#")
putexcel D`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1

putexcel B`row'=("EMBASE (n, %)")
count if Q704WasthisstudyindexedinE == "Yes"
putexcel C`row' = `r(N)', nformat("#")
putexcel D`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1

putexcel B`row'=("Psychinfo (n, %)")
count if Q705WasthisstudyindexedinP == "Yes"
putexcel C`row' = `r(N)', nformat("#")
putexcel D`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1

putexcel B`row'=("Cochrane Library (n, %)")
count if Q706Wasthisstudyindexedint == "Yes"
putexcel C`row' = `r(N)', nformat("#")
putexcel D`row' = `r(N)'/`totalstudies'*100, nformat("0")
local row = `row' + 1

*/

*==============================================================================
* Format Excel file
*==============================================================================

* Note: mata formatting may need adjustment depending on Stata version
* and whether running on Windows/Mac/Linux

cap {
    mata: b = xl()
    mata: b.load_book("`outexcelfile'")
    mata: b.set_sheet("Table 1")
    mata: b.set_column_width(1,1,40)
    mata: b.set_column_width(2,2,35)
    mata: b.set_column_width(3,3,12)
    mata: b.set_column_width(4,4,15)
    mata: b.set_column_width(5,5,12)
    mata: b.close_book()
}

di _n "Table 1 saved to: `outexcelfile'"
di "Total rows: `row'"

cap log close
cap translate "`logfile'.smcl" "`logfile'.pdf"


// ========== Table 1 analysis =================================0
/**************************************************************************
Association between study size (number of EEGs) and rater panel size
Non-parametric: Spearman rank correlation
**************************************************************************/

* Spearman correlation: Number of EEGs included vs number of raters involved
spearman NumberOfEegsIncluded NumberOfRatersInvolved

* (Optional but useful) show the same association visually on log scale
gen log_n_eegs   = log(NumberOfEegsIncluded)
gen log_n_raters = log(NumberOfRatersInvolved)
twoway scatter log_n_raters log_n_eegs, ///
    ytitle("log(Number of raters)") xtitle("log(Number of EEGs)") ///
    title("Raters vs EEGs (log scale)")
cap graph close
	
/**************************************************************************
Association between review format (clip-based vs continuous) and number of raters
Non-parametric: Wilcoxon rank-sum (Mann–Whitney)
**************************************************************************/

ranksum NumberOfRatersInvolved, by(gNewShortClips) exact

* (Optional) descriptive medians/IQR by review format for reporting
tabstat NumberOfRatersInvolved, by(gNewShortClips) stat(n median iqr)

di _n "Done!"
