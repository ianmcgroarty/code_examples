clear
local strings abc def ghi

foreach m of local strings {
	di "`m'"
	gen string`m' = "`m' "
} 
local nwords : word count `strings' 

clear
set obs  100
forvalues i = 2006/2017 {
	local j = `i' - 5
	cap gen TotalDeposits`j' = 1
	cap gen TotalDeposits`i' = 1
	cap gen TotalDeposits5year = 1
	cap gen ClosedYear = 1
	egen fiveyear`i' = rowmean(TotalDeposits`j'-TotalDeposits`i') 
	replace TotalDeposits5year = fiveyear`i' if ClosedYear == `i' 
}


local testmsa 35620  12060 12580 14460 16980 19100 19740 19820 26420 31080 33100 33460 37980 38060 40140 41740 41860 42660 45300 47900
foreach m of local testmsa {
	di `m'
}

clear
set obs 10 
	local N = _N

forvalues i = 1/`N' {
	di "count is " `i' 
	}

	
	
clear
set obs 10

gen crtr_attr1 = _n
gen crtr_attr2 = crtr_attr1+1
gen crtr_attr4 = 1

global crtr_list crtr_attr1
forvalues i = 1/5 {
	cap confirm variable crtr_attr`i'
		if !_rc {
			global crtr_list $crtr_list crtr_attr`i'
			}
		else { 
		}

	}
	di "$crtr_list"
	

 foreach i of numlist 54/67 75/88 125/136 143/154 161 162 164 165 172 173 175 176 183 184 186 187 {
 gen crtr_attr`i' =1 
 }
 foreach i of numlist 54/67 75/88 125/136 143/154 161 162 164 165 172 173 175 176 183 184 186 187 {
 drop crtr_attr`i' 
 }
 
 
clear
set obs 100
gen num = _n
gen one = 1
gen even = 0
	replace even = 1 if mod(num,2)==0

count if even == 1
scalar fidy = r(N)
di fidy
scalar tot = _N
di fidy/tot

count if even == 1
local fidyb r(N)
di `fidyb'

local row = 1 
forvalues i = 1/7 {
local row = `row' + 1
di `row' 
}

foreach i in 3 36 60{
di `i'
}




 
