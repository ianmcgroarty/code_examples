/* This code is the 4th in a many part series for the Branch Closure Project 
	It is preceeded by:
		- blockpull_branchgeocode_ian1.R
		- 01.block_appeding_ian20.do 
		- 02.branch_appending_ian21.do 
	It is followed by: 
		- 04.br_ccppull_ian4.R (SparkR) 
*/ 
/* The goal of this code file is to combine the branch closure data and the block geographic data.
	This will result in each block being related to one and only one closure. */

/* Starting Datasets:
	1. E:\Slava\branches\Data\Geography\top20msa_blocks_plus.dta
		- obs = 1,449,229 | vars = 8 
		- This data contains block level geographic data for the top 20MSAs cleaned and ready to be used. 
		- Compiled in 01.block_appending_ianX.do
	2. E:\Slava\branches\Data\Branch\top20msa_allbranches_lostall.dta	
		- Obs = 1296 |var = 5 | size = 31.64K
		- This data contains only key variables (for the merge) and only lost all branches
			* NOTE: Keeping only the variables which are necessary for the merge makes the merge process much simpler and faster.
		- Compiled in 02.branch_appending_ianX.do
*/
/* Ending Datasets: 
	1. E:\Slava\branches\Data\MSA_all_oneclose_lostall.dta 
		- Obs = 1,249,781 | vars = 15 | size = 73.90M
		- This data contains all relavant blocks (associated with a lostall branch closure) (one observations per block)
		along with the BID for the branch (allowing us to merge on bank data) 
	2. E:\Slava\branches\Data\geo_lostall_10mi_ian2
		- obs = 1,249,781 | vars = 6 | size = 38.14M
		- This data is the all important block list which we will use in SparkR to pull the relevant cid data. 
		- This data contains all relavant blocks (associated with a lostall branch closure) (one observations per block)
		- It was created using all blocks within 10 miles of a lostall branch.
	* There are a number of intermediate datasets created that erase at the end of the process. If the code fails before completion they may clog up the data folder. 
*/ 

**************************************************************************************************************************************
***********************		EMPEZAMOS 	**********************************************************************************************
**************************************************************************************************************************************

/* Preamble */ 
cls
clear
set more off
timer clear 3
timer on 3
set maxvar 32000 /* Important depending on the version of Stata */ 

******* DATA ******
/*** Set Directory  ***/ 
local datapath "E:\Slava\branches\Data"

/*** Starting Data ***/ 
local blockdata "Geography\top20msa_blocks_plus.dta"
local branchdata "Branch\top20msa_allbranches_lostall.dta" 
*local branchdata "Branch\top20msa_allbranches20.dta" 

/*** Ending Data ***/ 
local oneclose "MSA_all_oneclose_lostall.dta" 
local geocsv "geo_lostall_10mi_ian2"

/*** OPTIONS ***/ 
* First or Last Closure 
local closesort gsort +ClosedDate 
	/*Sort by +CloseDate if you want the most recent closure 
			  -CloseDate if you want the earliest closure */

* How many miles you want your control group to cover
scalar miles = 10

*set the code paths
adopath + "E:\Slava"
which vincenty
which coefplot
which outreg2
adopath 


**** Make sure I've got the right idea for the loop
local testmsa 35620  12060 12580 14460 16980 19100 19740 19820 26420 31080 33100 33460 37980 38060 40140 41740 41860 42660 45300 47900
foreach m of local testmsa {
	di `m'
}

/****** LOOP DETAILS
		1. Do for each MSA (
		  2. Expand the banch data so that nobs = number of blocks in the msa and each branch has its own .dta
		  3. For each branch dataset (
		   4. Merge the expanded branch data with the block data to match each block with each branch )
		  5. For each banch block pair (
		   6. calculate the distance between each branch and the block center
		   7. Eliminate blocks with no branches
		   8. Get only the earlist closure of the set ))
********/

**************************************************************************************************************************************
/* BEGIN THE LOOP */ 
**************************************************************************************************************************************
cd `datapath' 
local msacde 12060 12580 14460 16980 19100 19740 19820 26420 31080 33100 33460 35620 37980 38060 40140 41740 41860 42660 45300 47900
*local msacde 12580
foreach m of local msacde {
* Get the number of blocks
clear
use `blockdata'
	keep if MSACode == `m'
		local nblocks = _N
		display "MSA " `m' " has " `nblocks' " blocks."

* Get the number of closures 
clear
use `branchdata'  

* Keep one MSA Code at a time!
qui	keep if MSACode==`m'

/* Take the 1st closure */ /*Sort by +CloseDate if you want the most recent closure */ 
`closesort'	

	local N = _N
	display "MSA" `m' " has " `N' " closures."
save MSACode_`m' , replace

* expand for the merge 
forvalues i = 1/`N' {
use MSACode_`m'.dta , clear
qui		keep in `i'
qui		expand `nblocks' /* blocks in chicago */
		
		qui rename Latitude lat`i'
		qui rename Longitude longit`i'
		qui rename ClosedDate ClosedDate`i'
		qui rename BID BID`i'	
			
		qui	g index=_n
			sort index
qui	save tempcoor`i'.dta, replace
}

**** Merge with the blocks data ****
clear
use `blockdata' 
	keep if MSACode == `m'
		qui g index=_n
		
forval i=1/`N' {
	sort index
		qui merge 1:1 index using tempcoor`i'.dta
		qui	drop if _merge!=3
			drop _merge
}

