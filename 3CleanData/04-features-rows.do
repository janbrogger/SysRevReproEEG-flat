cd C:\Midlertidig_Lagring\SysRevReproEeg\3CleanData
cap log close
local logfile "log\04-features-rows.do"
cap log close
log using "`logfile'.smcl", replace
*ssc install title
*ssc install findname
pwd

use "C:\Midlertidig_Lagring\sysrevreproeeg\3CleanData\data-cleaned\2featuredata-raw" , clear



title "Count number of references before cleaning"
levels REFID
local refidsBefore ="`r(levels)'"
preserve
contract REFID
count
restore

*fix Kural 2022, and Kulick-soper 2022
replace featurescored="Epileptiform discharges yes/no" if Author=="Kural" & REFID==406 & featurescored=="Epileptiform discharges" & Year==2022
replace featurescored="Epileptiform discharges yes/no" if Author=="Kulick-Soper" & REFID==413 & featurescored=="Epileptiform discharges" & Year==2023
* Fix Zijlmans 2002 and 2008: unit of analysis is per-epoch/per-event within
* single recordings, not per-EEG. Reclassify as short clips.
rename D103 substudy

*==============================================================================
* Standardize feature names across studies
*
* Principles:
*   - Fix spelling errors (Hypsarrhytmia -> Hypsarrhythmia, Rhytmic -> Rhythmic)
*   - Merge identical features with slightly different names
*   - General category first: "Focal slowing" -> "Slowing focal"
*==============================================================================

title "Standardize feature names"

* --- 1. Hypsarrhythmia: fix missing 'h' throughout ---
* Affects ~50 feature names. Uses usubinstr for global replacement.
replace featurescored = usubinstr(featurescored, "Hypsarrhytmia", "Hypsarrhythmia", .)

* --- 2. Hypsarrhythmia: merge equivalent binary detection features ---
* "present/absent" is the same as "yes/no" for binary hypsarrhythmia detection.
* NB: "or modified hypsarrhythmia yes/no" is a DIFFERENT, broader feature — do not merge.
replace featurescored = "Hypsarrhythmia yes/no" if featurescored == "Hypsarrhythmia present/absent"

* --- 3. Hypsarrhythmia BASED score: standardize naming ---
* "Hypsarrhythmia BASED" and "Hypsarrhythmia:BASED score (final)" are the same
* as "Hypsarrhythmia - BASED score". Use consistent name.
* NB: "Hypsarrhythmia - BASED score low <=2, >=3" is a DIFFERENT feature (binary split).
replace featurescored = "Hypsarrhythmia BASED score" if featurescored == "Hypsarrhythmia BASED"
replace featurescored = "Hypsarrhythmia BASED score" if featurescored == "Hypsarrhythmia - BASED score"
replace featurescored = "Hypsarrhythmia BASED score" if featurescored == "Hypsarrhythmia:BASED score (final)"

* --- 4. Rhythmic or periodic pattern: fix typo ---
replace featurescored = "Rhythmic or periodic pattern yes/no" if featurescored == "Rhytmic or periodic pattern yes/no"

* --- 5. Focal slowing: general category first ---
replace featurescored = "Slowing focal yes/no" if featurescored == "Focal slowing yes/no"

* --- 6. RPP modifier: standardize plus modifier name ---
replace featurescored = "RPP modifier: any plus modifier" if featurescored == "RPP modifier: plus modifier"

* --- 7. Seizures: bare name is the same as yes/no ---
replace featurescored = "Seizures yes/no" if featurescored == "Seizures"

* --- 8. Epileptiform: add "discharges" where missing ---
* "Epileptiform focal yes/no" and "Epileptiform generalized yes/no" are the same
* as "Epileptiform discharges focal yes/no" and "Epileptiform discharges generalized yes/no".
replace featurescored = "Epileptiform discharges focal yes/no" if featurescored == "Epileptiform focal yes/no"
replace featurescored = "Epileptiform discharges generalized yes/no" if featurescored == "Epileptiform generalized yes/no"




title "Fix agreement value to numeric"
rename D203 agreementvalue
replace agreementvalue = usubinstr(agreementvalue, ",", ".",.) 
replace agreementvalue ="" if strpos(agreementvalue, "<")>0
replace agreementvalue ="" if strpos(agreementvalue, "NA")>0
replace agreementvalue ="" if strpos(agreementvalue, "/")>0
replace agreementvalue ="" if strpos(agreementvalue, "NaN")>0
tab agreementvalue	
destring agreementvalue, replace
label variable agreementvalue "Agreement value"




