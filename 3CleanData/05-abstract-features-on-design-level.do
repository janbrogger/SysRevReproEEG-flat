* =============================================================================
* 05-abstract-features-on-design-level-v2.do
*
* Purpose: Collapse feature-level data to study (REFID) level.
*          Produces three groups of study-level variables:
*            (A) Narrow agreement type indicators  (agreementType2, one per type)
*            (B) Broad agreement category indicators (derived from type2 in-script)
*            (C) Feature count and concatenated feature string
*          Then merges everything onto the design-level dataset and adds:
*            (D) Study-level intra/interrater classification
*            (E) hasAgreementCombo composite variable
*
* Input:   2featuredata-cleaned.dta   (one row per feature measurement)
*          1designleveldata-varscleaned.dta  (one row per study)
* Output:  3designleveldata-varscleaned-with-featureabstract.dta
*
* Broad category mapping (agreementType3 equivalent, derived in-script):
*
*   hasAgreement (non-aggregate percent/unadjusted agreement):
*     Unadjusted agreement
*     Weighted unadjusted agreement
*     Median agreement
*     Median majority perfect agreement
*     Median pairwise perfect agreement
*     Percent agreement 5 pairs median
*
*   hasKappaType (non-aggregate kappa/ICC/alpha):
*     Cohen's kappa
*     Cohen's quadratically weighted kappa
*     Fleiss' kappa
*     Gwet's AC1
*     Gwet's AC2
*     Unweighted kappa
*     Weighted kappa - quadratic weights
*     Weighted kappa - unknown weights
*     Weighted kappa - unspecified weights
*     Weighted kappa, unknown average method
*     Brennan and Prediger kappa
*     ICC
*     Cronbach's alpha
*     Krippendorff's alpha
*     Free-Marginal Multirater Kappa (kFree)
*     Kappa 5 pairs median
*     Spearman-Brown prophecy reliability coefficient
*     Median 3-rater kappa
*     Median Cohen's kappa
*     Median majority kappa
*     Median pairwise kappa
*     Mean kappa
*     Mean or median Kappa 2 raters across neonates
*
*   hasKappaAgg (aggregate kappa, averaged across raters):
*     Fleiss' kappa, aggregate
*     mean Cohen's kappa          <- Halford 2013 intrarater
*
*   hasUnadjAgreeAgg (aggregate unadjusted agreement):
*     Unadjusted agreement, aggregate
* =============================================================================

cd "C:\Midlertidig_Lagring\sysrevreproeeg\3CleanData"
cap log close
log using "log\05-abstract-features-on-design-level-v2.smcl", replace

local featuredata "data-cleaned\2featuredata-cleaned"
local designdata  "data-cleaned\1designleveldata-varscleaned"
local outputdata  "data-cleaned\3designleveldata-varscleaned-with-featureabstract"


* =============================================================================
* BLOCK A: Narrow agreement type indicators (one per agreementType2 value)
*
* One 0/1 variable per distinct narrow type. Names are abbreviated but
* unambiguous; labels carry the full string.
* The rowtotal assert at the end fires if any agreementType2 value in the
* data is not listed here — catches new types added to the source data.
* =============================================================================
title "Block A: Narrow agreement type indicators (agreementType2)"

use "`featuredata'", clear

* --- Agreement types ---
gen byte t2_unadj_agree      = 0
gen byte t2_unadj_agree_agg  = 0
gen byte t2_wtd_unadj_agree  = 0
gen byte t2_median_agree     = 0
gen byte t2_median_maj_perf  = 0
gen byte t2_median_pw_perf   = 0
gen byte t2_pct_agree_5pairs = 0

