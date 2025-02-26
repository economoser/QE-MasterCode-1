// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// This program generates the files that will be uploaded to the website
// This version Feb 01, 2022
// Created by Luigi Pistaferri
// Updated by Sergio Salgado
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

clear all
set more off
set matsize 800
cap log close

// Definitions 
	global maindir ="..."		// Define main directory
	do "$maindir/do/0_Initialize.do"	
	global folder="${maindir}${sep}out${sep}"

	global ineqdata = "25 Jan 2022 Inequality"			// Data on Inequality 
	global voladata = "20 Jan 2022 Volatility"				// Data on Volatility
	global mobidata = "19 Jan 2022 Mobility"				// Data on Mobility

	global datafran="${folder}${sep}19 Jan 2022 Upload"			// Define were data will be saved
*	capture noisily mkdir "${folder}${sep}19 Jan 2022 Upload"	// Create the folder	

****************TAIL INDEX
forvalues mm = 0/2{			/*0: Women; 1: Men; 2: All*/
			
	if `mm' == 1{
		insheet using "$folder${sep}${ineqdata}${sep}RI_male_earn_idex.csv", clear comma 
		keep if male == `mm'
	}
	else if `mm' == 0{
		insheet using "$folder${sep}${ineqdata}${sep}RI_male_earn_idex.csv", clear comma 
		keep if male == `mm'	
	}
	else {
		insheet using "$folder${sep}${ineqdata}${sep}RI_earn_idex.csv", clear comma 			
	}	
	reshape long t me ra ob, i(year) j(level) string
	split level, p(level) 
	drop level1
	rename level2 numlevel
	destring numlevel, replace 
	order numlevel level year 
	sort year numlevel
	
	*Re scale and share of pop
	by year: gen aux = 20*ob if numlevel == 0 
	by year: egen tob = max(aux)   // Because ob is number of observations in top 5%
	drop aux
	by year: gen  shob = ob/tob
			 gen  lshob = log(shob)		  	
	
	gen t1000s = (t/1000)/${exrate2018}				// Tranform to dollars of 2018
	gen lt1000s = log(t1000s)
	gen lt = log(t)
	gen l10t = log10(t)
	
	*Check number of observations 
	replace  shob = . if ob <= $minnumberobs
	replace lshob = . if ob <= $minnumberobs
	
	*Keep years end in 0 or 5
// 	keep if inlist(year,1950,1960,1970,1980,1990,2000,2010,2020) | ///
// 		inlist(year,1955,1965,1975,1985,1995,2005,2015,2025)
// 	drop if year < 1950
	levelsof year, local(yyrs)
	
	*Re-reshape 
	reshape wide t me ra ob tob shob lshob t1000s lt l10t lt1000s, i(numlevel) j(year)	
	
	*Tail idexed
	foreach yr of local yyrs{
	
		/*5% Tail*/
		regress lshob`yr' lt`yr'	
		global slopep`yr'_tp5 = _b[lt`yr']
								
		/*1% Tail*/		
		regress lshob`yr' lt`yr' if shob`yr' < 0.01	
		global slopep`yr'_tp1 = _b[lt`yr']
			
	}
	*Save
	clear 
	set obs 1 		
	foreach yr of local yyrs{		
		gen slopep_tp5`yr' = ${slopep`yr'_tp5}
		gen slopep_tp1`yr' = ${slopep`yr'_tp1}			
	}
	gen i = 1
	reshape long slopep_tp5 slopep_tp1, i(i) j(year)	
	g str3 country="${iso}"
	g str12 age="25-55"
	if `mm' == 1{		
		g str12 gender="Male"
	}
	else if `mm' == 0{		
		g str12 gender="Female"		
	}
	else {
		g str12 gender="All genders"
	}	
	drop i
	order country age gender year 
	
	save "$folder${sep}temp2_`mm'.dta", replace	
	
}

clear 
forvalues mm = 0/2{	
	append using "$folder${sep}temp2_`mm'.dta"
	erase "$folder${sep}temp2_`mm'.dta"
	
}
sort country age gender year
save "$datafran${sep}Slope.dta", replace
*export delimited using "$datafran${sep}Slope.csv", replace
	
	
********************************************************************************
insheet using "$folder${sep}${ineqdata}${sep}L_earn_con.csv",clear
drop top*me*
g str3 country="${iso}"

g str12 age="25-55"
g str12 gender="All genders"
save "$folder${sep}temp1.dta",replace
*sleep 500

forvalues j=1(1)3	{
    insheet using "$folder${sep}${ineqdata}${sep}L_earn_con_age.csv",clear
	drop top*me*
	g str3 country="${iso}"
	g str12 gender="All genders"
	keep if agegp==`j'
	g str20 age="" 
	replace age="25-34" if agegp==1 
	replace age="35-44" if agegp==2
	replace age="45-55" if agegp==3
	drop agegp
	save "$folder${sep}temp2_`j'.dta",replace
	*sleep 500
}

forvalues j=0(1)1	{
    insheet using "$folder${sep}${ineqdata}${sep}L_earn_con_male.csv",clear
	drop top*me*	
	g str3 country="${iso}"

	g str12 age="25-55"
	keep if male==`j'
	g str20 gender="" 
	replace gender="Male" if male==1 
	replace gender="Female" if male==0
	drop male
	save "$folder${sep}temp3_`j'.dta",replace
	*sleep 500
}

u "$folder${sep}temp1.dta",clear
append using "$folder${sep}temp2_1.dta"
append using "$folder${sep}temp2_2.dta"
append using "$folder${sep}temp2_3.dta"
append using "$folder${sep}temp3_0.dta"
append using "$folder${sep}temp3_1.dta"
order country year gender age
keep country year gender age *share gini
sort country year gender age
save "$datafran${sep}Ineq_earnings_stats_timeseries.dta", replace
*export delimited using "$datafran${sep}Ineq_earnings_stats_timeseries.csv", replace
erase "$folder${sep}temp1.dta"
erase "$folder${sep}temp2_1.dta"
erase "$folder${sep}temp2_2.dta"
erase "$folder${sep}temp2_3.dta"
erase "$folder${sep}temp3_1.dta"
erase "$folder${sep}temp3_0.dta"


********************************************************************************
insheet using "$folder${sep}${ineqdata}${sep}L_logearn_hist.csv",clear
reshape long val_logearn den_logearn,i(index) j(year)
g str3 country="${iso}"
g str20 gender="All genders"
save "$folder${sep}temp1.dta",replace
*sleep 500

forvalues j=0(1)1	{
    insheet using "$folder${sep}${ineqdata}${sep}L_logearn_hist_male.csv",clear
	g str3 country="${iso}"

	keep if male==`j'
	reshape long val_logearn den_logearn,i(index) j(year)
	g str20 gender="" 
	replace gender="Male" if male==1 
	replace gender="Female" if male==0
	drop male
	save "$folder${sep}temp2_`j'.dta",replace
	*sleep 500
}