title "References with no agreement data"
preserve
gen missingagreementvalue=agreementvalue==.
tab missingagreementvalue
contract REFID missingagreementvalue
rename _freq freq
reshape wide freq, i(REFID) j(missingagreementvalue)
keep if freq1==1 & freq0==.
levelsof REFID
restore

drop if agreementvalue==.


title "Rename confidence interval variables"
rename D302Whatisthelower95confi agreementConfidenceIntervalLower
rename D302Whatistheupper95confi agreementConfidenceIntervalUpper

title "Fix confidence intervals to numeric"
replace agreementConfidenceIntervalLower ="" if agreementConfidenceIntervalLower=="."
destring agreementConfidenceIntervalLower , replace
destring agreementConfidenceIntervalUpper , replace



title "Rename number of raters"
rename D114Howmanyratersareinvolve NumRatersThisFeaturePoint
label variable NumRatersThisFeaturePoint "Number of raters"

title "Investigate and clean agreementtype"
rename D115Whatisthetypeofagreeme agreementtype
tab agreementtype

drop if agreementtype=="Coefficient of variation" 
drop if agreementtype=="Paired Student t test"
drop if agreementtype=="Product-moment correlation coefficient r"
drop if agreementtype==`"correlation. Seizures were given another variable "perception" representing confidence level."'
drop if agreementtype=="inter-reader correlations"
drop if agreementtype=="inter-reader pearson correlations"
drop if agreementtype=="Spearman correlation coefficient"
drop if agreementtype=="Number of EEGs assigned to each outcome by each rater in Table 1."
drop if agreementtype=="Negative agreement"
drop if agreementtype=="Positive agreement"
drop if agreementtype=="Pearson correlation coefficient"
drop if agreementtype=="Modified kappa"

tab agreementtype

title "Investigate agreementtype"
preserve
contract REFID agreementtype
tab agreementtype, sort
restore
replace agreementtype="Cohen's kappa" if agreementtype=="Binary adjusted agreement - Cohen's kappa"
replace agreementtype="Fleiss' kappa" if agreementtype=="Multirater kappa - Fleiss"
replace agreementtype="Brennan and Prediger kappa" if agreementtype=="G coefficient"
replace agreementtype="ICC" if agreementtype=="intraclass correlation coefficient"
replace agreementtype="ICC" if agreementtype=="Intraclass correlation coefficient"
replace agreementtype="ICC" if agreementtype=="Intraclass correlation coefficients"
replace agreementtype="ICC" if strpos(agreementtype,"intraclass correlation coefficient")>0
replace agreementtype="ICC" if strpos(agreementtype,"Intraclass correlation coefficient")>0
replace agreementtype="Gwet's AC1" if agreementtype=="Gwet agreement 1"
replace agreementtype="Gwet's AC2" if agreementtype=="Gwet agreement 2"
replace agreementtype="Gwet's AC2" if agreementtype=="Gwet AC2"
replace agreementtype="Gwet's AC1" if agreementtype=="Gwet AC1"
replace agreementtype="Gwet's AC2" if agreementtype=="Gwet agreement AC2"
replace agreementtype="Unadjusted agreement" if agreementtype=="unadjusted agreement"
replace agreementtype="Unadjusted agreement" if agreementtype=="unknown resident vs epilepsy team, unadjusted agreement can be calculated"
replace agreementtype="Unadjusted agreement" if agreementtype=="Unadjusted agreement, unclear which raters were involved/grouped."
replace agreementtype="Unadjusted agreement" if agreementtype=="Percent agreement"
replace agreementtype="Unadjusted agreement" if agreementtype=="Proportion of agreement"
replace agreementtype="Unadjusted agreement" if agreementtype=="Proportion of overall agreement"
replace agreementtype="Unadjusted agreement" if agreementtype=="Percentage agreement (unadjusted agreement)"
replace agreementtype="Unadjusted agreement" if agreementtype=="Seizure agreement"
replace agreementtype="Krippendorff's alpha" if agreementtype=="Krippendorff's method (alpha)"
replace agreementtype="Cronbach's alpha" if agreementtype=="ICC Cronbach's alpha"
replace agreementtype="Weighted kappa - unspecified weights" if REFID==211

preserve
contract REFID agreementtype
tab agreementtype, sort
restore


*Look at infrequent ones only, with full text of agreementtype
preserve
contract agreementtype
gsort -_freq
list agreementtype _freq if _freq<7 , sep(0) noobs
restore

*List uncommon agreement types
preserve
contract REFID Author Year agreementtype
tab agreementtype , sort
drop if agreementtype=="Unadjusted agreement" ///
	| agreementtype=="Cohen's kappa" /// 
	| agreementtype=="Fleiss' kappa" ///
	| agreementtype=="ICC" ///
	| agreementtype=="Gwet's AC1" ///
	| agreementtype=="Gwet's AC2" ///
	| agreementtype=="Brennan and Prediger kappa" ///
	| agreementtype=="Krippendorff's alpha'" 
list REFID Author Year agreementtype  , sep(5) noobs
restore

gen gAgreementTypeAggregate=0
replace gAgreementTypeAggregate=1 if agreementtype=="Unadjusted agreement, median of 4"
replace gAgreementTypeAggregate=1 if agreementtype=="Cohen's kappa, median 4 raters"
replace gAgreementTypeAggregate=1 if agreementtype=="Median 6 pairs agreement"
replace gAgreementTypeAggregate=1 if agreementtype=="Median rater Kappa 6 pairs"
replace gAgreementTypeAggregate=1 if agreementtype=="Unadjusted agreement, median of 4"
replace gAgreementTypeAggregate=1 if agreementtype=="Weighted kappa, pairwise"
replace gAgreementTypeAggregate=1 if agreementtype=="Binary adjusted agreement - Cohen's kappa, aggregated"

tab agreementtype gAgreementTypeAggregate

*Final agreeement types, by whether aggregate or not
preserve
contract agreementtype gAgreementTypeAggregate
gsort gAgreementTypeAggregate -_freq
list gAgreementTypeAggregate agreementtype _freq  , sep(0) noobs
restore

gen agreementType2=agreementtype
replace agreementType2=agreementtype
replace agreementType2="Cohen's kappa, aggregate" if agreementtype=="Unadjusted agreement, median of 4"
replace agreementType2="Cohen's kappa, aggregate" if agreementtype=="Median rater Kappa 6 pairs"
replace agreementType2="Cohen's kappa, aggregate" if agreementtype=="Cohen's kappa, median 4 raters"
replace agreementType2="Unadjusted agreement, aggregate" if agreementtype=="Median 6 pairs agreement"

*Agreeement types so far, by whether aggregate or not
preserve
contract agreementType2 gAgreementTypeAggregate
gsort gAgreementTypeAggregate -_freq
list gAgreementTypeAggregate agreementType2 _freq  , sep(0) noobs
restore

title "Investigate number of raters, outcome classes and agreement types"
tab D106HowmanyEEGoutcomeclasse if agreementtype=="Cohen's kappa", sort
tab D106HowmanyEEGoutcomeclasse if agreementtype=="Fleiss' kappa" , sort
tab D112Howmanyrater if agreementtype=="Cohen's kappa"
tab D112Howmanyrater if agreementtype=="Fleiss' kappa"

replace agreementtype="Fleiss' kappa" if D112Howmanyrater>2 & D112Howmanyrater!=. & agreementtype=="Cohen's kappa"
replace agreementType2="Fleiss' kappa, aggregate" if D112Howmanyrater>2 & D112Howmanyrater!=. & agreementType2=="Cohen's kappa, aggregate"
replace agreementtype="Cohen's kappa" if D112Howmanyrater==2 & agreementtype=="Fleiss' kappa"

tab agreementtype , sort
tab agreementType2 , sort
label variable agreementType2 "Agreement type"

gen agreementType3=""
replace agreementType3="Kappa-type" if ///
	agreementType2=="Cohen's kappa" ///
	| agreementType2=="Fleiss' kappa" ///
	| agreementType2=="Gwet's AC1" ///
	| agreementType2=="Gwet's AC2" ///
	| agreementType2=="ICC" ///
	| agreementType2=="Cronbach's alpha" ///
	| agreementType2=="Krippendorff's alpha" ///
	| agreementType2=="Brennan and Prediger kappa" ///
	| agreementType2=="Weighted kappa - quadratic weights" ///
	| agreementType2=="Weighted kappa - unspecified weights" ///
	| agreementType2=="Spearman–Brown prophecy reliability coefficient" 
	
replace agreementType3="Agreement" if ///	
	agreementType2=="Unadjusted agreement" 
	
replace agreementType3="Unadjusted agreement, aggregate" if ///	
	agreementType2=="Unadjusted agreement, aggregate" 

replace agreementType3="Kappa-type, aggregate" if ///	
	agreementType2=="Fleiss' kappa, aggregate" 
tab agreementType3, missi

label variable agreementType3 "Agreement type"

title "Agreement type as kappa, Gwet AC, Gwet AC2, ICC"
gen agreementType4=""
replace agreementType4="Kappa Cohen/Fleiss" if agreementType2=="Cohen's kappa" | agreementType2=="Fleiss' kappa" 
replace agreementType4="Gwet AC1" if agreementType2=="Gwet's AC1" 	
replace agreementType4="Gwet AC2" if agreementType2=="Gwet's AC2" 
replace agreementType4="ICC" if agreementType2=="ICC" 
replace agreementType4="Cronbachs" if agreementType2=="Cronbach's alpha" 
replace agreementType4="Krippendorff" if agreementType2=="Krippendorff's alpha" 
replace agreementType4="Weighted kappa x2" if agreementType2=="Weighted kappa" 
replace agreementType4="Weighted kappa unsp" if agreementType2=="Weighted kappa - unspecified weights" 
replace agreementType4="Brennan-Prediger" if agreementType2=="Brennan and Prediger kappa" 
replace agreementType4="Spearman–Brown" if agreementType2=="Spearman–Brown prophecy reliability coefficient" 
replace agreementType4="Agreement" if agreementType2=="Unadjusted agreement" 
replace agreementType4="Agreement, aggregate" if agreementType2=="Unadjusted agreement, aggregate" 
replace agreementType4="Kappa, aggregate" if agreementType2=="Fleiss' kappa, aggregate" 
tab agreementType4, missi
label variable agreementType4 "Agreement type"
	
*Agreeement types so far, by whether aggregate or not
preserve
contract agreementType2 gAgreementTypeAggregate
gsort gAgreementTypeAggregate -_freq
list gAgreementTypeAggregate agreementType2 _freq  , sep(0) noobs
restore

*Agreeement types so far, coarsely classified
preserve
contract agreementType3 
gsort  -_freq
list agreementType3 _freq  , sep(0) noobs
restore


title "Count number of references after dropping"
levels REFID
local refidsAfter="`r(levels)'"
preserve
contract REFID
count
restore

