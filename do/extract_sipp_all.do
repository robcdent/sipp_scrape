clear all
set tracedepth 1
set trace on
set more off

local panel = 1991

* 1990 - 1993: all waves are already merged together for these
if inrange(`panel',1990,1993) {
    loc j = substr("`panel'",3,2)
  	pwd
  	use "sipp`j'.dta", clear										    // already merged waves for these in "fixjobids", just use that data
	  global panel = `j'
	  save sipp`j', replace											    // resave
	  do do/keepvars.do  													// keep only relevant variables, add in panel weights
  	clear all
}

// for the rest, the waves will be separate //
* 2008 and 2004 :
if inlist(`panel',2004,2008) {
  cd `panel'
  loc j = substr("`panel'",4,1)															
  local files: dir "." files "sippl0`j'puw*.dta"								// grab waves
  global panel = 0`j'																// check loops
  foreach f of local files {													// loop over waves
    disp "appending `f'"														// check append
    use `f',clear	
    sum swave
    
    * fix weird bug in nber data documented at thedataweb.rm.census.gov/ftp/sipp_ftp.html if it hasn't been fixed *
    if `panel'==2004 & r(mean)==7 {
        local length1 = length(epppnum)
        local length2 = length(eentaid)
        if `length1' <4 {
    		replace epppnum = "0"+ epppnum
    		}
        if `length1' <3 {		
    		replace eentaid = "0"+ eentaid
    		}
    }
    	
    gl wave = r(mean)															// append
    cd ..
    do do/keepvars.do
    cd `panel'
    }
  cd ..
  }

if `panel'==2004 {
    erase sipp_4w1.dta
    use sip4w1.dta, clear
    forval w = 2/12 {
    	append using sip4w`w'.dta
    	display "`w'"
      erase sip4w`w'.dta
      erase sipp_4w`w'.dta
    	}
    save sip04, replace
    erase sip4w1.dta
}

if `panel'==2008 {
    erase sipp_8w1.dta
    use sip8w1.dta, clear
    forval w = 2/16 {
    	append using sip8w`w'.dta
      erase sip8w`w'.dta
      erase sipp_8w`w'.dta
    	display "`w'"
    	}
    save sip08, replace
    erase sip8w1.dta
}


if `panel'==1996 {
    * 1996
    clear all
    gl panel = 96																	// hop into directory
    forval k=1/12 {																	// loop over waves
      use 1996/sipp1996sip96w`k'd, clear										// append
      sum swave
      gl wave = r(mean)
      do do/keepvars.do  														// after appending all waves, keep relevant variables, add in panel weights
      }
    erase sipp_96w1.dta
    use sip96w1.dta, clear
    forval w = 2/12 {
    	append using sip96w`w'.dta
      erase sip96w`w'.dta
      erase sipp_96w`w'.dta
    	display "`w'"
    	}
    save sip96, replace
    erase sip96w1.dta
    }

if `panel'==2001 {
    * 2001
    clear all	
    gl panel = 01																	// hop into directory
    forval k=1/9 {																	// loop over waves
      use 2001/sip01w`k', clear																// append
      sum swave
      gl wave = r(mean)
      do do/keepvars.do  
      }

    use sip1w1.dta, clear
    erase sipp_1w1.dta
    forval w = 2/9 {
    	append using sip1w`w'.dta
      erase sip1w`w'.dta
      erase sipp_1w`w'.dta
    	display "`w'"
    	}
    erase sip1w1.dta
    save sip01, replace
    }

