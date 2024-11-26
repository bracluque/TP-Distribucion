* estimate-occup.do


* dependent variable
local yvar = "ocup"

* independent variables
local xvar ///
  edad edad2 pric seci secc supi supc hombre jefe miembros casado 

  
  
* start: estimate mlogit  for occup choice
  
* multinominal logit
mlogit `yvar' `xvar' [pw=pondiio] if muestra==1, baseoutcome(1)

* compute average marginal effects
//margins, dydx(_all) 




matrix lambda = e(b)
matrix list lambda
matrix lambda21 = lambda[1,"2:"]
matrix lambda31 = lambda[1,"3:"]
gen sampocup = 1 if e(sample)

* generate linear prediction for occup	
matrix score xlambda21 = lambda21 
matrix score xlambda31 = lambda31 

* end: estimate mlogit for occup choice




* start: occup choice error calibration

* sort individuals so that results can be replicated
sort rnd

* init error and intermediate variables
gen r21_cal   = .
gen r31_cal   = .
gen draw_e1   = .
gen draw_e2   = .
gen draw_e3   = .
gen r21       = .
gen r31       = .
gen delta_u21 = .
gen delta_u31 = .
gen y_sim     = .




* init exit condition for while loop
gen cal = 0
* exclude obs with sampocup=0
replace cal = 1 if sampocup!=1
count if cal == 0
* non-calibrated indiv
local tot = r(N) 
  
* init counter
local cnt = 0

  
while `tot' != 0 {
	
	local cnt = `cnt' + 1
			
*	generate errors
* errors have a doble exponential dist
  replace draw_e1 = - ln(-ln(1-runiform())) if cal==0
  replace draw_e2 = - ln(-ln(1-runiform())) if cal==0
  replace draw_e3 = - ln(-ln(1-runiform())) if cal==0

*	difference in errors wrt base category (1)
  replace r21 = draw_e2 - draw_e1 if cal==0
  replace r31 = draw_e3 - draw_e1 if cal==0

*	difference in utility wrt base cateogory (1)
  replace delta_u21 = xlambda21 + r21 if cal==0
  replace delta_u31 = xlambda31 + r31 if cal==0

*	simulate occupation choice
  replace y_sim = 1 if (delta_u21<=0) & (delta_u31<=0)        & cal==0
  replace y_sim = 2 if (delta_u21>0) & (delta_u31<=delta_u21) & cal==0 
  replace y_sim = 3 if (delta_u21<=delta_u31) & (delta_u31>0) & cal==0
  replace y_sim = . if sampocup==0
	
*	calibrated errors
* note: if indiv is calibrated (i.e., yvar=y_sim), need all residuals
  replace r21_cal = r21 if y_sim==`yvar' & cal==0  
  replace r31_cal = r31 if y_sim==`yvar' & cal==0

* cal=0 for calibrated indiv   
  replace cal = 1 if y_sim==`yvar' & cal==0

*	rule to exit the while loop: 
* exit when 99% of (relevant) indiv is calibrated  sum cal if sampocup==1
  sum cal if sampocup==1
  if 100*r(mean) > 95 {
  
    replace sampocup=0 if sampocup==1 & cal==0
    replace cal=1				
  
  }
  
*	count non-calibrated indiv
	count if sampocup==1 & cal==0
	local tot = r(N)
	
}

* end: occup choice error calibration




* to check
tabulate ocup y_sim if sampocup==1


* compute probabilities associated with each ocup categ
gen pr1 = exp(0)         / ( 1 + exp(xlambda21) + exp(xlambda31) ) 
gen pr2 = exp(xlambda21) / ( 1 + exp(xlambda21) + exp(xlambda31) )
gen pr3 = exp(xlambda31) / ( 1 + exp(xlambda21) + exp(xlambda31) )

* compute utilities
gen ut1 = 0
gen ut2 = xlambda21 + r21_cal 
gen ut3 = xlambda31 + r31_cal  

* to check2
gen y_sim2 =.
replace y_sim2=1 if ut1==max(ut1,ut2,ut3)
replace y_sim2=2 if ut2==max(ut1,ut2,ut3)
replace y_sim2=3 if ut3==max(ut1,ut2,ut3)

tabulate ocup y_sim2 if sampocup==1
