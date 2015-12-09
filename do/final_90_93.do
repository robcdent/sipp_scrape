clear all
cap log close
set more off
pause on
version 12

* we want the files to be fully extracted from the raw data -- write a loop to 
* check the progress on 1993 (the last year)
cd 1993
gl files: dir . files "*.dta"
loc n_files: list sizeof global(files)
while `n_files'< 12 {
	sleep 100000
	gl files: dir . files "*.dta"
    loc n_files: list sizeof global(files)
}
cd ..
* output correct start date *
forval y=90/93 {   
	if `y'==90 {
		use 1990/sip90t2, clear
		destring id, replace
		tostring id, replace
		rename (id entry pnum) (ssuid eentaid epppnum)
		keep ssuid eentaid epppnum tm8270 tm8268
		ren tm8270 start_year90
		ren tm8268 start_month90
		gen spanel = 1990
		save 1990/start_year_1990, replace
		}
	if `y'==91 {
		use 1991/sip91t2, clear
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
	if `y'==92 {
		use 1992/sip92t1, clear
		destring id, replace
		tostring id, replace
		rename (id entry pnum) (ssuid eentaid epppnum)
		keep ssuid eentaid epppnum tm8270 tm8268
		ren tm8270 start_year92
		ren tm8268 start_month92
		gen spanel = 1992
		save 1992/start_year_1992, replace
		}
	if `y'==93 {
		use 1993/sip93t1, clear
		destring id, replace
		tostring id, replace
		rename (id entry pnum) (ssuid eentaid epppnum)
		keep ssuid eentaid epppnum tm8270 tm8268
		ren tm8270 start_year93
		ren tm8268 start_month93
		gen spanel = 1993
		save 1993/start_year_1993, replace
		}
	}
* load in the revised job id files for the 90-93 panels, save them to appropriate folder *
forval y=90/93 {                                                                                                			// cycle through year
  	infix str suid 1-9 str entry 10-11 str pnum 12-14 panel 15-18 ///
    wave 19-20 jobid 21-22 jobid_revised 23-24 ///
    jobid_revised_flag 25 using ///
    19`y'/components/sipp_revised_jobid_file_19`y'.dat, clear                                							// infix (short, easiest)
    gen puid = suid+entry+pnum
    describe puid sui entry pnum
    save 19`y'/rev_jobid_`y', replace                                                                     		 		// save for merge
   }	
/* 1990-1993 waves need renaming as well as fixing job ID inconsistency */

forval y=90/93 {
* each panel has a different number of waves
	if inlist(`y',90,91) {
    	local max_wave=8
    	}
  	else {
    	local max_wave=9
    	}
    	
  	forval i=1/`max_wave' {
	  	use 19`y'/sip`y'w`i', clear											// load in the data from the wave
		gen puid = suid+entry+pnum													// generate unique person id
	  	bys puid panel wave: keep if _n==1											// job id doesn't change within wave, keep first observation per individual									
	  	keep puid wave panel ws12002 ws22102 suid entry pnum                        // keep job numbers, identifiers
	  	gen jobid1 = ws12002														// job #1
	  	gen jobid2 = ws22102														// job #2
	  	preserve
	   	sort puid
	   	keep if !mi(jobid1) & jobid1!=0												// keep if job #1 data is nonmissing  
	   	drop jobid2
	   	ren jobid1 jobid
	   	gen job_num=1
	   	save 19`y'/firstjobs_`y'_`i', replace								 	// save in ``first job file"
	  	restore
	  	preserve																	// ... do the same for the second job
	   	sort puid
	   	keep if !mi(jobid2) & jobid2!=0		
	   	ren jobid2 jobid
	   	drop jobid1
	   	gen job_num=2
	   	save 19`y'/secondjobs_`y'_`i', replace
	  	restore
	  	use 19`y'/firstjobs_`y'_`i', clear
	  	append using 19`y'/secondjobs_`y'_`i'
	  	save 19`y'/jobid_rev_`y'_`i', replace									// this file will be unique by person id and job number
	  	erase 19`y'/firstjobs_`y'_`i'.dta
	  	erase 19`y'/secondjobs_`y'_`i'.dta
  		}
	clear																		 	// append all waves together, now unique by person id, wave , and job number
	forval i=1/`max_wave' {
  		append using 19`y'/jobid_rev_`y'_`i'
  		erase 19`y'/jobid_rev_`y'_`i'.dta
  		}

	keep puid wave panel jobid job_num
	replace panel = panel+1900
	count if job_num==.
	merge 1:1 puid wave jobid using 19`y'/rev_jobid_`y'.dta
	drop _merge jobid
	ren jobid_revised jobid

	reshape wide jobid jobid_revised_flag, i(panel wave puid) j(job_num)		// now unique by person id, wave 
	ren (jobid1 jobid2) (ws12002 ws22102)
	save 19`y'/fixed_jobid_`y', replace 
}

