clear all
cap log close
set more off
version 12
set tracedepth 1
set trace on


local year = 93
local w90 8
local w91 8
local w92 9
local w93 9
local w01 9

if inrange(`year',90,93) {
	cd 19`year'/components/
	forval w=1/`w`year'' {
	  do sip`year'w`w'.do
	  erase sipp`year'w`w'.dat
	  save ../sip`year'w`w'.dta, replace
	  clear
	}
	do sip`year'fp.do
	erase sipp`year'fp.dat
	compress
	save ../sip`year'fp.dta, replace
	cd ../../
}

if `year' == 01 {
	forval year=01/01 {
		cd 200`year'/components/
		forval w=1/`w0`year'' {
		  do sip0`year'w`w'.do
		  compress
		  save ../sip0`year'w`w'.dta, replace
		  cap log close
		  clear
		  }
		cd ../../
	}

	/* make dataset with longitudinal weights */
	cd 2001/components/	
	quietly infile using sip01lw9.dct, using(sipp01lw9.dat) clear
	save ../sip01lw9.dta, replace	
	cd ../../
}