replace t2_unadj_agree      = 1 if agreementType2 == "Unadjusted agreement"
replace t2_unadj_agree_agg  = 1 if agreementType2 == "Unadjusted agreement, aggregate"
replace t2_wtd_unadj_agree  = 1 if agreementType2 == "Weighted unadjusted agreement"
replace t2_median_agree     = 1 if agreementType2 == "Median agreement"
replace t2_median_maj_perf  = 1 if agreementType2 == "Median majority perfect agreement"
replace t2_median_pw_perf   = 1 if agreementType2 == "Median pairwise perfect agreement"
replace t2_pct_agree_5pairs = 1 if agreementType2 == "Percent agreement 5 pairs median"

label variable t2_unadj_agree      "Unadjusted agreement"
label variable t2_unadj_agree_agg  "Unadjusted agreement, aggregate"
label variable t2_wtd_unadj_agree  "Weighted unadjusted agreement"
label variable t2_median_agree     "Median agreement"
label variable t2_median_maj_perf  "Median majority perfect agreement"
label variable t2_median_pw_perf   "Median pairwise perfect agreement"
label variable t2_pct_agree_5pairs "Percent agreement 5 pairs median"

* --- Kappa-type (non-aggregate) ---
gen byte t2_cohen_kappa      = 0
gen byte t2_cohen_kappa_qwtd = 0
gen byte t2_fleiss_kappa     = 0
gen byte t2_fleiss_kappa_agg = 0
gen byte t2_gwet_ac1         = 0
gen byte t2_gwet_ac2         = 0
gen byte t2_unwtd_kappa      = 0
gen byte t2_wtd_kappa_quad   = 0
gen byte t2_wtd_kappa_unk    = 0
gen byte t2_wtd_kappa_unspec = 0
gen byte t2_wtd_kappa_avgunk = 0
gen byte t2_brennan_prediger = 0
gen byte t2_icc              = 0
gen byte t2_cronbach         = 0
gen byte t2_krippendorff     = 0
gen byte t2_kfree            = 0
gen byte t2_kappa5pairs      = 0
gen byte t2_spearman_brown   = 0
gen byte t2_median3r_kappa   = 0
gen byte t2_median_cohen     = 0
gen byte t2_median_maj_kappa = 0
gen byte t2_median_pw_kappa  = 0
gen byte t2_mean_kappa       = 0
gen byte t2_mean_kappa_neo   = 0
gen byte t2_mean_cohen       = 0

replace t2_cohen_kappa      = 1 if agreementType2 == "Cohen's kappa"
replace t2_cohen_kappa_qwtd = 1 if agreementType2 == "Cohen's quadratically weighted kappa"
replace t2_fleiss_kappa     = 1 if agreementType2 == "Fleiss' kappa"
replace t2_fleiss_kappa_agg = 1 if agreementType2 == "Fleiss' kappa, aggregate"
replace t2_gwet_ac1         = 1 if agreementType2 == "Gwet's AC1"
replace t2_gwet_ac2         = 1 if agreementType2 == "Gwet's AC2"
replace t2_unwtd_kappa      = 1 if agreementType2 == "Unweighted kappa"
replace t2_wtd_kappa_quad   = 1 if agreementType2 == "Weighted kappa - quadratic weights"
replace t2_wtd_kappa_unk    = 1 if agreementType2 == "Weighted kappa - unknown weights"
replace t2_wtd_kappa_unspec = 1 if agreementType2 == "Weighted kappa - unspecified weights"
replace t2_wtd_kappa_avgunk = 1 if agreementType2 == "Weighted kappa, unknown average method"
replace t2_brennan_prediger = 1 if agreementType2 == "Brennan and Prediger kappa"
replace t2_icc              = 1 if agreementType2 == "ICC"
replace t2_cronbach         = 1 if agreementType2 == "Cronbach's alpha"
replace t2_krippendorff     = 1 if agreementType2 == "Krippendorff's alpha"
replace t2_kfree            = 1 if agreementType2 == "Free-Marginal Multirater Kappa (kFree)"
replace t2_kappa5pairs      = 1 if agreementType2 == "Kappa 5 pairs median"
replace t2_spearman_brown   = 1 if agreementType2 == "Spearman-Brown prophecy reliability coefficient"
replace t2_median3r_kappa   = 1 if agreementType2 == "Median 3-rater kappa"
replace t2_median_cohen     = 1 if agreementType2 == "Median Cohen's kappa"
replace t2_median_maj_kappa = 1 if agreementType2 == "Median majority kappa"
replace t2_median_pw_kappa  = 1 if agreementType2 == "Median pairwise kappa"
replace t2_mean_kappa       = 1 if agreementType2 == "Mean kappa"
replace t2_mean_kappa_neo   = 1 if agreementType2 == "Mean or median Kappa 2 raters across neonates"
replace t2_mean_cohen       = 1 if agreementType2 == "mean Cohen's kappa"

