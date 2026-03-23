****** 1. PRE-PROCESSING ******

* Standardize CBR country-name data
use "cbr_combined.dta", clear
levelsof country, local(cbr_names)

drop if country == "Palestine (State of)"

kountry country, from(other) stuck
rename _ISO3N_ iso3

replace iso3 = 203 if country == "Czech Republic" | country == "Czechia"
replace iso3 = 807 if country == "North Macedonia" | country == "Macedonia"

keep if year >= 2009 & year <= 2022

save "cbrcombined_iso.dta", replace

* Standardize ILO country-name (inspectorsrate)
use "inspectorsrate.dta", clear
 
 ** Variable name and type alignment
rename ref_area_label country
rename time year
rename obs_value inspectors_per100k
destring year, replace
drop indicator_label

replace country = "Turkey" if country == "Türkiye"
replace country = "United Kingdom" if country == "United Kingdom of Great Britain and Northern Ireland"
replace country = "Venezuela" if country == "Venezuela (Bolivarian Republic of)"

drop if country == "Palestine (State of)"

kountry country, from(other) stuck
rename _ISO3N_ iso3

replace iso3 = 203 if country == "Czech Republic" | country == "Czechia"
replace iso3 = 807 if country == "North Macedonia" | country == "Macedonia"

save "inspectorsrate_iso.dta", replace

////Checking-up for duplicates (optional, just in case) / useful for all datasets
	duplicates tag iso3 year, gen(dup)
	tab country if dup > 0

* Standardize ILO country-name (inspectorsrate)
use "visits.dta", clear
 
 ** Variable name and type alignment
rename ref_area_label country
rename time year
rename obs_value n_visits
destring year, replace
drop indicator_label

replace country = "Turkey" if country == "Türkiye"
replace country = "United Kingdom" if country == "United Kingdom of Great Britain and Northern Ireland"
replace country = "Venezuela" if country == "Venezuela (Bolivarian Republic of)"

drop if country == "Palestine (State of)"

kountry country, from(other) stuck
rename _ISO3N_ iso3

replace iso3 = 203 if country == "Czech Republic" | country == "Czechia"
replace iso3 = 807 if country == "North Macedonia" | country == "Macedonia"

save "visits_iso.dta", replace	

* Establishments
use "registered_workplaces.dta", clear
rename ref_area_label country
rename time year
destring year, replace

replace country = "Turkey" if country == "Türkiye"
replace country = "United Kingdom" if country == "United Kingdom of Great Britain and Northern Ireland"
replace country = "Venezuela" if country == "Venezuela (Bolivarian Republic of)"
drop if country == "Palestine (State of)"

kountry country, from(other) stuck
rename _ISO3N_ iso3

replace iso3 = 203 if country == "Czech Republic" | country == "Czechia"
replace iso3 = 807 if country == "North Macedonia" | country == "Macedonia"
rename obs_value n_establishments
keep iso3 year n_establishments
save "registeredwp_iso.dta", replace

* Visits per inspector
use "visitsperinsp.dta", clear
rename ref_area_label country
rename time year
destring year, replace
rename obs_value visitsperinsp

replace country = "Turkey" if country == "Türkiye"
replace country = "United Kingdom" if country == "United Kingdom of Great Britain and Northern Ireland"
replace country = "Venezuela" if country == "Venezuela (Bolivarian Republic of)"
drop if country == "Palestine (State of)"

kountry country, from(other) stuck
rename _ISO3N_ iso3

replace iso3 = 203 if country == "Czech Republic" | country == "Czechia"
replace iso3 = 807 if country == "North Macedonia" | country == "Macedonia"

keep iso3 year visitsperinsp
save "visitsperinsp_iso.dta", replace


* Informality (ILOStat)

use "informality.dta", clear

rename ref_area_label country
rename time year
rename obs_value labor_informality
destring year, replace
drop indicator_label
keep if sex_label == "Total"

replace country = "Bolivia" if country == "Bolivia (Plurinational State of)"
replace country = "Turkey" if country == "Türkiye"

kountry country, from(other) stuck
rename _ISO3N_ iso3

keep if year >= 2009 & year <= 2022

replace iso3 = 203 if country == "Czech Republic" | country == "Czechia"
replace iso3 = 807 if country == "North Macedonia" | country == "Macedonia"
replace iso3 = 178 if country == "Republic of the Congo"
replace iso3 = 132 if country == "Cabo Verde"

drop if iso3 == .

keep iso3 year labor_informality

save "informality.dta", replace

* Income group (WB)
import excel "CLASS.xlsx", sheet("List of economies") cellrange(A1:E219) firstrow clear

