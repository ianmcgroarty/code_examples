cap putpdf  clear
putpdf begin
putpdf paragraph, halign(center)

clear
set obs 100
gen obs = _n
gen v1 = "h"
gen v2 = obs * 3.14
gen v3 = sqrt(obs)
lab var v3 "squart root"
ds , d
di r(varlist)



putpdf save "\\rb.win.frb.org\C1\Accounts\M-O\c1imm01\Redirected\Desktop\Data\Code\putpdf.pdf", replace




sysuse auto, replace

// Create a paragraph
putpdf paragraph
putpdf text ("putpdf "), bold
putpdf text ("can add formatted text to a paragraph.  You can ")
putpdf text ("italicize, "), italic
putpdf text ("striketout, "), strikeout
putpdf text ("underline"), underline
putpdf text (", sub/super script")
putpdf text ("2 "), script(sub)
putpdf text (", and   ")
putpdf text ("bgcolor"), bgcolor("blue")
qui sum mpg
local sum : display %4.2f `r(sum)'
putpdf text (".  Also, you can easily add Stata results to your paragraph (mpg total = `sum')")

// Embed a graph
histogram rep
graph export hist.png, replace
putpdf paragraph, halign(center)
putpdf image hist.png

// Embed Stata output
putpdf paragraph
putpdf text ("Embed the output from a regression command into your pdf file.")
regress mpg price
putpdf table mytable = etable

// Embed Stata dataset
putpdf paragraph
putpdf text ("Embed the data in Stata's memory into a table in your pdf file.")
statsby Total=r(N) Average=r(mean) Max=r(max) Min=r(min), by(foreign): summarize mpg
rename foreign Origin
putpdf table tbl1 = data("Origin Total Average Max Min"), varnames  ///
        border(start, nil) border(insideV, nil) border(end, nil)


		
		
		
stop		
tab bankid prescreen , matcell(bankps)
putpdf table tb5 = matrix(bankps) , rownames colnames nformat(%11.0gc)
putpdf table tb5(.,3), addcols(1)
putpdf table tb5(1,4) = ("Total") 


  forvalues j=1/13 {
	local blbl: label(bankid)`j'
	local row = `j' + 1
	putpdf table tb5(`row',1) = (`"`blbl'"')
	
forvalues i = 0/1 {
	local clbl: label(prescreen)`i'
	  local colm = `i' + 2
	  putpdf table tb5(1,`colm') = (`"`clbl'"')
	
	global freq`row' = bankps[`j', `i'+1]
	 global cumul`row' = ${cumul`row'}  + ${freq`row'}
	  putpdf table tb5(`row', 4) = ("${cumul`row'}") , nformat(%11.0gc)
	}
}
