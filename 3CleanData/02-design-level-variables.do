cd C:\Midlertidig_Lagring\sysrevreproeeg\3CleanData
cap log close
local logfile "log\02-design-level-variables"
cap log close
log using "`logfile'.smcl", replace
*ssc install title
*ssc install findname
pwd

use "C:\Midlertidig_Lagring\sysrevreproeeg\3CleanData\data-cleaned\1designleveldata", clear
tab _merge
drop _merge
foreach v of varlist DF DG DH DI DJ DK  {
	di "`v'"
	tab `v'
}
title "Drop empty variables"
drop DF DG DH DI DJ DK

title "Fix timestamp has different variables between old and update"

gen double ts_unified = cond(!missing(Timestamp), Timestamp, Tidsmerke)
format ts_unified %tc

assert !missing(ts_unified)
format ts_unified %tc

* Check results
list REFID ReviewPeriod ts_unified if missing(ts_unified), noobs
drop Timestamp Tidsmerke
rename ts_unified Timestamp
codebook Timestamp
rename Timestamp DateSubmitted

****************************
title "Tabulation, fix raters"
rename Q001Whoareyou  rater
replace rater="Eivind Aanestad" if rater=="Data extracter 1 (change name later)"
tab rater

****************************
title "Fix email address"
replace Epostadresse=EmailAddress if ReviewPeriod=="Old2018" & Epostadresse=="" & EmailAddress != ""
drop EmailAddress
rename Epostadresse EmailAddress
tab EmailAddress
replace EmailAddress="jan@brogger.no" if EmailAddress=="janbrogger@gmail.com"
tab EmailAddress rater , missi
replace EmailAddress="eivind.aanestad@gmail.com" if rater=="Eivind Aanestad" & EmailAddress==""
replace EmailAddress="jan@brogger.no" if rater=="Jan Brogger" & EmailAddress==""
tab EmailAddress rater , missi


****************************
title "Fix author names"
* --- Verify discrepancies before fixing ---
display _newline(1)
display "=== BEFORE fixes: listing discrepancies ==="
list REFID REFAUTH Author REFAUTH if Author != REFAUTH, noobs

* -------------------------------------------------------------------------
* 1. REFID 35 & 36: Swapped REFAUTH values
*    REFID 35: Krauss GL et al. "Anterior cheek electrodes..."
*    REFID 36: Hostetler WE et al. "Assessment of a computer program..."
* -------------------------------------------------------------------------
*replace Author  = "Krauss" if REFID == 36
*replace Author  = "Hostetler" if REFID == 35

* -------------------------------------------------------------------------
* 2. REFID 241: Dhakar MB et al. "Developing a Standardized Approach..."
*    REFAUTH had last/senior author Maciel instead of first author Dhakar
* -------------------------------------------------------------------------
replace REFAUTH = "Dhakar" if REFID == 241

* -------------------------------------------------------------------------
* 3. REFID 409: Nagarajan L et al. "CARFS7: A guide and proforma..."
*    REFAUTH had typo "Nagarajana" (extra trailing 'a')
* -------------------------------------------------------------------------
replace REFAUTH = "Nagarajan" if REFID == 409

* -------------------------------------------------------------------------
* 4. REFID 441: Spöndlin L et al. "EEG compatibility fitness to drive"
*    Author has umlaut (Spöndlin), REFAUTH was missing it (Spondlin)
* -------------------------------------------------------------------------
replace REFAUTH = "Spöndlin" if REFID == 441

* --- Verify all discrepancies are resolved ---
display _newline(1)
display "=== AFTER fixes: checking for remaining discrepancies ==="
count if Author != REFAUTH
list REFID Author REFAUTH if Author != REFAUTH, noobs

title "Check author names between master list and design-level data"
count if Author!=REFAUTH
list REFID Author REFAUTH if Author!=REFAUTH


****************
title "Inspect variables"
title "Q005 Mentions agreement"
tab Q005
*No errors

title "Q006 EEG can be reproduced"
tab Q006


title "EEG electrode setup"
tab Q007
tab Q008
tab Q009
tab Q007 if Q009==.

title "Length of EEG Q010 etc"
tab Q010

*Fix Ziljmans short clips status
replace Q010AreonlyshortEEGclipsbe = "Yes" if Author=="Zijlmans" & Year==2002
replace Q010AreonlyshortEEGclipsbe = "Yes" if Author=="Zijlmans" & Year==2008



tab Q011
tab Q012
replace Q012="Unclear" if Q012=="Unclerar"
tab Q012
tab Q013
replace Q013="Seizures, events or other subset" if strpos(Q013,"Seizures, events or other subset")>0
tab Q013
tab Q014
tab Q015L
codebook Q015L
destring Q015L , replace
summ Q015L
*Needs to be categorized
rename Q015Length LengthEEG
label variable LengthEEG "Length of EEG (minutes)"


title "Population"
tab Q015S
tab Q016
tab Q017


title "EEG setting"
tab Q018
tab Q019
tab Q020
bys Q019: tab Q021
bys Q020: tab Q021

list Q019 Q021 if strpos(Q021, "ECT")>0
replace Q019="Psychiatry" if strpos(Q021, "ECT")>0 & strpos(Q021, "BECTS")==0
replace Q019="Psychiatry" if strpos(Q021, "electroconvulsive")>0
replace Q019="Dementia" if strpos(Q021, "Creutzfeldt")>0
list Q019 Q021 if REFID==89 | REFID==88

replace Q019="Coma/critical care, not neonatal or status epilepticus" if REFID==89
replace Q019="Coma/critical care, not neonatal or status epilepticus" if REFID==88

bys Q019: tab Q021
list REFID if strpos(Q021, "endart")>0
replace Q019="IOM" if REFID==39
list REFID if strpos(Q021, "IOM")>0
replace Q019="IOM" if REFID==39
replace Q019="IOM" if REFID==126
list REFID Q021 if strpos(Q019, "Standard")>0

**************
title "Age group"
tab Q026
tab Q027Agecategorycoveredonec
tab Q028Agecategoryneonatal
tab Q029Agecategorypediatric
tab Q030Agecategoryadult
tab Q031Agecategorygeriatric
gen gAgeCat1=.
label define gAgeCat1 ///
1 "Neonatal only" ///
2 "Neonatal & pediatric" ///
3 "Pediatric" ///
4 "Pediatric and adult" ///
5 "Neonatal & pediatric & adult" ///
6 "Adult only" ///
7 "Adult and geriatric" ///
8 "Geriatric only" ///
9 "Pediatric, adult and geriatric" ///
10 "All age ranges" ///
99 "Unknown"
label values gAgeCat1 gAgeCat1
label variable gAgeCat1 "Population age group"
replace gAgeCat1=1 if Q028Agecategoryneonatal=="Yes" & Q029Agecategorypediatric!="Yes" & Q030Agecategoryadult!="Yes" & Q031Agecategorygeriatric!="Yes" & gAgeCat==.
replace gAgeCat1=2 if Q028Agecategoryneonatal=="Yes" & Q029Agecategorypediatric=="Yes" & Q030Agecategoryadult!="Yes" & Q031Agecategorygeriatric!="Yes" & gAgeCat==.
replace gAgeCat1=3 if Q028Agecategoryneonatal!="Yes" & Q029Agecategorypediatric=="Yes" & Q030Agecategoryadult!="Yes" & Q031Agecategorygeriatric!="Yes" & gAgeCat==.
replace gAgeCat1=4 if Q028Agecategoryneonatal!="Yes" & Q029Agecategorypediatric=="Yes" & Q030Agecategoryadult=="Yes" & Q031Agecategorygeriatric!="Yes" & gAgeCat==.
replace gAgeCat1=5 if Q028Agecategoryneonatal=="Yes" & Q029Agecategorypediatric=="Yes" & Q030Agecategoryadult=="Yes" & Q031Agecategorygeriatric!="Yes" & gAgeCat==.
replace gAgeCat1=6 if Q028Agecategoryneonatal!="Yes" & Q029Agecategorypediatric!="Yes" & Q030Agecategoryadult=="Yes" & Q031Agecategorygeriatric!="Yes" & gAgeCat==.
replace gAgeCat1=7 if Q028Agecategoryneonatal!="Yes" & Q029Agecategorypediatric!="Yes" & Q030Agecategoryadult=="Yes" & Q031Agecategorygeriatric=="Yes" & gAgeCat==.
replace gAgeCat1=8 if Q028Agecategoryneonatal!="Yes" & Q029Agecategorypediatric!="Yes" & Q030Agecategoryadult!="Yes" & Q031Agecategorygeriatric=="Yes" & gAgeCat==.
replace gAgeCat1=9 if Q028Agecategoryneonatal!="Yes" & Q029Agecategorypediatric=="Yes" & Q030Agecategoryadult=="Yes" & Q031Agecategorygeriatric=="Yes" & gAgeCat==.
replace gAgeCat1=10 if Q028Agecategoryneonatal=="Yes" & Q029Agecategorypediatric=="Yes" & Q030Agecategoryadult=="Yes" & Q031Agecategorygeriatric=="Yes" & gAgeCat==.
replace gAgeCat1=99 if gAgeCat1==.
tab gAgeCat1
sort Year
list Author Year Q027 if gAgeCat1==99

sort Year
title "Look at studies spanning age ranges"
list Author Year gAgeCat1 if gAgeCat1 == 2 | gAgeCat1 == 4 | gAgeCat1 == 5 | gAgeCat1 == 7 | gAgeCat1 == 8 | gAgeCat1 == 9
tab gAgeCat1  Q026 
replace Q026="Yes" if gAgeCat1!=99
tab gAgeCat1  Q026 
sort REFID
list REFID Q027Agecategorycoveredonec Q028Agecategoryneonatal Q029Agecategorypediatric Q030Agecategoryadult Q031Agecategorygeriatric if Q026=="No"
list REFID Q027Agecategorycoveredonec if Q026=="No" , noobs
replace gAgeCat1=5 if REFID==2
replace Q026="Yes" if REFID==2
replace gAgeCat1=7 if REFID==85
replace Q026="Yes" if REFID==85
replace gAgeCat1=7 if REFID==100
replace Q026="Yes" if REFID==100
replace gAgeCat1=4 if REFID==204
replace Q026="Yes" if REFID==204
replace gAgeCat1=5 if REFID==214
replace Q026="Yes" if REFID==214
replace gAgeCat1=5 if REFID==215
replace Q026="Yes" if REFID==215
tab gAgeCat1
list REFID Q027Agecategorycoveredonec if Q026=="No" , noobs
list REFID Q028Agecategoryneonatal Q029Agecategorypediatric Q030Agecategoryadult Q031Agecategorygeriatric if Q026=="No" , noobs
tab Q026
tab gAgeCat1

title "Generate an age category string"
gen gAgeString=""
replace gAgeString="N" if Q028Agecategoryneonatal=="Yes"
replace gAgeString=gAgeString+"P" if Q029Agecategorypediatric=="Yes"
replace gAgeString=gAgeString+"A" if Q030Agecategoryadult=="Yes"
replace gAgeString=gAgeString+"G" if Q031Agecategorygeriatric=="Yes"
tab gAgeString
label variable gAgeString "Ages: Neonatal, Pediatric, Adult, Geriatric"

gen gAgeString2=""
replace gAgeString2="N" if (Q028Agecategoryneonatal=="Yes")
replace gAgeString2=gAgeString2+"P" if (Q029Agecategorypediatric=="Yes")
replace gAgeString2=gAgeString2+"A" if (Q030Agecategoryadult=="Yes" | Q031Agecategorygeriatric=="Yes")
tab gAgeString2
label variable gAgeString2 "Ages: Neonatal, Pediatric, Adult"

title "Country performed"
tab Q032
replace Q032="UK" if Q032=="United Kingdom"
replace Q032="Ireland, UK" if Q032=="Ireland and United Kingdom"
replace Q032="Ireland, UK" if Q032=="Ireland and UK"
replace Q032="UK" if Q032=="Scotland"
replace Q032="USA" if Q032=="United States"
replace Q032="USA" if Q032=="USA?"
replace Q032="USA" if Q032=="U.S.A."
replace Q032="USA" if Q032=="United States of America"
replace Q032="The Netherlands" if Q032=="the Netherlands"
replace Q032="The Netherlands, Germany" if Q032=="Germany and The Netherlands"
replace Q032="The Netherlands, Sweden" if Q032=="The Netherlands and Sweden"
replace Q032="The Netherlands" if Q032=="Netherlands"
replace Q032="The Netherlands, UK" if Q032=="The Netherlands and UK"
replace Q032="The Netherlands, Belgium" if Q032=="Netherlands and Belgium"
replace Q032="USA" if strpos(Q032,"Probably USA")>0
replace Q032="USA" if strpos(Q032,"probably USA")>0
replace Q032="Canada" if strpos(Q032,"Probably Canada")>0
replace Q032="Poland" if strpos(Q032,"Probably Poland")>0
replace Q032="The Netherlands" if strpos(Q032,"Probably the Netherlands")>0
replace Q032="The Netherlands" if strpos(Q032,"The Netherlands (not stated)")>0
replace Q032="USA" if strpos(Q032,"USA (no explicit statement)")>0
replace Q032="USA" if strpos(Q032,"USA (probably)")>0
replace Q032="Germany" if Q032=="Unclear. Germany?"
replace Q032="Brazil" if Q032=="Brazil?"
list REFID Author Year Journal Q032 if strpos(Q032,"Many")>0
replace Q032="Europe, Israel, Australia,  New Zealand" if REFID==218
tab Q032
tab Q032, sort
gen gCountryMultiple=strpos(Q032,",")>0
label variable gCountryMultiple "Multiple countries involved"
tab gCountryMultiple

local countries=`'"USA Netherlands UK Canada Belgium Germany Ireland Australia Austria Denmark France Italy China Sweden Spain  Brazil Finland Japan Korea Mexico Singapore  Switzerland Argentina Bhutan Czechoslovakia India Israel Zealand Norway Poland Korea  Thailand Europe Unknown"´
local countriescount : word count `countries'
title "Number of countries: `countriescount'"

title "Studies by country"
cwf default
local i=0
foreach v in `countries' {
	local i=`i'+1
    cap drop gCountry`i'
	gen gCountry`i' = strpos(Q032,"`v'")>0
	label variable gCountry`i' "Country `i' `v'"
	tab gCountry`i'
}

title "Simpler table"
cap frame drop countrytab
frame create countrytab
cwf countrytab
set obs `countriescount'
gen country=""
gen count=.
cwf default
local i=1
foreach v in `countries' {
    cwf default
	count if strpos(Q032,"`v'")>0
	local n=`r(N)'
	cwf countrytab
	replace country="`v'" if _n==`i'
	replace count=`n' if _n==`i'
	cwf default
	local i=`i'+1
}
cwf countrytab
gen percent=count/188*100
format percent %3.0f
gsort -count
count
list, sep(0) noobs
cwf default
tab gCountryMultiple
title "34 countries, one not specified. " "Top countries: USA 124(66%) NL 27 (14%) UK 14(7%)" "Single country: 247 studies, multiple countries 13 (5%)"


title "Countries by continent"
local countriesAmerica=`'"USA Canada Brazil Mexico "´
local countriesEurope=`'"Netherlands UK  Belgium Germany  Ireland Austria  Denmark  France  Italy Sweden  Spain Finland Switzerland Argentina Bhutan Czechoslovakia  Poland Norway  "´
local countriesAsia=`'"China  Japan Singapore Bhutan India Israel Korea Thailand "´
local countriesOceania=`'"Australia Zealand"´
cap drop gContinentAmerica
gen gContinentAmerica=0
foreach v in `countriesAmerica' {
	di "`v'"
    replace gContinentAmerica=1 if strpos(Q032,"`v'")>0	
}
cap drop gContinentEurope
gen gContinentEurope=0
foreach v in `countriesEurope' {
	di "`v'"
    replace gContinentEurope=1 if strpos(Q032,"`v'")>0	
}
cap drop gContinentAsia
gen gContinentAsia=0
foreach v in `countriesAsia' {
	di "`v'"
    replace gContinentAsia=1 if strpos(Q032,"`v'")>0	
}
cap drop gContinentOceania
gen gContinentOceania=0
foreach v in `countriesOceania' {
	di "`v'"
    replace gContinentOceania=1 if strpos(Q032,"`v'")>0	
}
tab gContinentAmerica
tab gContinentEurope
tab gContinentAsia
tab gContinentOceania


