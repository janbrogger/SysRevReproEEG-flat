cd C:\Midlertidig_Lagring\SysRevReproEeg\3CleanData
cap log close
local logfile "log\06-featuresdata-substudies.do"
cap log close
log using "`logfile'.smcl", replace
*ssc install title
*ssc install findname
pwd


use "C:\Midlertidig_Lagring\sysrevreproeeg\3CleanData\data-cleaned\2featuredata-cleaned" , clear

gen agreementtypeShort=agreementtype
replace agreementtypeShort="Brenn" if agreementtype=="Brennan and Prediger kappa"
replace agreementtypeShort="Cohen" if agreementtype=="Cohen's kappa"
replace agreementtypeShort="CohenM4" if agreementtype=="Cohen's kappa, median 4 raters"
replace agreementtypeShort="Cronb" if agreementtype=="Cronbach's alpha"
replace agreementtypeShort="KappaFleiss" if agreementtype=="Fleiss' kappa"
replace agreementtypeShort="Gwet1" if agreementtype=="Gwet's AC1"
replace agreementtypeShort="Gwet2" if agreementtype=="Gwet's AC2"
replace agreementtypeShort="KappaM5" if agreementtype=="Kappa 5 pairs median"
replace agreementtypeShort="KappaM6" if agreementtype=="Median rater Kappa 6 pairs"
replace agreementtypeShort="Kripp" if agreementtype=="Krippendorff's alpha"
replace agreementtypeShort="AgreeM6" if agreementtype=="Median 6 pairs agreement"
replace agreementtypeShort="AgreeM5" if agreementtype=="Percent agreement 5 pairs median"
replace agreementtypeShort="Spearm" if agreementtype=="Spearman–Brown prophecy reliability coefficient"
replace agreementtypeShort="Agree" if agreementtype=="Unadjusted agreement"
replace agreementtypeShort="AgreeM4" if agreementtype=="Unadjusted agreement, median of 4"
replace agreementtypeShort="WQKappa" if agreementtype=="Weighted kappa - quadratic weights"
replace agreementtypeShort="WUKappa" if agreementtype=="Weighted kappa - unknown weights"
replace agreementtypeShort="WUUKappa" if agreementtype=="Weighted kappa - unspecified weights"
replace agreementtypeShort="AgreeW" if agreementtype=="Weighted unadjusted agreement"
rename agreementtypeShort atype

rename agreementvalue value
keep REFID Author Year value atype featurescored
reshape wide value , i(REFID Year Author featurescored) j(atype) string
des value*
gen value2Agree=valueAgree
gen value2Kappa=.
gen kappaType=""
foreach v in Brenn Cohen CohenM4 Cronb Gwet1 Gwet2 ICC KappaFleiss KappaM5 KappaM6 Kripp Spearm WQKappa WUKappa WUUKappa {
    gen tag=(value2Kappa==. & value`v'!=.)
    replace value2Kappa=value`v' if tag
	replace kappaType="`v'" if tag
	drop tag
}

bysort featurescored: gen datacount=_N
gsort -Year Author
preserve
keep if datacount>10
bysort featurescored: list Author Year value2Agree value2Kappa kappaType 
restore



title "Do a trial run for one feature"
keep if featurescored == "Abnormal study (global): abnormal yes/no"

replace agreementtype=subinstr(agreementtype, " ", "", .)
replace agreementtype=subinstr(agreementtype, "'", "", .)
replace agreementtype=subinstr(agreementtype, "-", "_", .)
replace agreementtype=subinstr(agreementtype, ",", "_", .) 
keep REFID Author Year agreementtype agreementvalue agreementConfidenceIntervalLower agreementConfidenceIntervalUpper agreementT*

gsort -Year Author
list Author Year agreementtype agreementvalue 


keep if  agreementType3=="Agreement"

replace agreementvalue=agreementvalue/100 if agreementvalue>1
replace agreementConfidenceIntervalLower=agreementConfidenceIntervalLower/100 if agreementConfidenceIntervalLower>1
replace agreementConfidenceIntervalUpper=agreementConfidenceIntervalUpper/100 if agreementConfidenceIntervalUpper>1
duplicates report REFID Year Author
duplicates list REFID Year Author

list if REFID==72

gsort -Year Author
cap drop ylab
cap drop studylabel
cap drop studylabpos
gen ylab=_n
gen studylabel=Author+" "+string(Year,"%04.0f")
local minx=-0.3
gen studylabpos=`minx'
cap graph drop agreement
scatter ylab studylabpos  , ///
	mlab(studylabel) msym(none) mlabsize(tiny) ///
	legend(off)  || ///
scatter ylab agreementvalue  if agreementType3=="Agreement", ///
	yti("Study") xti("Reproducibility")   ///
	xsc(range(`minx' 1)) xlab(0(0.1)1, format(%3.1f)) ///
	ylab(, nolab) || ///
rcap agreementConfidenceIntervalLower agreementConfidenceIntervalUpper ylab if agreementType3=="Agreement", ///
	horiz  ///	
	title("Agreement") name(agreement)

graph export   "SeizureYesNoAgreement.png" , replace	





title "Investigate a simpler test case"
use "C:\Midlertidig_Lagring\sysrevreproeeg\3CleanData\data-cleaned\2featuredata-cleaned" , clear
keep if featurescored == "Abnormal study (global): Grand Total EEG Score 1999"
list REFID Year 
*browse
duplicates report REFID agreementtype
tab agreementtype
sort Year Author
bys agreementtype: list Author Year agreementvalue agreementConfidenceIntervalLower agreementConfidenceIntervalUpper

replace agreementConfidenceIntervalLower=agreementConfidenceIntervalLower/100 if agreementConfidenceIntervalLower>1
replace agreementConfidenceIntervalUpper=agreementConfidenceIntervalUpper/100 if agreementConfidenceIntervalUpper>1

gsort -Year Author
cap drop ylab
cap drop studylabel
cap drop studylabpos
gen ylab=_n
gen studylabel=Author+" "+string(Year,"%04.0f")
local minx=-0.3
gen studylabpos=`minx'
cap graph drop agreement
scatter ylab studylabpos  , ///
	mlab(studylabel) msym(none) ///
	legend(off)  || ///
scatter ylab agreementvalue  if agreementType3=="Agreement", ///
	yti("Study") xti("Reproducibility")   ///
	xsc(range(`minx' 1)) xlab(0(0.1)1, format(%3.1f)) ///
	ylab(, nolab) || ///
rcap agreementConfidenceIntervalLower agreementConfidenceIntervalUpper ylab if agreementType3=="Agreement", ///
	horiz  ///	
	title("Agreement") name(agreement)

cap graph drop kappa
scatter ylab agreementvalue  if agreementType3=="Kappa-type", ///
	yti("Study") xti("Reproducibility")   ///
	xsc(range(`minx' 1)) xlab(0(0.1)1, format(%3.1f)) ///
	ylab(, nolab) || ///
rcap agreementConfidenceIntervalLower agreementConfidenceIntervalUpper ylab if agreementType3=="Kappa-type", ///
	horiz  ///
	legend(off) ///
	title("Kappa") name(kappa)
graph combine agreement kappa , title("Grand Total EEG Score 1999")
graph export   "GrandTotalEEGScore1999.png" , replace	
	
	

count
cap log close
translate "`logfile'.smcl" "`logfile'.pdf"
