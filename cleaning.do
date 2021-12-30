 * Spending
clear
set more off

** DATA
cd "\\rb.win.frb.org\C1\Accounts\M-O\c1imm01\Redirected\Desktop\spending"

global savor "savor2020.csv"
global capone19 "capone2019.csv"
global capone20 "capone2020.csv"
global capone21 "capone2021.csv"
global amex19 "amex_2019.csv"
global amex20 "amex_2020.csv"
global amex21 "amex_2021.csv"
global chase19 "Chase0622_Activity20190101_20191231_20200103"
global chase20 "chase2020"
global chase21 "chase2021"
global freedom20 "freedom2020"
global freedom21 "freedom2021"
global discover19blue "Discover-2019-YearEndSummary.csv"
global discover20blue "Discover-2020-YearEndSummary_blue.csv"
global discover21blue "Discover-2021-YeartoDateSummary_blue.csv"
global discover20red "Discover-2020-YearEndSummary_red.csv"
global discover21red "Discover-2021-YeartoDateSummary_red.csv"
global citia19 "citi_Last_year_2019.CSV"
global citia20 "citi2020.csv"
global citia21 "citi2021.csv"
global target19 "target19.csv"
global target20 "target2020.csv"

****** CAPITAL ONE *****
/* Download transaction data for the longest period possible for both cards */ 

import delimited $savor , clear
	gen card = "Savor"
	tempfile tempsavor
	save `tempsavor'
	
import delimited $capone19 , clear
	gen card = "Capital One"
	append using `tempsavor'
	tempfile tempsavor
	save `tempsavor'

* I can only download 12 months so I'll need to append this carefully. 
import delimited $capone20 , clear
	gen card = "Capital One"
	append using `tempsavor'
	tempfile tempsavor
	save `tempsavor'

import delimited $capone21 , clear
	gen card = "Capital One"
	append using `tempsavor'	

duplicates drop
		
gen date = date(transactiondate , "YMD")
	format date %td
	gsort + date description	

gen amount = debit
	replace amount = credit*-1 if credit != . 


drop transactiondate posteddate cardno debit credit 
save savor.dta, replace


****** AMEX *****
* 2019
	import delimited $amex19 , clear
	tempfile tempamex
	save `tempamex' 
	
*  2020 
	import delimited $amex20 , clear
	append using `tempamex'
	tempfile tempamex
	save `tempamex' 
	** NOTE: there are 2 true duplicates in here. 

* 2021
import delimited $amex21 , clear
	append using `tempamex'

gen card = "Amex"
rename date transactiondate
gen date = date(transactiondate , "MDY", 2020)
	format date %td
	gsort + date description	

drop reference cardmember cardnumber type transactiondate

save amex.dta , replace
		
****** Chase *****
* 2019
import delimited $chase19 , clear
	tempfile tempchase
	save `tempchase'
* 2020 
import delimited $chase20 , clear
	append using `tempchase'
	tempfile tempchase
	save `tempchase'

* 2021 
import delimited $chase21 , clear
	append using `tempchase'

gen card = "Chase"
gen date = date(transactiondate , "MDY")
	format date %td
	gsort + date description
replace amount = amount * -1
drop transactiondate postdate type 

save chase.dta , replace

****** Freedom *****
* 2020 
import delimited $freedom20 , clear
	tempfile tempfreedom
	save `tempfreedom'

* 2021 
import delimited $freedom21 , clear
	append using `tempfreedom'

gen card = "Freedom"
gen date = date(transactiondate , "MDY")
	format date %td
	gsort + date description
replace amount = amount * -1
drop transactiondate postdate type 

save freedom.dta , replace

****** Discover *****
* 2019 
import delimited $discover19blue , clear
	tempfile tempdisc
	save `tempdisc'
	
* 2020
import delimited $discover20blue , clear
	append using `tempdisc'

tempfile tempdisc
	save `tempdisc'
	
* 2021
import delimited $discover21blue , clear
	append using `tempdisc'
gen card = "DiscoverBlue"