clear
forval y=90/93 {
  	cd 19`y'
  	local files: dir . files "*`y'w*.dta"
  	foreach f of local files {
    	disp "appending `f'"
    	qui append using `f'
    	}
cd ..

destring suid, replace
tostring suid, replace
replace panel = panel+1900 if panel<100
gen puid = suid+entry+pnum

* merge in corrected job IDs
ren ws12002 ws12002_old
ren ws22102 ws22102_old
merge m:1 puid panel wave using ///
  19`y'/fixed_jobid_`y', keep(match master) 



/* fix imputation flags */
drop _merge
save 19`y'/sipp_`y', replace



/* get education variables from topical module 2 */

use 19`y'/sip`y't2, clear
if inlist(`y',92,93) {
	merge m:m id entry pnum wave using 19`y'/sip`y't1
	}
rename id suid
destring suid, replace
tostring suid, replace
gen puid = suid+entry+pnum
rename rotation rot
keep higrade grd_cmp tm8400 tm8408 tm8416 tm8422 tm8430 suid rot pnum wave entry puid

merge 1:m puid wave using 19`y'/sipp_`y'


* use crosswalk --> ../documentation/93_96_var_crosswalk.pdf
ren suseqnum ssuseq
ren suid ssuid
ren rot srotaton
ren addid shhadid
ren pnum epppnum
ren fnlwgt wpfinwgt
ren esr rmesr
ren month rhcalmn
ren year rhcalyr
ren hstate tfipsst
ren ms ems
ren fspouse efspouse
ren wkslok rmwklkg
ren frefper efrefper
ren intvw eppintvw
ren age tage
ren enrold renroll
ren wesr* rwkesr* 
ren ws1amt tpmsum1
ren ws1calc apmsum1
ren uhours ejbhrs1
ren ws12026 epayhr1
ren fkind efkind
ren fid* rfid*
ren ws12028 tpyrate1
ren iws12028 apyrate1
ren ws1ind ejbind1
ren sid rsid
ren rrp errp // also need famrel
ren pnsp epnspou
ren sex esex
ren race erace
ren fnkids rfnkids
ren weeks rwksperm
ren r103 east2a
ren ws12018 tsjdate1
ren ws12002 eeno1
ren ws22102 eeno2
ren inaf eafnow
ren socsr1 eresnss1
ren wksjob rmwkwjb
ren wave swave
ren ws12044 eunion1
ren ws12046 ecntrc1
ren panel spanel
ren refmth srefmon
ren se12202 ebiznow1
gen thprpinc = hprop + fprop
ren disab edisabl
ren entry eentaid
ren hwgt whfnwgt
rename fwgt wffinwgt
rename swgt wsfinwgt
rename vetstat eafever
replace eafever = -1 if eafever == 0
replace apmsum1 = 0 if apmsum1==2				// not imputed
rename hhsc ghlfsam
rename surgc grgc
rename hstrat gvarstr


/* fix education attainment variable using information from the topical module */
recode tm8422 (00=-1) (01=47) (02=46) (03=45) (04=44) (05=43) (06=41) (00=-1) (07=-1), generate(eeducate)

replace eeducate = 40 if inlist(higrade,21,26) & grdcmpl==2															// went to college, but did not complete
replace eeducate = 39 if inlist(higrade,9,10,11,12) & grdcmpl==1													// went ot high school and complete degree
replace eeducate = 38 if inlist(higrade,12) & grdcmpl==2															// attended 12th grade, didn't complete
replace eeducate = 37 if higrade==11 & grdcmpl==1																	// completed 11th grade
replace eeducate = 36 if (higrade==11 & grdcmpl==2) | (higrade==10 & grdcmpl==1) 									// completed 10th grade
replace eeducate = 35 if (higrade==10 & grdcmpl==2) | (higrade==9 & grdcmpl==1) 									// completed 9th grade

replace eeducate = 34 if (higrade==9 & grdcmpl==2)  | (higrade==8 & grdcmpl==1) 									// completed 8th grade
replace eeducate = 34 if (higrade==8 & grdcmpl==2)  | (higrade==7 & grdcmpl==1) 									// completed 7th grade

replace eeducate = 33 if (higrade==7 & grdcmpl==2)  | (higrade==6 & grdcmpl==1) 									// completed 6th grade
replace eeducate = 33 if (higrade==6 & grdcmpl==2)  | (higrade==5 & grdcmpl==1) 									// completed 5th grade

replace eeducate = 32 if (higrade==5 & grdcmpl==2)  | (higrade==4 & grdcmpl==1) 									// completed 4th grade
replace eeducate = 32 if (higrade==4 & grdcmpl==2)  | (higrade==3 & grdcmpl==1) 									// completed 3rd grade
replace eeducate = 32 if (higrade==3 & grdcmpl==2)  | (higrade==2 & grdcmpl==1) 									// completed 2nd grade
replace eeducate = 32 if (higrade==2 & grdcmpl==2)  | (higrade==1 & grdcmpl==1) 									// completed 1st grade


replace eeducate = 33 if (higrade==6 & grdcmpl==2)  | (higrade==5 & grdcmpl==1) 									// completed 5th grade
replace eeducate = 31 if (higrade ==1 * grdcmpl==2)																	// attended but did not complete 1st grade



replace eeducate = -1 if tage<=15																					// to be consistent with universe in later panels



*----------------------------*
*   start date for 1990-93   *
*----------------------------*
/* merge in start years for 1990-1993 panels */
merge m:1 ssuid epppnum eentaid spanel using 19`y'/start_year_19`y'.dta, gen(syear_`y')
  
local time "year month"
foreach t of local time {
 egen jstart_`t' = rowtotal(start_`t'`y')
 replace jstart_`t' = . if jstart_`t'==0
 replace jstart_`t' = . if eeno1!=1
 }

local panel = 1 // 1 for panel, 0 for non-panel
egen pid = group(ssuid epppnum eentaid spanel)
gen ym = ym(rhcalyr,rhcalmn)                                                                                                
tsset pid ym

* what date do job changers report switching?
gen jchange_ym = ym if ws1chg==1
format jchange_ym %tm
tsset pid ym
bys pid (ym): carryforward jchange_ym, replace

* create within-wave change variable to override the carryforward
bys pid swave: egen ww_change = max(jchange_ym)
format ww_change %tm
bys pid (ym): carryforward eeno1, gen(eeno1_carry)
gen jstart_ym = .
bys pid (ym): replace jstart_ym = ww_change if eeno1!=L1.eeno1 & _n!=1
replace jstart_ym = ym(jstart_year,jstart_month) if eeno1==1
bys pid eeno1 (ym): carryforward jstart_ym, replace
ren jstart_ym jstart_ym_90_93
drop jchange_ym ww_change jstart_year jstart_month ym


compress

save sipp`y', replace
clear all
}

/* final datasets will have merged waves with correct job ids and new variables names saved in the sipp/`panelyear' folder */
