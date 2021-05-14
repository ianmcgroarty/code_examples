clear
set obs 100

gen observation = _n 
	sum observation
	

gen random = runiform()
	sum random

gen catA = ""
	replace catA= "A" if random >0.5
	replace catA= "B" if random > 0.25 & random <0.5
	replace catA= "C" if random <0.25 
		tab catA
		
tab catA , gen(catdummy)


generate in_id = autocode(observation,10,0,100)
bysort in_id: gen time_id = _n

xtset in_id time_id
tab time_id catdummy1 


egen catdummy1_count = sum(catdummy1) , by (time_id) 

sort time_id
line catdummy1_count time_id


stop graveyard

xtline catdummy1
twoway xtline time_id catdummy1 
line  catdummy1_count time_id
		