label variable t2_cohen_kappa      "Cohen's kappa"
label variable t2_cohen_kappa_qwtd "Cohen's quadratically weighted kappa"
label variable t2_fleiss_kappa     "Fleiss' kappa"
label variable t2_fleiss_kappa_agg "Fleiss' kappa, aggregate"
label variable t2_gwet_ac1         "Gwet's AC1"
label variable t2_gwet_ac2         "Gwet's AC2"
label variable t2_unwtd_kappa      "Unweighted kappa"
label variable t2_wtd_kappa_quad   "Weighted kappa - quadratic weights"
label variable t2_wtd_kappa_unk    "Weighted kappa - unknown weights"
label variable t2_wtd_kappa_unspec "Weighted kappa - unspecified weights"
label variable t2_wtd_kappa_avgunk "Weighted kappa, unknown average method"
label variable t2_brennan_prediger "Brennan and Prediger kappa"
label variable t2_icc              "ICC"
label variable t2_cronbach         "Cronbach's alpha"
label variable t2_krippendorff     "Krippendorff's alpha"
label variable t2_kfree            "Free-Marginal Multirater Kappa (kFree)"
label variable t2_kappa5pairs      "Kappa 5 pairs median"
label variable t2_spearman_brown   "Spearman-Brown prophecy reliability coefficient"
label variable t2_median3r_kappa   "Median 3-rater kappa"
label variable t2_median_cohen     "Median Cohen's kappa"
label variable t2_median_maj_kappa "Median majority kappa"
label variable t2_median_pw_kappa  "Median pairwise kappa"
label variable t2_mean_kappa       "Mean kappa"
label variable t2_mean_kappa_neo   "Mean or median Kappa 2 raters across neonates"
label variable t2_mean_cohen       "mean Cohen's kappa (Halford 2013 intrarater)"

* Sanity check: every row claimed by exactly one indicator.
* Any output here means an agreementType2 value in the data is not listed above.
egen byte t2_check = rowtotal(t2_*)
assert t2_check == 1, rc0
tab agreementType2 if t2_check != 1
drop t2_check

* Collapse to study level: max = 1 if the study used that type at least once.
collapse (max) t2_*, by(REFID)

count
di "Studies in Block A: " r(N)

tempfile agreementTypes2
save "`agreementTypes2'"


* =============================================================================
* BLOCK B: Broad agreement category indicators
*
* Derived from agreementType2 in-script rather than read from agreementType3
* in the source data. This is robust against blank agreementType3 values
* (e.g. Halford 2013 intrarater row, where agreementType3 was missing).
* =============================================================================
title "Block B: Broad agreement category indicators"

use "`featuredata'", clear

gen byte is_agreement = 0
replace is_agreement = 1 if agreementType2 == "Unadjusted agreement"
replace is_agreement = 1 if agreementType2 == "Weighted unadjusted agreement"
replace is_agreement = 1 if agreementType2 == "Median agreement"
replace is_agreement = 1 if agreementType2 == "Median majority perfect agreement"
replace is_agreement = 1 if agreementType2 == "Median pairwise perfect agreement"
replace is_agreement = 1 if agreementType2 == "Percent agreement 5 pairs median"