title "Prior references"
tab Q041
tab Q042
tab Q043 , missi
list REFID Author Year Journal if Q043==.
replace Q043=4 if REFID==260
rename Q043 numRefs
egen gNumRefsCat=cut(numRefs) , at(0,1,2,5,999) ic label
tab gNumRefsCat

title "Recode number of prior references"
tab Q044
rename Q044 knownrefs
title "Correct knownrefs"
cwf default
cap frame drop knownrefs
frame create knownrefs
cwf knownrefs
use "C:\Midlertidig_Lagring\sysrevreproeeg\3CleanData\data-cleaned\0masterlist.dta"
contract Year
sort Year
gen cumref=sum(_freq)
list
cwf default
count
levels REFYEAR
foreach refyear in `r(levels)' {        
    cwf knownrefs
	summ cumref if Year<`refyear'
	if `r(N)' == 0 {
	    local knownrefs=0
	}
	else {
		local knownrefs=`r(max)'
	}
	cwf default
	replace knownrefs=`knownrefs' if REFYEAR==`refyear'	
}
tab knownrefs

title "Percent of known references"
gen gPercentKnownRefs=numRefs/knownrefs*100
replace gPercentKnownRefs=0 if gPercentKnownRefs==.
tab gPercentKnownRefs
summ gPercentKnownRefs
cap drop gPercentKnownRefsCat
egen gPercentKnownRefsCat=cut(gPercentKnownRefs) , at(0,0.0000001,10,50,999) ic label
tab gPercentKnownRefsCat



