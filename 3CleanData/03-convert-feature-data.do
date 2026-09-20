cd C:\Midlertidig_Lagring\SysRevReproEeg\3CleanData
cap log close
local logfile "log\03-convert-feature-data"
cap log close
log using "`logfile'.smcl", replace
*ssc install title
*ssc install findname
pwd


clear
import excel "C:\Midlertidig_Lagring\sysrevreproeeg\2Results\6-data-abstraction\SysRevReprodVisualEEGOnePaperDataPart (Responses)-MANUALFIXES.xlsx", sheet("Form Responses 2") firstrow
foreach v of varlist  D302Whatisthelower95confi D302Whatistheupper95confi  {
    tostring  `v', replace force format(%5.2f)
}
tempfile originaldata
save "`originaldata'"
clear
import excel "C:\Midlertidig_Lagring\SysRevReproEeg\2Results\15-update-april-2025\13-data-abstraction-completed\Update SysRevReprodVisualEEG- one paper, data part (Svar).xlsx", sheet("Skjemasvar 2") firstrow 
foreach v of varlist  D301Whatisthevalueofthez D302Whatisthelower95confi D302Whatistheupper95confi  {
    tostring  `v', replace force format(%5.2f)
}

tempfile updatedata
save "`updatedata'"

use "`originaldata'"
append using "`updatedata'" , force
rename REFID REFID
drop if REFID==.
tempfile allfeaturedata
save "`allfeaturedata'"

clear
use "C:\Midlertidig_Lagring\sysrevreproeeg\3CleanData\data-cleaned\0masterlist.dta"
merge 1:n REFID using  "`allfeaturedata'" , keep(1 3)
tab _merge
list REFID Year Author if _merge==1

title "Renaming variables"
rename Timestamp datesubmitted
rename D001Rater rater
rename D105HowmanyEEG NumberOfEegsIncluded
rename D100Whatfeatureisscored featurescored
rename D102 detaillevel

count
save "C:\Midlertidig_Lagring\sysrevreproeeg\3CleanData\data-cleaned\2featuredata-raw", replace

cap log close
translate "`logfile'.smcl" "`logfile'.pdf"
