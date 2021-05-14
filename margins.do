*set the code paths
adopath + "..\ado"
which vincenty
which coefplot
which outreg2
which estout
adopath 
set more off


/**** REFERENECES ****
https://stats.idre.ucla.edu/stata/faq/how-can-i-identify-cases-used-by-an-estimation-command-using-esample/
https://www3.nd.edu/~rwilliam/stats/Margins01.pdf
https://www.stata.com/meeting/germany13/abstracts/materials/de13_jann.pdf
https://www.stata.com/manuals13/rmargins.pdf
http://repec.sowi.unibe.ch/stata/coefplot/estimates.html#h-6
http://repec.sowi.unibe.ch/stata/coefplot/getting-started.html#h-4
http://repec.sowi.unibe.ch/stata/coefplot/help-file.html#stlog-1-ciopts
*/ 


*******************************************************************
* The data is too big to wait for margins so this will trim it down
*******************************************************************
/*
use "\\rb.win.frb.org\C1\Shared\Group\PCC\Staff Folders\Ian\Tom\Data\regdat_5pctsample.dta" , clear

global yvars util simpleprofit cycleendbal purchasevolume sumfees sumfees_noan  ///
  newrewards princechargeoff revolvingbalance intexprofit financecharge  ///
  cumfees cumfeesnoan cumfc cumpcharge cumprofit cumintprofit cumpv allrc revolverflag 

 global morecont bank_flag2-bank_flag11 hyflag1-hyflag2 hyflag4-hyflag12 ///
	origscore_reg cycleendingretailapr cobrand firstincome_reg promotionflag ///
	annfeeflag regionflag2-regionflag8 newrewardflag mrlim_reg oscorevers_flag* ///
	pre_origscore pre_apr  pre_cobr pre_inc pre_promo pre_annfee pre_rew pre_lim 
  
 keep maturity_nmon matfg* regionflag* bank_flag* hyflag* prescreened loanid cid banknm bankid $yvars  $morecont
 
* drop hyflag* bank_flag* oscorevers_flag* regionflag*
 sample 20 
save "\\rb.win.frb.org\C1\Shared\Group\PCC\Staff Folders\Ian\Tom\Data\regdat_5pct_novars.dta", replace
*/
********************************************************** 
/* LEGGO */ 
********************************************************** 
use "\\rb.win.frb.org\C1\Shared\Group\PCC\Staff Folders\Ian\Tom\Prescreen\Data\regdat_5pct_novars.dta"  , clear

global yvars util simpleprofit cycleendbal purchasevolume sumfees sumfees_noan  ///
  newrewards princechargeoff revolvingbalance intexprofit financecharge  ///
  cumfees cumfeesnoan cumfc cumpcharge cumprofit cumintprofit cumpv allrc revolverflag 

 global morecont bank_flag2-bank_flag11 hyflag1-hyflag2 hyflag4-hyflag12 ///
	origscore_reg cycleendingretailapr cobrand firstincome_reg promotionflag ///
	annfeeflag regionflag2-regionflag8 newrewardflag mrlim_reg oscorevers_flag* ///
	pre_origscore pre_apr  pre_cobr pre_inc pre_promo pre_annfee pre_rew pre_lim 
  
 keep maturity_nmon matfg* regionflag* bank_flag* hyflag* prescreened loanid cid banknm bankid $yvars  $morecont
 
********************************************************** 
/* Goal 1: See differences in the way I calculate the predicted value v.s. stata's method */ 
********************************************************** 
local dropvars predbal predbal_esample samplebal balnomiss boscore bpres bo pbal pbal_esample
foreach var in `dropvars' {
cap drop `var'
}

regress cycleendbal origscore prescreened
	predict predbal
		predict predbal_esample if e(sample) == 1
		gen samplebal = cycleendbal if e(sample)==1
		gen balnomiss = cycleendbal if origscore != .
	*ereturn list
	*matrix list e(b)
	
* These are my coefficients 
	gen boscore = _b[origscore]
	gen bpres = _b[prescreened]
	gen bo = _b[_cons]
	