tempfile tempdisc
	save `tempdisc'
	
**** Red card ***
* 2020

import delimited $discover20red , clear
gen card = "DiscoverRed"
	append using `tempdisc'
	
	tempfile tempdisc
	save `tempdisc'
	
* 2021 
import delimited $discover21red , clear
gen card = "DiscoverRed"
	append using `tempdisc'	
	
gen date = date(transdate , "MDY", 2020)
	format date %td
	gsort + date description	
drop transdate postdate

save discover.dta , replace


****** Citi *****
* 2019 
import delimited $citia19, clear
	tempfile tempcit
	save `tempcit'
* 2020
import delimited $citia20, clear
	append using `tempcit' 
	tempfile tempcit
	save `tempcit'
	
* 2021 
import delimited $citia21, clear
	append using `tempcit' 
	
 gen card = "citi"
 gen category = ""
rename date transactiondate
gen date = date(transactiondate , "MDY", 2020)
	format date %td
	gsort + date description	
 
 gen amount = debit
	replace amount = credit if credit != . 

drop status transactiondate debit credit

save citi.dta , replace

****** Target *****
* 2019
import delimited $target19 , clear
	tempfile temptar
	save `temptar'
* 2020
import delimited $target20 , clear
	append using `temptar'

gen card = "RedCard"
cap drop amount2
destring amount , replace ignore("$" "(" ")")
replace amount = amount * -1 if description == "Payment Adjustment Fee or Interest Charge"

gen date = date(transdate , "MDY", 2020)
		format date %td
		
drop transdate postingdate originatingaccountlast4 type merchantname merchantcity merchantstate transactiontype referencenumber v13	
	
save target.dta	, replace

****** Append *****	
append using citi.dta 	
append using discover.dta
append using chase.dta
append using amex.dta
append using savor.dta
append using freedom.dta

cap drop memo
save allcardsraw.dta , replace

*******************************************************
********	CLEANING 	*******************************
*******************************************************
gsort + date description	
gen month = month(date)
gen year = year(date)
gen yearmon = ym(year,month)
format yearmon %tm
drop month year
******* Cleaning 
gen des = description


