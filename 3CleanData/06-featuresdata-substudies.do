cd C:\Midlertidig_Lagring\SysRevReproEeg\3CleanData
cap log close
local logfile "log\06-featuresdata-substudies.do"
cap log close
log using "`logfile'.smcl", replace
*ssc install title
*ssc install findname
pwd

frame change default
use "C:\Midlertidig_Lagring\sysrevreproeeg\3CleanData\data-cleaned\2featuredata-cleaned" , clear
local minimumfeaturecount=3

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

gen featureCategory=""
replace featureCategory="1 Global scales" if strpos(featurescored,"Abnormal study (global):")>0
replace featureCategory="2 Seizures" if substr(featurescored, 1, 7) == "Seizure"
replace featureCategory="2 Seizures" if featurescored== "Status epilepticus yes/no"
replace featureCategory="3 IEDs" if substr(featurescored, 1, 12) == "Epileptiform"
replace featureCategory="4 Coma ACNS SCCET" if substr(featurescored, 1, 3) == "RPP"
replace featureCategory="4 Coma ACNS SCCET" if strpos(featurescored, "ACNS SCCET 2012")
replace featureCategory="4 Coma ACNS SCCET" if featurescored=="Background dominant frequency"
replace featureCategory="4 Coma ACNS SCCET" if featurescored=="Reactivity yes/no"
replace featureCategory="4 Coma ACNS SCCET" if featurescored=="Rhythmic or periodic pattern yes/no"
replace featureCategory="5 Coma other" if featurescored=="Burst suppression yes/no"
replace featureCategory="5 Coma other" if featurescored=="Reactivity-sound yes/no"
replace featureCategory="5 Coma other" if featurescored=="Bursts yes/no"
replace featureCategory="5 Coma other" if featurescored=="Background continuity yes/no"
replace featureCategory="6 Neonatal" if substr(featurescored,1,19)=="Neonatal background"
replace featureCategory="7 Other" if featurescored=="Slowing yes/no"
replace featureCategory="7 Other" if featurescored=="Focal slowing yes/no"
replace featureCategory="7 Other" if featurescored=="ECT seizure duration"
gen featureCount=1



label variable NumRefids "Number of papers"
label variable featurescored "Feature scored"
label variable featureCount "Feature count"
drop featureCount

keep if NumRefids>=`minimumfeaturecount' | NumRefids==.


save "C:\Midlertidig_Lagring\sysrevreproeeg\3CleanData\data-cleaned\2featuredata-cleaned-minimum3" , replace

count
cap log close
translate "`logfile'.smcl" "`logfile'.pdf"