* Do the model by hand
	gen pbal = bo + (boscore*origscore) + (bpres*presc)
	gen pbal_esample = pbal if e(sample) == 1

* Results
	sum cycleendbal pbal predbal balnomiss samplebal predbal_esample pbal_esample
		* pbal and predbal are exactly the same!!
		* esample is the same as nomiss
		* even if cycleendbal is missing there is still a pbal
		* balnomiss is missing becuase cycleendbal is missing
		* if bal is missing it is not in the e(sample)
		* e(sample)==0 if cycleendbal == . | origscore == . 
	drop pbal predbal balnomiss samplebal predbal_esample pbal_esample 

**********************************************************
/* Goal 2: relationships more closely with interactions */
********************************************************** 
local dropvars balmeanpre scoremeanpre balmeanita scoremeanita balmeantot scoremeantot int_osc_pre int_osc_ita
foreach var in `dropvars' {
cap drop `var'
}
order cycleendbal origscore prescreened boscore bpres
	
** Gain understanding of averages
	sum cycleendbal origscore if prescreened == 1
		qui sum cycleendbal if prescreened == 1
			qui gen balmeanpre = r(mean)
		qui sum origscore if prescreened == 1
			qui gen scoremeanpre = r(mean)
	sum cycleendbal origscore if prescreened == 0
		qui sum cycleendbal if prescreened == 0
			qui gen balmeanita = r(mean)
		qui sum origscore if prescreened == 0
			qui gen scoremeanita = r(mean)
	sum cycleendbal origscore
			egen balmeantot = mean(cycleendbal)
			egen scoremeantot = mean(origscore)
			
	regress cycleendbal prescreened
		* The constant is cycleendbal average if prescreened == 0
		* b0 + b1 is the cycleendbal average if prescreened == 1

** Gain understanding of averages with other term
	regress cycleendbal origscore prescreened 
		di (scoremeanpre * _b[origscore])  + _b[_cons] + _b[prescreened]  
		di (scoremeantot * _b[origscore])  + _b[_cons] + _b[prescreened]  /* This one */
			sum cycleendbal origscore if e(sample) & prescreened == 1
	/* This one uses average of origscore for the whole sample and is very close 
				to the cycleendbal if prescreened == 1 */ 
	
** Gain understanding of factor variables	
	** Define interaction terms
		gen int_osc_pre = 0 
			replace int_osc_pre = origscore if prescreened == 1
		gen int_osc_ita = 0 
			replace int_osc_ita = origscore if prescreened == 0
		
	** These three regressions are equivalent but they display difference coefficients
		regress cycleendbal c.origscore##prescreened 
		*regress cycleendbal origscore prescreened int_osc_pre
		*regress cycleendbal prescreened int_osc_pre int_osc_ita
	
