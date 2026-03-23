* ---------------------------------------------------------------------------- *
* 0. Setup
* ---------------------------------------------------------------------------- *

clear all
set more off

* Set working directory to wherever the Excel file lives
* cd "/path/to/your/folder"

local file "cbr-labour-regulation-index-2023-dataset.xlsx"


* ---------------------------------------------------------------------------- *
* 1. Standard layout (115 countries)
*    Excel structure: Col A = country name, Col B = blank, Col C = year,
*                     Cols D-AO = cbr_1 through cbr_40
*                     Row 1 = variable number header; data from row 2 onward
*    Import strategy: cellrange(C2) skips cols A/B and the header row
*                     so imported col A = year, cols B onward = cbr vars
* ---------------------------------------------------------------------------- *

local standard_sheets ///
    afghanistan algeria angola argentina armenia australia austria        ///
    azerbaijan bangladesh belarus belgium belize benin bolivia botswana   ///
    brazil bulgaria "burkina faso" cambodia cameroon canada chad chile    ///
    china colombia "costa rica" "cote d'ivoire" czechia denmark           ///
    "dominican republic" ecuador egypt ethiopia finland france gabon      ///
    germany ghana greece guatemala honduras hungary india indonesia iran   ///
    iraq ireland israel italy jamaica japan jordan kenya "korea rep"      ///
    latvia lithuania luxembourg malawi malaysia mali mauritius mexico      ///
    moldova mongolia morocco mozambique namibia netherlands nicaragua      ///
    niger nigeria norway pakistan paraguay peru philippines poland         ///
    portugal romania russia senegal "sierra leone" singapore slovakia     ///
    slovenia "south africa" spain "sri lanka" sweden switzerland tanzania ///
    thailand togo turkey uganda ukraine "united kingdom" "united states"  ///
    uruguay venezuela vietnam zambia zimbabwe

