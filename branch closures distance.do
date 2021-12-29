*****************************************************************************
** Title: Branch closures and credit outcomes: distance
** Author: AET
** Created: 12/14/17
** Updated: 6/20/17
******************************************************************************
cd "Z:\Tranfaglia\Data\SNL\Credit Outcomes"
set more off

*merge all shapefiles together  
import excel "Z:\Tranfaglia\Data\SNL\Credit Outcomes\2010_DE.xls", sheet("2010_DE") firstrow clear
	tempfile DE
	save `DE'
import excel "Z:\Tranfaglia\Data\SNL\Credit Outcomes\2010_MD.xls", sheet("2010_MD") firstrow clear
	tempfile MD
	save `MD'
import excel "Z:\Tranfaglia\Data\SNL\Credit Outcomes\2010_NJ.xls", sheet("2010_NJ") firstrow clear
	tempfile NJ
	save `NJ'
import excel "Z:\Tranfaglia\Data\SNL\Credit Outcomes\2010_PA.xls", sheet("2010_PA") firstrow clear
	
	append using `NJ'
	append using `MD'
	append using `DE'
		save "Z:\Tranfaglia\Data\SNL\Credit Outcomes\PHL_msa__2010_blocks.dta",replace		

/////// new branch data //////////////////////////////
** begin calculating distances again**
	use "Z:\Tranfaglia\Data\SNL\Credit Outcomes\allmsabranch.dta",clear
		keep if MSACode==37980  /* Philadelphia only */

******************************************************************************
	/// now construct new variables for closed branches only /////
	keep if BranchStatus == "Closed"
		gen close_month = substr(BranchClosed,1,2)
		gen close_year = substr(BranchClosed,-4,4)
		gen close_qtr = 0
			replace close_qtr =1 if close_month=="01" | close_month=="02" | close_month=="03"
			replace close_qtr =2 if close_month=="04" | close_month=="05" | close_month=="06"
			replace close_qtr =3 if close_month=="07" | close_month=="08" | close_month=="09"
			replace close_qtr =4 if close_month=="10" | close_month=="11" | close_month=="12"
	egen closeperiod = concat (close_year close_qtr)
		sort closeperiod
			egen closetime = group(closeperiod)
			drop close_qtr close_month
			**** save just PHL closures
			save "Z:\Tranfaglia\Data\SNL\Credit Outcomes\PHLbranchCLOSED2018.dta",replace
******************************************************************************	
	use "Z:\Tranfaglia\Data\SNL\Credit Outcomes\PHLbranchCLOSED2018.dta",clear
	** upload Philly Data
