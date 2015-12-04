#!/bin/bash
# -------------------------------------------------------------------------------- #
# This program pulls the SIPP files from NBER and creates the .DTA for use         #
# Authors: Laura Pilossoph; Rob Dent (robcdent@gmail.com)						   #
# Please email the above with any comments, suggestions or corrections. 		   #
# All errors are the authors' -- use at your own descretion!					   #
# -------------------------------------------------------------------------------- #

# tracking code
exec > >(tee pull_sipp_$(date +"%F")_$(date +"%H_%M_%S").txt)
exec 2>&1

# --------------------------------- USER OPTIONS --------------------------------- #
# SET THESE ACCORDING TO YOUR OPERATING SYSTEM!
# 1) OS should be: mac, linux, windows
os="linux"
# 2) Proxy settings (only change http_proxy if proxy=on)
proxy=on    								# on or off
http_proxy="http://p1web1.frb.org:8080/"	# only set if ${proxy}="on"
# 3) How your machine calls Stata (see instructions)
#export PATH=${PATH}:/Applications/Stata/StataSE.app/Contents/MacOS/.
stata="stata13-se-batch 15"
 

# --------------------------------- SYSTEM SET UP -------------------------------- #
# setting the proxy from above
if [ "${proxy}" == "on" ]; then
	export http_proxy=${http_proxy}
fi
# correcting the sed command across operating systems
if [ "${os}" == "mac" ]; then
	sed="sed -i.bak"
else 
	sed="sed -i "
fi
# directories
sipp_pull="`pwd`"							# initialize in current folder
# links for NBER and Census datasites:							  				
nber="http://www.nber.org/sipp"
census="http://thedataweb.rm.census.gov/pub/sipp"
echo "OS: ${os}; sed: ${sed}; proxy: ${proxy}; Stata: ${stata}"
# ------------------------------------------------------------------------------ #
# grab PCE data first and submit cleaning program
source pce.bash
while [ `ls -l pce.csv | wc -l` -lt 1 ]; do
	sleep 10
done

${stata} pce.do