replace des = "Fandango" if strpos(lower(description), "fandango") > 0 
replace des = "Wolfram Alpha" if strpos(lower(description), "wolframalpha") > 0 
replace des = "Microsoft" if strpos(lower(description), "microsoft") > 0 
replace cat = "Services" if des == "Microsoft"
replace des = "Target" if strpos(lower(description), "target") > 0 
replace des = "Target" if card == "RedCard" 
replace des = "Walgreens" if strpos(lower(description), "walgreens") > 0 
replace des = "Wawa" if strpos(lower(description), "wawa") > 0 
replace des = "Fed Reserve" if strpos(lower(description), "fed reserve") > 0 
replace des = "Starbucks" if strpos(lower(description), "starbucks") > 0 
replace des = "Shake Shack" if strpos(lower(description), "shake sha") > 0 
replace des = "Amazon" if strpos(lower(description), "amzn") > 0 
replace des = "Amazon" if strpos(lower(description), "amazon") > 0 
replace des = "Five Below" if strpos(lower(description), "five below") > 0 
replace des = "Honey Grow" if strpos(lower(description), "honey grow") > 0 
replace des = "Honey Grow" if strpos(lower(description), "honeygrow") > 0 
replace des = "CVS" if strpos(lower(description), "cvs") > 0 
replace des = "Mcdonalds" if strpos(lower(description), "mcdonald") > 0 
replace des = "Wendys" if strpos(lower(description), "wendy") > 0 
replace des = "Patco" if strpos(lower(description), "patco") > 0 
replace des = "Panera" if strpos(lower(description), "panera") > 0 
replace des = "Rite Aid" if strpos(lower(description), "rite aid") > 0 
replace des = "Dunkin" if strpos(lower(description), "dunkin") > 0 
replace des = "Acme" if strpos(lower(description), "acme") > 0 
replace des = "Trader Joes" if strpos(lower(description), "trader joe") > 0 
replace des = "Chipotle" if strpos(lower(description), "chipotle") > 0 
replace des = "AC Moore" if strpos(lower(description), "a.c. moore") > 0 
replace des = "Milkboy" if strpos(lower(description), "milkboy") > 0 
replace des = "El Fuego" if strpos(lower(description), "el fuego") > 0 
replace des = "McGillins" if strpos(lower(description), "mcgillins") > 0 
replace des = "Vending Machine" if description == "USA*USA*CANTEEN PHOENI"
replace des = "Vending Machine" if strpos(lower(description), "cmsvend") > 0 
replace des = "Vending Machine" if strpos(lower(description), "usa*canteen") > 0 
replace des = "American Test" if strpos(lower(description), "american") > 0 
replace des = "Lyft" if strpos(lower(description), "lyft") > 0 
replace des = "Uber" if strpos(lower(description), "uber") > 0 
replace des = "Caviar" if strpos(lower(description), "caviar") > 0 
replace des = "Apple" if strpos(lower(description), "apl*itunes") > 0 
replace des = "Apple" if strpos(lower(description), "apple") > 0 & strpos(lower(description), "apple pay") == 0 
replace des = description if des == "Apple" & category == "Restaurant-Restaurant"
replace des = "TickPick" if strpos(lower(description), "tickpick") > 0 
replace des = "Knead Bagels" if strpos(lower(description), "knead bagels") > 0
replace des = "Audible" if strpos(lower(description), "audible") > 0 
replace des = "Great Clips" if strpos(lower(description), "great clips") > 0 
replace des = "UPS" if strpos(lower(description), "ups*") > 0 
replace des = "UPS" if strpos(lower(description), "usps") > 0 
replace des = "Wine and Spirits" if strpos(lower(description), "wine and") > 0 
replace des = "Wine and Spirits" if strpos(lower(description), "wine/spirits") > 0 
replace des = "Whole Foods" if strpos(lower(description), "whole foods") > 0 
replace des = "Whole Foods" if strpos(lower(description), "wholefds") > 0 
replace des = "IBG" if strpos(lower(description), "independence beer") > 0 
replace des = "Taxi" if strpos(lower(description), "taxi") > 0 
replace des = "Shell Oil" if strpos(lower(description), "shell oil") > 0 
replace des = "Riverside" if strpos(lower(description), "riverside") > 0 
replace des = "Regal Cinemas" if strpos(lower(description), "regal cinema") > 0 
replace des = "Pizza Fresca" if strpos(lower(description), "pizza fresca") > 0 
replace des = "Moms Organic" if strpos(lower(des), "moms organic") > 0
replace des = "MegaBus" if strpos(lower(des), "megabus") > 0
replace des = "La Colombe" if strpos(lower(des), "la colombe") > 0
replace des = "Joyce Cleaners" if strpos(lower(des), "joyce custom") > 0 
replace des = "Jos A Bank" if strpos(lower(des), "josabank") > 0 
replace des = "Jos A Bank" if strpos(lower(des), "jos a bank") > 0 
replace des = "JHU" if strpos(lower(des), "jhu stdnt acct") > 0 
replace des = "Iovine Brothers" if strpos(lower(des), "iovine") > 0 
replace des = "Exxonmobil" if strpos(lower(des), "exxonmobil") > 0 
replace des = "Expedia" if strpos(lower(des), "expedia") > 0 
replace des = "grubhub" if strpos(lower(des), "grubhub") > 0 
replace des = "Membership Fee" if strpos(lower(des), "membership fee") > 0 
replace des = "Insomnia" if strpos(lower(des), "insomnia") > 0 
replace des = "Joyce Cleaners" if strpos(lower(des), "joyce") > 0 
replace des = "Little Petes" if strpos(lower(des), "little pete") > 0 
replace des = "Chegg" if strpos(lower(des), "chegg") > 0 
replace des = "BRU" if strpos(lower(des), "bru") > 0
replace des = "Indego Bike" if des == "BICYCLE TRANSIT 8444463346 PA"
replace des = "MAX BRENNER" if strpos(lower(des), "max brenner") > 0
replace des = "Rita's" if strpos(lower(des), "rita's") > 0
replace des = "STUBHUB" if strpos(lower(des), "stubhub") > 0
replace des = "Wegmans" if strpos(lower(des), "wegmans") > 0
replace des = "Hudson News" if strpos(lower(des), "hudsonnews") > 0
replace des = "Hudson News" if strpos(lower(des), "hudson news") > 0
replace des = "Hudson News" if strpos(lower(des), "hudson union") > 0
replace des = "Hudson News" if strpos(lower(des), "newslink") > 0
replace des = "Buffalo Billiards" if strpos(lower(des), "buffalo bill") > 0
replace des = "Taco Bell" if strpos(lower(des), "taco bell") > 0
replace des = "GrubHub" if strpos(lower(des), "grubhub") > 0
replace des = "DoorDash" if strpos(lower(des), "doordash") > 0

