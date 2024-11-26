* master.do

/*
Economía de la Distribución
Trabajo Práctico Nro. 7
Martín Cicowiez                                                   
martin@depeco.econo.unlp.edu.ar                                   
Noviembre, 2024
*/

version 16

clear all
set type double
set seed 121212

cd "C:\wrk\Curso-Distribucion\TP6-microsim\Solucion\Do-Files-Punto-3"


capture log close
log using "..\Output\tp7-punto3.log", replace

* programa fgt
run "..\Do-Files-Shared\fgt-libro.do"             

* programa gini
run "..\Do-Files-Shared\gini-libro.do"            

* programa cuantiles
run "..\Do-Files-Shared\gcuan.do"


* abrir base de datos
use "C:\wrk\Curso-Distribucion\EPH-1-Trim-2024\usu_individual_T124"

* preparar base de datos
do "..\Do-Files-Shared\prepara-db.do" 
  

*### Punto 3 --------------------------------------------------------

* estimate mincer equation 
do "estimate-mincer.do"

* estimate occupation choice model
do "estimate-occup.do"


* describe data
do "desc-data.do"




* sim changes in determinants of occup categ: secc
do "sim-secc.do" "secc"




* start: sim-part parametric sorting


* do file with scenario definition: blank
include "scen-defn-blank.doi"
do "sim-part.do" "blank" "shk_part" 15 999


* do file with scenario definition: unemp
include "scen-defn-unemp.doi"
do "sim-part.do" "unemp" "shk_part" 15 999

* end: sim-part parametric sorting



* cic
do "..\Do-Files-Shared\rep-cic.do" "secc" "ipcf" "ipcf_secc"
do "..\Do-Files-Shared\rep-cic.do" "unemp" "ipcf" "ipcf_unemp"


* argumento = lp
do "..\Do-Files-Shared\calcula-indicadores.do" 125000



log close