** Understand Sums and Factor variables (with interactions)
	regress cycleendbal c.origscore##prescreened 
		di (scoremeanpre * _b[origscore])  + _b[_cons] + _b[1.prescreen] + (1.prescreened#c.origscore*scoremeanpre )
		di (scoremeantot * _b[origscore])  + _b[_cons] + _b[1.prescreen] + (1.prescreened#c.origscore *scoremeantot)
		di (scoremeantot * _b[origscore])  + _b[_cons]
			/* This works similarly to above. The average score for the full 
				sample gets the best estimates. But the ITA estimates are not great.  */
			*sum cycleendbal if e(sample) & prescreened == 0
********************************************************** 
/* Goal 3: Understand Margins Command */ 
********************************************************** 
local dropvars pbal_scoreint boscore2 bopre2 bosc_pre2 bo2 balhat bal_allpre bal_allita 
foreach var in `dropvars' {
cap drop `var'
}
	* Exactly
		regress cycleendbal prescreened
		margins, at(prescreened=(0 1))
			* This gives the exact means for cycleend balance

	* With Interaction
		regress cycleendbal c.origscore##i.prescreened 
			predict pbal_scoreint
			* The following margins are equivalent
				margins, at(prescreened=(0 1))
				*margins prescreened
				*margins prescreened , atmeans
					/* These are about the results of the regression but not exactly
						I'm not quite sure how the interaction changes this... */ 
		
	* Coefficients
		gen boscore2 = _b[origscore]
		gen bopre2 = _b[1.prescreened]
		gen bosc_pre2 = _b[1.prescreened#c.origscore]
		gen bo2 = _b[_cons]
		
	* Model... 
		gen balhat = bo2 + boscore2*origscore + bopre2*prescreened + bosc_pre2*prescreened*origscore
		tabstat pbal_scoreint balhat , by(prescreened) 
			* still the same 
		
		* Compute the model if everyone is prescreened/ITA but everything else is the same
			gen bal_allpre = bo2 + boscore2*origscore + bopre2 + bosc_pre2*origscore	
			gen bal_allita = bo2 + boscore2*origscore 

			tabstat bal_allpre bal_allita balhat , by(prescreened) 
				* We are pretty close to the margins output but not exactly....
			tabstat bal_allpre bal_allita balhat if e(sample)==1, by(prescreened) 
				* GOT IT! - so the total averages match the margins

	
********************************************************
* Goal 7: Understanding Adjust -- DEPRECIATED
********************************************************				
			regress cycleendbal origscore prescreened 
				cap drop balhat
				predict balhat
			tabstat balhat , stat(mean) by(prescreened)
			*adjust , by(prescreened)

				
********************************************************** 
/* Goal 4: Add a Second Dummy Variable  */ 
**********************************************************  
local dropvars int_prefee mod3 boscore3 bpres3 bannfee3 bosc_pres3 bfee_pres3 bo3 ///
	balhat3 balhat3_pre balhat3_ita balhat3_preann
foreach var in `dropvars' {
cap drop `var'
}		
	gen int_prefee = annfeeflag*prescreened 
	
	regress cycleendbal i.prescreened##(c.origscore annfeeflag) 
		predict mod3 
	
	* Margins 
		margins  annfeeflag , at(prescreened=(0 1))
	
	* Coefficients 
		gen boscore3 = _b[origscore]
		gen bpres3 = _b[1.prescreened] 
		gen bannfee3 = _b[1.annfeeflag]
		gen bosc_pres3 = _b[1.prescreened#c.origscore]
		gen bfee_pres3 = _b[1.prescreened#1.annfeeflag]
		gen bo3 = _b[_cons]
	
	* Model
		gen balhat3 = bo3 + boscore3*origscore + bpres3*prescreen + bannfee3*annfeeflag ///
					+ bosc_pres3*origscore*prescreen + bfee_pres3*annfeeflag*prescreen 		
		gen balhat3_pre = bo3 + boscore3*origscore + bpres3 + bannfee3*annfeeflag ///
					+ bosc_pres3*origscore + bfee_pres3*annfeeflag
		gen balhat3_ita = bo3 + boscore3*origscore + bannfee3*annfeeflag 
		
		gen balhat3_preann = bo3 + boscore3*origscore + bpres3 + bannfee3 ///
					+ bosc_pres3*origscore + bfee_pres3 		
		
		tabstat mod3 balhat3 balhat3_pre balhat3_ita balhat3_preann if e(sample)==1 , by(prescreened)
			* This is still fine. It works the same. Just assume everyone is prescreen & has an annual fee.			
			
********************************************************** 			
/* Goal 5: Master Margins Plot */ 
********************************************************** 
		regress cycleendbal i.prescreened##(c.origscore annfeeflag maturity_nmon) 
			eststo regtable
			margins  annfeeflag , at(prescreened=(1))
			margins  annfeeflag , at(prescreened=(0))
			margins  annfeeflag , at(prescreened=(0 1)) post 
				eststo annfee_margin
				esttab annfee_margin
			
		
coefplot (annfee_margin, keep(2.*) label(Prescreen)) ///
			(annfee_margin, keep(1.*) label(ITA)) , ///
			vertical
			
********************************************************** 			
/* Goal 6: With Maturity Month Dummies */ 
********************************************************** 
	regress cycleendbal i.prescreened##(ib3.maturity_nmon c.origscore) 
		margins maturity_nmon , at(prescreened=(0 1)) post 
			eststo bal_margin
			

coefplot (bal_margin, keep(2.*) label(Prescreen) lcolor(orange) mcolor(orange) ciopts(recast(rarea) col(orange%40))) ///
			(bal_margin, keep(1.*) label(ITA) lcolor(midblue) mcolor(midblue) ciopts(recast(rarea) col(midblue%40))) , ///
			vertical recast(connected) nooffsets ///
			title("Predictions (Margins)") ytitle("`: variable label `var''") xtitle("Maturity") ///
        note("Controls: (Most Recent Credit Limit), BankFlag, OrigHY, OrigScore, APR," ///
              "Rewards, CoBrand, First Income, Promo, AnnFee." ///
              "Omit: Maturty Month 3, AXP, HY1-2014 , Far West") /// 
			rename(^1._at#([0-9]+).maturity_nmon$ = 2._at#\1.maturity_nmon , regex) ///
			coeflabels( ///
			*1.* = " " 2._at#2.maturity_nmon = " " *3.*= " " *4.*= " " *5.*= "5" ///
			*6.* = " "  *7.*= " " *8.*= " "  *9.*= " "  *10.*= "10" /// 
			*11.*= " " *12.*= " " *13.*= " " *14.*= " " *15.*= "15" /// 
			*16.*= " " *17.*= " " *18.*= " " *19.*= " " *20.*= "20" /// 
			*21.*= " " *22.*= " " *23.*= " " *24.*= " " *25.*= "25" /// 
			*26.*= " " *27.*= " " *28.*= " " *29.*= " " *30.*= "30" /// 
			*31.*= " " *32.*= " " *33.*= " " *34.*= " " *35.*= "35" /// 
			*36.*= " " *37.*= " " *38.*= " " *39.*= " " *40.*= "40" /// 
			*41.*= " " *42.*= " " *43.*= " " *44.*= " " *45.*= "45" /// 
			*46.*= " " *47.*= " " *48.*= " " *49.*= " " *50.*= "50" /// 
			*51.*= " " *52.*= " " *53.*= " " *54.*= " " *55.*= "55" /// 
			*56.*= " " *57.*= " " *58.*= " " *59.*= " " *60.*= "60" )
			
			
			
*** Things to consider ***
** Treat all factor variables as balanced????
** No esample????
** over? 

********************************************************
* I just make sure I can esttab using interactions 	
********************************************************
	
 global morecont bank_flag2-bank_flag11 hyflag1-hyflag2 hyflag4-hyflag12 ///
	 regionflag2-regionflag8 oscorevers_flag* 
	
	global intconts c.origscore_reg c.cycleendingretailapr cobrand c.firstincome_reg ///
						promotionflag annfeeflag newrewardflag c.mrlim_reg 
  

	
	qui regress cycleendbal i.prescreened##(c.origscore annfeeflag maturity_nmon) 
			eststo regtable
	 qui reg cycleendbal matfg2-matfg60 $morecont $intconts if prescreened == 1
          	  eststo prescr_m0_bal
	qui reg cycleendbal prescreened##(ib3.maturity_nmon ib1275216.bankid $intconts) $morecont 
				  eststo model2
				  			
	
	lab var prescreened "Presc"
	lab define pre2 0 "ITA" 1 "Presc" ,replace
	lab val prescreened pre2
	
				esttab prescr_m0_bal model2 , wide label ///
				drop(*maturity_nmon 0.* bank_flag* regionflag* matfg* hyflag* oscorevers* *bankid _cons 1.prescreened#0.*) ///
				rename(1.cobrand cobrand 1.promotionflag promotionflag 1.annfeeflag annfeeflag 1.newrewardflag newrewardflag )

			
				
***********************************************************************
* I want to preserve this method of plotting fitted values just in case
***********************************************************************
	cap drop pbal_pre pbal_ita 
	
	* Do the regression to get the predictions
		qui reg cycleendbal matfg2-matfg60 $morecont $intconts if pre == 1
			predict pbal_pre
		qui reg cycleendbal matfg2-matfg60 $morecont $intconts if pre == 0	
			predict pbal_ita
		
	* Get the average prediction for each month 
		qui reg pbal_pre matfg2-matfg60 , noconstant
			eststo avgpbal_pre
		qui reg pbal_ita matfg2-matfg60 , noconstant
			eststo avgpbal_ita
			
	* Coefplot 
		coefplot (avgpbal_pre , lcolor(orange)  mcolor(orange)  ciopts(recast(rarea) col(orange%40))) ///
               (avgpbal_ita   , lcolor(midblue) mcolor(midblue) ciopts(recast(rarea) col(midblue%40))) , ///
        keep(matfg*)   yscale(titlegap(*20)) ///
          vertical recast(connected) offset(0)  legend(order(4 "ITA" 2 "Prescreen")) ///
          title("Predicted Averages") ytitle("`: variable label `var''") xtitle("Maturity") ///
          note("Controls: (Most Recent Credit Limit), BankFlag, OrigHY, OrigScore, APR," ///
                "Rewards, CoBrand, First Income, Promo, AnnFee." ///
                "Omit: Maturty Month 3, AXP, HY1-2014 , Far West") ///
        coeflabels ( ///
          matfg1  = "1"  matfg2  = " " matfg3  = " "  matfg4  = " " matfg5 = "5"  ///
          matfg6  = " "  matfg7  = " " matfg8  = " "  matfg9  = " " matfg10 = "10" ///
          matfg11 = " "  matfg12 = " " matfg13 = " "  matfg14 = " " matfg15 = "15" ///
          matfg16 = " "  matfg17 = " " matfg18 = " "  matfg19 = " " matfg20 = "20" ///
          matfg21 = " "  matfg22 = " " matfg23 = " "  matfg24 = " " matfg25 = "25" ///
          matfg26 = " "  matfg27 = " " matfg28 = " "  matfg29 = " " matfg30 = "30" ///
          matfg31 = " "  matfg32 = " " matfg33 = " "  matfg34 = " " matfg35 = "35" ///
          matfg36 = " "  matfg37 = " " matfg38 = " "  matfg39 = " " matfg40 = "40" ///
          matfg41 = " "  matfg42 = " " matfg43 = " "  matfg44 = " " matfg45 = "45" ///
          matfg46 = " "  matfg47 = " " matfg48 = " "  matfg49 = " " matfg50 = "50" ///
          matfg51 = " "  matfg52 = " " matfg53 = " "  matfg54 = " " matfg55 = "55" ///
          matfg56 = " "  matfg57 = " " matfg58 = " "  matfg59 = " " matfg60 = "60" )
	
	
	
	
	
*************************************
*** Efficient margins ***************
use "\\rb.win.frb.org\C1\Shared\Group\PCC\Staff Folders\Ian\Tom\Data\regdat_5pct_novars.dta"  , clear

*regress cycleendbal c.origscore##i.prescreened 

 global morecont bank_flag2-bank_flag11 hyflag1-hyflag2 hyflag4-hyflag12 ///
	origscore_reg cycleendingretailapr cobrand firstincome_reg promotionflag ///
	annfeeflag regionflag2-regionflag8 newrewardflag mrlim_reg oscorevers_flag* ///
	pre_origscore pre_apr  pre_cobr pre_inc pre_promo pre_annfee pre_rew pre_lim 
  
global yvars util simpleprofit cycleendbal purchasevolume sumfees sumfees_noan  ///
  newrewards princechargeoff revolvingbalance intexprofit financecharge  ///
  cumfees cumfeesnoan cumfc cumpcharge cumprofit cumintprofit cumpv allrc revolverflag 

  
	qui reg  util prescreened##(ib3.maturity_nmon ib1275216.bankid)  
			
			
			
esttab using "margins_coefficients.csv", replace nostar wide 
import delimited "margins_coefficients.csv", clear  delimiter(`"=","')
br



	
	
	
	
	
	
	
	
	
	
	
	
	
