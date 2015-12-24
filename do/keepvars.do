******************************************************************************************
* keep only relevant variables: this is where you should specify things you want to keep *
******************************************************************************************

display ${panel}

if inlist(${panel},96,01,04,08) {
	# delimit ;
	keep ssuseq ssuid srotaton shhadid eentaid epppnum wpfinwgt 
  	rmesr rmwklkg rhcalmn rhcalyr tfipsst ems efspouse 
  	efrefper eppintvw tage eppintvw srefmon renroll 
  	rwkesr* tpmsum1 ejbhrs1 epayhr1 efkind rfid* 
  	tpyrate1 apyrate1 ejbind1 rsid errp epnspou esex 
  	erace eeducate rfnkids emax ebuscntr east2a 
  	tsjdate1 tejdate1 rwksperm 
  	eeno1 eafnow eresnss1 rmwkwjb eafever 
  	swave eeno1 eeno2 eunion1 ecntrc1 apmsum1 apyrate1 
  	spanel renroll eocctim1 ebiznow1 edisabl 
  	ersend1 ersend2 gvarstr ghlfsam grgc  ;
  	# delimit cr ;
	}


else if inlist(${panel},90,91,92,93) {
 keep ssuseq ssuid srotaton shhadid epppnum wpfinwgt whfnwgt wffinwgt wsfinwgt rmesr ///
  rhcalmn rhcalyr tfipsst ems efspouse rmwklkg efrefper eppintvw ///
  tage renroll rwkesr* tpmsum1 ejbhrs1 epayhr1 efkind rfid* rwksperm ///
  tpyrate1 apyrate1 ejbind1 rsid errp epnspou esex erace rfnkids apmsum1 ///
  east2a tsjdate1 eeno1 eeno2 eafnow eresnss1 rmwkwjb ///
  swave eunion1	ecntrc1	spanel srefmon ebiznow1 thprpinc edisabl ebiznow1 ///
  /* now add in variables we'll need from 1990-93 */ ///
  higrade grdcmpl ws1chg ws12024 eentaid eeducate eafever gvarstr ghlfsam grgc ///
  /* the new job start variables */ ///
  jstart_ym
  }

* save the data *
if inlist(${panel},1,4,8,96) {
	save sipp_${panel}w${wave}, replace								// resave
	}
else if inlist(${panel},90,91,92,93) {
	save sipp_${panel}, replace
	}

******************************************************************************************
*                   bring in panel data to get longitudinal weights                      *
******************************************************************************************
if inlist(${panel},90,91,92,93) {
	use 19${panel}/sip${panel}fp, clear											// bring in panel data  
  	foreach v of var pp_entry pp_id pp_pnum {
    	destring `v', replace													// drop leading zeros
    	tostring `v', replace													// string for concat
    				}
  	ren (pp_id pp_entry pp_pnum ) (ssuid eentaid epppnum)						// gen puid: in full panel we didn't change the var names yet
  	keep ssuid eentaid epppnum pnlwgt fnlwgt*									// keep weights
  	gen spanel=1900+${panel}													// merge year
  	save sip${panel}pnlwgt, replace										// save off
  }

if inlist(${panel},1,4,8,96) {
	use sipp_${panel}w${wave}, clear									// resave
	}
else if inlist(${panel},90,91,92,93) {
	use  sipp_${panel}, clear
	}


* merge on longitudinal weights to the main data *
if inlist(${panel},90,91,92,93) {												// loop over 90/93
  	merge m:1 ssuid eentaid epppnum spanel using ///					
    sip${panel}pnlwgt, keep(match master) nogen							// merge in
  	ren pnlwgt pnlwgt${panel}													// rename to prevet overwrite	
	gen puid = ssuid + eentaid + epppnum
	tostring shhadid, replace
	gen hhid = ssuid + shhadid
}
  
if ${panel}==96 {  
	merge m:1 ssuid epppnum spanel using ///
  	1996/sipp96lw, keep(match master) nogen									// 1996 panel weights
    gen puid = ssuid+epppnum
    tostring shhadid, replace
  	gen hhid = ssuid + shhadid
  }
  
if ${panel}==01 {  
	merge m:1 ssuid epppnum spanel using ///
  	2001/sip01lw9, keep(match master) nogen									// 2001 panel weights
  	ren lgtpnwt3 pnlwgt
  	gen puid = ssuid+epppnum
  	tostring shhadid, replace
   	gen hhid = ssuid + shhadid

  }
  
if ${panel}==04 {  
merge m:1 ssuid epppnum spanel using ///
  2004/sipplgtwgt2004w12, keep(match master) nogen 							// 2004 panel weights
	gen puid = ssuid+epppnum
	tostring shhadid, replace
  	gen hhid = ssuid + shhadid
}

if ${panel}==08 {
merge m:1 ssuid epppnum spanel using ///
  2008/sipplgtwgt2008w16, keep(match master) nogen							// 2008 panel weights
	gen puid = ssuid+eentaid+epppnum
	tostring shhadid, replace
  	gen hhid = ssuid + shhadid
}



******************************************************************************************
*                    rename some variables to something normal *
******************************************************************************************

ren (srefmon  rhcalyr rhcalmn ///
     eppintvw tpmsum1 ejbhrs1 swave) ///
    (refmon   h_year  h_month ///
     pp_intvw earnings1 hours1  wave)

* recode employment status variable *
recode rmesr (0=.) (1/3=1) (4=-1) (5/7=0) (8=-1) (-1=.), gen(lms0) 				// using monthly aggregate of weekly data: 																																							
label define lms0lbl  1 "employed" 0 "unemployed" -1 "nilf"
label values lms0 lms0lbl																				
																				// -1 is nilf and missing is missing
recode rwkesr4 (1/3=1) (4=0) (5=-1) (-1=.), gen(lms_alt1)   					// using 4th week data only: 
label define lms_alt1  1 "employed" 0 "unemployed" -1 "nilf"
label values lms_alt1 lmsalt1lbl																				
																				


* recode year variable *
replace h_year = 1900+h_year if h_year<1995										// fix 90/93 panels
replace h_year = 1995 if h_year==3895											// quirky 1995 bug
gen ym=ym(h_year,h_month)		  												// generate date variable
format ym %tm																	// formats


* generate other useful controls *
gen nev_mar = (ems==6 & !mi(ems))												// never married
gen union = (eunion1==1)													 	// belong to a union

merge m:1 h_year h_month using pce.dta 

if inlist(${panel},90 ,91,92,93) {
  *merge in topical module data
  merge m:1 ssuid eentaid epppnum wave srotaton using "19${panel}/sip${panel}tm_a", gen(tmmerge)
	save sip${panel}, replace
  erase sipp_${panel}.dta
}
if inlist(${panel},1,4,8,96) {
	gen jstart_ym_90_93 = . 
	save sip${panel}w${wave}, replace												// final dataset
}

clear all
