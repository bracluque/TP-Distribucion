* prepara-db.do

*### Paso 1 ---------------------------------------------------------

import delimited using "${data}\engho2018_hogares.txt", delimiters("|")
//destring _all, dpcomma replace
destring _all, replace
save "${data}\ENGHo-Hogares", replace 

import delimited using "${data}\engho2018_personas.txt", delimiters("|") clear
//destring _all, dpcomma replace
destring _all, replace
save "${data}\ENGHo-Personas", replace

*### Paso 2 ---------------------------------------------------------

use "${data}\ENGHo-Personas", clear

* combinar personas + hogares
merge m:1 id using "${data}\ENGHo-Hogares"
drop _merge

* generar variables
clonevar ipcf = ingpch
clonevar cpcf = gastotpc

* consumo total familiar
clonevar ctf = gastot


* eliminar observaciones
drop if ipcf<=0
drop if cpcf<=0

* consumo alimentos per capita
* gc_01 = Alimentos y bebidas no alcohólicas
gen cfood = gc_01/cantmiem

* participacion consumo alimentos en consumo total
gen shfood = cfood / cpcf


save "${data}\data-1", replace


