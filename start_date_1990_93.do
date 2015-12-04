clear all
set more off
version 12
cap log close


local year = 93
*-----------------------------------------*
* DEFINE PROGRAM TO WAIT UNTIL FILE COUNT *
*    EQUALS REQUIRED NUMBER OF FILES      *
*-----------------------------------------*
cap prog drop wait
prog define wait
  gl files: dir . files "*t?.dta"
  loc n_files: list sizeof global(files)
  while `n_files'<`1' {
  	sleep 100000
  	gl files: dir . files "*.dta"
  	loc n_files: list sizeof global(files)
  }

end
*-----------------------------------------*

pwd
* set up job start year for respondent's 

* first job in early waves

if `year'==90 {
	cd 1990
	wait 1
	cd ..
	use 1990/sip90t2, clear

	desc id pnum entry
	destring id, replace
	tostring id, replace
	rename (id entry pnum) (ssuid eentaid epppnum)
	keep ssuid eentaid epppnum tm8270 tm8268
	ren tm8270 start_year90
	ren tm8268 start_month90
	gen spanel = 1990
	save 1990/start_year_1990, replace
	}
else if `year'==91 {
	cd 1991
	wait 1
	cd ..
	use 1991/sip91t2, clear

	desc id pnum entry
	destring id, replace
	tostring id, replace
	gen perid = id + entry + pnum
	rename (id entry pnum) (ssuid eentaid epppnum)
	keep ssuid eentaid epppnum tm8270 tm8268
	ren tm8270 start_year91
	ren tm8268 start_month91
	gen spanel = 1991
	save 1991/start_year_1991, replace
	}
else if `year'==92 {
	cd 1992
	wait 1
	cd ..
	use 1992/sip92t1, clear

	desc id pnum entry
	destring id, replace
	tostring id, replace
	rename (id entry pnum) (ssuid eentaid epppnum)
	keep ssuid eentaid epppnum tm8270 tm8268
	ren tm8270 start_year92
	ren tm8268 start_month92
	gen spanel = 1992
	save 1992/start_year_1992, replace
	}
else {
	cd 1993
	wait 1
	cd ..
	use 1993/sip93t1, clear

	desc id pnum entry
	destring id, replace
	tostring id, replace
	rename (id entry pnum) (ssuid eentaid epppnum)
	keep ssuid eentaid epppnum tm8270 tm8268
	ren tm8270 start_year93
	ren tm8268 start_month93
	gen spanel = 1993
	save 1993/start_year_1993, replace
	}