gen byte is_kappa = 0
replace is_kappa = 1 if agreementType2 == "Cohen's kappa"
replace is_kappa = 1 if agreementType2 == "Cohen's quadratically weighted kappa"
replace is_kappa = 1 if agreementType2 == "Fleiss' kappa"
replace is_kappa = 1 if agreementType2 == "Gwet's AC1"
replace is_kappa = 1 if agreementType2 == "Gwet's AC2"
replace is_kappa = 1 if agreementType2 == "Unweighted kappa"
replace is_kappa = 1 if agreementType2 == "Weighted kappa - quadratic weights"
replace is_kappa = 1 if agreementType2 == "Weighted kappa - unknown weights"
replace is_kappa = 1 if agreementType2 == "Weighted kappa - unspecified weights"
replace is_kappa = 1 if agreementType2 == "Weighted kappa, unknown average method"
replace is_kappa = 1 if agreementType2 == "Brennan and Prediger kappa"
replace is_kappa = 1 if agreementType2 == "ICC"
replace is_kappa = 1 if agreementType2 == "Cronbach's alpha"
replace is_kappa = 1 if agreementType2 == "Krippendorff's alpha"
replace is_kappa = 1 if agreementType2 == "Free-Marginal Multirater Kappa (kFree)"
replace is_kappa = 1 if agreementType2 == "Kappa 5 pairs median"
replace is_kappa = 1 if agreementType2 == "Spearman-Brown prophecy reliability coefficient"
replace is_kappa = 1 if agreementType2 == "Median 3-rater kappa"
replace is_kappa = 1 if agreementType2 == "Median Cohen's kappa"
replace is_kappa = 1 if agreementType2 == "Median majority kappa"
replace is_kappa = 1 if agreementType2 == "Median pairwise kappa"
replace is_kappa = 1 if agreementType2 == "Mean kappa"
replace is_kappa = 1 if agreementType2 == "Mean or median Kappa 2 raters across neonates"

gen byte is_kappa_agg = 0
replace is_kappa_agg = 1 if agreementType2 == "Fleiss' kappa, aggregate"
replace is_kappa_agg = 1 if agreementType2 == "mean Cohen's kappa"

gen byte is_unadj_agree_agg = 0
replace is_unadj_agree_agg = 1 if agreementType2 == "Unadjusted agreement, aggregate"

* Sanity check: every row claimed by exactly one broad category.
* Any output here means an agreementType2 value is missing from the mapping above.
egen byte broad_check = rowtotal(is_agreement is_kappa is_kappa_agg is_unadj_agree_agg)
assert broad_check == 1, rc0
tab agreementType2 if broad_check != 1
drop broad_check

* Collapse to study level.
collapse (max)                            ///
    hasAgreement     = is_agreement       ///
    hasKappaType     = is_kappa           ///
    hasKappaAgg      = is_kappa_agg       ///
    hasUnadjAgreeAgg = is_unadj_agree_agg ///
    , by(REFID)

label variable hasAgreement     "Study has unadjusted/percent agreement measure"
label variable hasKappaType     "Study has kappa-type measure (non-aggregate)"
label variable hasKappaAgg      "Study has aggregate kappa measure (mean Cohen, Fleiss agg)"
label variable hasUnadjAgreeAgg "Study has aggregate unadjusted agreement measure"

* Composite: study has at least one non-aggregate type.
gen byte hasKappaOrAgreement = (hasAgreement == 1 | hasKappaType == 1)
label variable hasKappaOrAgreement "Has kappa-type or agreement (non-aggregate)"
tab hasKappaOrAgreement