replace Economy = "Turkey" if Economy == "Türkiye"

encode Incomegroup, generate (income)
kountry Economy, from(other) stuck
rename _ISO3N_ iso3

replace iso3 = 203 if Economy == "Czech Republic" | Economy == "Czechia"
replace iso3 = 807 if Economy == "North Macedonia" | Economy == "Macedonia"
replace iso3 = 132 if Economy == "Cabo Verde"
replace iso3 = 384 if Economy == "Côte d'Ivoire" | replace iso3 = 384 if Economy == "Côte dIvoire"
replace iso3 = 158 if Economy == "Taiwan, China"

rename Economy country_name

drop if if iso3 == .

save "wb_incomegroups.dta", replace

* VDEM data
use "V-Dem-CY-Full+Others-v16.dta", clear

keep if year >= 2009 & year <= 2022

replace country_name = "Turkey" if country_name == "Türkiye"
kountry country_name, from(other) stuck
rename _ISO3N_ iso3

replace iso3 = 203 if country_name == "Czech Republic" | country_name == "Czechia"
replace iso3 = 807 if country_name == "North Macedonia" | country_name == "Macedonia"
replace iso3 = 178 if country_name == "Republic of the Congo"

drop if iso3 == . 

keep country_name country_id year v2clrspct v2eltvrexo v2stcritrecadm e_wbgi_gee e_wbgi_cce iso3 e_gdppc e_peaveduc
merge m:1 iso3 using "wb_incomegroups.dta"
tab _merge

keep if _merge == 3
drop _merge

drop country_id

save "wb+vdem16.dta", replace

****** 2. MERGING DATASETS ******

* Merge ILO by iso3 + year
use "inspectorsrate_iso.dta", clear
destring year, replace
merge 1:1 iso3 year using "visits_iso.dta"
tab _merge

keep if _merge == 3 | _merge == 1
keep if year >= 2009 & year <= 2022
drop _merge

xtset iso3 year
xtdescribe
codebook iso3

save "visits+inspectors_iso.dta", replace
	
* Merge with CBR by iso3 + year
use "visits+inspectors_iso.dta", clear
destring year, replace
merge 1:1 iso3 year using "cbrcombined_iso.dta"
tab _merge

*Keep relevant years only (with data for both key variables)
keep if year >= 2009 & year <= 2022
keep if _merge == 3

* Check panel balance
xtset iso3 year
xtdescribe

* Merge registered establishments
use "visits+inspectors+cbr_iso.dta", clear
merge 1:1 iso3 year using "registeredwp_iso.dta"
tab _merge

keep if _merge == 3
keep if year >= 2009 & year <= 2022
drop _merge

save "visits+inspectors+cbr+wp_iso.dta", replace

* Merge visits/insp
use "visits+inspectors+cbr+wp_iso.dta", clear
merge 1:1 iso3 year using "visitsperinsp_iso.dta"
tab _merge
keep if year >= 2009 & year <= 2022

keep if _merge == 3 | _merge == 1
drop _merge

save "visits+inspectors+cbr+wp+visperinsp_iso.dta", replace

*Merge with informality
use "visits+inspectors+cbr+wp+visperinsp_iso.dta", clear
merge 1:1 iso3 year using "informality.dta"
tab _merge

keep if _merge == 3 | _merge == 1
drop _merge

save "visits+inspectors+cbr+wp+visperinsp+informal_iso.dta", replace

*Merge with VDEM + WB

use "visits+inspectors+cbr+wp+visperinsp+informal_iso.dta", clear
merge 1:1 iso3 year using "wb+vdem16.dta"
tab _merge

drop if _merge == 2
drop _merge

save "finaldataset.dta", replace

****** 3. DEFINING VARIABLES ******

use "finaldataset.dta", replace

* BURDEN: CBR Labor Regulation Index
//Preferred specification *cbr_1 to cbr_31, excluding industrial politics
egen cbr_index = rowmean(cbr_1-cbr_31)

bysort year: egen m_cbr = mean(cbr_index)
bysort year: egen sd_cbr = sd(cbr_index)
gen z_cbr = (cbr_index - m_cbr) / sd_cbr

* CAPACITY: inspectors/100k
summarize inspectors_per100k

bysort year: egen m_insp = mean(inspectors_per100k)
bysort year: egen sd_insp = sd(inspectors_per100k)
gen z_inspectors = (inspectors_per100k - m_insp) / sd_insp

* GAP: capacity/burden /normalized per year
gen gap = z_cbr - z_inspectors
summarize gap

* DV1: coverage rate (inspected / registered establishments)
gen coverage_rate = n_visits / n_establishments
summarize coverage_rate, detail


*CONTROLS
	* Mean gov_eff