*use Philadelphia_total.dta,clear
	*keep if branchstatus == "Closed"
	forval i=1/354 {
***Store branch coordinates in this file
		use PHLbranchCLOSED2018.dta,clear
		***Store branch coordinates in this file
		keep in `i'
		expand 90052
*** Expand to the number of blocks
	rename InstitutionCompanyName2010 firm`i'
	rename Latitude lat`i'
	rename Longitude longit`i'
	rename closeperiod closeperiod`i'
	
	g index=_n
	sort index
	save tempcoor`i'.dta, replace
	}
		* use data with block coordinates
		use "Z:\Tranfaglia\Data\SNL\Credit Outcomes\PHL_msa__2010_blocks.dta", clear
		g index=_n
		
			forval i=1/354 {
			sort index
			merge index using tempcoor`i'.dta
			drop if _merge!=3
			drop _merge
			}
			*
***Compute distances with vincenty
**convert blocl lat/long to numeric
gen strlat =substr(INTPTLAT,-10,.)
	gen lat = real(strlat)
*gen strlong = substr(INTPTLON,-10,.)
	gen longit = real(INTPTLON)
forval i=1/354 {
vincenty lat longit lat`i' longit`i', hav(dtrust`i') 
drop lat`i' longit`i'
}
save "Z:\Tranfaglia\Data\SNL\Credit Outcomes\PHL_block_distances.dta",replace

** now remove blocks that don't have any closures within 10 miles
use "Z:\Tranfaglia\Data\SNL\Credit Outcomes\PHL_block_distances.dta",clear
	egen firstcheck=rowmin(dtrust1-dtrust354)
	sum firstcheck,d

*** egen for 2 mile radii  // median = 2 branches within radius
forval j = 1/354 {
	g Dd`j'=0
	replace Dd`j' = 1 if dtrust`j' <2
	}
	egen r2=rowtotal(Dd1-Dd354)
	sum r2,d
	hist r2, title(Branches within 2 miles of Block centroid)

	keep if firstcheck<2 /* now only have 63,464 blocks */
	save "Z:\Tranfaglia\Data\SNL\Credit Outcomes\PHL_2_mile_block_distances.dta",replace
	
	///////////// Start with correct data set //////////////////
	*use blocks whose centroids are less than 2 miles from atleast one closed bank
	use "Z:\Tranfaglia\Data\SNL\Credit Outcomes\PHL_2_mile_block_distances.dta",clear
	
*Now use this to just get the first closure, rather than the 6 above
// used on 6/21/18 //
gen bank_name=""
gen bank_num=.
gen bank_close_period=""
gen bank_industry_type=""
gen distance=.

	forval i=1/354 {
		replace bank_num=`i' if Dd`i'==1
		replace bank_name=firm`i' if Dd`i'==1
		replace bank_close_period=closeperiod`i' if Dd`i'==1
		replace distance = dtrust`i' if Dd`i'==1
		replace bank_industry_typ =`i' if Dd`i'==1
	}
	*
	*drop all the individual bank closure variables (since one interested in the attributes of the first closure*
drop firm2 - Dd354 
*save block dataset (which now contains bank info)
save "F:\bankdatacorrect.dta"
	*

////////////////////////////////////////////////////////////////////////////////
** CCP Data Analysis **
////////////////////////////////////////////////////////////////////////////////
 *** First Step: import the csv from the CCP pull on the server 
*use "F:\newCCPdata2.dta",clear
	
	*check for duplicates
	duplicates report cid qtr
		
	qui bys cid qtr: gen dup = _n
	count if dup >=2 & dup!=. & qtr!=""
		drop if dup >= 2
		
		rename census_block censusblock
		tostring censusblock, gen(census_block)

		rename census_tract censustract
		tostring censustract, gen(census_tract)
		
		rename qtr qtr2
		gen qtr = substr(qtr2,1,7)
		
		*save "F:\newCCPdata2.dta",replace

 *use "X:\Staff Folders\Anna\Research\branch closures + credit\testset.dta",clear
	***** Now use Bank Closure Data *****
	use "Z:\Tranfaglia\Data\SNL\Credit Outcomes\bankdatacorrect.dta",clear
	 *use "D:\blocktest.dta",clear
	 rename BLOCKCE00 census_block
	 rename TRACTCE00 census_tract
	 rename COUNTYFP00 county_code
	 rename STATEFP00 state
		 	 
	** sort all the closure date fields and convert time ID into a numeric variable
		rename 
		sort bank_close_period
			egen newtime = group(bank_close_period)
			gen timeid = newtime+22
		
		 tempfile bankdata
		 save `bankdata'

** Clean CCP Data
use "D:\philmsa.dta",clear
	rename census_block block
	gen census_block = string(block)
		rename census_tract tract
		gen census_tract = string(tract)
		replace census_tract = "0" + census_tract if length(census_tract)==5
		replace census_tract = "00" + census_tract if length(census_tract)==4
		replace census_tract = "000" + census_tract if length(census_tract)==3
			gen county = string(county_code) 
			replace county = "0" + county if length(county)==2
			replace county = "00" + county if length(county)==1
	sort cid qtr

** check and remove duplicates
duplicates report cid qtr
	qui by cid qtr: gen dup = cond(_N==1,0,_n)
	drop if dup>1
	
** drop fragments (drop if less than <5 qtrs)
egen long in_id=group(cid)
sort in_id qtr
by in_id: gen counter=_n
by in_id: egen max_counter=max(counter)
drop if max_counter<5

*remove individuals who have died
sort in_id qtr
gen dead = 0
	replace dead = 1 if cust_attr292=="Y"
	tab dead
by in_id: egen deceased = max(dead) 
	*if we want to drop everyone who died:
	drop if deceased > 0
	
	*** convert time id to numeric value **
	sort qtr
	egen timeid = group(qtr)
	save "D:\philmsa_clean.dta",replace 
	*/
		** merge with census block data 
		use "D:\philmsa_clean.dta",clear
		count
		merge m:1 county census_tract census_block using `bankdata'
		count
		
		** save dataset here
		keep if _m==3
		*save "D:/phlmerge2.dta",replace
		
			use "Z:\Tranfaglia\Data\SNL\Credit Outcomes\PHLbranchCLOSED2018.dta",clear
				keep if lostall==1
						collapse (max) closetime, by(CensusTract)
						rename CensusTract census_tract
						rename closetime closetime2
						gen closetime = closetime2 + 22
						drop closetime2						
				tempfile desert
				save `desert' 
			
			* use correct version of ccp data here*
				drop _m 
			merge m:1 census_tract using `desert'
				gen bankdesert=0
				replace bankdesert = 1 if _m==3
				
		///// Data prep for Regression Analysis begins here //////
		*clean 
		use "D:/phlmerge2.dta",clear
		gen year = year(qtr)
			rename year year2
			tostring year2, gen(year)
			
		gen month2 = month(qtr) 
			tostring month2, gen(month)
				replace month = "0" + month if length(month)<2
				
			** Important: the format of the qtr variable is different from the PCC SAS pull and the RADAR SAS pull ***	 
			rename qtr qtr2
			gen qtr = year + "-" + month
			
				*** New merge to get additional CCP variables****
				drop _m
				drop qtr2
				merge 1:1 cid qtr using "F:\newCCPdata.dta"
				keep if _m==3
				save "F:\CCP2.dta"	/* Use this dataset for movers and non-movers */
				******
		
		*****Generate variables to help identify if individuals have moved.
		***Check to see how individuals' census locations have changed from period to period
		bys in_id: gen last_census_block=census_block[_n-1]
		bys in_id: gen last_census_tract=census_tract[_n-1]
		
		gen cblock_change=.
		bys in_id: replace cblock_change=0 if (last_census_block==census_block) & (last_census_tract==census_tract)
		bys in_id: replace cblock_change=1 if (last_census_block!=census_block) & (last_census_tract!=census_tract) & last_census_block!="" 

		***Identify entire panels where the individual moved
		by in_id: egen mover=max(cblock_change) 
		gen nonmover = 0
			replace nonmover = 1 if mover!=1		/* NOTE: Therefore nonmover (0/1) is variable to use to split moving cohorts */
					
	** gen event time dummies
	drop eventb
	gen eventb = newtime - time_id
			
	** generating event time **
	gen d0 = 0 
		replace d0 = 1 if eventb==0
	
** 20 qtrs prior dummies **
		forval i = 1/20 {
		g dmin`i' = 0
			replace dmin`i' = 1 if eventb == -`i' /*eventb1 == -`i' | eventb2==-`i' | eventb3==-`i' | eventb4==-`i' | eventb5==-`i' | eventb6==-`i' */
			}
** 20 qtrs after dummies **
		forval i = 1/20 {
		g da`i' = 0
			replace da`i' = 1 if eventb == `i' /*eventb1 == `i' | eventb2==`i' | eventb3==`i' | eventb4==`i' | eventb5==`i' | eventb6==`i' */
	}
	
///// Regressions: DISTANCE /////
	
** generate distance variables
forval i=1/39 {
	gen distance_`i' = 0
		replace distance_`i'  = 1 if distance >= ((`i' - 1)*0.05) & distance <(`i' * 0.05)
		}
			
		/*number of accounts opened
		reg riskscore distance_1 - distance_39 if eventb1==-4, noconstant 
			estimates store est_1
		reg riskscore distance_1 - distance_39 if eventb1==4, noconstant 
			estimates store est_2 */
		
		forval i = 1/12 {
			reg cma_attr3902 distance_1 - distance_39 if eventb==-`i', noconstant
				estimates store before_`i'
			reg cma_attr3902 distance_1 - distance_39 if eventb==`i', noconstant
				estimates store after_`i'		
			
	coefplot before_`i' after_`i', ///
		keep(distance_*) vertical coeflabels( ///
distance_1 = " "  distance_2 = " " distance_3=" " distance_4=" " ///
distance_5 = "0.25"  distance_6 = " " distance_7=" " distance_8=" "  ///
distance_9 = " " distance_10="0.50" distance_11=" " distance_12 = " " distance_13=" " ///
distance_14=" " distance_15="0.75" distance_16=" " distance_17 = " " distance_18=" " ///
distance_19=" " distance_20="1.0" distance_21=" " distance_22 = " " distance_23=" " ///
distance_24=" " distance_25="1.25" distance_26=" " distance_27 = " " distance_28=" " ///
distance_29=" " distance_30="1.50" distance_31=" " distance_32 = " " distance_33=" " ///
distance_34=" " distance_35="1.75" distance_36=" " distance_37 = " " distance_38=" " ///
distance_39="2.0") recast(connected) ci(none) offset(0) 

 graph save Graph `"X:\Staff Folders\Anna\Research\branch closures + credit\graphs\Presence of Bankruptcy (cma_attr3902)\estudy`i'.gph"' 
			}
	*
	///// Regressions ////
	* gen treatment groups 
		gen control = .
			replace control = 1 if distance >1.0
		gen treated1 = .
			replace treated1 =1  if distance <=0.25
			replace treated1 = 0 if control==1
		gen treated2 = .
			replace treated2 =1 if distance >0.25 & distance <=0.5
			replace treated2 = 0 if control==1
		gen treated3 = .
			replace treated3 =1 if distance >0.5 & distance <=0.75
			replace treated3 = 0 if control==1
		gen treated4 = .
			replace treated4 =1 if distance >0.75 & distance <=1.0
			replace treated4 = 0 if control==1

	*how many in each treatment group?	
	foreach x in 1 2 3 4 {
		tab treated`x'
		}
		
	* convert to panel data format
	xtset in_id timeid
	 *factor variables cannot have negative values, so change event time *
	 gen eventime = eventb + 51
		tab eventime
		*gen new event time variable(s)
		tab eventime,gen(eventi)
		save "F:\CCP2.dta",replace /*now includes movers and nonmover dummy in set */
	
	** Add any conditional statements here **
	 local credit crtr_attr1 crtr_attr2 crtr_attr3 crtr_attr4 crtr_attr5 crtr_attr6 crtr_attr7 crtr_attr8 crtr_attr9 crtr_attr10 crtr_attr11 crtr_attr166 crtr_attr167 crtr_attr168 crtr_attr169 crtr_attr170 crtr_attr171 crtr_attr172 crtr_attr173 crtr_attr174 crtr_attr175 crtr_attr176 crtr_attr180 crtr_attr185 crtr_attr13 crtr_attr19 crtr_attr20 crtr_attr26 crtr_attr27 crtr_attr33 crtr_attr34 crtr_attr47 crtr_attr48 crtr_attr75 crtr_attr76 crtr_attr95 crtr_attr96 crtr_attr101 crtr_attr102 crtr_attr107 crtr_attr108 crtr_attr118 crtr_attr119 crtr_attr143 crtr_attr144
		foreach var in `credit' {
		forval x = 1/4 {
	xtreg `var' i.treated`x'##(eventi35-eventi46 eventi51-eventi67) if eventime <68 & eventime>=31,fe
	
	coefplot, ///
		keep(1.treated`x'#1.eventi35 1.treated`x'#1.eventi36 ///
		1.treated`x'#1.eventi37 1.treated`x'#1.eventi38 1.treated`x'#1.eventi39 ///
		1.treated`x'#1.eventi40 1.treated`x'#1.eventi41 1.treated`x'#1.eventi42 ///
		1.treated`x'#1.eventi43 1.treated`x'#1.eventi44 1.treated`x'#1.eventi45 ///
		1.treated`x'#1.eventi46 1.treated`x'#1.eventi47 1.treated`x'#1.eventi48 ///
		1.treated`x'#1.eventi49 1.treated`x'#1.eventi50 1.treated`x'#1.eventi51 ///
		1.treated`x'#1.eventi52 1.treated`x'#1.eventi53 1.treated`x'#1.eventi54 ///
		1.treated`x'#1.eventi55 1.treated`x'#1.eventi56 1.treated`x'#1.eventi57 ///
		1.treated`x'#1.eventi58 1.treated`x'#1.eventi59 1.treated`x'#1.eventi60 ///
		1.treated`x'#1.eventi61 1.treated`x'#1.eventi62 1.treated`x'#1.eventi63 ///
		1.treated`x'#1.eventi64 1.treated`x'#1.eventi65 1.treated`x'#1.eventi66 ///
		1.treated`x'#1.eventi67) vertical coeflabels( ///
	1.treated`x'#1.eventi35 = "-16"  1.treated`x'#1.eventi36 = " " ///	
1.treated`x'#1.eventi37 = " "  1.treated`x'#1.eventi38 = " " 1.treated`x'#1.eventi39= "-12" 1.treated`x'#1.eventi40= " " ///
1.treated`x'#1.eventi41 = " "  1.treated`x'#1.eventi42 = " " 1.treated`x'#1.eventi43= "-8" 1.treated`x'#1.eventi44= " "  ///
1.treated`x'#1.eventi45 = " "  1.treated`x'#1.eventi46 = " " 1.treated`x'#1.eventi47= "-4" 1.treated`x'#1.eventi48= " " ///
1.treated`x'#1.eventi49 = " "  1.treated`x'#1.eventi50 = " " 1.treated`x'#1.eventi51= "0" 1.treated`x'#1.eventi52= " " ///
1.treated`x'#1.eventi53 = " "  1.treated`x'#1.eventi54 = " " 1.treated`x'#1.eventi55= "4" 1.treated`x'#1.eventi56= " " ///
1.treated`x'#1.eventi57 = " "  1.treated`x'#1.eventi58 = " " 1.treated`x'#1.eventi59= "8" 1.treated`x'#1.eventi60= " " ///
1.treated`x'#1.eventi61 = " "  1.treated`x'#1.eventi62 = " " 1.treated`x'#1.eventi63= "12" 1.treated`x'#1.eventi64= " " ///
1.treated`x'#1.eventi65 = " "  1.treated`x'#1.eventi66 = " " 1.treated`x'#1.eventi67= "16") recast(line) ciopts(recast(rline) ///
  lpattern(dash)) xline(13) yline(0) xtitle(Event Time Quarters)
  
		graph export "X:\Staff Folders\Anna\Research\branch closures + credit\graphs\movers/`var'_treatment`x'.png", as (png)
		}
		}
*
	
** generate birthyear and year of observation
	
	gen byear = yofd(cust_attr1)
		gen yearclose = real(substr(bank_close_period,1,4))
			format yearclose %ty
		
		*gen individual's age at time of CCP observation
		gen age = yearclose - byear
		
		gen cohort =.
			replace cohort = 1 if age <25
			replace cohort = 2 if age>24 & age<35
			replace cohort = 3 if age>34 & age <45
			replace cohort = 4 if age>44 & age <55
			replace cohort = 5 if age>54 & age <65
			replace cohort = 6 if age>64 & age <75
			replace cohort = 7 if age>74
		** make new bankruptcy variable
			sort in_id newtime
			xtset in_id newtime
		
		gen newbankruptcy = 0
			by in_id: replace newbankruptcy = 1 if cma_attr3902==1 & L.cma_attr3902==0	
	
		forval i=1/12 {
				replace newbankruptcy =. if l`i'.newbankruptcy==1
				}
		** gen success rate variable
		gen successrate = cma_attr3133/cma_attr3000
		
			** gen charts with only individuals 60 or older
		keep if age >=60
		
		
//// big bank verse community bank analysis /////
	use "F:\CCP2.dta",clear
		 gen bigbank = 0
			replace bigbank = regexm(bank_name, "PNC") |  regexm(bank_name, "BNY") |  regexm(bank_name, "TD") | regexm(bank_name, "Fargo") | regexm(bank_name, "Citibank") | regexm(bank_name, "Santander") | regexm(bank_name, "Citizens") | regexm(bank_name, "Citicorp")

		* split on bank size (remove large FIs)
		keep if bigbank==1
		gen successrate = cma_attr3133/cma_attr3000
		 local credit successrate riskscore crtr_attr1 crtr_attr2 crtr_attr3 crtr_attr4 crtr_attr5 crtr_attr6 crtr_attr7 crtr_attr8 crtr_attr9 crtr_attr10 crtr_attr11 crtr_attr166 crtr_attr167 crtr_attr168 crtr_attr169 crtr_attr170 crtr_attr171 crtr_attr172 crtr_attr173 crtr_attr174 crtr_attr175 crtr_attr176 crtr_attr180 crtr_attr185 crtr_attr13 crtr_attr19 crtr_attr20 crtr_attr26 crtr_attr27 crtr_attr33 crtr_attr34 crtr_attr47 crtr_attr48 crtr_attr75 crtr_attr76 crtr_attr95 crtr_attr96 crtr_attr101 crtr_attr102 crtr_attr107 crtr_attr108 crtr_attr118 crtr_attr119 crtr_attr143 crtr_attr144 
		foreach var in `credit' {
		forval x = 1/4 {
	xtreg `var' i.treated`x'##(eventi35-eventi46 eventi51-eventi67) if eventime <68 & eventime>=31,fe
	
	*est sto riskscore_`x'
	
	coefplot, ///
		keep(1.treated`x'#1.eventi35 1.treated`x'#1.eventi36 ///
		1.treated`x'#1.eventi37 1.treated`x'#1.eventi38 1.treated`x'#1.eventi39 ///
		1.treated`x'#1.eventi40 1.treated`x'#1.eventi41 1.treated`x'#1.eventi42 ///
		1.treated`x'#1.eventi43 1.treated`x'#1.eventi44 1.treated`x'#1.eventi45 ///
		1.treated`x'#1.eventi46 1.treated`x'#1.eventi47 1.treated`x'#1.eventi48 ///
		1.treated`x'#1.eventi49 1.treated`x'#1.eventi50 1.treated`x'#1.eventi51 ///
		1.treated`x'#1.eventi52 1.treated`x'#1.eventi53 1.treated`x'#1.eventi54 ///
		1.treated`x'#1.eventi55 1.treated`x'#1.eventi56 1.treated`x'#1.eventi57 ///
		1.treated`x'#1.eventi58 1.treated`x'#1.eventi59 1.treated`x'#1.eventi60 ///
		1.treated`x'#1.eventi61 1.treated`x'#1.eventi62 1.treated`x'#1.eventi63 ///
		1.treated`x'#1.eventi64 1.treated`x'#1.eventi65 1.treated`x'#1.eventi66 ///
		1.treated`x'#1.eventi67) vertical coeflabels( ///
	1.treated`x'#1.eventi35 = "-16"  1.treated`x'#1.eventi36 = " " ///	
1.treated`x'#1.eventi37 = " "  1.treated`x'#1.eventi38 = " " 1.treated`x'#1.eventi39= "-12" 1.treated`x'#1.eventi40= " " ///
1.treated`x'#1.eventi41 = " "  1.treated`x'#1.eventi42 = " " 1.treated`x'#1.eventi43= "-8" 1.treated`x'#1.eventi44= " "  ///
1.treated`x'#1.eventi45 = " "  1.treated`x'#1.eventi46 = " " 1.treated`x'#1.eventi47= "-4" 1.treated`x'#1.eventi48= " " ///
1.treated`x'#1.eventi49 = " "  1.treated`x'#1.eventi50 = " " 1.treated`x'#1.eventi51= "0" 1.treated`x'#1.eventi52= " " ///
1.treated`x'#1.eventi53 = " "  1.treated`x'#1.eventi54 = " " 1.treated`x'#1.eventi55= "4" 1.treated`x'#1.eventi56= " " ///
1.treated`x'#1.eventi57 = " "  1.treated`x'#1.eventi58 = " " 1.treated`x'#1.eventi59= "8" 1.treated`x'#1.eventi60= " " ///
1.treated`x'#1.eventi61 = " "  1.treated`x'#1.eventi62 = " " 1.treated`x'#1.eventi63= "12" 1.treated`x'#1.eventi64= " " ///
1.treated`x'#1.eventi65 = " "  1.treated`x'#1.eventi66 = " " 1.treated`x'#1.eventi67= "16") recast(line) ciopts(recast(rline) ///
  lpattern(dash)) xline(13) yline(0) xtitle(Event Time Quarters)
  
		graph export "X:\Staff Folders\Anna\Research\branch closures + credit\graphs\big banks/`var'_treatment`x'.png", as (png)
		}
		}