u "$folder${sep}temp1.dta",clear
append using "$folder${sep}temp2_1.dta"
append using "$folder${sep}temp2_0.dta"
g str12 age="25-55"
order country year gender age index
sort country gender year age index
save "$datafran${sep}Ineq_earnings_density_timeseries", replace
*export delimited using "$datafran${sep}Ineq_earnings_density_timeseries.csv", replace

erase "$folder${sep}temp1.dta"
erase "$folder${sep}temp2_1.dta"
erase "$folder${sep}temp2_0.dta"

********************************************************************************

foreach vv in permearn researn logearn {
	global varx = "`vv'"
	insheet using "$folder${sep}${ineqdata}${sep}L_${varx}_sumstat.csv",clear	
	g str3 country="${iso}"
	
	*Adjust for min number of observations
	qui: desc mean${varx}-p99_99${varx}, varlist
	local tvlist = r(varlist)
	foreach vvg of local tvlist {
		qui: replace `vvg' = . if n${varx} < $minnumberobs							
		}
	
	gen p9010${varx} = p90${varx} - p10${varx}
	gen p9050${varx} = p90${varx} - p50${varx}
	gen p5010${varx} = p50${varx} - p10${varx}
	gen ksk${varx} = (p9050${varx} - p5010${varx})/p9010${varx}
	gen cku${varx} = (p97_5${varx} - p2_5${varx})/(p75${varx} - p25${varx})
	drop min${varx} max${varx}
	
	g str12 age="25-55"
	g str12 gender="All genders"
	save "$folder${sep}temp1.dta",replace
	*sleep 500
	
forvalues j=$begin_age(1)$end_age	{
	insheet using "$folder${sep}${ineqdata}${sep}L_${varx}_age_sumstat.csv",clear	
	keep if age==`j'
	
	drop age
	g str3 country="${iso}"	
	qui: desc mean${varx}-p99_99${varx}, varlist
	local tvlist = r(varlist)
	foreach vvg of local tvlist{
		qui: replace `vvg' = . if n${varx} < $minnumberobs
	}
	
	
	gen p9010${varx} = p90${varx} - p10${varx}
	gen p9050${varx} = p90${varx} - p50${varx}
	gen p5010${varx} = p50${varx} - p10${varx}
	gen ksk${varx} = (p9050${varx} - p5010${varx})/p9010${varx}
	gen cku${varx} = (p97_5${varx} - p2_5${varx})/(p75${varx} - p25${varx})
	drop min${varx} max${varx}
	
	g str12 gender="All genders"
	g str2 age="`j'"
	save "$folder${sep}temp2_`j'.dta",replace
}	
	
forvalues j=0(1)1	{
	insheet using "$folder${sep}${ineqdata}${sep}L_${varx}_male_sumstat.csv",clear
	keep if male==`j'
	g str3 country="${iso}"
	qui: desc mean${varx}-p99_99${varx}, varlist
	local tvlist = r(varlist)
	foreach vvg of local tvlist{
		qui: replace `vvg' = . if n${varx} < $minnumberobs
	}
	gen p9010${varx} = p90${varx} - p10${varx}
	gen p9050${varx} = p90${varx} - p50${varx}
	gen p5010${varx} = p50${varx} - p10${varx}
	gen ksk${varx} = (p9050${varx} - p5010${varx})/p9010${varx}
	gen cku${varx} = (p97_5${varx} - p2_5${varx})/(p75${varx} - p25${varx})
	drop min${varx} max${varx}
	
	g str20 gender="" 
	replace gender="Male" if male==1 
	replace gender="Female" if male==0
	drop male
	g str20 age="25-55"
	save "$folder${sep}temp3_`j'.dta",replace
}	

forvalues j=0(1)1	{
	    forvalues k=$begin_age(1)$end_age		{
		    insheet using "$folder${sep}${ineqdata}${sep}L_${varx}_maleage_sumstat.csv",clear
			keep if male==`j'
			keep if age==`k'
			drop age
			g str3 country="${iso}"
			
			qui: desc mean${varx}-p99_99${varx}, varlist
			local tvlist = r(varlist)
			foreach vvg of local tvlist{
				qui: replace `vvg' = . if n${varx} < $minnumberobs
			}
			
			gen p9010${varx} = p90${varx} - p10${varx}
			gen p9050${varx} = p90${varx} - p50${varx}
			gen p5010${varx} = p50${varx} - p10${varx}
			gen ksk${varx} = (p9050${varx} - p5010${varx})/p9010${varx}
			gen cku${varx} = (p97_5${varx} - p2_5${varx})/(p75${varx} - p25${varx})
			drop min${varx} max${varx}
			
			
			g str20 age="`k'"
			g str20 gender="" 
			replace gender="Male" if male==1
			replace gender="Female" if male==0
			drop male
	save "$folder${sep}temp5_`j'_`k'.dta",replace
		}
	}

u "$folder${sep}temp1.dta",clear
forvalues j=$begin_age(1)$end_age	{
	append using "$folder${sep}temp2_`j'.dta"
}	
forvalues j=0(1)1	{
	append using "$folder${sep}temp3_`j'.dta"
}	
forvalues j=0(1)1	{
	    forvalues k=25(1)55	{
	append using "$folder${sep}temp5_`j'_`k'.dta"
		}
	}
order country year gender age
sort country gender age year 
save "$datafran${sep}Ineq_${varx}_stats_timeseries", replace
*export delimited using "$datafran${sep}Ineq_${varx}_stats_timeseries.csv", replace

preserve
	drop if age=="25-55"
	destring age,gen(age_num)
	drop age
	ren age_num age
	gen groupage=1 if age>=25 & age<=34
	replace groupage=2 if age>=35 & age<=44
	replace groupage=3 if age>=45 & age<=55
	collapse (sum) n${varx} (mean) mean${varx}-p99_99${varx},by(groupage gender country year)
	
	gen p9010${varx} = p90${varx} - p10${varx}
	gen p9050${varx} = p90${varx} - p50${varx}
	gen p5010${varx} = p50${varx} - p10${varx}
	gen ksk${varx} = (p9050${varx} - p5010${varx})/p9010${varx}
	gen cku${varx} = (p97_5${varx} - p2_5${varx})/(p75${varx} - p25${varx})	

	
	ren groupage age
	tostring age,replace
	replace age="25-34" if age=="1"
	replace age="35-44" if age=="2"
	replace age="45-55" if age=="3"
	save "$datafran${sep}Ineq_${varx}_stats_timeseries_addition",replace
restore

u "$datafran${sep}Ineq_${varx}_stats_timeseries", clear
append using "$datafran${sep}Ineq_${varx}_stats_timeseries_addition"
erase "$datafran${sep}Ineq_${varx}_stats_timeseries_addition.dta"
sort country gender age year 
save,replace

}	

// END loop over variables
	
erase "$folder${sep}temp1.dta"
forvalues j=$begin_age(1)$end_age	{
	erase "$folder${sep}temp2_`j'.dta"
}	
forvalues j=0(1)1	{
	erase "$folder${sep}temp3_`j'.dta"
}	
forvalues j=0(1)1	{
	    forvalues k=$begin_age(1)$end_age	{
	erase "$folder${sep}temp5_`j'_`k'.dta"
		}
	}




********************************************************************************
********************************************************************************

foreach ff in 1 5{
		foreach x in res {
		insheet using "$folder${sep}${voladata}${sep}L_`x'earn`ff'F_hist.csv",clear
		
		reshape long val_`x'earn`ff'f den_`x'earn`ff'f,i(index) j(year)
		g str3 country="${iso}"

g str20 gender="All genders"
save "$folder${sep}temp1.dta",replace
*sleep 500

forvalues j=0(1)1	{
	insheet using "$folder${sep}${voladata}${sep}L_`x'earn`ff'F_hist_male.csv",clear
	g str3 country="${iso}"

	keep if male==`j'
	reshape long val_`x'earn`ff'f den_`x'earn`ff'f,i(index) j(year)
	g str20 gender="" 
	replace gender="Male" if male==1 
	replace gender="Female" if male==0
	drop male
	save "$folder${sep}temp2_`j'.dta",replace
	*sleep 500
}

u "$folder${sep}temp1.dta",clear
append using "$folder${sep}temp2_1.dta"
append using "$folder${sep}temp2_0.dta"
g str12 age="25-55"
order country year gender age index
sort country gender year age index
save "$datafran${sep}Dynamics_`x'earn_`ff'_density_timeseries.dta", replace
*export delimited using "$datafran${sep}Dynamics_`x'earn_`ff'_density_timeseries.csv", replace
}

erase "$folder${sep}temp1.dta"
erase "$folder${sep}temp2_1.dta"
erase "$folder${sep}temp2_0.dta"
}