replace des = subinstr(des, "TST*","",.)
replace des = subinstr(des, "SQU*SQ *","",.)
replace des = subinstr(des, "SQUARE *SQ *","",.)
replace des = subinstr(des, "SQ *SQ *","",.)
replace des = subinstr(des, "SQ *","",.)



replace des = "Payment" if amount <0


gen cat = category
replace cat = "Merchandise"  if strpos(lower(cat), "merchandise") > 0 
replace cat = "Travel"  if strpos(lower(cat), "travel") > 0 
replace cat = "Travel"  if strpos(lower(des), "travel") > 0 
replace cat = "Travel"  if strpos(lower(cat), "transportation") > 0 
replace cat = "Dining"  if strpos(lower(cat), "restaurant") > 0 
replace cat = "Dining"  if strpos(lower(cat), "food") > 0 
replace cat = "Entertainment"  if strpos(lower(cat), "entertainment") > 0
replace cat = "Health Care"  if strpos(lower(cat), "health") > 0 
replace cat = "Health Care"  if strpos(lower(cat), "medical") > 0 
replace cat = "Gas/Automotive"  if strpos(lower(cat), "gas") > 0 
replace cat = "Grocery" if cat == "Groceries"
replace cat = "Grocery" if cat == "Supermarkets"

replace cat = "School" if des == "JHU STDNT ACCT SELF SR"
replace cat = "School" if cat == "Education"

replace cat = "Target" if des == "Target"
replace des = "Target" if card == "RedCard" 

replace cat = "Gas/Automotive"  if strpos(lower(cat), "gas") > 0 
replace cat = "Gas/Automotive"  if des == "AUTOPARK AT 8TH & FILBERT"
replace cat = "Gas/Automotive"  if des == "Shell Oil"
replace cat = "Gas/Automotive"  if des == "PARKMOBILE 10"
replace cat = "Gas/Automotive"  if strpos(lower(des), "ppa autopark") > 0 
replace cat = "Gas/Automotive"  if strpos(lower(des), "lukoil") > 0 
replace cat = "Gas/Automotive"  if strpos(lower(des), "sunoco") > 0 
replace cat = "Gas/Automotive"  if strpos(lower(des), "exxon") > 0 
replace cat = "Gas/Automotive"  if strpos(lower(des), "scooter") > 0 
replace cat = "Gas/Automotive"  if des == "PIER V GARAGE BALTIMORE MD"
replace cat = "Gas/Automotive"  if des == "PABC-SINGLE SPACE METE BALTIMORE MD"
replace cat = "Gas/Automotive"  if strpos(lower(des), "pepboys") > 0 
replace cat = "Gas/Automotive"  if strpos(lower(des), "parking") > 0 
replace cat = "Gas/Automotive"  if des == "CITY OF FLAGSTAFF FLAG"

