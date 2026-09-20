* 00 Extract IED data: Data extraction for Manuscript 2 - Epileptiform Discharges
* Converted from R script 02extractdata.Rmd
* This script filters the data to epileptiform discharge studies only
* and saves the filtered datasets for use by other scripts

version 18
clear all
set more off

* Set working directory - adjust path as needed for your system
* The script assumes working directory is 6Manuscript2/v1/

cap log close
cd C:\Midlertidig_Lagring\SysRevReproEeg\6Manuscript2\v6
local logfile "3log/00_ExtractIEDdata"
log using "`logfile'.smcl", replace

pwd
di "Starting data extraction for epileptiform discharge studies..."

use "../../3CleanData/data-cleaned/2featuredata-cleaned.dta", clear
drop _merge
merge m:1 REFID using "../../3CleanData/data-cleaned/3designleveldata-varscleaned-with-featureabstract.dta", nogen

**==================
* Add re-abstracted EEG length and rated EEG clip length
* Create temporary file with re-abstracted variables
preserve
import excel "C:\Midlertidig_Lagring\SysRevReproEeg\6Manuscript2\v6\6re-abstract-variables\re-abstract data.xlsx", firstrow clear
keep REFID LL05* LL06* LL07* LL08* SS*
tempfile eeglength
save `eeglength'
restore


*==============================================================================
* Step 1: Filter feature-level data
*==============================================================================

* Correct Kural and Kulick-Soper papers' features (as done in R script)
replace featurescored = "Epileptiform discharges yes/no" if inlist(REFID, 413, 406)

* Filter to epileptiform discharges only
keep if featurescored == "Epileptiform discharges yes/no"

* Correct Piccinelli Upper CI (REFID 86)
replace agreementConfidenceIntervalUpper = 1 if REFID == 86 & D300Whattypeofstatisticalun == "95% confidence interval"

* Correct Jing 2019's Fleiss Kappa average (REFID 236)
replace agreementvalue = 0.487 if REFID == 236 & agreementvalue == 0.809 & agreementtype == "Fleiss' kappa"

* Merge new EEG length variables into master
merge n:1 REFID using `eeglength', nogen
drop LengthEEG Q010Are 
rename LL07 LengthEEG
gen gNewShortClips=LL08<=300
rename gNewShortClips gShortClips


*==============================================================================
* Create EEG Setting variable improved, feature level
*==============================================================================

cap drop gEEGSetting
gen gEEGSetting = ""
replace gEEGSetting = "Epilepsy" if Q019TypeofEEGsettingbroad == "Epilepsy"
replace gEEGSetting = "Acute Brain" if Q019TypeofEEGsettingbroad == "Coma/critical care, not neonatal or status epilepticus"
replace gEEGSetting = "Other" if gEEGSetting == ""
replace gEEGSetting = "Epilepsy" if REFID==227 // Halford 2018, epilepsy-based
replace gEEGSetting = "Epilepsy" if REFID==248 // Beniczky 2020, epilepsy-based
replace gEEGSetting = "Acute Brain" if REFID==109 // Lee 2010, craniotomy with seizures
replace gEEGSetting = "Acute Brain" if REFID==176 // Mohammad 2016, known encephalitis
replace gEEGSetting = "First seizure" if REFID==37 // van Donselaar 1992, first seizure not epilepsy
replace gEEGSetting = "First seizure" if REFID==94 // Stroink 2006, first seizure not epilepsy
tab gEEGSetting

* Count observations
count
local n_feature_obs = `r(N)'
di "Number of observations (feature-level): `n_feature_obs'"

* Save filtered feature-level data
save "2data/data_long_feature.dta", replace

*==============================================================================
* Build study-level raterIntraType from the IED-filtered feature rows (no extra saved file)
tempfile intratypes
preserve
keep REFID intra_or_inter
gen byte has_intra = (intra_or_inter == "Yes")
gen byte has_inter = (intra_or_inter == "No")
collapse (max) has_intra has_inter, by(REFID)
gen str25 raterIntraType = ""
replace raterIntraType = "Interrater only"        if has_inter==1 & has_intra==0
replace raterIntraType = "Intrarater only"        if has_intra==1 & has_inter==0
replace raterIntraType = "Inter- and intrarater"  if has_intra==1 & has_inter==1
keep REFID raterIntraType
save "`intratypes'", replace
restore

* Step 2: Extract unique REFIDs for IED studies
*==============================================================================

* Get unique REFIDs
preserve
keep REFID
duplicates drop
count
local n_ied_studies = `r(N)'
di "Number of unique epileptiform discharge studies: `n_ied_studies'"
save "2data/epileptiform_discharge_refids.dta", replace
restore



*==============================================================================
* Step 3: Filter design-level data to IED studies
*==============================================================================

* Load design-level data
use "../../3CleanData/data-cleaned/3designleveldata-varscleaned-with-featureabstract.dta", clear

* Merge with IED REFIDs to filter
merge m:1 REFID using "2data/epileptiform_discharge_refids.dta", keep(match) nogen
merge 1:1 REFID using "`intratypes'", nogen


* Merge new EEG length variables into master
merge 1:1 REFID using `eeglength', nogen
drop LengthEEG Q010Are 
rename LL07 LengthEEG
gen gNewShortClips=LL08<=300

count
local n_design = `r(N)'
di "Number of design-level observations: `n_design'"

cap drop gEEGSetting
gen gEEGSetting = ""
replace gEEGSetting = "Epilepsy" if Q019TypeofEEGsettingbroad == "Epilepsy"
replace gEEGSetting = "Acute Brain" if Q019TypeofEEGsettingbroad == "Coma/critical care, not neonatal or status epilepticus"
replace gEEGSetting = "Other" if gEEGSetting == ""
replace gEEGSetting = "Epilepsy" if REFID==227 // Halford 2018, epilepsy-based
replace gEEGSetting = "Epilepsy" if REFID==248 // Beniczky 2020, epilepsy-based
replace gEEGSetting = "Acute Brain" if REFID==109 // Lee 2010, craniotomy with seizures
replace gEEGSetting = "Acute Brain" if REFID==176 // Mohammad 2016, known encephalitis
replace gEEGSetting = "First seizure" if REFID==37 // van Donselaar 1992, first seizure not epilepsy
replace gEEGSetting = "First seizure" if REFID==94 // Stroink 2006, first seizure not epilepsy
tab gEEGSetting


* Save filtered design-level data
save "2data/data_short_design.dta", replace

*==============================================================================
* Summary
*==============================================================================

di _n "===== Data Extraction Summary ====="
di "Feature-level observations: `n_feature_obs'"
di "Unique IED studies: `n_ied_studies'"
di "Design-level observations: `n_design'"
di ""
di "Files created:"
di "  - 2data/data_long_feature.dta"
di "  - 2data/epileptiform_discharge_refids.dta"
di "  - 2data/data_short_design.dta"

cap log close
cap translate "`logfile'.smcl" "`logfile'.pdf"

di _n "Done!"
