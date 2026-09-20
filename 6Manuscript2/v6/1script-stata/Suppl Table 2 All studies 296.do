cd C:\Midlertidig_Lagring\sysrevreproeeg\6Manuscript2\v6
cap log close
local logfile "3log\Suppl Table 2 All studies 296.do"
cap log close
log using "`logfile'.smcl", replace
*ssc install title
*ssc install findname
pwd


use "C:\Midlertidig_Lagring\sysrevreproeeg\3CleanData\data-cleaned\3designleveldata-varscleaned-with-featureabstract", clear

local excelfile "C:\Midlertidig_Lagring\sysrevreproeeg\6Manuscript2\v6\4output\SupplementaryTable2-All296Studies.xlsx"

* Peer review revision 1: start from an empty template that has landscape page
* orientation (A4, fit to width) already set, and write into it with
* sheet(..., modify) so the page setup survives. putexcel/export excel cannot
* set page orientation directly.
copy "1script-stata\SupplTable2-template.xlsx" "`excelfile'", replace

keep REFID Author REFYEAR Title Journal Volume Issue Pages NumPatientsIncluded NumberOfEegsIncluded NumberOfRatersInvolved NumberOfEegElectFromDesign featurecount allfeaturenames
order REFID Author REFYEAR Journal Volume Issue Pages Title NumPatientsIncluded NumberOfEegsIncluded NumberOfRatersInvolved NumberOfEegElectFromDesign featurecount allfeaturenames
label variable REFYEAR "Year"
label variable NumPatientsIncluded "Number of patients included"
label variable NumberOfEegsIncluded "Number of EEGs included"
label variable NumberOfRatersInvolved "Number of raters involved"
label variable NumberOfEegElectFromDesign "Number of EEG electrodes"
export excel using "`excelfile'" , sheet("Sheet1", modify) firstrow(varlabels)


putexcel set "`excelfile'", sheet("Sheet1") modify
putexcel (A1:L1), border(bottom) 

putexcel (H1:N1), txtwrap

* Peer review revision 1: the feature list column was 254 characters wide,
* which forced fit-to-width to downscale the whole page to unreadable text.
* Narrow it and word-wrap the data cells instead.
local lastrow = _N + 1
putexcel (N2:N`lastrow'), txtwrap

title "Fix column widths"
mata: b = xl()
mata: b.load_book("`excelfile'")
mata: b.set_sheet("Sheet1")
mata: b.set_column_width(2,2,25)
mata: b.set_column_width(3,3,15)
mata: b.set_column_width(4,4,50)
mata: b.set_column_width(8,8,100)
mata: b.set_column_width(14,14,70)
mata: b.close_book()


cap log close
translate "`logfile'.smcl" "`logfile'.pdf"