title "Compare REFID list before and after cleaning"
local droppedREFIDs ""
foreach r1 in `refidsBefore' {
    local found=0
    foreach r2 in `refidsAfter' {	    
	    if "`r1'"=="`r2'" {
		    local found=1
		}
	}	
	if `found'==0 {
	    local droppedREFIDs="`droppedREFIDs' `r1'"
	    di "REFID dropped `r1'"
	}
}

title "Dropped REFIDs"
di "Dropped REFIDs: `droppedREFIDs' "





*********************
title "Fix detaillevel"
replace detaillevel="1" if detaillevel=="1 - Global"
destring detaillevel, replace
tab detaillevel


****************************
title "Tabulation of raters"
replace rater="Eivind Aanestad" if rater=="Data extracter 1 (change name later)"
tab rater

******************
title "Clean dirty data"
summ REFYEAR

title "Look at features and categories"
*************
title "Features scored, intrarater etc."
tab featurescored
tab featurescored , sort
rename D101 featuretype

des D10* D11* DD11*
rename D108 featureNameCat01
rename D109 featureNameCat02
rename D110 featureNameCat03
rename D111 featureNameCat04
rename DD112 featureNameCat05
rename DD113 featureNameCat06
rename DD114 featureNameCat07
rename DD115 featureNameCat08
rename DD116 featureNameCat09
rename DD117 featureNameCat10
rename D107 featureNames
rename DD106 featureScoringSystem
rename D106HowmanyEEGoutcomeclasse featureOutcomeCats
des feature*


