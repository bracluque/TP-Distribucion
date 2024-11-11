/********************************************************************
				Distribucion
				
				Trabajo Practico Nº 5:
				Desigualdad de Oportunidades (DOP)
				Pedrazzi, Julian (CEDLAS-IIE-UNLP)
				Fecha: Noviembre, 2024
********************************************************************/
version 16

clear all
local cd = "D:/Dropbox/A-work/C-Ayudantias/distribucion/TPs/tp_propuesta/enes"
set seed 123

* Base Hogar:
import delimited "`cd'/datos/bruto/Base_ENESHogares.csv"
save "`cd'/datos/modif/ENES_hogares.dta", replace

* Base Personas:
clear all
import delimited "`cd'/datos/bruto/Base_ENESPersonas.csv"
save "`cd'/datos/modif/ENES_personas.dta", replace

*Número Identificador de Vivienda (nocues) y el Número Identificador de Hogar (nhog)
merge m:1 nocues nhog using "`cd'/datos/modif/ENES_hogares.dta", assert(3) keep(3) nogen
save "`cd'/datos/modif/ENES_f.dta", replace

clear all
use "`cd'/datos/modif/ENES_f.dta", replace

* Variables:
gen mujer = 0 if v109 == 1
replace mujer = 1 if v109 == 2
label var mujer "=1 si es mujer"
label define mujer 0 "Hombre" 1 "Mujer"
label values mujer mujer
clonevar edad = v108
label var edad "Edad"
clonevar parent = v111
label var parent "Parentesco"
label define parent 1 "PSH" 2 "Conyuge"
label values parent parent
* La variable region está en la encuesta de los hogares:
* Separamos CABA de Buenos Aires.
replace region = 2 if aglo == 1
label define region 1 "GBA" 2 "CABA" 3 "Cuyo" 4 "Pampeana" 5 "Centro" 6 "NEA" 7 "NOA" 8 "Patagonia"
label values region region

/* 
CIRCUNSTANCIA 1: LUGAR DE NACIMIENTO. 
*/

* Esta variable se construye con base en REGION.
* Si nació en la misma localidad u otra pero de la misma provincia, no cambia la región.
gen nacimiento = region if v149a == 1 | v149a == 2
* Acomodamos las regiones si reporta haber nacido en otra provincia: Si v149a == 3 nació en otra provincia (puede ser otra región de nacimiento)
replace nacimiento = 1  if v149a == 3 & (v149b_pcia == 1) // 24 partidos BSAS
replace nacimiento = 2  if v149a == 3 & (v149b_pcia == 4) // CABA
replace nacimiento = 3  if v149a == 3 & (v149b_pcia == 13 | v149b_pcia == 21 | v149b_pcia == 22) // Cuyo:Mendoza, San Juan y San Luis
replace nacimiento = 4  if v149a == 3 & (v149b_pcia == 11) // Pampeana: La Pampa
replace nacimiento = 5  if v149a == 3 & (v149b_pcia == 3 | v149b_pcia == 8 | v149b_pcia == 20) // Centro: Cordoba, entre rios y santa Fe
replace nacimiento = 6  if v149a == 3 & (v149b_pcia == 6 | v149b_pcia == 5 | v149b_pcia == 9 | v149b_pcia == 14) // NEA: Chaco, Corrientes, Formosa y Misiones
replace nacimiento = 7  if v149a == 3 & (v149b_pcia == 2 | v149b_pcia == 10 | v149b_pcia == 12 | v149b_pcia == 17 | v149b_pcia == 19 | v149b_pcia == 24) // NOA: Catamarca, Jujuy, La Rioja, Salta, Santiago del Estero y Tucumán
replace nacimiento = 8  if v149a == 3 & (v149b_pcia == 7 | v149b_pcia == 15 | v149b_pcia == 16 | v149b_pcia == 18 | v149b_pcia == 23) // Patagonia: Chubut, Neuquen, Río Negro, Santa Cruz y Tierra del Fuego
* Si nació en otro país.
replace nacimiento = 9 if v149a == 4 | v149a == 5

label var nacimiento "Region de nacimiento"
label define nacimiento 1 "Partidos BsAs" 2 "CABA" 3 "Cuyo" 4 "Pampeana" 5 "Centro" 6 "NEA" 7 "NOA" 8 "Patagonia" 9 "Otro Pais"
label values nacimiento nacimiento


* Los missings son: si no sabemos en que lugar nacio (v149 = .) si no sabemos en que provincia nació (v149 = .)
* Los del segundo caso se podrían aproximar con la residencia actual, pero mejor no las usamos.
ta nacimiento, m
ta v149a if nacimiento == ., m

/* 
CIRCUNSTANCIA 2: Etnia.
*/
gen etnia = 0 if v148 == 3
replace etnia = 1 if v148 == 1 | v148 == 2
label var etnia "=1 si es descendencia de pueblo indígena (originario) o afrodescendiente"

/* 
CIRCUNSTANCIA 3: EDUCACIÓN DE LOS PADRES. 
*/
do "`cd'/do-files/nivel_ed.do"

keep if edad >= 25 & edad <= 55 & (parent == 1 | parent == 2)

----------HASTA ACA PUEDO PASARLES.