*

************************************************
************************************************
************************************************
************* code not utilized in final version
************************************************
************************************************

/*
*egen nbanks = anycount(dtrust1-dtrust409), values(<10)
	forval j = 1/354 {
		g d`j'=0
		replace d`j' = 1 if dtrust`j' <10
		}
		egen r10=rowtotal(d1-d354)
		sum r10,d
		hist r10, title(Branches within 10 miles of Block centroid)
		
*** egen for 5 mile radii // median = 14 branches within radius
forval j = 1/354 {
	g dd`j'=0
	replace dd`j' = 1 if dtrust`j' <5
	}
	egen r5=rowtotal(dd1-dd354)
	sum r5,d
	hist r5, title(Branches within 5 miles of Block centroid)
	*/
		
/** egen for 1 mile radii  // median = 1 branch within radius
forval j = 1/354 {
	g DD`j'=0
	replace DD`j' = 1 if dtrust`j' <1
	}
	egen r1=rowtotal(DD1-DD354)
	sum r1,d
	hist r1, title(Branches within 1 mile of Block centroid)
	*/
	*save "Z:\Tranfaglia\Data\SNL\Credit Outcomes\PHL_block_distances.dta",replace
	
	* generate group with only one closure (17,076 census blocks)
/*	keep if r2==6
gen firm_name1=""
gen firm_name2=""
gen firm_name3=""
gen firm_name4=""
gen firm_name5=""
gen firm_name6=""
gen firm_num1=.
gen firm_num2=.
gen firm_num3=.
gen firm_num4=.
gen firm_num5=.
gen firm_num6=.
gen firm1_close_period=""
gen firm2_close_period=""
gen firm3_close_period=""
gen firm4_close_period=""
gen firm5_close_period=""
gen firm6_close_period=""
gen dist1 =.
gen dist2 =.
gen dist3 =.
gen dist4 =.
gen dist5 =.
gen dist6 =. 

****************** Census Tract analysis to see look at tracts lost all, some, etc. branches *********************
sort CensusTract
		gen index = _n
		egen N_trctbranch = count(index), by(CensusTract)
		gen closedbranch = 0
			replace closedbranch = 1 if BranchClosed !="-"
		by CensusTract: egen N_trctclose = sum(closedbranch)
		drop closedbranch
		
		gen lostall = 0
			replace lostall = 1 if N_trctbranch==N_trctclose /*83 Census tracts lost all of their branches over 2010 - 2016 in the PHL MSA*/
			gen remainingbranches = 0
				replace remainingbranches = N_trctbranch - N_trctclose
			** save new data set of just Philly branches (open and closed) with new variables
			save "Z:\Tranfaglia\Data\SNL\Credit Outcomes\PHLbranch2018.dta"


