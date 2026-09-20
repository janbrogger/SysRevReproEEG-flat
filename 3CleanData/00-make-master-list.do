cd C:\Midlertidig_Lagring\sysrevreproeeg\3CleanData
cap log close
local logfile "log\00-make-master-list"
cap log close
log using "`logfile'.smcl", replace
*ssc install title
*ssc install findname
pwd

clear
import excel "C:\Midlertidig_Lagring\SysRevReproEeg\2Results\15-update-april-2025\12-all-update-and-previous –exclude-REM\Master list 20260223.xlsx", sheet("Ark 1") firstrow
rename Number REFID
drop if ReviewPeriod=="" 
drop if REFID==77 & Author=="Zijlmans" & Year==2002
des
count
tab ReviewPeriod , missi
tab Year
list in 1/3
count
save "C:\Midlertidig_Lagring\sysrevreproeeg\3CleanData\data-cleaned\0masterlist.dta", replace

cap log close
translate "`logfile'.smcl" "`logfile'.pdf"
