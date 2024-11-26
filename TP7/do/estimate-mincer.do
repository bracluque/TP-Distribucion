* estimate-mincer.do

* mincer equation 
/*
* note: 
ocupdum1 = not working -- not in mincer eq
ocupdum2 = wage worker
ocupdum3 = self-employed
*/
regress lila edad edad2 hombre pric seci secc supi supc ocupdum3 [w=pondiio] ///
  if muestra==1 & (ocup==2 | ocup==3)

* note: alt: if employed==1  

* store parameters from mincer eq
matrix beta = e(b)

* store estimates
estimate store mincer

* standard errors of residuals -- unobservables
local sigma = e(rmse)
display "sigma = " `sigma'

* mincer=1 for individuals in estimation sample
gen sampmincer=1 if e(sample)

* linear prediction of lila
//predict xbeta 
matrix score xbeta = beta


* residuals from mincer eq + unobservables for all observations 
gen resid = lila - xbeta if sampmincer==1
replace resid = rnormal(0,`sigma') if sampmincer!=1