forval i=1/354 {
		replace firm_num1=`i' if Dd`i'==1
		replace firm_name1=firm`i' if Dd`i'==1
		replace firm1_close_period=closeperiod`i' if Dd`i'==1
		replace dist1 = dtrust`i' if Dd`i'==1
	}
	*save "Z:\Tranfaglia\Data\SNL\Credit Outcomes\PHL_1_closure_only.dta",replace
forval j=1/354 {
	if firm_num1!=. {
		replace firm_num2=`j' if Dd`j'==1 & `j'!=firm_num1
		replace firm_name2=firm`j' if Dd`j'==1 & `j'!=firm_num1
		replace firm2_close_period=closeperiod`j' if Dd`j'==1 & `j'!=firm_num1
		replace dist2 = dtrust`j' if Dd`j'==1 & `j'!=firm_num1
		}
	} 
	
	*save "Z:\Tranfaglia\Data\SNL\Credit Outcomes\PHL_2_closure_only.dta",replace
forval k=1/354 {
	if firm_num1!=. & firm_num2!=. {
		replace firm_num3=`k' if Dd`k'==1 & `k'!=firm_num1 & `k'!=firm_num2
		replace firm_name3=firm`k' if Dd`k'==1 & `k'!=firm_num1 & `k'!=firm_num2
		replace firm3_close_period=closeperiod`k' if Dd`k'==1 & `k'!=firm_num1 & `k'!=firm_num2
		replace dist3 = dtrust`k' if Dd`k'==1 & `k'!=firm_num1 & `k'!=firm_num2
		}
	}
	
	*save "Z:\Tranfaglia\Data\SNL\Credit Outcomes\PHL_3_closure_only.dta",replace