tempfile master
save `master', replace emptyok

foreach sheet of local standard_sheets {

    * Import data from cell C2: skips country name col, blank col, and header row
    import excel using "`file'", sheet("`sheet'") cellrange(C2) firstrow(no) clear

    * Imported col A = year (was col C in Excel)
    rename A year
    destring year, replace
    drop if missing(year)
    drop if year < 1900 | year > 2100

    * Rename imported cols B-AO as cbr_1 to cbr_40
    local letters B C D E F G H I J K L M N O P Q R S T U V W X Y Z ///
                  AA AB AC AD AE AF AG AH AI AJ AK AL AM AN AO
    forvalues v = 1/40 {
        local col : word `v' of `letters'
        capture rename `col' cbr_`v'
    }

    * Get country name from cell A1 (properly formatted, e.g. "Costa Rica")
    preserve
        import excel using "`file'", sheet("`sheet'") cellrange(A1:A1) ///
            firstrow(no) clear
        local cname = A[1]
    restore
    gen country = "`cname'"

    * Destring cbr indicators
    forvalues v = 1/40 {
        capture destring cbr_`v', replace
    }

    append using `master'
    save `master', replace
}


* ---------------------------------------------------------------------------- *
* 2. Croatia (non-standard layout)
*    Row 1 in Excel is entirely blank; country name and variable header are
*    both on row 2; data starts at row 24 (1991 onward)
*    Import strategy: cellrange(C3) skips the extra blank row
* ---------------------------------------------------------------------------- *

import excel using "`file'", sheet("croatia") cellrange(C3) firstrow(no) clear

rename A year
destring year, replace
drop if missing(year)
drop if year < 1900 | year > 2100

local letters B C D E F G H I J K L M N O P Q R S T U V W X Y Z ///
              AA AB AC AD AE AF AG AH AI AJ AK AL AM AN AO
forvalues v = 1/40 {
    local col : word `v' of `letters'
    capture rename `col' cbr_`v'
}

* Country name is in cell A2 for Croatia
preserve
    import excel using "`file'", sheet("croatia") cellrange(A2:A2) ///
        firstrow(no) clear
    local cname = A[1]
restore
gen country = "`cname'"

forvalues v = 1/40 {
    capture destring cbr_`v', replace
}

append using `master'
save `master', replace


* ---------------------------------------------------------------------------- *
* 3. Panama (non-standard layout)
*    No country name in col A; year is col A, cbr_1-40 are cols B-AO
*    Row 1 = variable number header; data from row 2 onward
*    Import strategy: cellrange(A2)
* ---------------------------------------------------------------------------- *

import excel using "`file'", sheet("panama") cellrange(A2) firstrow(no) clear

rename A year
destring year, replace
drop if missing(year)
drop if year < 1900 | year > 2100

local letters B C D E F G H I J K L M N O P Q R S T U V W X Y Z ///
              AA AB AC AD AE AF AG AH AI AJ AK AL AM AN AO
forvalues v = 1/40 {
    local col : word `v' of `letters'
    capture rename `col' cbr_`v'
}

gen country = "Panama"  // No A1 cell available; name set manually

forvalues v = 1/40 {
    capture destring cbr_`v', replace
}

append using `master'


* ---------------------------------------------------------------------------- *
* 4. Final cleanup and save
* ---------------------------------------------------------------------------- *

order country year cbr_1-cbr_40
sort country year

drop if missing(country) | missing(year)

* Label variables
label data "CBR Labour Regulation Index 1970-2022 (Adams et al., Cambridge CBR)"
label variable country  "Country name (from cell A1 of each sheet)"
label variable year     "Year"
forvalues v = 1/40 {
    label variable cbr_`v' "CBR indicator `v'"
}

* Quick coverage check
di as result "=== Coverage check ==="
di "Total obs: `=_N'"
unique country
local latam "Argentina Bolivia Brazil Chile Colombia Costa Rica Dominican Republic Ecuador Honduras Mexico Nicaragua Panama Paraguay Peru Uruguay Venezuela"
foreach c of local latam {
    count if country == "`c'"
    di "`c': `r(N)' obs"
}

save "cbr_combined.dta", replace
export delimited using "cbr_combined.csv", replace

di as result "Done. Saved cbr_combined.dta and cbr_combined.csv"


*==============================================================================*
* OPTIONAL: Compute aggregate CBR index and sub-indices
*
* The 40 indicators map to 5 thematic sub-indices (Adams et al. 2023):
*   EP  Employment protection:    cbr_1  - cbr_8
*   WT  Working time regulation:  cbr_9  - cbr_16
*   LMR Leave and maternity:      cbr_17 - cbr_24
*   CB  Collective bargaining:    cbr_25 - cbr_32
*   SW  Social security/dismissal:cbr_33 - cbr_40
*
* Overall index = mean of the 5 sub-index means (each sub-index = mean of 8 vars)
*==============================================================================*

/*
egen cbr_ep    = rowmean(cbr_1  cbr_2  cbr_3  cbr_4  cbr_5  cbr_6  cbr_7  cbr_8)
egen cbr_wt    = rowmean(cbr_9  cbr_10 cbr_11 cbr_12 cbr_13 cbr_14 cbr_15 cbr_16)
egen cbr_lmr   = rowmean(cbr_17 cbr_18 cbr_19 cbr_20 cbr_21 cbr_22 cbr_23 cbr_24)
egen cbr_cb    = rowmean(cbr_25 cbr_26 cbr_27 cbr_28 cbr_29 cbr_30 cbr_31 cbr_32)
egen cbr_sw    = rowmean(cbr_33 cbr_34 cbr_35 cbr_36 cbr_37 cbr_38 cbr_39 cbr_40)
egen cbr_index = rowmean(cbr_ep cbr_wt cbr_lmr cbr_cb cbr_sw)

label variable cbr_ep    "CBR sub-index: Employment protection (vars 1-8)"
label variable cbr_wt    "CBR sub-index: Working time (vars 9-16)"
label variable cbr_lmr   "CBR sub-index: Leave and maternity (vars 17-24)"
label variable cbr_cb    "CBR sub-index: Collective bargaining (vars 25-32)"
label variable cbr_sw    "CBR sub-index: Social security/dismissal (vars 33-40)"
label variable cbr_index "CBR overall index (mean of 5 sub-indices)"

save "cbr_combined.dta", replace
*/