replace cat = "Alcohol" if strpos(lower(des), "bar") > 0 
replace cat = "Merchandise" if des == "BARNES&NOBLE.COM    800-843-2665        NY"
replace cat = "Alcohol" if strpos(lower(des), "wine") > 0 
replace cat = "Alcohol" if strpos(lower(des), "beer") > 0 
replace cat = "Alcohol" if strpos(lower(des), "distil") > 0 
replace cat = "Alcohol" if strpos(lower(des), "discount liq") > 0 
replace cat = "Alcohol" if strpos(lower(des), "brewing") > 0 
replace cat = "Alcohol" if  des == "NBC SPORTS ARENA"
replace cat = "Alcohol" if  des == "BRU"
replace cat = "Alcohol" if  des == "McGillins"
replace cat = "Alcohol" if  des == "GARAGE FISHTOWN"
replace cat = "Alcohol" if des == "VILLAGE WHISKEYTINTO"
replace cat = "Alcohol" if des == "Milkboy"
replace cat = "Alcohol" if des == "ARAMARK WACHOVIA CTR CONC"
replace cat = "Alcohol" if des == "FRANKFORD HALL PHILADELPHIA PA"
replace cat = "Alcohol" if des == "FERGIE'S PUB"
replace cat = "Alcohol" if des == "DRINKER'S PUB"
replace cat = "Alcohol" if des == "FADO PHILADELPHIA INC"
replace cat = "Alcohol" if des == "Buffalo Billiards"
replace cat = "Alcohol" if des == "IBG"
replace cat = "Alcohol" if des == "BRICKWALL TAVERN - P"
replace cat = "Alcohol" if des == "BB&T PAVILION"
replace cat = "Alcohol" if des == "Irish Pub 20th Street"
replace cat = "Alcohol" if des == "MONK'S CAFE"
replace cat = "Alcohol" if des == "OTT'S MEDFORD"
replace cat = "Alcohol" if des == "POP UP GARDEN"
replace cat = "Alcohol" if des == "BLUE MOUNTAIN Philadelphia PA"
replace cat = "Alcohol" if des == "SAM ADAMS"
replace cat = "Alcohol" if des == "BAMBOULAS"
replace cat = "Alcohol" if des == "DEPT 68 - DILWORTH 2Philadelphia        PA"
replace cat = "Alcohol" if des == "ROTHMAN CABIN       Philadelphia        PA"