forval l=1/354 {
	if firm_num1!=. & firm_num2!=. & firm_num3!=. {
		replace firm_num4=`l' if Dd`l'==1 & `l'!=firm_num1 & `l'!=firm_num2 & `l'!=firm_num3
		replace firm_name4=firm`l' if Dd`l'==1 & `l'!=firm_num1 & `l'!=firm_num2 & `l'!=firm_num3
		replace firm4_close_period=closeperiod`l' if Dd`l'==1 & `l'!=firm_num1 & `l'!=firm_num2 & `l'!=firm_num3
		replace dist4 = dtrust`l' if Dd`l'==1 & `l'!=firm_num1 & `l'!=firm_num2 & `l'!=firm_num3
		}
	}
	*save "Z:\Tranfaglia\Data\SNL\Credit Outcomes\PHL_4_closure_only.dta",replace
	
forval m=1/354 {
	if firm_num1!=. & firm_num2!=. & firm_num3!=. & firm_num4!=. {
		replace firm_num5=`m' if Dd`m'==1 & `m'!=firm_num1 & `m'!=firm_num2 & `m'!=firm_num3 & `m'!=firm_num4
		replace firm_name5=firm`m' if Dd`m'==1 & `m'!=firm_num1 & `m'!=firm_num2 & `m'!=firm_num3 & `m'!=firm_num4
		replace firm5_close_period=closeperiod`m' if Dd`m'==1 & `m'!=firm_num1 & `m'!=firm_num2 & `m'!=firm_num3 & `m'!=firm_num4
		replace dist5 = dtrust`m' if Dd`m'==1 & `m'!=firm_num1 & `m'!=firm_num2 & `m'!=firm_num3 & `m'!=firm_num4
		}
	}
	
	*save "Z:\Tranfaglia\Data\SNL\Credit Outcomes\PHL_5_closure_only.dta",replace
