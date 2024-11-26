* gcuan.do

/*
a diferencia de otras situaciones, no puede utilizarse preserve-keep-restore 
debido a que queremos agregar variables a la base de datos
*/



*clear
*set mem 100m

capture program drop gcuan

* start: codigo libro ===============================================

* gcuan.do

capture program drop gcuan
program define gcuan
  syntax varlist(max=1) [if] [iweight], Ncuantiles(integer) Generate(namelist) 

  quietly {

    * touse = 1 -> observación si cumple if & !=. 
    * touse = 0 -> observación no cumple if | ==. 
    marksample touse 

    local wt : word 2 of `exp'
    if "`wt'"=="" {
      local wt = 1
    }  

    * variables temporales
    tempvar myvar shrpop popwt

    * hacer copia de `varlist'
    gen `myvar' = `varlist'
    replace `myvar' = . if `touse' != 1 
    
    * ordenar por `varlist'
    sort `myvar', stable

    gen `popwt' = `wt'
    replace `popwt' = 0 if `touse' != 1

    * computar porcentaje acumulado población
    gen double `shrpop' = sum(`popwt')
    replace `shrpop' = `shrpop'/`shrpop'[_N]

    * shr de la encuesta que percenece a cada cuantil (ej 20% si ncuantiles=5)
    local shrcuantil = 1/`ncuantiles'

    * nombre variable a generar con numero de cuantil para cada observación
    local cuantil = "`generate'"

    * identificar cuantiles de `varlist'
    gen `cuantil' = .
    forvalues i = 1(1)`ncuantiles' {
      replace `cuantil' = `i' if `shrpop' > (`i'-1)*`shrcuantil' ///
        & `shrpop' <= `i'*`shrcuantil' & `myvar' !=.
    }  

  }
  
  * mostrar descripción cuantiles  
  tabulate `cuantil' [`weight'`exp'], summ(`varlist')

end

* end: codigo libro ===============================================

exit

*### test

drop _all
set mem 200m

do db-open bol05

gcuan ipcf [w=pondera], n(5) g(quintil)

run cuantiles
cuantiles ipcf [w=pondera], n(5) g(quintil2)

exit

gcuan ipcf [w=pondera] if urbano, n(10) c1(10) c2(1)

run cuantiles
cuantiles ipcf [w=pondera], n(5) g(quintil)

* ingreso promedio quintil 1
summ ipcf [w=pondera] if quintil ==1
local media_q1=r(mean)
* ingreso promedio cuantil 5
summ ipcf [w=pondera] if quintil ==5
local media_q5=r(mean)

* mostrar resultado
display "ratq51 = " `media_q5'/`media_q1'