u "$datafran${sep}Dynamics_researn_1_density_timeseries", clear
merge country gender year age index using "$datafran${sep}Dynamics_researn_5_density_timeseries" 
drop _merge
sort country gender year age index
merge using "$datafran${sep}Ineq_earnings_density_timeseries"
drop _merge
sort country gender year age index
rename index bin
export delimited using "$datafran${sep}Density_${iso}.csv", replace

erase "$datafran${sep}Dynamics_researn_1_density_timeseries.dta"
erase "$datafran${sep}Dynamics_researn_5_density_timeseries.dta"
erase "$datafran${sep}Ineq_earnings_density_timeseries.dta"

********************************************************************************
foreach ff in 1 5 {
	foreach x in res arc {
	global varx = "`x'earn`ff'"
	
	insheet using "$folder${sep}${voladata}${sep}L_`x'earn`ff'F_sumstat.csv",clear	
	g str3 country="${iso}"
	
	*Adjust for min number of observations
	qui: desc mean${varx}-p99_99${varx}, varlist
	local tvlist = r(varlist)
	foreach vvg of local tvlist{
		qui: replace `vvg' = . if n${varx} < $minnumberobs
	}
	
	gen p9010${varx} = p90${varx} - p10${varx}
	gen p9050${varx} = p90${varx} - p50${varx}
	gen p5010${varx} = p50${varx} - p10${varx}
	gen ksk${varx} = (p9050${varx} - p5010${varx})/p9010${varx}
	gen cku${varx} = (p97_5${varx} - p2_5${varx})/(p75${varx} - p25${varx})
	drop min${varx} max${varx}
	
	g str12 age="25-55"
	g str12 gender="All genders"
	save "$folder${sep}temp1.dta",replace
	*sleep 500

forvalues j=$begin_age(1)$end_age	{
	insheet using "$folder${sep}${voladata}${sep}L_`x'earn`ff'F_age_sumstat.csv",clear
	keep if age==`j'
	drop age
	g str3 country="${iso}"
	
	*Adjust for min number of observations
	qui: desc mean${varx}-p99_99${varx}, varlist
	local tvlist = r(varlist)
	foreach vvg of local tvlist{
		qui: replace `vvg' = . if n${varx} < $minnumberobs
	}
	
	gen p9010${varx} = p90${varx} - p10${varx}
	gen p9050${varx} = p90${varx} - p50${varx}
	gen p5010${varx} = p50${varx} - p10${varx}
	gen ksk${varx} = (p9050${varx} - p5010${varx})/p9010${varx}
	gen cku${varx} = (p97_5${varx} - p2_5${varx})/(p75${varx} - p25${varx})
	drop min${varx} max${varx}

	g str12 gender="All genders"
	g str2 age="`j'"
	save "$folder${sep}temp2_`j'.dta",replace
}		
	
	
forvalues j=0(1)1	{
	insheet using "$folder${sep}${voladata}${sep}L_`x'earn`ff'F_male_sumstat.csv",clear
	keep if male==`j'
	g str3 country="${iso}"
	
	*Adjust for min number of observations
	qui: desc mean${varx}-p99_99${varx}, varlist
	local tvlist = r(varlist)
	foreach vvg of local tvlist{
		qui: replace `vvg' = . if n${varx} < $minnumberobs
	}
	
	gen p9010${varx} = p90${varx} - p10${varx}
	gen p9050${varx} = p90${varx} - p50${varx}
	gen p5010${varx} = p50${varx} - p10${varx}
	gen ksk${varx} = (p9050${varx} - p5010${varx})/p9010${varx}
	gen cku${varx} = (p97_5${varx} - p2_5${varx})/(p75${varx} - p25${varx})
	drop min${varx} max${varx}
	
	g str20 gender="" 
	replace gender="Male" if male==1 
	replace gender="Female" if male==0
	drop male
	g str20 age="25-55"
	save "$folder${sep}temp3_`j'.dta",replace
}	