forval n=1/354 {
	if firm_num1!=. & firm_num2!=. & firm_num3!=. & firm_num4!=. & firm_num5!=. {
		replace firm_num6=`n' if Dd`n'==1 & `n'!=firm_num1 & `n'!=firm_num2 & `n'!=firm_num3 & `n'!=firm_num4 & `n'!=firm_num5
		replace firm_name6=firm`n' if Dd`n'==1 & `n'!=firm_num1 & `n'!=firm_num2 & `n'!=firm_num3 & `n'!=firm_num4 & `n'!=firm_num5
		replace firm6_close_period=closeperiod`n' if Dd`n'==1 & `n'!=firm_num1 & `n'!=firm_num2 & `n'!=firm_num3 & `n'!=firm_num4 & `n'!=firm_num5
		replace dist6 = dtrust`n' if Dd`n'==1 & `n'!=firm_num1 & `n'!=firm_num2 & `n'!=firm_num3 & `n'!=firm_num4 & `n'!=firm_num5
		}
	}
	*save "Z:\Tranfaglia\Data\SNL\Credit Outcomes\PHL_6_closure_only.dta",replace
	
	*test
	gen closedbank_1 =.
	foreach i of numlist 1/354 {
	replace closedbank_1 = firm`i' if Dd`i'==1
	}
*** Now try to append all the data sets together
use "Z:\Tranfaglia\Data\SNL\Credit Outcomes\PHL_1_closure_only.dta",clear
	tempfile one
	save `one'
use "Z:\Tranfaglia\Data\SNL\Credit Outcomes\PHL_2_closure_only.dta",clear
	tempfile two
	save `two'
use "Z:\Tranfaglia\Data\SNL\Credit Outcomes\PHL_3_closure_only.dta",clear
	tempfile three
	save `three'
use "Z:\Tranfaglia\Data\SNL\Credit Outcomes\PHL_4_closure_only.dta",clear
	tempfile four
	save `four'
use "Z:\Tranfaglia\Data\SNL\Credit Outcomes\PHL_5_closure_only.dta",clear
	tempfile five
	save `five'
use "Z:\Tranfaglia\Data\SNL\Credit Outcomes\PHL_6_closure_only.dta",clear
	tempfile six
	save `six'

use `one'
	count
	append using `two'
	count
	append using `three'
	count
	append using `four'
	count
	append using `five'
	count
	append using `six'
	count
	
	save "Z:\Tranfaglia\Data\SNL\Credit Outcomes\PHL_closures.dta",replace
	use "Z:\Tranfaglia\Data\SNL\Credit Outcomes\PHL_closures.dta",clear

	** CCP Data

	/*
		sort firm1_close_period
			egen newtime1 = group(firm1_close_period)
		sort firm2_close_period
			egen newtime2 = group(firm2_close_period)
		sort firm3_close_period
			egen newtime3 = group(firm3_close_period)
		sort firm4_close_period
			egen newtime4 = group(firm4_close_period)
		sort firm5_close_period
			egen newtime5 = group(firm5_close_period)
		sort firm6_close_period
			egen newtime6 = group(firm6_close_period)
			
		** since the CCP numeric date begins in 2005Q1, need to add 21 to all time fields so they match up
		gen time_id1 = newtime1 + 22
		gen time_id2 = newtime2 + 22
		gen time_id3 = newtime3 + 22
		gen time_id4 = newtime4 + 22
		gen time_id5 = newtime5 + 22
		gen time_id6 = newtime6 + 22  */
		
		/*replace State = "10" if state=="DE"
		replace State = "24" if state=="MD"
		replace State = "34" if state=="NJ"
		replace State = "42" if state=="PA" */
		
			/*
		use "D:\testmerge.dta"
		drop _m
		count
		merge m:1 county census_tract census_block using `bankdata'
		*/
		
		 /***Check and see how individuals' scrambled addresses have changed from period to period
		by in_id: gen last_address=address[_n-1]
		*drop address_change
		gen address_change=.
		by in_id: replace address_change=0 if last_address==address
		by in_id: replace address_change=1 if last_address!=address & last_address!=""
	
		*drop moved_dummy
		gen moved_dummy=0
		replace moved_dummy=1 if cblock_change==1 & address_change==1 */
		
		
			** new CPP data (additional variables) pulled from RADAR can be inserted here*
			drop in_id
				egen in_id = group(cid)
				sort qtr
				drop newtime
				egen newtime = group(qtr) 
					replace newtime = newtime - 8 /* VITAL for new CCP dataset */
					
	/////////////////////////////////////////////////////////////////////
* 6/12/18 * More CCP data cleaning
////////////////////////////////////////////////////////////////////
 
use "F:\CCP2.dta",clear			/*use newest CCP pull from RADAR (includes more cust_attr variable merged onto original dataset */
		use "F:\newCCPdata2.dta",clear  /*use FRESH CCP pull from RADAR - new sample*/
					tostring county_code, gen(county)
					replace county = "0" + county if length(county)==2
					replace county = "00" + county if length(county)==1
						rename county_code county_code2
						rename county county_code
						rename census_block BLOCK
						gen census_block = substr(BLOCK,3,4)
							drop BLOCK
	*
		******************* Create set of movers ***
		sort cid
		egen in_id = group(cid)
				sort qtr
					egen time_id = group(qtr)
		sort in_id time_id
	gen dead = 0
		replace dead = 1 if cust_attr292=="Y"
	tab dead
		by in_id: egen deceased = max(dead) 
	*if we want to drop everyone who died:
	drop if deceased > 0
	
	
	egen newtime = group(firm1_close_period)
			gen timeid = newtime+22
	rename TRACTCE00 census_tract
	rename BLOCKCE00 census_block
	rename COUNTYFP00 county_code
	drop firm_name2 - dist6
	tempfile bankdata
		 save `bankdata'
	use "F:\newCCPdata2.dta",clear 
		count
		merge m:1 county_code census_tract census_block using `bankdata'
		count
	save "F:\phillymergejune2018.dta"
	use "F:\phillymergejune2018.dta",clear
	use "F:\CCP2.dta",clear

			gen timeid = newtime+22