title "Sample size etc"
tab Q100
tab Q101
list REFID Author REFYEAR if Q101=="Yes"
tab Q102
tab Q103

title "Recruitment"
tab Q104
tab Q105
list  Q105 REFID if Q105!="Consecutive" & Q105!="Convenience" & Q105!="Unclear" & Q105!="Synthetic mix" , noobs sep(0)
replace Q105="Consecutive" if REFID==17
replace Q105="Unclear" if REFID==20
replace Q105="Unclear" if REFID==47
replace Q105="Unclear" if REFID==48
replace Q105="Consecutive" if REFID==74
replace Q105="Convenience" if REFID==77
replace Q105="Convenience" if REFID==81
replace Q105="Synthetic mix" if REFID==91
replace Q105="Synthetic mix" if REFID==94
replace Q105="Consecutive" if REFID==100
replace Q105="Convenience" if REFID==101
replace Q105="Consecutive" if REFID==121
replace Q105="Consecutive" if REFID==129
replace Q105="Consecutive" if REFID==138
replace Q105="Consecutive" if REFID==148
replace Q105="Consecutive" if REFID==150
replace Q105="Consecutive" if REFID==155
replace Q105="Convenience" if REFID==161
replace Q105="Synthetic mix" if REFID==169
replace Q105="Consecutive" if REFID==175
replace Q105="Consecutive" if REFID==176
replace Q105="Consecutive" if REFID==204
replace Q105="Synthetic mix" if REFID==209
replace Q105="Consecutive" if REFID==274

