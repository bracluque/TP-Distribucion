* sim-secc.do

args nombre

gen sampsel = 1 if sampocup==1 & edad>=18 


* start: sim changes in determinants of occup categ: secc 

clonevar prii_aux = prii
clonevar pric_aux = pric
clonevar seci_aux = seci
clonevar secc_aux = secc
clonevar supi_aux = supi
clonevar supc_aux = supc
   
replace secc = 1 if (prii == 1 | pric == 1 | seci == 1) & sampsel==1 
replace prii = 0 if prii == 1 & sampsel==1
replace pric = 0 if pric == 1 & sampsel==1 
replace seci = 0 if seci == 1 & sampsel==1 


* start: modificar ocup

matrix score xlambda21_sim = lambda21
matrix score xlambda31_sim = lambda31
		
gen delta_u21_sim = xlambda21_sim + r21_cal
gen delta_u31_sim = xlambda31_sim + r31_cal
	
gen ocup_sim = .
replace ocup_sim = 1 if (delta_u21_sim<=0) & (delta_u31_sim<=0)  
replace ocup_sim = 2 if (delta_u21_sim>0) & (delta_u31_sim<=delta_u21_sim)  
replace ocup_sim = 3 if (delta_u21_sim<=delta_u31_sim) & (delta_u31_sim>0)  



drop xlambda?1_sim delta_u?1_sim 


tabulate ocup ocup_sim if sampocup==1

* end: modificar ocup




drop prii pric seci secc supi supc

rename (prii_aux pric_aux seci_aux secc_aux supi_aux supc_aux) ///
  (prii pric seci secc supi supc)

* end:  sim changes in determinants of occup categ: secc 







* start: simulate labor incomes





* generate dummy variables from ocup
tabulate ocup_sim, generate(ocupdum_sim)

* rename original ocupdum
rename (ocupdum?) (ocupdum?_aux)

* rename sim ocupdum
rename (ocupdum_sim?) (ocupdum?)


* compute labor income
include "${dofile}\punto3/genera-ing-laboral.do"



* overwrite ila_sim for individual in the same ocup
replace ila_`nombre' = ila if ocup_sim == ocup

* overwrite ila_sim for individuals that do not work
replace ila_`nombre' = . if ocup_sim==1 & sampsel==1



* rename to original variable names
drop ocupdum?
rename (ocupdum?_aux) (ocupdum?)




* end: simulate labor incomes


* start: simulate household incomes and consumption


* compute household income 
include "${dofile}\punto3/genera-ing-familiar.do" 



* end: simulate household incomes and consumption


rename ocup_sim occup_`nombre'



* start: cleaning

drop sampsel

* end: cleaning
