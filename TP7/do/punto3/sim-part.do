* sim-part.do

args nombre m_shk agemin agemax

* start: diagnostic shock

local n_rows=rowsof(`m_shk')
local n_cols=colsof(`m_shk')

if `n_rows' != $n_gender {
  display as error "error in number of rows"
  exit 198
} 

if `n_cols' != $n_ocup {
  display as error "error in number of columns" 
  exit 198
} 


* end: diagnostic shock

matrix define m_sim = `m_shk'

* row totals; to check = 1
matrix aux = m_sim*J(`n_cols',1,1)

gen sampsel = 1 if sampocup==1 & edad>=`agemin' & edad<=`agemax' 



* start: compute observed shares

preserve

version 16: table gender ocup [w=pondiio] if sampsel==1, replace 
reshape wide table1, i(gender) j(ocup)
egen tot = rowtotal(table1*)
forvalues i = 1(1)$n_ocup {
  gen shr`i' = table1`i'/tot
}
egen shrtot = rowtotal(shr*)

* matrix with observed shares
mkmat shr?, matrix(m_obs)

restore


* end: compute observed shares


* matrix with changes in shares
matrix define m_chg = m_sim - m_obs
matrix list m_chg



* start: single out individuals that change ocup

/*
Two cases:

  (1) ocup categ with share sim > share obs -> increase number of indiv
  (2) ocup categ with share sim < share obs -> decrease number of indiv
  
Thus, individuals with obs ocup categ under (1) should not move and individuals
with obs ocup under (2) should move.
*/


* tomove=1 for individuals in shrinking ocup's
gen tomove=.

forvalues i = 1(1)$n_gender {

  forvalues j = 1(1)$n_ocup {

    display as text "i (gender) = " as result `i' _newline as text "j (ocup) = " as result `j'

    summ pondiio if sampsel==1 & gender==`i', meanonly
    local obstot = r(sum)
    display as text "obtot = " as result `obstot'
     
    * sort individuals in sample according to rand
    gsort -sampsel gender ocup -pr`j' rnd
    
    gen shrpop = sum(pondiio) if sampsel==1 & gender==`i' & ocup==`j'
    replace shrpop = shrpop/`obstot'
    
    * show share in [gender,ocup]; should be the same as in m_obs
    summ shrpop, meanonly
    display as text "obs share in [i=`i',j=`j'] = " as result r(max) 
    
    * tomove=1 taking into account the lower bound in m_sim
    replace tomove=1 if shrpop > m_sim[`i',`j'] & shrpop!=.
    
    drop shrpop
    
  }
}

* end: single out individuals that change ocup




* start: change ocup for individuals with tomove=1

gen ocup_sim = .

forvalues i = 1(1)$n_gender {
  
  forvalues j = 1(1)$n_ocup {
  
    display as text "i (gender) = " as result `i' _newline as text "j (ocup) = " as result `j'
    
    * share sim > share obs -> ocup is expanding
    if m_sim[`i',`j'] > m_obs[`i',`j'] {

      display as text "gender = " as result `i' as text " ocup = " as result `j' as text " ... expanding"          
      
      * individuals in current [gender,ocup] do not move
      replace ocup_sim = ocup if gender==`i' & ocup==`j' & sampsel==1
      
/*      
      aux=1 for (ordered) indiv that might move to current ocup
      these are indiv with the following characteristics: 
      (1) ocup with share sim < share obs (shrinking ocup)
      (2) gender = current gender (i)
      (3) ocup != current ocup (j) 
      (4) have not moved yet (ocup_sim=.)
      (5) have an estimated pr (pr!=.)
*/
      gen aux = 1 if tomove==1 & gender==`i' & ocup!=`j' & pr`j'!=. & ocup_sim==.
      gsort -aux -pr`j' rnd
      
      * generate accum pondiio share
      gen shrpop = sum(pondiio) if sampsel==1 & gender==`i'
      summ shrpop, meanonly
      replace shrpop = shrpop/r(max)
      
      
      replace ocup_sim = `j' if shrpop <= m_chg[`i',`j'] 
   
      drop shrpop aux

    }
    
    * share sim < share obs -> ocup is shrinking
    if m_sim[`i',`j'] < m_obs[`i',`j'] {
      display as text "gender = " as result `i' as text " ocup = " as result `j' as text " ... shrinking"    
    }    

    
  }
}



* for individuals that do not move, same `cvar'
replace ocup_sim = ocup if ocup_sim ==. & sampsel==1


* show movements
bysort gender: tabulate ocup ocup_sim if sampsel==1

* show obs shares
tabulate gender ocup [iw=pondiio] if sampocup==1, row

* show sim shares
tabulate gender ocup_sim [iw=pondiio] if sampocup==1, row


* start: compute sim shares

preserve

version 16: table gender ocup_sim [w=pondiio] if sampsel==1, replace 
reshape wide table1, i(gender) j(ocup_sim)
egen tot = rowtotal(table1*)
forvalues i = 1(1)$n_ocup {
  gen shr`i' = table1`i'/tot
}
egen shrtot = rowtotal(shr*)

* matrix with observed shares
mkmat shr?, matrix(m_sim2)

restore

matrix list m_sim
matrix list m_sim2
matrix define m_chg2 = m_sim2 - m_sim
matrix list m_chg2

* end: compute sim shares






* start: simulate labor incomes



* generate dummy variables from ocup
tabulate ocup_sim, generate(ocupdum_sim)

* rename original ocupdum
rename (ocupdum?) (ocupdum?_aux)

* rename sim ocupdum
rename (ocupdum_sim?) (ocupdum?)


* compute labor income
include "${dofile}\punto3\genera-ing-laboral.do"



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
include "${dofile}\punto3\genera-ing-familiar.do" 



* end: simulate household incomes and consumption


rename ocup_sim occup_`nombre'



* start: cleaning

drop sampsel tomove

* end: cleaning