forvalues j=0(1)1	{
	    forvalues k=$begin_age(1)$end_age	{
		    insheet using "$folder${sep}${voladata}${sep}L_`x'earn`ff'F_maleage_sumstat.csv",clear
			keep if male==`j'
			keep if age==`k'
			drop age
			g str3 country="${iso}"
			*Adjust for min number of observations
			qui: desc mean${varx}-p99_99${varx}, varlist
			local tvlist = r(varlist)
			foreach vvg of local tvlist{
				qui: replace `vvg' = . if n${varx} < $minnumberobs
			}		
			
			// HERE
			gen p9010${varx} = p90${varx} - p10${varx}
			gen p9050${varx} = p90${varx} - p50${varx}
			gen p5010${varx} = p50${varx} - p10${varx}
			gen ksk${varx} = (p9050${varx} - p5010${varx})/p9010${varx}
			gen cku${varx} = (p97_5${varx} - p2_5${varx})/(p75${varx} - p25${varx})
			drop min${varx} max${varx}	
			//------
			
*			drop male	
			
			g str20 age="`k'"
			g str20 gender="" 
			replace gender="Male" if male==1
			replace gender="Female" if male==0
			drop male
			save "$folder${sep}temp5_`j'_`k'.dta",replace
		}
	}

u "$folder${sep}temp1.dta",clear
forvalues j=$begin_age(1)$end_age	{
	append using "$folder${sep}temp2_`j'.dta"
}	
forvalues j=0(1)1	{
	append using "$folder${sep}temp3_`j'.dta"
}	
forvalues j=0(1)1	{
	    forvalues k=$begin_age(1)$end_age	{
	append using "$folder${sep}temp5_`j'_`k'.dta"
		}
	}
order country year gender age

sort country gender age year
save "$datafran${sep}Dynamics_`x'earn_`ff'_stats_timeseries", replace
*export delimited using "$datafran${sep}Dynamics_`x'earn_`ff'_stats_timeseries.csv", replace
*sleep 1000

preserve
	drop if age=="25-55"
	destring age,gen(age_num)
	drop age
	ren age_num age
	gen groupage=1 if age>=25 & age<=34
	replace groupage=2 if age>=35 & age<=44
	replace groupage=3 if age>=45 & age<=55
	collapse (sum) n`x'earn`ff' (mean) mean`x'earn`ff'-p99_99`x'earn`ff',by(groupage gender country year)
	
	//------
	cap: drop min${varx} max${varx} 		// HERE
	//------
	gen p9010${varx} = p90${varx} - p10${varx}
	gen p9050${varx} = p90${varx} - p50${varx}
	gen p5010${varx} = p50${varx} - p10${varx}
	gen ksk${varx} = (p9050${varx} - p5010${varx})/p9010${varx}
	gen cku${varx} = (p97_5${varx} - p2_5${varx})/(p75${varx} - p25${varx})	
	
	ren groupage age
	tostring age,replace
	replace age="25-34" if age=="1"
	replace age="35-44" if age=="2"
	replace age="45-55" if age=="3"
	save "$datafran${sep}Dynamics_`x'earn_`ff'_stats_timeseries_addition",replace
restore

u "$datafran${sep}Dynamics_`x'earn_`ff'_stats_timeseries", clear
append using "$datafran${sep}Dynamics_`x'earn_`ff'_stats_timeseries_addition"
erase "$datafran${sep}Dynamics_`x'earn_`ff'_stats_timeseries_addition.dta"
sort country gender age year 
save,replace

}	// END loop over variables
}	// END loop over jumps


erase "$folder${sep}temp1.dta"
forvalues j=$begin_age(1)$end_age	{
	erase "$folder${sep}temp2_`j'.dta"
}	
forvalues j=0(1)1	{
	erase "$folder${sep}temp3_`j'.dta"
}	
forvalues j=0(1)1	{
	    forvalues k=$begin_age(1)$end_age	{
	erase "$folder${sep}temp5_`j'_`k'.dta"
		}
	}

insheet using "$folder${sep}${ineqdata}${sep}autocorr.csv", clear
sort country gender age year 
drop if age=="2555"
save "$folder${sep}${ineqdata}${sep}autocorr.dta", replace

	
u "$datafran${sep}Ineq_earnings_stats_timeseries.dta",clear
sort country gender age year 
merge country gender age year using "$datafran${sep}Ineq_logearn_stats_timeseries.dta"
tab _merge
drop _merge
sort country gender age year 
merge country gender age year using "$datafran${sep}Ineq_researn_stats_timeseries.dta"
tab _merge
drop _merge
sort country gender age year 
merge country gender age year using "$datafran${sep}Ineq_permearn_stats_timeseries.dta"
tab _merge
drop _merge
sort country gender age year 
merge country gender age year using "$datafran${sep}Dynamics_researn_1_stats_timeseries.dta"
tab _merge
drop _merge
sort country gender age year 
merge country gender age year using "$datafran${sep}Dynamics_researn_5_stats_timeseries.dta"
tab _merge
drop _merge
sort country gender age year 
merge country gender age year using "$datafran${sep}Dynamics_arcearn_1_stats_timeseries.dta"
tab _merge
drop _merge
sort country gender age year 
merge country gender age year using "$datafran${sep}Dynamics_arcearn_5_stats_timeseries.dta"
tab _merge
drop _merge
sort country gender age year 
merge country gender age year using "$datafran${sep}Dynamics_arcearn_5_stats_timeseries.dta"
tab _merge
drop _merge
sort country gender age year 
merge country gender age year using "$folder${sep}${ineqdata}${sep}autocorr.dta"
tab _merge
drop _merge
sort country gender age year 
replace nresearn5f=. if nresearn5f==0
replace narcearn5f=. if narcearn5f==0
replace nresearn1f=. if nresearn1f==0
replace narcearn1f=. if narcearn1f==0
replace npermearn=. if npermearn==0

*drop min* max*

sort country age gender year
merge country age gender year using "$datafran${sep}Slope.dta"
drop if _merge==2
drop _merge

export delimited using "$datafran${sep}Stats_${iso}.csv", replace
	
erase "$datafran${sep}Ineq_logearn_stats_timeseries.dta"
erase "$datafran${sep}Ineq_researn_stats_timeseries.dta"	
erase "$datafran${sep}Ineq_permearn_stats_timeseries.dta"
erase "$datafran${sep}Dynamics_arcearn_5_stats_timeseries.dta"
erase "$datafran${sep}Dynamics_arcearn_1_stats_timeseries.dta"
erase "$datafran${sep}Dynamics_researn_5_stats_timeseries.dta"
erase "$datafran${sep}Dynamics_researn_1_stats_timeseries.dta"
erase "$datafran${sep}Ineq_earnings_stats_timeseries.dta"
erase "$folder${sep}${ineqdata}${sep}autocorr.dta"
erase "$datafran${sep}Slope.dta"