**make feature list with number of references
frame change default
preserve
contract featurescored
rename _freq NumRowsAgreement
drop NumRowsAgreement
gen NumRefids=0
tempfile featurelist
save "`featurelist'"
restore

frame change default
cap frame drop features
frame create features
frame change features
use "`featurelist'" , clear
count
forvalues i=1(1)`r(N)' {
	frame change features
	local feature =featurescored[`i']
	frame change default
	qui levelsof REFID if strupper(featurescored)==strupper(`"`feature'"')
	local NumRefids=`r(r)'
	frame change features
	qui replace NumRefids=`NumRefids' if _n==`i'
}
frame change features
gsort -NumRefids featurescored
export excel using "C:\Midlertidig_Lagring\sysrevreproeeg\3CleanData\output\featureList", sheet("FeatureList") firstrow(variables) replace
frame change default
frame drop features



******
tab featuretype
bys featuretype: count 
bys featuretype: tab featurescored , sort
tab featuretype, sort

title "Type of statistic"
rename D113Isthisanintraraterdata intra_or_inter
tab intra_or_inter
label variable intra_or_inter "Intra-rater?"

title "Intrarater only"
tab featuretype if intra_or_inter=="Yes", sort
bys featuretype: tab featurescored if intra_or_inter=="Yes", sort

