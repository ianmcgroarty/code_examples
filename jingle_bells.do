

/*
forvalues i = 1/1000000  {
	sleep 300
	beep
	di `i'
}
*/ 
forvalues i = 1/2{
di `i'

beep  /* Jin - */ 
sleep 700
beep /* gle */ 
sleep 700
beep /* bells */
sleep 1400

beep  /* Jin - */ 
sleep 700
beep /* gle */ 
sleep 700
beep /* bells */
sleep 1500


beep  /* Jin - */ 
sleep 700
beep /* gle */ 
sleep 700
beep /* all */
sleep 1200
beep /* the */ 
sleep 600 
beep /* way */
sleep 800
stop
}
di "happy holidays"