// END of Stats code	
	
	
********************************************************************************
foreach ff in 1 5{
	foreach x in res arc {
	global varx = "`x'earn`ff'"
	insheet using "$folder${sep}${voladata}${sep}L_`x'earn`ff'F_allrank.csv",clear
	g str3 country="${iso}"
	
	*Adjust for min number of observations
	qui: desc mean${varx}-p99_99${varx}, varlist
	local tvlist = r(varlist)
	foreach vvg of local tvlist{
		qui: replace `vvg' = . if n${varx} < $minnumberobs
	}			
	
	gen p9010${varx} = p90${varx} - p10${varx}
	gen p9050${varx} = p90${varx} - p50${varx}
	gen p5010${varx} = p50${varx} - p10${varx}
	gen ksk${varx} = (p9050${varx} - p5010${varx})/p9010${varx}
	gen cku${varx} = (p97_5${varx} - p2_5${varx})/(p75${varx} - p25${varx})
	drop min${varx} max${varx}
	
	g str12 age="25-55"
	g str12 gender="All genders"
	save "$folder${sep}temp1.dta",replace
	*sleep 500
	
forvalues j=1(1)3	{
    insheet using "$folder${sep}${voladata}${sep}L_`x'earn`ff'F_agerank.csv",clear
	g str3 country="${iso}"
	
	*Adjust for min number of observations
	qui: desc mean${varx}-p99_99${varx}, varlist
	local tvlist = r(varlist)
	foreach vvg of local tvlist{
		qui: replace `vvg' = . if n${varx} < $minnumberobs
	}	
	
	gen p9010${varx} = p90${varx} - p10${varx}
	gen p9050${varx} = p90${varx} - p50${varx}
	gen p5010${varx} = p50${varx} - p10${varx}
	gen ksk${varx} = (p9050${varx} - p5010${varx})/p9010${varx}
	gen cku${varx} = (p97_5${varx} - p2_5${varx})/(p75${varx} - p25${varx})
	drop min${varx} max${varx}

	g str12 gender="All genders"
	keep if agegp==`j'
	g str20 age="" 
	replace age="25-34" if agegp==1 
	replace age="35-44" if agegp==2
	replace age="45-55" if agegp==3
	drop agegp
	save "$folder${sep}temp2_`j'.dta",replace
	*sleep 500
}

u "$folder${sep}temp1.dta",clear
drop gender age country
collapse *earn*f,by(permrank)
	g str3 country="${iso}"
	
	gen p9010${varx} = p90${varx} - p10${varx}
	gen p9050${varx} = p90${varx} - p50${varx}
	gen p5010${varx} = p50${varx} - p10${varx}
	gen ksk${varx} = (p9050${varx} - p5010${varx})/p9010${varx}
	gen cku${varx} = (p97_5${varx} - p2_5${varx})/(p75${varx} - p25${varx})

	g str12 gender="All genders"
	g str20 age="25-55" 
	g year=9999
	save "$folder${sep}temp0.dta",replace


u "$folder${sep}temp0.dta",clear
append using "$folder${sep}temp1.dta"
append using "$folder${sep}temp2_1.dta"
append using "$folder${sep}temp2_2.dta"
append using "$folder${sep}temp2_3.dta"
order country year gender age
sort country gender year age permrank 
*sleep 1000
save "$datafran${sep}Dynamics_`x'earn_`ff'_rank_heterogeneity.dta", replace
*export delimited using "$datafran${sep}Dynamics_`x'earn_`ff'_rank_heterogeneity.csv", replace

erase "$folder${sep}temp0.dta"
erase "$folder${sep}temp1.dta"
erase "$folder${sep}temp2_1.dta"
erase "$folder${sep}temp2_2.dta"
erase "$folder${sep}temp2_3.dta"

}	// END loop arc res
}	// END loop over 1 and 5

u "$datafran${sep}Dynamics_researn_1_rank_heterogeneity.dta", replace
merge country gender year age permrank using "$datafran${sep}Dynamics_researn_5_rank_heterogeneity.dta"
tab _merge
drop _merge
sort country gender year age permrank
merge country gender year age permrank using "$datafran${sep}Dynamics_arcearn_1_rank_heterogeneity.dta"
tab _merge
drop _merge
sort country gender year age permrank
merge country gender year age permrank using "$datafran${sep}Dynamics_arcearn_5_rank_heterogeneity.dta"
tab _merge
drop _merge
ren * d*
ren  dcountry country  
ren  dgender gender 
ren  dyear year
ren  dage age
ren  dpermrank permrank

sort country gender year age permrank
export delimited using "$datafran${sep}Rank_${iso}.csv", replace

erase "$datafran${sep}Dynamics_researn_1_rank_heterogeneity.dta"
erase "$datafran${sep}Dynamics_researn_5_rank_heterogeneity.dta"
erase "$datafran${sep}Dynamics_arcearn_1_rank_heterogeneity.dta"
erase "$datafran${sep}Dynamics_arcearn_5_rank_heterogeneity.dta"


****************MOBILITY
foreach jump in 1 5{
global wvari = "permearnalt"
insheet using "$folder${sep}${mobidata}${sep}L_all_${wvari}_mobstat.csv",clear

*Adjust for min number of observations
replace mean${wvari}ranktp`jump' = . if  n${wvari}ranktp`jump' < $minnumberobs

keep year ${wvari}rankt n${wvari}ranktp`jump' mean${wvari}ranktp`jump'
rename (${wvari}rankt n${wvari}ranktp`jump' mean${wvari}ranktp`jump') (rankt nranktp`jump' meanranktp`jump')

g str3 country="${iso}"
g str12 age="25-55"
g str12 gender="All genders"
save "$folder${sep}temp`jump'.dta",replace
*sleep 500

forvalues j=1(1)3	{
    insheet using "$folder${sep}${mobidata}${sep}L_agegp_${wvari}_mobstat.csv",clear
	
	*Adjust for min number of observations
	replace mean${wvari}ranktp`jump' = . if  n${wvari}ranktp`jump' < $minnumberobs
	
	keep year agegp ${wvari}rankt n${wvari}ranktp`jump' mean${wvari}ranktp`jump'
	rename (${wvari}rankt n${wvari}ranktp`jump' mean${wvari}ranktp`jump') (rankt nranktp`jump' meanranktp`jump')

	g str3 country="${iso}"

	g str12 gender="All genders"
	keep if agegp==`j'
	g str20 age="" 
	replace age="25-34" if agegp==1 
	replace age="35-44" if agegp==2
	replace age="45-55" if agegp==3
	drop agegp
	save "$folder${sep}temp2_`j'.dta",replace
	*sleep 500
}

u "$folder${sep}temp`jump'.dta",clear
append using "$folder${sep}temp2_1.dta"
append using "$folder${sep}temp2_2.dta"
append using "$folder${sep}temp2_3.dta"
order country year gender age
sort country year gender age rankt
save, replace
erase "$folder${sep}temp2_1.dta"
erase "$folder${sep}temp2_2.dta"
erase "$folder${sep}temp2_3.dta"

}	// Jumps 1 and 5

u "$folder${sep}temp1.dta",clear
merge 1:1 country year gender age rankt using "$folder${sep}temp5.dta"
drop _merge
drop nranktp*
export delimited using "$datafran${sep}Mobility_${iso}.csv", replace
erase "$folder${sep}temp1.dta"
erase "$folder${sep}temp5.dta"

clear
insheet using "$datafran${sep}Mobility_${iso}.csv"
rename rankt pct_year_t_log_earnings
rename meanranktp1 avg_pct_year_t_1_log_inc	
rename meanranktp5 avg_pct_year_t_5_log_inc
export delimited using "$datafran${sep}Mobility_${iso}.csv", replace

clear
insheet using "$datafran${sep}Rank_${iso}.csv"
rename permrank rank_permanent_inc
rename dnresearn1f 		nobs_res_1yr_log_chg_by_skill
rename dmeanresearn1f 	mean_res_1yr_log_chg_by_skill
rename dsdresearn1f 	std_res_1yr_log_chg_by_skill
rename dskewresearn1f 	skew_res_1yr_log_chg_by_skill
rename dkurtresearn1f 	kurt_res_1yr_log_chg_by_skill
rename dp9010researn1 	p9010_res_1yr_log_chg_by_skill
rename dp9050researn1 	p9050_res_1yr_log_chg_by_skill
rename dp5010researn1 	p5010_res_1yr_log_chg_by_skill
rename dkskresearn1 	kelley_res_1yr_log_chg_by_skill
rename dckuresearn1 	crows_res_1yr_log_chg_by_skill
rename dp1researn1f 	p1_res_1yr_log_chg_by_skill
rename dp2_5researn1f 	p2_5_res_1yr_log_chg_by_skill
rename dp5researn1f 	p5_res_1yr_log_chg_by_skill
rename dp10researn1f 	p10_res_1yr_log_chg_by_skill
rename dp12_5researn1f 	p12_5_res_1yr_log_chg_by_skill
rename dp25researn1f 	p25_res_1yr_log_chg_by_skill
rename dp37_5researn1f 	p37_5_res_1yr_log_chg_by_skill
rename dp50researn1f 	p50_res_1yr_log_chg_by_skill
rename dp62_5researn1f 	p62_5_res_1yr_log_chg_by_skill
rename dp75researn1f 	p75_res_1yr_log_chg_by_skill
rename dp87_5researn1f 	p87_5_res_1yr_log_chg_by_skill
rename dp90researn1f 	p90_res_1yr_log_chg_by_skill
rename dp95researn1f 	p95_res_1yr_log_chg_by_skill
rename dp97_5researn1f 	p97_5_res_1yr_log_chg_by_skill
rename dp99researn1f 	p99_res_1yr_log_chg_by_skill
rename dp99_9researn1f 	p99_9_res_1yr_log_chg_by_skill
rename dp99_99researn1f p99_99_res_1yr_log_chg_by_skill
rename dnresearn5f 		nobs_res_5yr_log_chg_by_skill
rename dmeanresearn5f 	mean_res_5yr_log_chg_by_skill
rename dsdresearn5f 	std_res_5yr_log_chg_by_skill
rename dskewresearn5f 	skew_res_5yr_log_chg_by_skill
rename dkurtresearn5f 	kurt_res_5yr_log_chg_by_skill
rename dp9010researn5 	p9010_res_5yr_log_chg_by_skill
rename dp9050researn5 	p9050_res_5yr_log_chg_by_skill
rename dp5010researn5 	p5010_res_5yr_log_chg_by_skill
rename dkskresearn5 	kelley_res_5yr_log_chg_by_skill
rename dckuresearn5 	crows_res_5yr_log_chg_by_skill
rename dp1researn5f 	p1_res_5yr_log_chg_by_skill
rename dp2_5researn5f 	p2_5_res_5yr_log_chg_by_skill
rename dp5researn5f 	p5_res_5yr_log_chg_by_skill
rename dp10researn5f 	p10_res_5yr_log_chg_by_skill
rename dp12_5researn5f 	p12_5_res_5yr_log_chg_by_skill
rename dp25researn5f 	p25_res_5yr_log_chg_by_skill
rename dp37_5researn5f p37_5_res_5yr_log_chg_by_skill
rename dp50researn5f 	p50_res_5yr_log_chg_by_skill
rename dp62_5researn5f 	p62_5_res_5yr_log_chg_by_skill
rename dp75researn5f 	p75_res_5yr_log_chg_by_skill
rename dp87_5researn5f 	p87_5_res_5yr_log_chg_by_skill
rename dp90researn5f 	p90_res_5yr_log_chg_by_skill
rename dp95researn5f 	p95_res_5yr_log_chg_by_skill
rename dp97_5researn5f 	p97_5_res_5yr_log_chg_by_skill
rename dp99researn5f 	p99_res_5yr_log_chg_by_skill
rename dp99_9researn5f 	p99_9_res_5yr_log_chg_by_skill
rename dp99_99researn5f p99_99_res_5yr_log_chg_by_skill
rename dnarcearn1f 		nobs_arcpct_1yr_chg_by_skill
rename dmeanarcearn1f 	mean_arcpct_1yr_chg_by_skill
rename dsdarcearn1f 	std_arcpct_1yr_chg_by_skill
rename dskewarcearn1f 	skew_arcpct_1yr_chg_by_skill
rename dkurtarcearn1f 	kurt_arcpct_1yr_chg_by_skill
rename dp9010arcearn1 	p9010_arcpct_1yr_chg_by_skill
rename dp9050arcearn1 	p9050_arcpct_1yr_chg_by_skill
rename dp5010arcearn1 	p5010_arcpct_1yr_chg_by_skill
rename dkskarcearn1 	kelley_arcpct_1yr_chg_by_skill
rename dckuarcearn1 	crows_arcpct_1yr_chg_by_skill
rename dp1arcearn1f 	p1_arcpct_1yr_chg_by_skill
rename dp2_5arcearn1f 	p2_5_arcpct_1yr_chg_by_skill
rename dp5arcearn1f 	p5_arcpct_1yr_chg_by_skill
rename dp10arcearn1f 	p10_arcpct_1yr_chg_by_skill
rename dp12_5arcearn1f 	p12_5_arcpct_1yr_chg_by_skill
rename dp25arcearn1f 	p25_arcpct_1yr_chg_by_skill
rename dp37_5arcearn1f 	p37_5_arcpct_1yr_chg_by_skill
rename dp50arcearn1f 	p50_arcpct_1yr_chg_by_skill
rename dp62_5arcearn1f 	p62_5_arcpct_1yr_chg_by_skill
rename dp75arcearn1f 	p75_arcpct_1yr_chg_by_skill
rename dp87_5arcearn1f 	p87_5_arcpct_1yr_chg_by_skill
rename dp90arcearn1f 	p90_arcpct_1yr_chg_by_skill
rename dp95arcearn1f 	p95_arcpct_1yr_chg_by_skill
rename dp97_5arcearn1f 	p97_5_arcpct_1yr_chg_by_skill
rename dp99arcearn1f 	p99_arcpct_1yr_chg_by_skill
rename dp99_9arcearn1f 	p99_9_arcpct_1yr_chg_by_skill
rename dp99_99arcearn1f p99_99_arcpct_1yr_chg_by_skill
rename dnarcearn5f 		nobs_arcpct_5yr_chg_by_skill
rename dmeanarcearn5f 	mean_arcpct_5yr_chg_by_skill
rename dsdarcearn5f 	std_arcpct_5yr_chg_by_skill
rename dskewarcearn5f 	skew_arcpct_5yr_chg_by_skill
rename dkurtarcearn5f 	kurt_arcpct_5yr_chg_by_skill
rename dp9010arcearn5 	p9010_arcpct_5yr_chg_by_skill
rename dp9050arcearn5 	p9050_arcpct_5yr_chg_by_skill
rename dp5010arcearn5 	p5010_arcpct_5yr_chg_by_skill
rename dkskarcearn5 	kelley_arcpct_5yr_chg_by_skill
rename dckuarcearn5 	crows_arcpct_5yr_chg_by_skill
rename dp1arcearn5f 	p1_arcpct_5yr_chg_by_skill
rename dp2_5arcearn5f 	p2_5_arcpct_5yr_chg_by_skill
rename dp5arcearn5f 	p5_arcpct_5yr_chg_by_skill
rename dp10arcearn5f 	p10_arcpct_5yr_chg_by_skill
rename dp12_5arcearn5f 	p12_5_arcpct_5yr_chg_by_skill
rename dp25arcearn5f 	p25_arcpct_5yr_chg_by_skill
rename dp37_5arcearn5f 	p37_5_arcpct_5yr_chg_by_skill
rename dp50arcearn5f 	p50_arcpct_5yr_chg_by_skill
rename dp62_5arcearn5f 	p62_5_arcpct_5yr_chg_by_skill
rename dp75arcearn5f 	p75_arcpct_5yr_chg_by_skill
rename dp87_5arcearn5f 	p87_5_arcpct_5yr_chg_by_skill
rename dp90arcearn5f 	p90_arcpct_5yr_chg_by_skill
rename dp95arcearn5f 	p95_arcpct_5yr_chg_by_skill
rename dp97_5arcearn5f 	p97_5_arcpct_5yr_chg_by_skill
rename dp99arcearn5f 	p99_arcpct_5yr_chg_by_skill
rename dp99_9arcearn5f 	p99_9_arcpct_5yr_chg_by_skill
rename dp99_99arcearn5f p99_99_arcpct_5yr_chg_by_skill

export delimited using "$datafran${sep}Rank_${iso}.csv", replace


clear
insheet using "$datafran${sep}Stats_${iso}.csv"
rename q1share share_first_quintile_inc
rename q2share share_second_quintile_inc
rename q3share share_third_quintile_inc
rename q4share share_fourth_quintile_inc
rename q5share share_fifth_quintile_inc
rename bot50share share_bottom50_inc
rename top10share share_top10_pct_inc
rename top5share share_top5_pct_inc
rename top1share share_top1_pct_inc
rename top05share share_top0_5_pct_inc
rename top01share share_top0_1_pct_inc
rename top001share share_top0_01_pct_inc
rename gini gini_coefficient
rename npermearn nobs_log_perm_inc
rename meanpermearn mean_log_perm_inc
rename sdpermearn std_log_perm_inc
rename p9010permearn p9010_log_perm_inc
rename p9050permearn p9050_log_perm_inc
rename p5010permearn p5010_log_perm_inc
rename kskpermearn kelley_log_perm_inc
rename ckupermearn crows_log_perm_inc
rename p1permearn p1_log_perm_inc
rename p2_5permearn p2_5_log_perm_inc
rename p5permearn p5_log_perm_inc
rename p10permearn p10_log_perm_inc
rename p12_5permearn p12_5_log_perm_inc
rename p25permearn p25_log_perm_inc
rename p37_5permearn p37_5_log_perm_inc
rename p50permearn p50_log_perm_inc
rename p62_5permearn p62_5_log_perm_inc
rename p75permearn p75_log_perm_inc
rename p87_5permearn p87_5_log_perm_inc
rename p90permearn p90_log_perm_inc
rename p95permearn p95_log_perm_inc
rename p97_5permearn p97_5_log_perm_inc
rename p99permearn p99_log_perm_inc
rename p99_9permearn p99_9_log_perm_inc
rename p99_99permearn p99_99_log_perm_inc
rename nresearn nobs_res_log_inc
rename meanresearn mean_res_log_inc
rename sdresearn std_res_log_inc
rename p9010researn p9010_res_log_inc
rename p9050researn p9050_res_log_inc
rename p5010researn p5010_res_log_inc
rename kskresearn kelley_res_log_inc
rename ckuresearn crows_res_log_inc
rename p1researn p1_res_log_inc
rename p2_5researn p2_5_res_log_inc
rename p5researn p5_res_log_inc
rename p10researn p10_res_log_inc
rename p12_5researn p12_5_res_log_inc
rename p25researn p25_res_log_inc
rename p37_5researn p37_5_res_log_inc
rename p50researn p50_res_log_inc
rename p62_5researn p62_5_res_log_inc
rename p75researn p75_res_log_inc
rename p87_5researn p87_5_res_log_inc
rename p90researn p90_res_log_inc
rename p95researn p95_res_log_inc
rename p97_5researn p97_5_res_log_inc
rename p99researn p99_res_log_inc
rename p99_9researn p99_9_res_log_inc
rename p99_99researn p99_99_res_log_inc
rename ac_researn_1 autocorr_lag1_res_log_inc
rename ac_researn_2 autocorr_lag2_res_log_inc
rename ac_researn_3 autocorr_lag3_res_log_inc
rename ac_researn_4 autocorr_lag4_res_log_inc
rename ac_researn_5 autocorr_lag5_res_log_inc
rename nlogearn nobs_log_inc
rename meanlogearn mean_log_inc
rename sdlogearn std_log_inc
rename p9010logearn p9010_log_inc
rename p9050logearn p9050_log_inc
rename p5010logearn p5010_log_inc
rename ksklogearn kelley_log_inc
rename ckulogearn crows_log_inc
rename p1logearn p1_log_inc
rename p2_5logearn p2_5_log_inc
rename p5logearn p5_log_inc
rename p10logearn p10_log_inc
rename p12_5logearn p12_5_log_inc
rename p25logearn p25_log_inc
rename p37_5logearn p37_5_log_inc
rename p50logearn p50_log_inc
rename p62_5logearn p62_5_log_inc
rename p75logearn p75_log_inc
rename p87_5logearn p87_5_log_inc
rename p90logearn p90_log_inc
rename p95logearn p95_log_inc
rename p97_5logearn p97_5_log_inc
rename p99logearn p99_log_inc
rename p99_9logearn p99_9_log_inc
rename p99_99logearn p99_99_log_inc
rename nresearn1f nobs_res_1yr_log_chg
rename meanresearn1f mean_res_1yr_log_chg
rename sdresearn1f std_res_1yr_log_chg
rename skewresearn1f skew_res_1yr_log_chg
rename kurtresearn1f kurt_res_1yr_log_chg
rename p9010researn1 p9010_res_1yr_log_chg
rename p9050researn1 p9050_res_1yr_log_chg
rename p5010researn1 p5010_res_1yr_log_chg
rename kskresearn1 kelley_res_1yr_log_chg
rename ckuresearn1 crows_res_1yr_log_chg
rename p1researn1f p1_res_1yr_log_chg
rename p2_5researn1f p2_5_res_1yr_log_chg
rename p5researn1f p5_res_1yr_log_chg
rename p10researn1f p10_res_1yr_log_chg
rename p12_5researn1f p12_5_res_1yr_log_chg
rename p25researn1f p25_res_1yr_log_chg
rename p37_5researn1f p37_5_res_1yr_log_chg
rename p50researn1f p50_res_1yr_log_chg
rename p62_5researn1f p62_5_res_1yr_log_chg
rename p75researn1f p75_res_1yr_log_chg
rename p87_5researn1f p87_5_res_1yr_log_chg
rename p90researn1f p90_res_1yr_log_chg
rename p95researn1f p95_res_1yr_log_chg
rename p97_5researn1f p97_5_res_1yr_log_chg
rename p99researn1f p99_res_1yr_log_chg
rename p99_9researn1f p99_9_res_1yr_log_chg
rename p99_99researn1f p99_99_res_1yr_log_chg
rename ac_dresearn_1 autocorr_lag1_res_1yr_log_chg
rename ac_dresearn_2 autocorr_lag2_res_1yr_log_chg
rename ac_dresearn_3 autocorr_lag3_res_1yr_log_chg
rename ac_dresearn_4 autocorr_lag4_res_1yr_log_chg
rename ac_dresearn_5 autocorr_lag5_res_1yr_log_chg
rename nresearn5f nobs_res_5yr_log_chg
rename meanresearn5f mean_res_5yr_log_chg
rename sdresearn5f std_res_5yr_log_chg
rename skewresearn5f skew_res_5yr_log_chg
rename kurtresearn5f kurt_res_5yr_log_chg
rename p9010researn5 p9010_res_5yr_log_chg
rename p9050researn5 p9050_res_5yr_log_chg
rename p5010researn5 p5010_res_5yr_log_chg
rename kskresearn5 kelley_res_5yr_log_chg
rename ckuresearn5 crows_res_5yr_log_chg
rename p1researn5f p1_res_5yr_log_chg
rename p2_5researn5f p2_5_res_5yr_log_chg
rename p5researn5f p5_res_5yr_log_chg
rename p10researn5f p10_res_5yr_log_chg
rename p12_5researn5f p12_5_res_5yr_log_chg
rename p25researn5f p25_res_5yr_log_chg
rename p37_5researn5f p37_5_res_5yr_log_chg
rename p50researn5f p50_res_5yr_log_chg
rename p62_5researn5f p62_5_res_5yr_log_chg
rename p75researn5f p75_res_5yr_log_chg
rename p87_5researn5f p87_5_res_5yr_log_chg
rename p90researn5f p90_res_5yr_log_chg
rename p95researn5f p95_res_5yr_log_chg
rename p97_5researn5f p97_5_res_5yr_log_chg
rename p99researn5f p99_res_5yr_log_chg
rename p99_9researn5f p99_9_res_5yr_log_chg
rename p99_99researn5f p99_99_res_5yr_log_chg
rename narcearn1f nobs_arcpct_1yr_chg
rename meanarcearn1f mean_arcpct_1yr_chg
rename sdarcearn1f std_arcpct_1yr_chg
rename skewarcearn1f skew_arcpct_1yr_chg
rename kurtarcearn1f kurt_arcpct_1yr_chg
rename p9010arcearn1 p9010_arcpct_1yr_chg
rename p9050arcearn1 p9050_arcpct_1yr_chg
rename p5010arcearn1 p5010_arcpct_1yr_chg
rename kskarcearn1 	 kelley_arcpct_1yr_chg
rename ckuarcearn1 	 crows_arcpct_1yr_chg
rename p1arcearn1f 	 p1_arcpct_1yr_chg
rename p2_5arcearn1f 	p2_5_arcpct_1yr_chg
rename p5arcearn1f 		p5_arcpct_1yr_chg
rename p10arcearn1f 	p10_arcpct_1yr_chg
rename p12_5arcearn1f 	p12_5_arcpct_1yr_chg
rename p25arcearn1f 	p25_arcpct_1yr_chg
rename p37_5arcearn1f 	p37_5_arcpct_1yr_chg
rename p50arcearn1f 	p50_arcpct_1yr_chg
rename p62_5arcearn1f 	p62_5_arcpct_1yr_chg
rename p75arcearn1f 	p75_arcpct_1yr_chg
rename p87_5arcearn1f 	p87_5_arcpct_1yr_chg
rename p90arcearn1f 	p90_arcpct_1yr_chg
rename p95arcearn1f 	p95_arcpct_1yr_chg
rename p97_5arcearn1f 	p97_5_arcpct_1yr_chg
rename p99arcearn1f 	p99_arcpct_1yr_chg
rename p99_9arcearn1f 	p99_9_arcpct_1yr_chg
rename p99_99arcearn1f 	p99_99_arcpct_1yr_chg
rename narcearn5f 		nobs_arcpct_5yr_chg
rename meanarcearn5f 	mean_arcpct_5yr_chg
rename sdarcearn5f 		std_arcpct_5yr_chg
rename skewarcearn5f 	skew_arcpct_5yr_chg
rename kurtarcearn5f 	kurt_arcpct_5yr_chg
rename p9010arcearn5 	p9010_arcpct_5yr_chg
rename p9050arcearn5 	p9050_arcpct_5yr_chg
rename p5010arcearn5 	p5010_arcpct_5yr_chg
rename kskarcearn5 		kelley_arcpct_5yr_chg
rename ckuarcearn5 		crows_arcpct_5yr_chg
rename p1arcearn5f 		p1_arcpct_5yr_chg
rename p2_5arcearn5f 	p2_5_arcpct_5yr_chg
rename p5arcearn5f 		p5_arcpct_5yr_chg
rename p10arcearn5f 	p10_arcpct_5yr_chg
rename p12_5arcearn5f 	p12_5_arcpct_5yr_chg
rename p25arcearn5f 	p25_arcpct_5yr_chg
rename p37_5arcearn5f 	p37_5_arcpct_5yr_chg
rename p50arcearn5f 	p50_arcpct_5yr_chg
rename p62_5arcearn5f 	p62_5_arcpct_5yr_chg
rename p75arcearn5f 	p75_arcpct_5yr_chg
rename p87_5arcearn5f 	p87_5_arcpct_5yr_chg
rename p90arcearn5f 	p90_arcpct_5yr_chg
rename p95arcearn5f 	p95_arcpct_5yr_chg
rename p97_5arcearn5f 	p97_5_arcpct_5yr_chg
rename p99arcearn5f 	p99_arcpct_5yr_chg
rename p99_9arcearn5f 	p99_9_arcpct_5yr_chg
rename p99_99arcearn5f 	p99_99_arcpct_5yr_chg
rename slopep_tp5 		Pareto_tail_index_5pct
rename slopep_tp1  		Pareto_tail_index_1pct

export delimited using "$datafran${sep}Stats_${iso}.csv", replace


clear
insheet using "$datafran${sep}Density_${iso}.csv"
rename val_logearn midp_bin_log_inc_distr
rename den_logearn dens_bin_log_inc_distr
rename val_researn1f midp_bin_res_1yr_log_chg_distr
rename den_researn1f dens_bin_res_1yr_log_chg_distr
rename val_researn5f midp_bin_res_5yr_log_chg_distr
rename den_researn5f dens_bin_res_5yr_log_chg_distr
export delimited using "$datafran${sep}Density_${iso}.csv", replace


*#########################
*# END THE CODE
*#########################
