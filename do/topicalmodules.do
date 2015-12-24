clear all
set tracedepth 1
set trace off
set more off

local panel = 2008

*Select desired topical modules
if `panel'==1990 | `panel'==1992 {
  local tms 4
}
else if `panel'==1991 | `panel'==1993 {
  local tms 7
}
else if `panel'==1996 {
  local tms 3 6 9 12
}
else if `panel'==2001 {
  local tms 3 6 9
}
else if `panel'==2004 {
  local tms 3 6
}
else if `panel'==2008 {
  local tms 4 7 10
}

*Prepare topical module files for merge
cd `panel'

loc j = substr("`panel'",3,2)
foreach tm in `tms' {
  if inrange(`panel',1990,1993) {
    use "sip`j't`tm'.dta", clear
    *rename matching variables
    rename (id entry pnum rot) (ssuid eentaid epppnum srotaton)
    *rename net worth and wealth variables
    rename (hh_tnw hh_twlth) (thhtnw thhtwlth)
    *only keep wealth and matching variables
    keep ssuid eentaid epppnum srotaton wave thhtnw thhtwlth

    tostring ssuid, replace
  }
  else if `panel'==1996 {
    use "sipp`panel'tm`j'puw`tm'.dta", clear
    rename (swave) (wave)
    tostring shhadid, replace
    *only keep wealth and matching variables
    keep ssuid eentaid epppnum spanel wave srotaton thhtnw thhtwlth
  }
  else if `panel'==2001 {
    use "components/sip`j't`tm'.dta", clear
    rename (swave) (wave)
    tostring shhadid, replace
    *only keep wealth and matching variables
    keep ssuid eentaid epppnum spanel wave srotaton thhtnw thhtwlth
  }
  else if `panel'==2004 | `panel'==2008 {
    use "sippp`j'putm`tm'.dta", clear
    rename (swave) (wave)
    tostring shhadid, replace
    *only keep wealth and matching variables
    keep ssuid eentaid epppnum spanel wave srotaton thhtnw thhtwlth
  }

  save "sip`j't`tm'_ed.dta", replace 
}

*append topical module files
clear
qui foreach tm in `tms' {
  append using "sip`j't`tm'_ed.dta"
}
save "sip`j'tm_a.dta", replace 