gen str hasAgreementCombo = ""
replace hasAgreementCombo = "Agreement only"           if hasAgreement==1 & hasKappaType==0
replace hasAgreementCombo = "Kappa-type only"          if hasAgreement==0 & hasKappaType==1
replace hasAgreementCombo = "Both agreement and kappa" if hasAgreement==1 & hasKappaType==1
replace hasAgreementCombo = "Aggregates only"          if hasKappaOrAgreement==0
label variable hasAgreementCombo "Agreement type combination (study level)"
tab hasAgreementCombo, miss

count
di "Studies in Block B: " r(N)

tempfile agreementTypes3
save "`agreementTypes3'"


* =============================================================================
* BLOCK C: Feature count and concatenated feature string
* =============================================================================
title "Block C: Feature count and feature string per study"

use "`featuredata'", clear

* Deduplicate to one row per (REFID, featurescored) before counting.
contract REFID featurescored
drop _freq

sort REFID featurescored
by REFID: gen int featurecount = _N

* Build semicolon-delimited string of all feature names, sorted alphabetically.
by REFID: gen allfeaturenames = featurescored[1]
by REFID: replace allfeaturenames = allfeaturenames[_n-1] + "; " + featurescored if _n > 1
by REFID: replace allfeaturenames = allfeaturenames[_N]

contract REFID featurecount allfeaturenames
drop _freq

label variable featurecount    "Count of distinct EEG features studied"
label variable allfeaturenames "All EEG features studied, separated by semicolons"

count
di "Studies in Block C: " r(N)

tempfile featurenames
save "`featurenames'"


* =============================================================================
* BLOCK D: Study-level intra/interrater classification
*
* Replaces the original encode + min/max trick with direct string comparison.
* =============================================================================
title "Block D: Study-level intra/interrater classification"

preserve
use "`featuredata'", clear

gen byte row_is_inter = (intra_or_inter == "No")
gen byte row_is_intra = (intra_or_inter == "Yes")

collapse (max) hasInterrater=row_is_inter hasIntrarater=row_is_intra, by(REFID)

gen str raterIntraType = ""
replace raterIntraType = "Interrater only"      if hasInterrater==1 & hasIntrarater==0
replace raterIntraType = "Intrarater only"       if hasInterrater==0 & hasIntrarater==1
replace raterIntraType = "Inter- and intrarater" if hasInterrater==1 & hasIntrarater==1
replace raterIntraType = "UNKNOWN - check data"  if raterIntraType==""

label variable raterIntraType "Study-level inter/intrarater classification (from features)"
tab raterIntraType

keep REFID raterIntraType
tempfile intratypes
save "`intratypes'"
restore


* =============================================================================
* FINAL MERGE: Assemble all blocks onto the design-level dataset
* =============================================================================
title "Final merge: assemble design-level dataset with feature abstracts"

use "`designdata'", clear

merge 1:1 REFID using "`agreementTypes2'", nogen
merge 1:1 REFID using "`agreementTypes3'", nogen
merge 1:1 REFID using "`featurenames'",    nogen
merge 1:1 REFID using "`intratypes'",      nogen

merge m:1 REFID using "`designdata'", keepusing(RaterExperience) nogen

* Consistency check: raterIntraType from features vs design-level IntraRater flag.
title "Consistency check: intra/interrater classification vs design-level IntraRater flag"
tab raterIntraType IntraRater, miss
list REFID Author Year raterIntraType IntraRater ///
    if raterIntraType == "Inter- and intrarater" & IntraRater == "No"
list REFID Author Year raterIntraType IntraRater ///
    if raterIntraType == "Intrarater only"        & IntraRater == "No"

* Summary of broad agreement type distribution across studies.
di _n "Broad agreement categories, prevalence across studies:"
tab hasAgreement
tab hasKappaType
tab hasKappaAgg
tab hasUnadjAgreeAgg
tab hasAgreementCombo

save "`outputdata'", replace

cap log close
translate "log\05-abstract-features-on-design-level-v2.smcl" ///
          "log\05-abstract-features-on-design-level-v2.pdf"
