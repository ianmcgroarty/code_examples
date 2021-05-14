  
  gen ogscrprs = origscore * presc_flag
  
  regress util origscore i.presc_flag  ogscrprs
  *regress util presc_flag##origscore /* Doesn't work */ 
  
  gen bk1prs = presc_flag * bank_flag1
  
  /* THESE ARE THE SAME (in groups)*/ 
	regress  util origscore presc_flag bank_flag1 bk1prs
	regress util origscore presc_flag##bank_flag1
	regress util origscore i.presc_flag##i.bank_flag1
	regress util origscore i.presc_flag bank_flag1 bk1prs
  
  regress util origscore presc_flag#bank_flag1
  
  regress util origscore presc_flag producttype  
  
  regress util origscore presc_flag i.producttype  
  regress util origscore presc_flag product_flag2 product_flag3 product_flag4 /* Same but the numbers don't match */ 
  
  regress util origscore presc_flag product_flag1 product_flag3 product_flag4
  regress util origscore presc_flag ib3.producttype  
 
 
 gen prspt1 = presc_flag * product_flag1
 gen prspt2 = presc_flag * product_flag2
 gen prspt3 = presc_flag * product_flag3
 gen prspt4 = presc_flag * product_flag4

  
  regress util origscore presc_flag i.producttype prspt2 prspt3 prspt4
  regress util origscore presc_flag##producttype , coeflegend
 
 