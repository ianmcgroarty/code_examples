clear
set obs 21
gen one = 1
gen observation = _n
gen eventb = observation - 11  
	/* lowest number at -10 observation 1 
		eventb = 0 at observation 11
		highest number at 10 observation 21
	*/ 
	
qui tab eventb, gen (eventi)
	/* there are 21  dummies, eventi1 == 1 if eventb == -10*/
	tab eventb if eventi1 == 1

/* Goal I want to rename them s.t. eventi_n10 = 1 if eventb==-10 */
/* I want this in a loop 
	rename eventi1 eventi_n10 
	rename eventi2 eventi_n9 
	rename eventi3 eventi_n8 
	...
	rename eventi11 eventi_0
	rename eventi12 eventi_1
	rename eventi13 eventi_2
*/ 


forvalues j=1/12 {
local k = 11 - `j' 
local p = `j' - 11
di "k="`k' " and p=" `p' 

}

forvalues j=1/21 {
	local k = 11 - `j'
	local p = `j' - 11
	if `j' <= 11 {
		gen ntime`k' = eventi`j'
		}
	if `j' >= 11 {
		gen ptime`p' = eventi`j'
		}
	drop eventi`j' 
}


*****
rename eventb event_time
tab event_time /* 48 negative values */ 

/* 1. Make all event times > 0 */ 
	gen alltime = event_time + 49 
	
/* 2. Create all time dummy variables */ 
	qui tab alltime, gen(atime)
		tab alltime if atime10 == 1 

/* Find your zero */ 
		tab event_time if atime49 == 1 	
	
/* Rename the dummies */ 
	forvalues j = 1/70 { 						/* 70 is the max */ 
		local n = 49 - `j' 						/* if even_time = 0 then atime49 = 1 */ 
		local p = `j' - 49
			if `j' <=49 {						/* negative time is j < 49 */ 
				gen ntime`n' = atime`j' 
			}
			if `j' > 49  {
				gen ptime`p' = atime`j' 		/* positive numbers */ 
			}
		drop atime`j'
			}
	
