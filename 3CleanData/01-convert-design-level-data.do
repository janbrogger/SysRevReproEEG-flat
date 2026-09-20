cd C:\Midlertidig_Lagring\sysrevreproeeg\3CleanData
cap log close
local logfile "log\01-convert-design-level-data"
cap log close
log using "`logfile'.smcl", replace
*ssc install title
*ssc install findname
pwd

clear
import excel "C:\Midlertidig_Lagring\SysRevReproEeg\2Results\15-update-april-2025\13-data-abstraction-completed\Update SysRevReprodVisualEEG- one paper, design part (Svar)", sheet("Skjemasvar 2") firstrow
tempfile originaldata
save "`originaldata'"
clear
import excel "C:\Midlertidig_Lagring\sysrevreproeeg\2Results\6-data-abstraction\SysRevReprodVisualEEG-onePaper-Design(Responses).xlsx", sheet("Form Responses 2") firstrow 
tempfile updatedata
save "`updatedata'"

use "`originaldata'"
append using "`updatedata'" , force
rename REFID REFID
drop if REFID==.
duplicates drop REFID, force
tempfile alldesigndata
save "`alldesigndata'"


clear
use "C:\Midlertidig_Lagring\sysrevreproeeg\3CleanData\data-cleaned\0masterlist.dta"
merge 1:1 REFID using  "`alldesigndata'" , keep(1 3)
tab _merge
list REFID Year Author if _merge==1

tab ReviewPeriod
egen gRefDecade=cut(Year), at (1950(10)2030) label
tab gRefDecade
drop gRefDecade


duplicates report REFID
duplicates list REFID

count
save "C:\Midlertidig_Lagring\sysrevreproeeg\3CleanData\data-cleaned\1designleveldata", replace

cap log close
translate "`logfile'.smcl" "`logfile'.pdf"