title "Fix number of EEG outcome classes"
replace featureOutcomeCats="" if featureOutcomeCats=="?"
replace featureOutcomeCats="" if featureOutcomeCats=="unknown"
replace featureOutcomeCats="99" if featureOutcomeCats=="999"
tab featureOutcomeCats
destring featureOutcomeCats, replace
tab featureOutcomeCats
replace featureOutcomeCats=99 if featureOutcomeCats==0
replace featureOutcomeCats=99 if featureOutcomeCats>14
tab featureOutcomeCats

title "Look at is this an average data"
rename D200 isaverage
tab isaverage , missi
list REFID REFAUTH REFYEAR isaverage D201 D202 if isaverage==""
label variable isaverage "Average of all raters?"
rename D201 RaterID1
label variable RaterID1 "Rater 1 ID"
rename D202 RaterID2
label variable RaterID2 "Rater 2 ID"

title "Look at substudy"
tab substudy, missi
*TODO: look at remaining studies with high number of substudies
tab DD103 , missi


replace substudy=substudy+" "+DD103 if DD103!=""

title "Exclude some temporal-based figures which are difficult"
list REFID Author substudy if strpos(upper(substudy),"TEMPORAL")>0
drop if REFID==162 & substudy=="1 Temporal-based agreement"
list REFID Author substudy if strpos(upper(substudy),"EVENT")>0
drop if REFID==162 & substudy=="1 Event-based agreement"
*drop if REFID==157 & substudy=="event-duration based"

title "Look at feature categories"
list REFID REFY featurescored if strpos(featurescored,"+")>0 | strpos(featurescored,"plus")>0 , sep(0) noobs
list REFID REFY featurescored if strpos(lower(featurescored),"modifier")>0  , sep(0) noobs
list REFID REFY featurescored if strpos(lower(featurescored),"prefix")>0  , sep(0) noobs
list REFID REFY featurescored if strpos(lower(featurescored),"sirpid")>0



preserve
collapse (min) AgrMin=agreementvalue (max) AgrMax=agreementvalue , by(agreementtype)
list  , sep(0) noobs
restore


preserve
collapse (min) AgrMin=agreementvalue (max) AgrMax=agreementvalue , by(agreementtype)
list  , sep(0) noobs
restore

***Classify as 0-1 or 0-100.
bysort agreementtype: summ agreementvalue 
gen agreementtypeTo100=0
replace agreementtypeTo100=1 if agreementtype=="Median 6 pairs agreement"
replace agreementtypeTo100=1 if agreementtype=="Percent agreement"
replace agreementtypeTo100=1 if agreementtype=="Seizure agreement"
replace agreementtypeTo100=1 if agreementtype=="Unadjusted agreement"
replace agreementtypeTo100=1 if agreementtype=="Unadjusted agreement, median of 4"
replace agreementtypeTo100=0 if agreementtype=="Gwet AC1 for categorical, AC2 for ordinal"
replace agreementvalue=agreementvalue/100 if agreementtype=="Gwet AC1 for categorical, AC2 for ordinal"

replace agreementtypeTo100=1 if agreementtype=="Proportion of overall agreement "

preserve
collapse (min) AgrMin=agreementvalue (max) AgrMax=agreementvalue , by(agreementtype agreementtypeTo100)
sort agreementtypeTo100
list  , sep(0) noobs
restore

sort REFID
list REFID agreementtype agreementvalue if agreementtypeTo100==1 & agreementvalue<1
foreach v of varlist agreementvalue agreementConfidenceIntervalLower agreementConfidenceIntervalUpper  {
	replace `v'=`v'*100 if agreementtypeTo100==1 & `v'<=1
}
list REFID agreementtype agreementvalue if agreementtypeTo100==0 & agreementvalue>1
foreach v of varlist agreementvalue agreementConfidenceIntervalLower agreementConfidenceIntervalUpper  {
	replace `v'=`v'/100 if agreementtypeTo100==0 & `v'>1
}


preserve
collapse (min) AgrMin=agreementvalue (max) AgrMax=agreementvalue , by(agreementtype agreementtypeTo100)
sort agreementtypeTo100
list  , sep(0) noobs
restore