replace cat = "Dining" if  strpos(lower(des), "juice") > 0 
replace cat = "Dining" if strpos(lower(des), "pizzeria") > 0
replace cat = "Dining" if strpos(lower(des), "pizza") > 0
replace cat = "Dining" if strpos(lower(des), "restaurant") > 0
replace cat = "Dining" if des == "Knead Bagels"
replace cat = "Dining" if des == "Mcdonalds"
replace cat = "Dining" if des == "Shake Shack"
replace cat = "Dining" if des == "Honey Grow"
replace cat = "Dining" if des == "Fed Reserve"
replace cat = "Dining" if des == "Starbucks"
replace cat = "Dining" if des == "Wawa"
replace cat = "Dining" if des == "Panera"
replace cat = "Dining" if des == "Dunkin"
replace cat = "Dining" if des == "Chipotle"
replace cat = "Dining" if des == "Caviar"
replace cat = "Dining" if des == "El Fuego"
replace cat = "Dining" if des == "Vending Machine"
replace cat = "Dining" if des == "CLEO CUISINE NEW ORLEANS LA"
replace cat = "Dining" if des == "ATWOOD CHICAGO IL"
replace cat = "Dining" if des == "POPEYE`S PHILADELPHIA PA"
replace cat = "Dining" if des == "6844 CITY FITNESS"
replace cat = "Dining" if des == " CASA DEL BARCO RICHMOND VA"
replace cat = "Dining" if des == " 521 BISCUITS & WA RICHMOND VA"
replace cat = "Dining" if des == "FAMOUS 4TH STREET DELI PHILADELPHIA PA"
replace cat = "Dining" if des == "Insomnia"
replace cat = "Dining" if des == "Taco Bell" 
replace cat = "Dining" if des == "MAXS ON BROAD RICHMOND VA"
replace cat = "Dining" if des == "CRY BABY PASTA PHILADELPHIA PA"
replace cat = "Dining" if des == "SLICE"
replace cat = "Dining" if strpos(lower(des), "cry baby") > 0
replace cat = "Dining" if strpos(lower(des), "two boots") > 0
replace cat = "Dining" if strpos(lower(des), "strangeloves") > 0
replace cat = "Dining" if strpos(lower(des), "diner") > 0
replace cat = "Dining" if strpos(lower(des), "chick-fil-a") > 0
replace cat = "Dining" if strpos(lower(des), "cavanaugh's rittenhouse") > 0
replace cat = "Dining" if strpos(lower(des), "grubhub") > 0
replace cat = "Dining" if strpos(lower(des), "doordash") > 0
replace cat = "Dining" if strpos(lower(des), "uncle bill") > 0
replace cat = "Dining" if strpos(lower(des), "scoop deville") > 0
replace cat = "Dining" if strpos(lower(des), "emmy squared") > 0
replace cat = "Dining" if strpos(lower(description), "di bruno ") > 0
replace cat = "Dining" if strpos(lower(description), "mud city crab") > 0
replace cat = "Dining" if strpos(lower(description), "7-eleven") > 0
replace cat = "Dining" if strpos(lower(description), "hungry pigeon") > 0
replace cat = "Dining" if strpos(lower(description), "franklin fountain") > 0
replace cat = "Dining" if strpos(lower(description), "lobster house") > 0
replace cat = "Dining" if strpos(lower(description), "auntie annes") > 0
replace cat = "Dining" if strpos(lower(description), "vip market") > 0
replace cat = "Dining" if strpos(lower(description), "la fontana della") > 0
replace cat = "Dining" if strpos(lower(description), "talulas garden") > 0
replace cat = "Dining" if strpos(lower(description), "square pie") > 0
replace cat = "Dining" if strpos(lower(description), "restphiladelphia") > 0
replace cat = "Dining" if strpos(lower(description), "pretzel") > 0
replace cat = "Dining" if strpos(lower(description), "one world cafe") > 0
replace cat = "Dining" if strpos(lower(description), "giorgio") > 0
replace cat = "Dining" if strpos(lower(description), "cleavers") > 0
replace cat = "Dining" if strpos(lower(description), "bagel") > 0
replace cat = "Dining" if strpos(lower(description), "biscuit") > 0
replace cat = "Dining" if strpos(lower(description), "auntie anne") > 0
replace cat = "Dining" if strpos(lower(description), "porta at") > 0
replace cat = "Dining" if des == "AplPay  OVER EASFLAGSTAFF           AZ"
replace cat = "Dining" if des == "BARONE S TUSCANMOORESTOWN          NJ"




replace cat = "Health Care" if des == "CVS"
replace cat = "Health Care" if des == "Walgreens"
replace cat = "Health Care" if des == "Rite Aid"
replace cat = "Health Care" if des == "RMG MOORESTOWN MAIN STREET"

replace cat = "Grocery" if des == "Trader Joes"
replace cat = "Grocery" if des == "Acme"
replace cat = "Grocery" if des == "GIANT HEIRLOOM MARKET"
replace cat = "Grocery" if strpos(lower(des), "moms organic") > 0
replace cat = "Grocery" if strpos(lower(des), "moms of center city") > 0
replace cat = "Grocery" if des == "Iovine Brothers"
replace cat = "Grocery" if des == "BOYARS FOOD MARKET OCEAN CITY NJ"
replace cat = "Grocery" if des == "GREAT SCOT'S RITTENH PHILADELPHIA PA"
replace cat = "Grocery" if des == "SOUTH SQUARE MARKET"
replace cat = "Grocery" if des == "THE FRESH GROCER OF GRAYS FERRY"
replace cat = "Grocery" if des == "Wegmans"
replace cat = "Grocery" if des == "Whole Foods"
replace cat = "Grocery" if strpos(lower(des), "shoprite") > 0
replace cat = "Grocery" if strpos(lower(des), "nutty novelties") > 0
	

replace cat = "Dry Clean" if strpos(lower(des), "cleaners") > 0 