tab Q105
list REFID Q105 if Q105!="Consecutive" & Q105!="Convenience" & Q105!="Unclear" & Q105!="Synthetic mix" , noobs sep(0)

tab Q106
tab Q105 Q106

title "Measurement process"
tab Q200
tab Q201
tab Q202
tab Q201 Q202

**Fix some errors in intrarater assessment
list REFID REFYEAR Author Q203 Q204 if Q203=="Yes", sep(0) noobs
list REFID Author Year Journal if Q201=="No" & Q202=="No" , sep(0) noobs

tab Q203

tab Q201 Q202 , missi

rename Q201 IntraRater
rename Q202 InterRater


list REFID Author Year Journal if IntraRater=="" , sep(0) noobs

replace InterRater="Yes" if REFID==83
replace IntraRater="No" if REFID==83
replace InterRater="Yes" if REFID==258
replace IntraRater="No" if REFID==258

list REFID InterRater Author Year Journal Title if InterRater=="" , sep(0) noobs
replace InterRater="Yes" if REFID==68
replace IntraRater="No" if REFID==68
replace InterRater="Yes" if REFID==88
replace IntraRater="No" if REFID==88

tab IntraRater InterRater , missi
list REFID InterRater Author Year Journal Title if InterRater=="No" & IntraRater=="No" , sep(0) noobs
**Missing on both intrarater and interrater, fix:
foreach R in 39 65 115 116 187 188 193 {
	replace InterRater="Yes" if REFID==`R'
	replace IntraRater="No" if REFID==`R'
}