gen agreementunadjusted=agreementtypeTo100
replace agreementunadjusted=1 if agreementtype=="Proportion of overall agreement"
replace agreementunadjusted=1 if agreementtype=="Percentage agreement (unadjusted agreement)"
replace agreementunadjusted=1 if agreementtype=="Proportion of overall agreement"
replace agreementunadjusted=1 if agreementtype=="Proportion of agreement"

replace agreementvalue=agreementvalue*100 if agreementtype=="Proportion of agreement"
replace agreementvalue=agreementvalue*100 if agreementtype=="Proportion of overall agreement"
replace agreementvalue=agreementvalue*100 if agreementtype=="Percentage agreement (unadjusted agreement)"


preserve
collapse (min) AgrMin=agreementvalue (max) AgrMax=agreementvalue , by(agreementtype agreementunadjusted)
sort agreementunadjusted
list  , sep(0) noobs
restore

drop agreementtypeTo100

title "agreementvalue is now is now 0-100 if agreementunadjusted=1, else 0-1"

foreach v of varlist agreementvalue agreementConfidenceIntervalLower agreementConfidenceIntervalUpper  {
	replace `v'=`v'/100 if agreementunadjusted==1
}


list REFID REFAUTH REFY* feature* agreem* if agreementunadjusted==1 & agreementvalue<5
sort date
list REFID REFAUTH REFY* feature* agreem* if REFID==166 , sep(0) noobs
sort featurescored
bys intra: list REFID REFAUTH REFY*  intra feature* agreem* if REFID==166 , sep(0) noobs
**Westhall's data are abstracted correctly


***Fix featuretype for some variables
replace featuretype="Seizure-related" if featurescored=="Seizure count"
replace featuretype="Interictal-related" if featurescored=="Slowing"
replace featuretype="Coma-related" if featurescored=="Reactivity"


title "Look at new modality variable"
rename D500 DisplayModalityMain
rename D501 DisplayModalityDetail
rename D502 SubstudyForPublish
rename D503 NumberOfEegElecFromFeature
rename D504 ExplanationOfResult
label variable DisplayModalityMain "EEG display modality"
label variable DisplayModalityDetail  "EEG display modality"
label variable SubstudyForPublish "Substudy in paper"
label variable NumberOfEegElecFromFeature "Number of EEG electrodes"
label variable ExplanationOfResult "Explanation of result, compared to other studies of same feature"


title "Generate Number of EEG electrodes per feature, if available or take it from design level"
cap drop _merge
merge m:1 REFID using "C:\Midlertidig_Lagring\sysrevreproeeg\3CleanData\data-cleaned\1designleveldata-varscleaned", keepusing(NumberOfEegElectFromDesign)
gen gNumberOfEegElectrodes=NumberOfEegElecFromFeature if NumberOfEegElecFromFeature!=.
replace gNumberOfEegElectrodes=NumberOfEegElectFromDesign if gNumberOfEegElectrodes==. & NumberOfEegElectFromDesign!=.
label variable gNumberOfEegElectrodes "Number of EEG electrodes (study-level or feature-level, if available)"
codebook gNumberOfEegElectrodes

title "Look at our assessed experience level"
rename D505 RaterExpOurAssessed
label variable RaterExpOurAssessed "Rater experience, our assessment"


title "Compare REFIDs to look for dropped ones at end of script"
levels REFID
local refidsAfter="`r(levels)'"
preserve
contract REFID
count
restore

title "Compare REFID list before and after cleaning"
local droppedREFIDs ""
foreach r1 in `refidsBefore' {
    local found=0
    foreach r2 in `refidsAfter' {	    
	    if "`r1'"=="`r2'" {
		    local found=1
		}
	}	
	if `found'==0 {
	    local droppedREFIDs="`droppedREFIDs' `r1'"
	    di "REFID dropped `r1'"
	}
}

di "Dropped REFIDs: `droppedREFIDs' "
preserve
use "C:\Midlertidig_Lagring\sysrevreproeeg\3CleanData\data-cleaned\2featuredata-raw" , clear
contract REFID Author Year
count
foreach ref in `droppedREFIDs' {
    list REFID Author Year if REFID==`ref'
}
restore

save "C:\Midlertidig_Lagring\sysrevreproeeg\3CleanData\data-cleaned\2featuredata-cleaned" , replace





count
cap log close
translate "`logfile'.smcl" "`logfile'.pdf"