replace cat = "Entertainment" if des == "OMEN PSYCHIC PARLOR AN"
replace cat = "Entertainment" if des == "Fandango"
replace cat = "Entertainment" if des == "TickPick"
replace cat = "Entertainment" if des == "SM CASINO CS629"
replace cat = "Entertainment" if des == "PTIBEYOND THE BELL"
replace cat = "Entertainment" if des == "COLONIALSHOOTING ACADE RICHMOND VA"
replace cat = "Entertainment" if des == "NAT AQUA WEB 410-576-2296 MD"
replace cat = "Entertainment" if des == "FEVER USA* CANDLELIGHT 6467817359 NY"

	
replace cat = "Travel" if des == "Uber"
replace cat = "Travel" if des == "Lyft"
replace cat = "Travel" if des == "Taxi"
replace cat = "Travel" if des == "Patco"
replace cat = "Travel" if des == "Expedia"
replace cat = "Travel" if des == "American Test"
replace cat = "Travel" if des == "ZG *ZILLOWRENTALS 206-516-2265 WA"
replace cat = "Travel" if des == "Indego Bike"
replace cat = "Travel" if des == "LIME US"
replace cat = "Travel" if des == "AplPay LIM*RIDE COSTSAN FRANCISCO       CA"

replace cat = "Travel" if des == "BICYCLE TRANSIT"

replace cat = "Work" if des == "Expedia" & amount == 394
replace cat = "Work" if description == "EXPEDIA 7409582305272" 
replace cat = "Work" if des == "HYATT ATLANTA MIDTOWN"
replace cat = "Work" if des == "MAGNOLIA HOTEL DALLAS"
replace cat = "Work" if des == "Lyft" & date == date("20200127","YMD")
replace cat = "Work" if cat == "Dining" & date == date("20200127","YMD")
replace cat = "Work" if cat == "Dining" & date == date("20200128","YMD")
replace cat = "Work" if cat == "Dining" & date == date("20200129","YMD")
replace cat = "Work" if cat == "Dining" & date == date("20200130","YMD")
replace cat = "Work" if cat == "Dining" & date == date("20200131","YMD")
replace cat = "Work" if des == "Taxi" & date == date("20200131","YMD")
replace cat = "Work" if des == "Lyft" & date == date("20200201","YMD")
replace cat = "Work" if des == "HILTON HOTELS" & date == date("20200131","YMD")
replace cat = "Work" if strpos(lower(des), "killabee gaming") > 0
	
replace cat = "Work" if des == "Lyft" & date == date("20200127","YMD")
replace cat = "Merchandise" if des == "Fed Reserve" & amount == 113 
replace cat = "Merchandise" if des == "Amazon"
replace cat = "Merchandise" if des == "Five Below"
replace cat = "Merchandise" if des == "MANOS CRUCENAS"
replace cat = "Merchandise" if cat == "Shopping"
replace cat = "Merchandise" if strpos(lower(des), "five ultimate") > 0
replace cat = "Merchandise" if des == "SP * THE OUTRAGE WASHINGTON DC"
replace cat = "Merchandise" if des == "IKEA.COM 329669835 8884344532 MD"
replace cat = "Merchandise" if des == "RT 72 BUY RITE MANAHAWKIN NJ"
replace cat = "Merchandise" if des == "PARADIES #9535 PHL PHILADELPHIA PA"
replace cat = "Merchandise" if des == "CLOVE BRAND, INC."
replace cat = "Merchandise" if des == "PAUL FREDRICK SHIRT CO"
replace cat = "Merchandise" if strpos(lower(des), "allbirds") > 0
replace cat = "Merchandise" if strpos(lower(des), "speck hq") > 0
replace cat = "Merchandise" if strpos(lower(des), "ridge wallet") > 0
replace cat = "Merchandise" if strpos(lower(des), "rittenhouse hardware") > 0
replace cat = "Merchandise" if strpos(lower(des), "clarksusa") > 0
replace cat = "Merchandise" if strpos(lower(des), "macys") > 0
replace cat = "Merchandise" if strpos(lower(des), "lululemon") > 0
replace cat = "Merchandise" if strpos(lower(des), "ta dah") > 0
replace cat = "Merchandise" if cat == "Home Improvement"
replace cat = "Merchandise" if des == "SP * STONKSGOUP.MONEY 856-313-7346 PAAPPLE PAY ENDING IN 0585"


