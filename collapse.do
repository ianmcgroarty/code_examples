use "C:\Users\c1imm01\Downloads\college.dta"  , clear

replace hour = . if hour == 35
collapse	(min) minhour=hour mingpa=gpa ///
			(max) maxhour=hour maxgpa=gpa ///
			(mean) avghour=hour avggpa=gpa, by(year) cw
			list
