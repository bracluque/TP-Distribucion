* calcula-indicadores.do 

args lp

foreach i of varlist ipcf* {

  display as text "i    = " as result "`i'"
//  local aux=length("`i'")-5
//  local name=substr("`i'",5,`aux'+1)
// alt:
  local name = substr(("`i'"),5,.)  
  display as text "name = " as result "`name'"

  * POBREZA +++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  fgt `i' [w=pondih], a(0) z(`lp')
  scalar fgt0`name'=r(fgt)
  
  fgt `i' [w=pondih], a(1) z(`lp')
  scalar fgt1`name'=r(fgt)

  fgt `i' [w=pondih], a(2) z(`lp')
  scalar fgt2`name'=r(fgt)

  * DESIGUALDAD +++++++++++++++++++++++++++++++++++++++++++++++++++++

  gini `i' [w=pondih]
  scalar gini`name'=r(gini)

  * INGRESO PROMEDIO ++++++++++++++++++++++++++++++++++++++++++++++++

  summ `i' [w=pondih], meanonly
  scalar mu`name'=r(mean)

}

* muestro fgt
foreach i of varlist ipcf* {
  local aux=length("`i'")-5
  local name=substr("`i'",5,`aux'+1)
  
  display as result %5.2fc fgt0`name' as text " = fgt0`name'" 
  display as result %5.2fc fgt1`name' as text " = fgt1`name'" 
  display as result %5.2fc fgt2`name' as text " = fgt2`name'" 
}

* muestro gini
foreach i of varlist ipcf* {
  local aux=length("`i'")-5
  local name=substr("`i'",5,`aux'+1)
  display as result %6.4f gini`name' as text " = gini`name'" 
}

* muestro mu
foreach i of varlist ipcf* {
  local aux=length("`i'")-5
  local name=substr("`i'",5,`aux'+1)
  display as result %12.4f scalar(mu`name') as text " = mu`name'" 
}







