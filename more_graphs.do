*view browse http://www.pnc.com/
clear
set obs 100
gen n = _n
egen month = seq(), f(1) t(12)
sort month n
bysort month: gen dup = cond(_N==0,1,_n)
gen year = 2000 + dup if month==1
sort n
replace year = year[_n-1] if year== .
gen day = 1 
gen date = mdy(month,day,year)
format date %td



gen var1 = 2*n -100
gen var2 = -2*n +75
gen var3 = sin(n)
gen var4 = var3-40

twoway( ///
	(line var1 date ,yaxis(1)) ///
	(line var2 date , yaxis(2)))


twoway( ///
	(line var1 date , yaxis(1) yscale(range(-150(50)150) axis(1))) ///
	(line var2 date , yaxis(2) yscale(range(-150(50)150) axis(2))))

	
twoway( ///
	(line var1 date , yaxis(1) yscale(range(-150 150) axis(1)) ylabel(-150(50)150)) ///
	(line var4 date , yaxis(2) yscale(range(-150 150) axis(2)) ylabel(-150(50)150, axis(2))  )  ///
	)