tab IntraRater InterRater , missi

**Too many with both intrarater and interrater?
list REFID InterRater Author Year Journal Title if InterRater=="Yes" & IntraRater=="Yes" , sep(0) noobs
foreach R in 13 17 36 41 124  176 209 231 {
	replace InterRater="Yes" if REFID==`R'
	replace IntraRater="No" if REFID==`R'
}

tab IntraRater InterRater , missi

**Double check those with only intrarater
list REFID InterRater Author Year Journal Title if InterRater=="No" & IntraRater=="Yes" , sep(0) noobs
*All these are correct

title "Statistics"
tab Q211
tab Q212
tab Q211 Q212
rename Q211 StatsUnadj
rename Q212 StatsKappa
list REFID Stats* Author Year Journal Title if StatsUnadj=="No" & StatsKappa=="No" , sep(0) noobs
replace StatsUnadj="Yes" if REFID==13
replace StatsUnadj="Yes" if REFID==133
replace StatsUnadj="Yes" if REFID==148
replace StatsUnadj="Yes" if REFID==189
replace StatsUnadj="Yes" if REFID==193
replace StatsUnadj="Yes" if REFID==209
replace StatsUnadj="Yes" if REFID==214
tab StatsUnadj StatsKappa
drop if REFID==96
tab StatsUnadj StatsKappa




