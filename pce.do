clear
set more off 
version 12
cap log close

*-----------------------------PCE DEFLATOR: MONTHLY----------------------------*
* BEA spreadsheet is messy so find the appropriate range first
insheet using pce.csv, clear
gen obs = _n

* we want table 2.8.5 but nothing afterwards -- mark the start and ending
* observations for that table in the CSV
sum obs if v1 == "Table 2.8.5. Personal Consumption Expenditures by Major Type of Product, Monthly", meanonly
loc downkeep = `r(mean)'
sum obs if v1 == "Table 2.8.6. Real Personal Consumption Expenditures by Major Type of Product, Monthly, Chained Dollars", meanonly
loc upkeep = `r(mean)'
keep if inrange(obs,`downkeep',`upkeep')


* we still have three "panels" within that table -- drop needless cells
replace v1 = "year" if v1=="Line"
replace v1 = "month" if v1[_n-1]=="year"
replace v1 = "pce" if v1=="1"
keep if v1=="year" | v1=="month" | v1=="pce"
format v1 %5s
drop v2 v3

* now reshape each panel into wide format to unstack them vertically
gen panel = round((_n+1)/3,1) // obs{1..9} so this formula results in 3 panels
loc c=1 // initialize counter
qui {
  foreach v of var v4-v207 {
    preserve
    keep `v' panel v1
    reshape wide `v', i(panel) j(v1) s
    pause
    ren (`v'month `v'pce `v'year) (month pce year)
    if `c'==1 {
      save temp, replace
      }
    else if `c'>1 {
      append using temp
      save temp, replace
      }
    restore
    loc ++c
    }
  }
* now bring in tempfile for appended sets
use temp, clear
* clean everything up and produce time series
drop if mi(month)
drop panel
replace pce = subinstr(pce,",","",.)
destring _all, replace

* index to January 2007 (doesn't really matter)
sort year month
gen ym = ym(year,month)
gen index_t = pce if year==2007 & month==1
egen index = max(index_t)
drop index_t
gen pce_i = 100*pce/index
format ym %tm

* rename time variables to match SIPP
ren (year month) (h_year h_month)
ren pce pce_unindexed
ren pce_i pce
saveold pce, replace
erase temp.dta
erase pce.csv
*------------------------------------------------------------------------------*