** Erase extra tempfiles ** /* I HAVE TO DO THIS WITHIN THE MSA LOOP */
forval i = 1/`N' {
erase tempcoor`i'.dta
}
	
forval i=1/`N' {
qui vincenty lat longit lat`i' longit`i', hav(dtrust`i') 
drop lat`i' longit`i'
}

* Get rid of all blocks without a closure within 10 miles
qui egen firstcheck=rowmin(dtrust1-dtrust`N')
	keep if firstcheck < miles 
save MSA_`m'_2mi_close.dta , replace	
	
*************************
** LIMIT TO ONE BRANCH **
************************
clear
use MSA_`m'_2mi_close.dta

* Create the new variables
	qui gen bank_num = .
	qui gen bank_bid = ""
	qui gen bank_close_period = .
	qui gen distance = .

* Create a flag for the relavant branches 
forval j = 1/`N' {
	qui	g Ddflag`j'=0
	qui	replace Ddflag`j' = 1 if dtrust`j' <10

	* Get rid of extra branches 
	qui		replace bank_num		 	=`j' 			if Ddflag`j'==1
	qui		replace bank_bid		 	=BID`j' 		if Ddflag`j'==1
	qui		replace bank_close_period	=ClosedDate`j' 	if Ddflag`j'==1
	qui		replace distance 			= dtrust`j' 	if Ddflag`j'==1
}

* One branch closure 
/*	egen r5=rowtotal(Dd1-Dd`N') 
		gen onebranch = 0
			replace onebranch = 1 if rowtotal == 1 */
qui gen number10m = 0
forval j = 1/`N' {
        qui replace number10m = number10m + (dtrust`j' < 10 )
        }

*drop all the individual bank closure variables (since only interested in the attributes of the first closure*
	drop ClosedDate* dtrust* Dd* BID*
save MSA_`m'_oneclose.dta , replace	
}

*************************
**** APPEND THE DATA ****
*************************
local appmsa 14460 19100 16980 12580 19740 19820 26420 31080 33100 33460 35620 37980 38060 40140 41740 41860 42660 45300 47900
clear

* append the block/branch data
use MSA_12060_oneclose.dta
foreach m of local appmsa {
di `m'
	append using MSA_`m'_oneclose.dta
}

	
****************************************
*** PREPARATION FOR THE CCP MERGE ******
****************************************
* Drop Duplicates *
bysort state county_code CensusTract census_block: gen dupgeography = cond(_N==1,0,_n)
	drop if dupgeography >1 /* NO Duplicates dropped ! */ 
	drop dupgeography
	
rename CensusTract census_tract
save `oneclose' , replace
	*** NOTE: 28 VARIABLES 828,762 OBSERVATIONS 256M SIZE; (EARLY VERSION)
	*** NOTE: 18 VARIABLES 1,126,143 OBSERVATIONS;  (20PCT SAMPLE)
	*** NOTE: 15 VARABLES 1,375,669 Observations;  (All Closed - 10 MI)
**************************
**** ERASE DATA **********
**************************
foreach m of local msacde {
cap erase MSA_`m'_2mi_close.dta
cap erase MSA_`m'_oneclose.dta 
cap erase MSACode_`m'.dta
cap erase lostallMSA`m'_tract.dta
}

**************************
**** PREP FOR R **********
**************************
keep state county_code census_tract census_block bank_close_period
	destring county_code , replace
	destring census_tract , replace
	destring census_block , replace
sort state county_code census_tract census_block

**** YEAR BARS ****
	/* We were having a problem with the data size so I wanted to only take observations of cids that were inside 5 years of a closure. 
		We end up using 4 years, I use 5 just to be safe. Thus I need a data 5 years before and after the closure to use in the ccp pull. */ 
format bank_close_period %td
	gen closeyear = year(bank_close_period)
	  gen closeyearn5 = closeyear-5
	  gen closeyearp5 = closeyear+5
		tostring closeyear , replace
		tostring closeyearn5 , replace
		tostring closeyearp5 , replace 
	gen closemon = month(bank_close_period)
		tostring closemon , replace
			replace closemon = "0" + closemon if length(closemon) == 1
	gen closeday= day(bank_close_period)
		tostring closeday , replace
	replace closeday = "0" + closeday if length(closeday) == 1 

	egen closedate = concat(closeyear closemon closeday) , punct("-")
	egen closedaten5 = concat(closeyearn5 closemon closeday) , punct("-")
	egen closedatep5 = concat(closeyearp5 closemon closeday) , punct("-")

keep state county_code census_tract census_block closedaten5 closedatep5
export delimited using  `geocsv' ,  replace delimiter(,)

timer off 3
timer list
**   3:  22585.04
** 	 3:  13751.55
**   3:   7954.27 /* STATA 14mp all closed 10mi */ 
** 	 3:    976.74 /* STATA 14mp lostall 10mi */ 

