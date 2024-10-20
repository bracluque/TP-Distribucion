* gcuan.do

/*
a diferencia de otras situaciones, no puede utilizarse preserve-keep-restore 
debido a que queremos agregar variables a la base de datos
*/



capture program drop gcuan

* start: codigo libro ===============================================

program define gcuan
  syntax varlist(max=1) [if] [iweight], Ncuantiles(integer) Generate(namelist) 

  quietly {
    tokenize `varlist'

    * touse = 1 -> observacion si cumple if & !=. 
    * touse = 0 -> observacion no cumple if | ==. 
    marksample touse 

    local wt : word 2 of `exp'
    if "`wt'"=="" {
      local wt = 1
    }  

    * variables temporales
    tempvar myvar shrpop popwt

    * hacer copia de `1'
    gen `myvar' = `1'
    replace `myvar' = . if `touse' != 1 
    
    * ordenar por `1'
    sort `myvar', stable

    gen `popwt' = `wt'
    replace `popwt' = 0 if `touse' != 1

    * computar porcentaje acumulado poblacion
    gen double `shrpop' = sum(`popwt')
    replace `shrpop' = `shrpop'/`shrpop'[_N]

    * shr de la encuesta que percenece a cada cuantil (ej 20% si ncuantiles=5)
    local shrcuantil = 1/`ncuantiles'

    * nombre variable a generar con numero de cuantil para cada observacion
    local cuantil = "`generate'"

    * identificar cuantiles de `1'
    gen `cuantil' = .
    forvalues i = 1(1)`ncuantiles' {
      replace `cuantil' = `i' if `shrpop' > (`i'-1)*`shrcuantil' & `shrpop' <= `i'*`shrcuantil' & `myvar' !=.
    }  

  }
  
  * mostrar descripcion cuantiles  
  tabulate `cuantil' [`weight'`exp'], summ(`1')

 
end

* end: codigo libro ===============================================