replace cat = "Other" if  strpos(lower(des), "blokes") > 0
replace cat = "Other" if  des == "Great Clips"

replace cat = "Other" if des == "NEW ORLEANS AIRPORT"
replace cat = "Other" if des == "UPS"
replace cat = "Other" if cat == "Other-Charities"
replace cat = "Other" if cat == "Gifts & Donations"
replace cat = "Other" if des == "VENMO" 
replace cat = "Other" if des == "DAVID J. MICHIE VIOLINS L"
replace cat = "Other" if strpos(lower(des), "planned parenthood") > 0 
replace cat = "Other" if strpos(lower(des), "bluewhite") > 0 
replace cat = "Other" if strpos(lower(description), "change") > 0 
replace cat = "Other" if strpos(lower(des), "corporation for digital scholarship") > 0 
replace cat = "Other" if des == "EDIBLE ARRANGEMENTS" 
replace cat = "Other" if date == date("20201001","YMD") & strpos(lower(des), "bed bath") > 0 
replace cat = "Fee" if des == "Membership Fee"
replace cat = "Fee" if strpos(lower(des), "interest") > 0

replace cat = "Entertainment" if strpos(lower(des), "chess.com") > 0
replace cat = "Entertainment" if des == "PEEK.COM"
replace cat = "Entertainment" if des == "GRAND CANYON NATIONAL P GRAND CANYON AZ"



replace cat = "Services" if des == "AMSTAT.ORG"
replace cat = "Services" if des == "Microsoft"
replace cat = "Services" if des == "Wolfram Alpha"
replace cat = "Services" if des == "Apple"
replace cat = "Services" if des == "Chegg"
replace cat = "Services" if des == "Audible"
replace cat = "Services" if strpos(lower(des), "zotero") > 0
replace cat = "Services" if des == "Amazon" & round(amount,.01) == 13.77
replace cat = "Other" if des == "PEEK.COM" & round(amount,.01) == 109.18
replace cat = "Other" if strpos(lower(des), "groupon") > 0  & round(amount,.01) == 18.98

replace cat = "Merchandise" if des == "Apple" & category == "Merchandise & Supplies-Computer Supplies"
replace cat = "Merchandise" if des == "VENMO" & date == date("20191129" , "YMD")
replace cat = "Travel" if des == "VENMO" & date == date("20191113" , "YMD")
replace cat = "Travel" if des == "VENMO" & date == date("20191211" , "YMD")
replace cat = "Entertainment" if des == "VENMO" & date == date("20191230" , "YMD")
replace cat = "Travel" if des == "VENMO" & date == date("20200103" , "YMD")
replace cat = "School" if des == "JHU"
replace cat = "Health Care" if des == "Target" & date == date("20200516","YMD")
replace cat = "Health Care" if des == "Amazon" & date == date("20200724","YMD")
replace cat = "Other" if des == "PTI*BEYOND THE BELL SAN FRANCISCO       CA" & date == date("20200611","YMD")
replace cat = "Technology" if des == "Apple" & date == date("20200724", "YMD")
	drop if des == "Apple" & date == date("20200723", "YMD")	
	drop if des == "Payment" & date == date("20200723", "YMD")	
	drop if des == "AMEXTRAVEL CAR      800-297-2977        WA" & round(amount, 0.1) == 1520.9

replace cat = "Technology" if date == date("20200929","YMD") &  strpos(lower(des), "overstock") > 0 
replace cat = "Payment" if amount <0 
replace cat = "School" if strpos(lower(description), "university") > 0

replace amount = amount - 177 if des == "TickPick" & date == date("20200113" , "YMD")
sort des cat 

tab description if cat == "Work"
tab amount if des == "Expedia"

sort date

export excel using "stataspend.xlsx", sheet("Transactions") sheetreplace firstrow(variables)

*keep if date >= date("20200731","YMD")
sort date
order card date des cat amount

format des %30s
tab des if cat == ""
tab cat
STOP

gen subcat = ""
replace subcat = "Puerto Rico" if date >= date("20200214","YMD") & date <= date("20200217","YMD")
egen sumpr = sum(amount) if subcat == "Puerto Rico"