title "Inclusion"
rename Q503 NumberOfEegsIncluded

tab Q500
tab Q501
rename Q501 NumPatientsIncluded
summ NumPatientsIncluded
cap drop gNumPatientsIncludedCat
egen gNumPatientsIncludedCat=cut(NumPatientsIncluded), at(0,10,50, 100,200,99999) ic label
label define gNumPatientsIncludedCat 999 "Missing" , modify
replace gNumPatientsIncludedCat=999 if gNumPatientsIncludedCat==.
tab gNumPatientsIncludedCat

tab Q502 
tab NumberOfEegsIncluded
cap drop gNumberOfEegsIncludedCat
egen gNumberOfEegsIncludedCat=cut(NumberOfEegsIncluded), at(0,10,50, 100,200,99999) ic label
label define gNumberOfEegsIncludedCat 999 "Missing" , modify
replace gNumberOfEegsIncludedCat=999 if gNumberOfEegsIncludedCat==.
tab gNumberOfEegsIncludedCat


*****************************
tab Q402 Q403 , missi
gen RaterExperience=""
replace RaterExperience="Expert" if Q402=="Yes"
replace RaterExperience="Experienced" if Q403=="Yes" & RaterExperience==""
replace RaterExperience="Missing" if RaterExperience==""
tab RaterExperience
label variable RaterExperience "Self-reported experience level"