# download and clean each panel individually to economize on disk space
for year in 1990 1991 1992 1993 1996 2001 2004 2008; do	
	cd ${sipp_pull}
	mkdir ${year}																# one folder per year
	mkdir ${year}/components													# underlying files for the dta
	cd ${sipp_pull}
	if [ ${year} -lt 1996 ]; then
		for filetype in dct do dat.Z; do 										# 1990-1993 we can grab all files
  			cd ${year}/components							
  			wget -r -nd -l 1 -A $filetype ${nber}/${year}/						# download all files with certain extension			
		done
	elif [ ${year} -eq 2001 ]; then												# 2001 has separate wget urls
		cd ${year}/components													# download into components
		for i in {1..9}; do								                        # loop over waves
   			wget -r -nd ${nber}/2001/sipp01w$i.zip								# zipped dat files
			wget -r -nd ${nber}/2001/sip01w$i.do 								# stata .do files
			wget -r -nd ${nber}/2001/sip01w$i.dct 								# stata infile dictionaries
		done
		wget -r -nd ${nber}/2001/sipp01lw9.zip 									# 2001 longitudinal weights
		wget -r -nd ${nber}/2001/sip01lw9.dct 									# 2001 longitudinal weight dct
    elif [ ${year} -eq 1996 -o ${year} -gt 2001 ]; then							# 1996, 2004, 2008 have dta's ready
    	cd ${year}
    	wget -r -nd -l 1 -A dta.zip ${nber}/${year}/							# download dta's directly
	fi
	find . -type f -not \( -name '*w*'  -or -name '*fp*' \
	               -or -name '*lw*' -or -name '*lgtwgt*' \) -delete				# remove files we don't need
	gunzip *.Z 																	# some files are .Z
	unzip \*.zip 																# unzip
	rm *.zip																	# remove zipped files
	if [ ${year} -lt 1996 ] || [ ${year} -eq 2001 ]; then						# run .do files for non-dta years
		for f in $(ls *.dct *.do); do                                   		# loop over dct & do files
    		${sed} "s/\/home\/data\/sipp\/${year}\///g" ${f}					# variant of the directory
    		${sed} "s/\/homes\/data\/sipp\/${year}\///g" ${f}        			# remove nber directory
			${sed} "s/log/*log/g" ${f}                             				# turn logging off
			${sed} "s/save/*save/g" ${f}										# turn saving off
		done
			cd ${sipp_pull}
			yy=${year:2:2}														# last two digits for year
			${sed} "s/.*local year =.*/local year = ${yy}/" dtamake.do  		# replace entire line for local year
			${stata} $sipp_pull/dtamake.do 										# submit job for year
		if [ ${year} -lt 1996 ]; then
			cd ${sipp_pull}/${year}/components
			if [ ${year} -gt 1991 ]; then
				modules="1 2"
			else
				modules="2"
			fi
			for tm in ${modules}; do
				wget -r -nd ${nber}/${year}/sipp${yy}t${tm}.dat.Z       				# Z files
				wget -r -nd ${nber}/${year}/sip${yy}t${tm}.do       					# .do files
				wget -r -nd ${nber}/${year}/sip${yy}t${tm}.dct      					# .dct files
				gunzip -f *.Z             												# unzip with overwrite
				${sed} "s/log/*log/g" sip${yy}t${tm}.do        							# turn logging off
				${sed} "s/\/homes\/data\/sipp\/${year}\///g" sip${yy}t${tm}.dct     	# remove NBER dir
				echo "save ../sip${yy}t${tm}.dta, replace;" >> sip${yy}t${tm}.do    	# add in line for saving
				echo "erase sip*t.dat" >> sip${yy}t${tm}.do
				echo "  " >> sip${yy}t${tm}.do           								# add empty line for .do file
				${stata} ${sipp_pull}/${year}/components/sip${yy}t${tm}.do         		# submit job
			done
		   	cd ${sipp_pull}/${year}/components
		   	wget -r -nd ${census}/${year}/sipp_revised_jobid_file_$year.zip 			# grab revised job IDs
		   	unzip \*.zip  																# unzip all files
		   	rm *.zip 																	# delete zips
		   	cd ${sipp_pull}
		   	${sed} "s/.*local year =.*/local year = ${yy}/" start_date_1990_93.do  		# modify .do file for current year 
		   	${stata} start_date_1990_93.do 												# submit job for start dates
		   	#${sed} "s/local year = ${yy}/local year = /" start_date_1990_93.do			# modify .do file back
		  	if [ ${year} -eq 1993 ]; then												# proceed if on last of the early 90s
		  		cd ${sipp_pull}
		 		${stata} final_90_93.do 												# submit 90-93 aggregation program
		 		for yy in 90 91 92 93; do 
		 			while [ `ls -l sipp${yy}.dta | wc -l` -lt 1 ]; do					# once final .dta is outputted, delete components
		 				echo "wait to drop 19${yy}"
		 				sleep 100
		 			done
		 			${sed} "s/.*local panel =.*/local panel = 19${yy}/" extract_sipp_all.do # modify .do file for current year 
		 			${stata} extract_sipp_all.do
		 			#${sed} "s/local panel = 19${yy}/local panel = /" extract_sipp_all.do # modify .do file for current year 
		 			while [ `ls -l sip${yy}.dta | wc -l` -lt 1 ]; do
		 				sleep 100
		 			done
		 			rm -rf 19${yy}
		 			rm sipp${yy}.dta
		 			rm sip${yy}pnlwgt.dta
		 		done
		 	fi
		fi
	fi
	if [ ${year} -eq 1996 ] || [ ${year} -ge 2001 ]; then
		if [ ${year} -eq 1996 ]; then											# we need 1996 longitudinal weights separately
			cd $sipp_pull/${year}
			wget -r -nd ${nber}/${year}/ctl_fer.zip
			wget -r -nd ${nber}/${year}/sip96lw.do       						# .do files
			wget -r -nd ${nber}/${year}/sip96lw.dct      						# .dct files
			unzip -o \*.zip									                    # unzip files
			rm *.zip
			mv ctl_fer.dat sipp96lw.dat
			${sed} "s/log/*log/g" sip96lw.do        							# turn logging off
			${sed} "s/\/homes\/data\/sipp\/1996\///g" sip96lw.do     			# remove NBER dir
			${sed} "s/\/homes\/data\/sipp\/1996\///g" sip96lw.dct     			# remove NBER dir
			echo "save sip9lw.dta, replace" >> sip96lw.do    					# add in line for saving
			echo "  " >> sip96lw.do           									# add empty line for .do file
			${stata} sip96lw.do
			cd ${sipp_pull}
		fi
		if [ ${year} -eq 2001 ]; then
			while [ `ls 2001/sip01lw9.dta -l | wc -l` -lt 1 ]; do
				sleep 100
			done
		fi
		cd ${sipp_pull}
		${sed} "s/.*local panel =.*/local panel = ${year}/" extract_sipp_all.do # modify .do file for current year 
		${stata} extract_sipp_all.do
		#${sed} "s/local panel = ${year}/local panel = /" extract_sipp_all.do # modify .do file for current year 
		yy=${year:2:2}
		while [ `ls -l sip${yy}.dta | wc -l` -lt 1 ]; do					# once final .dta is outputted, delete components
		 	echo "wait to drop ${year}"
		 	sleep 100
		done
		rm -rf ${year}
	fi
done

for i in {1..9}; do
    rm -f -r *.e${i}*
    rm -f -r *.o${i}*
    rm -f -r *.po${i}*
    rm -f -r *.pe${i}*
done

>&2
