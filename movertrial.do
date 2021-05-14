clear
import excel "\\P1pdf221\c1\Shared\Group\PCC\Staff Folders\Ian\Nathan\Fraud\Code\moveblocks.xlsx", sheet("Sheet1") firstrow
rename C block00
rename D block10


* Gen indicator for first block10
bysort cid: gen first10 = block10 if block10 != . & block10[_n-1] ==.
br 

	** Apply to lifetime of cid
	bysort cid: egen mfblk = max(first10)
	
* gen indicator for the qtr in which the first block10 occurs
gen fqtr = qtr if first10 != . 
	** Apply to lifetime of cid
	bysort cid: egen mfqtr = max(fqtr)

* gen indicator for move
bysort cid: gen move = 1 if block00 != block00[_n-1] 
	* replace if it is the first cid
	replace move = . if cid != cid[_n-1]
	
* gen indicator for the move quarter 
gen moveqtr = qtr if move == 1
	** apply for the the lifetime of the cid
		** note the use of the min to get the first move
	bysort cid: egen mmvqtr = min(moveqtr)
	
	** I don't care if you moved after the block10 came into play
	replace mmvqtr = . if mmvqtr > mfqtr 	

* gen adjusted block00 
gen att1 = block00 if qtr < mmvqtr & mmvqtr != . 
	replace att1 = mfblk if att1 == . 
	replace att1 = block10 if block10 !=. 


count if want != att1
drop first10 first10 fqtr mfqtr move moveqtr mmvqtr mfblk
