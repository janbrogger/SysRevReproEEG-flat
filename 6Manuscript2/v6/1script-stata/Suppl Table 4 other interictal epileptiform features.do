cd C:\Midlertidig_Lagring\sysrevreproeeg\6Manuscript2\v6
cap log close
local logfile "3log\Suppl Table 3 Feature list epileptiform.do"
cap log close
log using "`logfile'.smcl", replace
pwd
local keepif ///
if strpos(subinstr(subinstr(lower(featurescored),"nonepileptiform","",.),"non-epileptiform","",.),"epileptiform") ///
& !regexm(lower(featurescored),"^epileptiform discharges yes/no")

use "C:\Midlertidig_Lagring\sysrevreproeeg\3CleanData\data-cleaned\2featuredata-cleaned" , clear
keep `keepif'

contract featurescored REFID Year 
qui tab REFID
ret li
drop _freq 
collapse (min) YearFrom=Year (max) YearTo=Year (count) NumReferences=REFID , by(featurescored)
gsort -NumReferences
label variable YearFrom "Year published first"
label variable YearTo "Year published last"

tempfile featurelist
save "`featurelist'"

title "Found some EEG features by same author with different number of EEGs for same feature. Fix later"

use "C:\Midlertidig_Lagring\sysrevreproeeg\3CleanData\data-cleaned\2featuredata-cleaned" , clear
keep `keepif'

contract featurescored REFID Author Year NumberOfEegs
bysort featurescored REFID: gen wrongnumber=1 if _N>1
list REFID Author Year NumberOfEegs featurescored if wrongnumber==1 , sep(0) noobs


use "C:\Midlertidig_Lagring\sysrevreproeeg\3CleanData\data-cleaned\2featuredata-cleaned" , clear
keep `keepif'

contract featurescored REFID Author Year 
drop _freq
sort featurescored, stable

by featurescored: gen allREFIDs = strofreal(REFID[1],"%3.0f")
by featurescored: replace allREFIDs= allREFIDs[_n-1] + ";" + strofreal(REFID[_n],"%3.0f") if _n > 1
by featurescored: replace allREFIDs = allREFIDs[_N]

by featurescored: gen allAuthorYear = Author[1]+" "+strofreal(Year[1],"%4.0f")
by featurescored: replace allAuthorYear= allAuthorYear[_n-1] + ";" + Author[_n] + " " + strofreal(Year[_n],"%4.0f") if _n > 1
by featurescored: replace allAuthorYear = allAuthorYear[_N]

contract featurescored allREFIDs allAuthorYear
rename _freq CountOfReferences

order featurescored CountOfReferences allREFIDs allAuthorYear
label variable featurescored "EEG feature name"
label variable allREFIDs "List of reference IDs"
label variable CountOfReferences "Count of references"
label variable allAuthorYear "List of author, year"

merge 1:1 featurescored using "`featurelist'"
drop NumReferences _merge
order featurescored CountOfReferences YearFrom YearTo allREFIDs allAuthorYear
gsort -CountOfReferences featurescored


local excelfile "4output\Suppl S4 Other epileptiform feature list.xlsx"

* Peer review revision 1: start from an empty template that has landscape page
* orientation (A4, fit to width) already set, and write into it with
* sheet(..., modify) so the page setup survives. putexcel/export excel cannot
* set page orientation directly.
copy "1script-stata\SupplTable4-template.xlsx" "`excelfile'", replace

export excel using "`excelfile'" , sheet("Sheet1", modify) firstrow(varlabels)

putexcel set "`excelfile'", sheet("Sheet1") modify
putexcel (A1:E1), border(bottom)
putexcel (A1:E1), txtwrap

* Peer review revision 1: footnote with the Aanestad kappa clarification that
* was shortened out of manuscript section 3.4
local noterow = _N + 3
putexcel A`noterow' = "Note: For Aanestad 2021 (Epileptiform discharges - Halford scale), the published value of 0.43 in that paper's supplemental table reflects percent agreement; the corresponding Cohen's kappa was 0.23 (Aanestad, personal communication)."

title "Fix column widths"

mata: b = xl()
mata: b.load_book("`excelfile'")
mata: b.set_sheet("Sheet1")
mata: b.set_column_width(1,1,100)
mata: b.set_column_width(2,2,15)
mata: b.set_column_width(3,3,15)
mata: b.set_column_width(4,4,15)
mata: b.set_column_width(5,5,15)
mata: b.set_column_width(6,6,100)
mata: b.set_column_width(7,7,100)
mata: b.close_book()

cap log close
translate "`logfile'.smcl" "`logfile'.pdf"