bysort iso3: egen gee_mean = mean(e_wbgi_gee)

	*Mean labor_informality
bysort iso3: egen informality_m = mean(labor_informality)
	
	*Log coverage for robustness
gen log_coverage = log(coverage_rate)

	*Log visits for robustness
gen log_visits = log(visitsperinsp)
 
	*Income / GDP
gen high_income = (income == 1)
gen log_gdppc = log(e_gdppc)

* BASIC DESCRIPTIVES

xtset iso3 year
xtdescribe
tabstat gap coverage_rate cbr_index inspectors_per100k, ///
    stat(mean sd min max n) col(stat)
	
tabstat coverage_rate, stat(mean sd min max n) by(year)
summarize coverage_rate, detail

* Checking outliers
summarize coverage_rate, detail
list country year coverage_rate if coverage_rate > 10
drop if iso3 == 496 & year >= 2013 & year <= 2017 //removing Mongolia. Reporting issue 2013-2017

* Within-country gap
bysort iso3: egen sd_gap_within = sd(gap)
summarize sd_gap_within

* Simple correlation
preserve
collapse (mean) coverage_rate gap, by(iso3)
correlate coverage_rate gap
restore

preserve
collapse (mean) log_coverage gap, by(iso3)
correlate log_coverage gap
restore

preserve
collapse (mean) visitsperinsp gap, by(iso3)
correlate visitsperinsp gap
restore

scatter coverage_rate gap, mlabel(country) mlabsize(tiny)

****** 4. PLOTTING TRENDS ******




****** 5. RUNNING ANALYSIS ******

//Coverage / Gap

* FE
xtreg coverage_rate gap, fe
estimates store fe1

* FE with Logged DV
xtreg log_coverage gap, fe
estimates store fe2

* RE
xtreg coverage_rate gap, re 
estimates store re1

* RE with Logged DV
xtreg log_coverage gap, re
estimates store re2

hausman fe1 re1
hausman fe2 re2

	//With controls + clustered errors
	
* RE
xtreg coverage_rate gap log_gdppc e_wbgi_gee, re vce(cluster iso3)
estimates store re3

* RE with Logged DV
xtreg log_coverage gap log_gdppc e_wbgi_gee, re vce(cluster iso3)
estimates store re4

* RE with Logged DV
xtreg log_coverage gap log_gdppc e_wbgi_gee informality_m, re vce(cluster iso3)
estimates store re5

esttab re1 re2 re3 re4 using coverage_gap.rtf, replace se label scalars(N rmse r2_o p)

	//Hausman for model with controls
*FE
xtreg coverage_rate gap log_gdppc e_wbgi_gee, fe
estimates store fe3

*RE
xtreg coverage_rate gap log_gdppc e_wbgi_gee, re
estimates store re6

hausman fe3 re6


//Inspectors overload / Gap
* FE
xtreg visitsperinsp gap log_gdppc e_wbgi_gee, fe
estimates store ife1

* FE with logged DV
xtreg log_visits gap log_gdppc e_wbgi_gee, fe
estimates store ife2

* RE
xtreg visitsperinsp gap log_gdppc e_wbgi_gee, re 
estimates store ire1

* RE with logged DV
xtreg log_visits gap log_gdppc e_wbgi_gee, re
estimates store ire2

hausman ife1 ire1
hausman ife2 ire2

esttab ife1 ife2 ire1 ire2 using visits_insp.rtf, replace se label scalars(N rmse r2_w r2_o r2_b p)


****** 6. PLOTTING TRENDS ******

* Scatter with regression line (country avg)
preserve
collapse (mean) log_coverage gap, by(country iso3)
twoway (scatter log_coverage gap, mlabel(country) mlabsize(tiny) mcolor(navy%70)) ///
       (lfit log_coverage gap, lcolor(red)), ///
    xtitle("Burden-Capacity Gap") ///
    ytitle("Coverage rate") ///
    legend(off)
restore

* Overall trends

preserve
collapse (mean) m_cbr m_insp, by(year)
* Estandarizar para comparabilidad visual
egen m_cbr_std = std(m_cbr)
egen m_insp_std = std(m_insp)

twoway ///
    (line m_cbr_std year, lcolor(midgreen) lwidth(medium) lpattern(solid)) ///
    (line m_insp_std year, lcolor(navy) lwidth(medium) lpattern(dash)), ///
    ytitle("Standardized mean") ///
    xtitle("") ///
    xlabel(2009(1)2022, angle(45) labsize(small)) ///
    legend(order(1 "Regulatory burden (CBR index)" 2 "Inspection capacity (inspectors/100k)") ///
           position(6) rows(1) size(small)) ///
    scheme(s2color) ///
    graphregion(color(white)) plotregion(color(white))