*****************************
//Compute GRRAS point score
* Item 1: Identifyintitleorabstractth
cap drop Gras*
tab Q005Identifyintitleorabstra 
gen Gras01_Title=1 if Q005Identifyintitleorabstra=="Yes"
//Gras 2
tab Q006EEGismentionedasuseda
gen Gras02_DeviceEEG=1 if Q006EEGismentionedasuseda=="Yes"
//Gras 3
tab Q015Subjectpopulationspecifie
gen Gras03_PopulationDescribed=1 if Q015Subjectpopulationspecifie=="Yes"
//Gras 4
tab Q039Isthetargetraterpopulat
gen Gras04_RaterDescribed=1 if Q039Isthetargetraterpopulat=="Yes"
//Gras 5
tab Q041Describewhatisalreadykn
gen Gras05_Rationale=1 if Q041Describewhatisalreadykn=="Yes"
//Gras 6
tab Q100Isitexplainedhowthesam
gen Gras06_SampleSize=1 if Q100Isitexplainedhowthesam=="Yes"
//Gras 7
tab Q033Wastherecruitmentbasiss
gen Gras07_Recruitment=1 if Q033Wastherecruitmentbasiss=="Yes"
//Gras 8
tab Q200Isthemeasurementratingp
gen Gras08_Measurement=1 if Q200Isthemeasurementratingp=="Yes"
//Gras 9
tab Q206Wereallratersindependent
gen Gras09_RatersIndep=1 if Q206Wereallratersindependent=="Yes"
//Gras 10
tab Q208Isthestatisticalanalysis
gen Gras10_StatsAnalysis=1 if Q208Isthestatisticalanalysis=="Yes"
//Gras 11
gen Gras11_ActualNumber=1 if Q502IsthenumberofEEGinclud=="Yes" & Q302Numberofratersinvolved!=. & NumberOfEegsIncluded!=.
tab Gras11_ActualNumber
//Gras 12
tab Q400Arethesamplecharacterist
gen Gras12_SampleChar=1 if Q400Arethesamplecharacterist=="Yes"
//Gras 13
tab Q506Areestimatesofreliabilit
gen Gras13_Uncertainty=1 if Q506Areestimatesofreliabilit=="Yes" | substr(Q506Areestimatesofreliabilit,1,7)=="No, but"
tab Gras13_Uncertainty Q506Areestimatesofreliabilit
//Gras 14
tab Q507Arethepracticalrelevance
gen Gras14_Practical=1 if Q507Arethepracticalrelevance=="Yes"
//Gras 15
tab Q508Aredetailedresultsgiven
gen Gras15_Detail=1 if Q508Aredetailedresultsgiven=="Yes"
//Now replace those GRAS points with missing as zero
foreach v of varlist Gras*_*  {
	replace `v'=0 if `v'==.
}

// Sum Gras
egen GrrasSum=rsum(Gras*_*)
tab GrrasSum , missi
summ GrrasSum


rename Q302Numberofratersinvolved NumberOfRatersInvolved
rename Q009NumberofelectrodesofEEG NumberOfEegElectFromDesign

tab Q409
destring Q409 , replace force
tab Q409

tab Q410
destring Q410 , replace force
tab Q410
rename Q409 RaterExpLengthMin
rename Q410 RaterExpLengthMax

save "C:\Midlertidig_Lagring\sysrevreproeeg\3CleanData\data-cleaned\1designleveldata-varscleaned", replace


cap log close
translate "`logfile'.smcl" "`logfile'.pdf"