///
		///
				///
				
			*import delimited F:\additionalccp.csv, clear 
			use "F:\additionalccp.dta",clear
			*check for duplicates
	duplicates report cid qtr
		
	qui bys cid qtr: gen dup = _n
	count if dup >=2 & dup!=. & qtr!=""
		drop if dup >= 2
		
		rename census_block censusblock
		tostring censusblock, gen(census_block)
				drop censusblock
		
		rename census_tract censustract
		tostring censustract, gen(census_tract)
			replace census_tract = "000" + census_tract if length(census_tract)==3
			replace census_tract = "00" + census_tract if length(census_tract)==4
			replace census_tract = "0" + census_tract if length(census_tract)==5
			save "F:\additionalccp.dta" 
					rename qtr qtr2
					gen qtr = substr(qtr2,1,7)
		
			tempfile test
			save `test'
			
			use "F:\CCP2.dta",clear
			drop _m
			merge 1:1 cid qtr using `test'
					
	***************** Older
	***************** Regressions
	
	foreach x in 1 2 3 4 {
	esttab riskscore_`x' using RiskScore.txt,append
	}
	*
	* number of accounts opened 
	foreach x in 1 2 3 4 {
	xtreg cma_attr3902 i.treated`x'##ib46.eventime,fe
	est sto AccountsOpened_`x'
	}
	foreach x in 1 2 3 4 {
	esttab AccountsOpened_`x' using AccountsOpened.txt,append
	}
	
	*success rate
	gen successrate = cma_attr3133/cma_attr3000
	foreach x in 1 2 3 4 {
	xtreg successrate i.treated`x'##ib46.eventime,fe
	est sto successrate_`x'
	}
	foreach x in 1 2 3 4 {
	esttab successrate_`x' using SuccessRate.txt,append
	}
	
	* inquiries
	foreach x in 1 2 3 4 {
	xtreg cma_attr3000 i.treated`x'##ib46.eventime,fe
	est sto inquiries_`x'
	}
	foreach x in 1 2 3 4 {
	esttab inquiries_`x' using Inquiries.txt,append
	}
	
	* new accounts
	foreach x in 1 2 3 4 {
	xtreg cma_attr3133 i.treated`x'##ib46.eventime,fe
	est sto newaccounts_`x'
	}
	foreach x in 1 2 3 4 {
	esttab newaccounts_`x' using NewAccounts.txt,append
	}
	
	*bankruptcy
	foreach x in 1 2 3 4 {
	xtreg cma_attr3902 i.treated`x'##ib46.eventime,fe
	est sto bankruptcy_`x'
	}
	foreach x in 1 2 3 4 {
	esttab bankruptcy_`x' using Bankruptcy.txt,append
	}
	
	* Total PD
	foreach x in 1 2 3 4 {
	xtreg cma_attr3236 i.treated`x'##ib46.eventime,fe
	est sto pd_`x'
	}
	foreach x in 1 2 3 4 {
	esttab pd_`x' using TotalPD.txt,append
	}
	
	** gen charts for individuals in census tracts that lost all of their branches
		keep if bankdesert ==0
		
		forval j = 1/7 {
		preserve
		keep if cohort == `j'
		forval i= 1/12 {
			reg successrate distance_1 - distance_39 if eventb==-`i', noconstant
				estimates store before_`i'
			reg successrate distance_1 - distance_39 if eventb==`i', noconstant
				estimates store after_`i'
				
	coefplot before_`i' after_`i', ///
		keep(distance_*) vertical coeflabels( ///
distance_1 = " "  distance_2 = " " distance_3=" " distance_4=" " ///
distance_5 = "0.25"  distance_6 = " " distance_7=" " distance_8=" "  ///
distance_9 = " " distance_10="0.50" distance_11=" " distance_12 = " " distance_13=" " ///
distance_14=" " distance_15="0.75" distance_16=" " distance_17 = " " distance_18=" " ///
distance_19=" " distance_20="1.0" distance_21=" " distance_22 = " " distance_23=" " ///
distance_24=" " distance_25="1.25" distance_26=" " distance_27 = " " distance_28=" " ///
distance_29=" " distance_30="1.50" distance_31=" " distance_32 = " " distance_33=" " ///
distance_34=" " distance_35="1.75" distance_36=" " distance_37 = " " distance_38=" " ///
distance_39="2.0") recast(connected) ci(none) offset(0) 

 graph export "X:\Staff Folders\Anna\Research\branch closures + credit\graphs\Larger sample\successrate_lrgsample\estudy`i'.png", as(png) 
 }
 restore
 }
	*************************************************************
	** Edit variables
	replace cma_attr3000 =. if cma_attr3000 >92
	replace cma_attr3100 =. if cma_attr3100 >92	
	replace cma_attr3133 =. if cma_attr3133 >92
	replace cma_attr3159 =. if cma_attr3159 >9999992
	replace cma_attr3215 =. if cma_attr3215 >92
	replace cma_attr3236 =. if cma_attr3236 >9999992
	replace cma_attr3268 =. if cma_attr3268 >92
	replace cma_attr3902 =. if cma_attr3902 >92
	replace cma_attr3907 =. if cma_attr3907 >92
	
	replace crtr_attr1 =. if  crtr_attr1 >92
	replace crtr_attr2 =. if  crtr_attr2 >92
	replace crtr_attr3 =. if  crtr_attr3 >92
	replace crtr_attr4 =. if  crtr_attr4 >92
	replace crtr_attr5 =. if  crtr_attr5 >92
	replace crtr_attr6 =. if  crtr_attr6 >92
	replace crtr_attr7 =. if  crtr_attr7 >92
	replace crtr_attr8 =. if  crtr_attr8 >92
	replace crtr_attr9 =. if  crtr_attr9 >92
	replace crtr_attr10 =. if  crtr_attr10 >92
	replace crtr_attr11 =. if  crtr_attr11 >92
	replace crtr_attr13 =. if  crtr_attr13 >92
	replace crtr_attr14 =. if  crtr_attr14 >92
	replace crtr_attr15 =. if  crtr_attr15 >92
	replace crtr_attr16 =. if  crtr_attr16 >92
	replace crtr_attr17 =. if  crtr_attr17 >92
	replace crtr_attr18 =. if  crtr_attr18 >92
	replace crtr_attr19 =. if  crtr_attr19 >92
	replace crtr_attr20 =. if  crtr_attr20 >92
	replace crtr_attr21 =. if  crtr_attr21 >92
	replace crtr_attr22 =. if  crtr_attr22 >92
	replace crtr_attr23 =. if  crtr_attr23 >92
	replace crtr_attr24 =. if  crtr_attr24 >92
	replace crtr_attr25 =. if  crtr_attr25 >92	
	replace crtr_attr26 =. if  crtr_attr26 >92
	replace crtr_attr27 =. if  crtr_attr27 >92
	replace crtr_attr28 =. if  crtr_attr28 >92
	replace crtr_attr29 =. if  crtr_attr29 >92
	replace crtr_attr30 =. if  crtr_attr30 >92
	replace crtr_attr31 =. if  crtr_attr31 >92
	replace crtr_attr32 =. if  crtr_attr32 >92
	replace crtr_attr33 =. if  crtr_attr33 >92
	replace crtr_attr34 =. if  crtr_attr34 >92
	replace crtr_attr35 =. if  crtr_attr35 >92	
	replace crtr_attr36 =. if  crtr_attr36 >92
	replace crtr_attr37 =. if  crtr_attr37 >92
	replace crtr_attr38 =. if  crtr_attr38 >92
	replace crtr_attr39 =. if  crtr_attr39 >92	
	replace crtr_attr47 =. if  crtr_attr47 >92	
	replace crtr_attr48 =. if  crtr_attr48 >92
	replace crtr_attr50 =. if  crtr_attr50 >92
	replace crtr_attr51 =. if  crtr_attr51 >92
	replace crtr_attr52 =. if  crtr_attr52 >92
	replace crtr_attr53 =. if  crtr_attr53 >92
	replace crtr_attr75 =. if  crtr_attr75 >92
	replace crtr_attr76 =. if  crtr_attr76 >92
	replace crtr_attr77 =. if  crtr_attr77 >92
	replace crtr_attr78 =. if  crtr_attr78 >92
	replace crtr_attr79 =. if  crtr_attr79 >92
	replace crtr_attr80 =. if  crtr_attr80 >92
	replace crtr_attr81 =. if  crtr_attr81 >92
	replace crtr_attr95 =. if  crtr_attr95 >9999992
	replace crtr_attr96 =. if  crtr_attr96 >9999992
	replace crtr_attr97 =. if  crtr_attr97 >9999992
	replace crtr_attr98 =. if  crtr_attr98 >9999992
	replace crtr_attr99 =. if  crtr_attr99 >9999992
	replace crtr_attr100 =. if  crtr_attr100 >9999992
	replace crtr_attr101 =. if  crtr_attr101 >9999992
	replace crtr_attr102 =. if  crtr_attr102 >9999992
	replace crtr_attr103 =. if  crtr_attr103 >9999992
	replace crtr_attr104 =. if  crtr_attr104 >9999992
	replace crtr_attr105 =. if  crtr_attr105 >9999992
	replace crtr_attr106 =. if  crtr_attr106 >9999992
	replace crtr_attr107 =. if  crtr_attr107 >9999992
	replace crtr_attr108 =. if  crtr_attr108 >9999992
	replace crtr_attr109 =. if  crtr_attr109 >9999992
	replace crtr_attr110 =. if  crtr_attr110 >9999992
	replace crtr_attr111 =. if  crtr_attr111 >9999992
	replace crtr_attr112 =. if  crtr_attr112 >9999992
	replace crtr_attr118 =. if  crtr_attr118 >9999992
	replace crtr_attr119 =. if  crtr_attr119 >9999992
	replace crtr_attr120 =. if  crtr_attr120 >9999992
	replace crtr_attr121 =. if  crtr_attr121 >9999992
	replace crtr_attr122 =. if  crtr_attr122 >9999992
	replace crtr_attr123 =. if  crtr_attr123 >9999992
	replace crtr_attr124 =. if  crtr_attr124 >9999992
	replace crtr_attr143 =. if  crtr_attr143 >9999992
	replace crtr_attr144 =. if  crtr_attr144 >9999992
	replace crtr_attr145 =. if  crtr_attr145 >9999992
	replace crtr_attr146 =. if  crtr_attr146 >9999992
	replace crtr_attr147 =. if  crtr_attr147 >9999992
	replace crtr_attr148 =. if  crtr_attr148 >9999992
	replace crtr_attr166 =. if  crtr_attr166 >9999992
	replace crtr_attr167 =. if  crtr_attr167 >9999992
	replace crtr_attr168 =. if  crtr_attr168 >9999992
	replace crtr_attr169 =. if  crtr_attr169 >9999992
	replace crtr_attr170 =. if  crtr_attr170 >9999992
	replace crtr_attr171 =. if  crtr_attr171 >9999992
	replace crtr_attr172 =. if  crtr_attr172 >9999992
	replace crtr_attr173 =. if  crtr_attr173 >9999992
	replace crtr_attr174 =. if  crtr_attr174 >9999992
	replace crtr_attr175 =. if  crtr_attr175 >9999992
	replace crtr_attr176 =. if  crtr_attr176 >9999992
	replace crtr_attr180 =. if  crtr_attr180 >9999992
	replace crtr_attr185 =. if  crtr_attr185 >9999992
*/