restore

** LABOR REGULATION // using cbr_combined clean
use "cbr_combined.dta", clear
levelsof country, local(cbr_names)

egen cbr_index = rowmean(cbr_1-cbr_40)
egen cbr_subindex1 = rowmean(cbr_1-cbr_8)
egen cbr_subindex2 = rowmean(cbr_9-cbr_15)
egen cbr_subindex3 = rowmean(cbr_16-cbr_24)
egen cbr_subindex4 = rowmean(cbr_25-cbr_31)
egen cbr_subindex5 = rowmean(cbr_32-cbr_40)

bysort year: egen m_cbr = mean(cbr_index)
bysort year: egen m_cbr_subindex1 = mean(cbr_subindex1)
bysort year: egen m_cbr_subindex2 = mean(cbr_subindex2)
bysort year: egen m_cbr_subindex3 = mean(cbr_subindex3)
bysort year: egen m_cbr_subindex4 = mean(cbr_subindex4)
bysort year: egen m_cbr_subindex5 = mean(cbr_subindex5)

preserve
collapse (mean) m_cbr m_cbr_subindex1 m_cbr_subindex2 m_cbr_subindex3 m_cbr_subindex4 m_cbr_subindex5, by(year)

twoway ///
    (line m_cbr year, lcolor(midgreen) lwidth(medium) lpattern(dash)) ///
    (line m_cbr_subindex1 year, lcolor(lavender) lwidth(medium) lpattern(solid)) ///
	(line m_cbr_subindex2 year, lcolor(cranberry) lwidth(medium) lpattern(solid)) ///
	(line m_cbr_subindex3 year, lcolor(navy) lwidth(medium) lpattern(solid)) ///
	(line m_cbr_subindex4 year, lcolor(teal) lwidth(medium) lpattern(solid)) ///
	(line m_cbr_subindex5 year, lcolor(sand) lwidth(medium) lpattern(solid)), ///
    xlabel(1970(5)2022, angle(45) labsize(small)) ///
    legend(order(1 "Regulatory burden (CBR index)" 2 "D1. Forms of employment" 3 "D2. Working time" 4 "D3. Dismissal" 5 "D4. Employee representation" 6 "D5. Industrial action" ) ///
           position(6) rows(3) size(small)) ///
    scheme(s2color) ///
    graphregion(color(white)) plotregion(color(white))
restore


/////////////ROBUSTNESS CHECKS/////////////

* BURDEN: CBR Labor Regulation Index
* cbr_1 to cbr_40 = 40 index items
* aggregated index = simple avg
//Alternative specification, including industrial politics
egen cbr_index = rowmean(cbr_1 - cbr_40)
summarize cbr_indexfull

bysort year: egen m_cbrf = mean(cbr_indexf)
bysort year: egen sd_cbrf = sd(cbr_indexf)
gen z_cbrf = (cbr_indexf - m_cbrf) / sd_cbrf

* CAPACITY: inspectors/100k / remains the same
* GAP: burden - capacity / per year deviation
gen gapv2 = z_cbr - z_inspectors
summarize gapv2

* GAP: burden - capacity / full sample instead of year deviation
egen m_cbrf_fs = mean(cbr_indexf_fs)
egen sd_cbrf_fs = sd(cbr_indexf_fs)
gen z_cbrf_fs = (cbr_indexf - m_cbrf_fs) / sd_cbrf_fs

egen m_insp_fs = mean(inspectors_per100k)
egen sd_insp_fs = sd(inspectors_per100k)
gen z_inspectors_fs = (inspectors_per100k - m_insp) / sd_insp

gen gap = z_cbr - z_inspectors
summarize gap_v3

gen gapv4 = inspectors_per100k / cbr_index
summarize gapv4

* Normalized DV: coverage rate (inspected / registered establishments)
bysort year: egen m_coverage = mean(coverage_rate)
bysort year: egen sd_coverage = sd(coverage_rate)
gen z_coverage = (coverage_rate - m_coverage) / sd_coverage

//DESCRIPTIVES

*With normalized DV
xtset iso3 year
tabstat gap z_coverage cbr_index inspectors_per100k, ///
    stat(mean sd min max n) col(stat)

* Simple correlation (with normalized DV)
preserve
collapse (mean) z_coverage gap, by(iso3)
correlate z_coverage gap
restore

scatter z_coverage gap, mlabel(country) mlabsize(tiny)

// MODELLING ALTERNATIVES
* Between estimator
xtreg log_coverage gap, be
estimates store m3

xtreg coverage_rate gap, be
estimates store m4
