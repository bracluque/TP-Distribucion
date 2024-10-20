
/*------------------------------------------------------------------------------*
**# SECTION 3							
*------------------------------------------------------------------------------*

*Curva de Engel: Elasticidad <1
* Incrementos en el ingreso reduce el share del gasto en alimentos

gen shr_food = gc_01/gastot

*identificar una unica observacion por hogar
egen aux = tag(id)

*shr_food promedio por decil de cpcf

taable deccpcf [w=pondera] if aux == 1 c(mean shr_food)

* La dereivada primera es negativa, la segunda es positiva, decrece cada vez mas rapido.

*Si resulta interesante: nutricion. Como cambia la dieta entre percentiles de ingreso, como cambia la dieta-. FAO dataset, affordability index. 

*------------------------------------------------------------------------------*
**# SECTION 4				
*------------------------------------------------------------------------------*

*El respondable legal de pagar el impuesto no siempre es quien soporta la carag ecoomica de los impuestps.


*Presion tributaria: impursto soportadopor el individuo respecto del indicador de bienestar elegido. La carga se reparte entre oferentes y demandantes, pero depende la magnitud.

* Se realiza supuestos de traslación. Suponemos que el impuesto al consumo recae sobre el consumidor.


* Qué tan bien está capturado el ingreso? etpicamente en las escuestas dehogares, no se captura bien las colas.

*Analisis: revisar el gasto en tabaco de cada decil. Objetivo: dsitribuir la recaudacion entre deciles

** RESPECTO AL INGRESO
* Impuesto proporcional: tiene que ser igual
* Impuesto progresivo: los ricos tienen que pagar mas que su proporcion. La carga del impuesto tiene que estar desigualmente distribuido


* Impuesto al tabaco es para desincentivar el consumo. 


* CURVA de concentracion: Azul Lorenz.

* El impuesto al cigarrillo no es progresivo. El impuesto es menos desigualmente distribuido que los ingresos.

* Para kakwani, el eje es el mismo: Indice concentracion - Gini.

*Kawwani <0: Impuesto regresivo
*kakwani >0: Impuesto progresivo
* Kawwani = 0: Impuesto proporcional

^*

use "engho_gastos.dta", clear

*keep cigarrillos

keep if articulo == "A0221101" | ///
		articulo == "A0221102" | ///
		articulo == "A0221103"
		
		collapse (sum) monto, by (id)
		
tempfile tmp_tabaco
save `tmp_tabaco'

merge con tmp-personas-hogares
merge m:1 id using `tmp_tabaco', nogen

rename monto cigar

* reemplazar por cero observacioenss in consumo de cigarrillos

replace cigar = 0 if cigar == .
gen cigarpcf = cigar/cantmiem
table decipcf [w=pondera], c(freq mean ipcf mean cigarpcf)
* Para ver incidencia:
local recaudacion = 216129*1000000

* Hacer con los dos: consumo e ingreso como proxies.

table deccpcf []

*4 concentracion, solo la curva de lorenz



*Curva de concentracion
gen txpcf = cigarpcf

sort ipcf


gen shrpop = dum(pondera)
replace shrpop = shrpop/shrpop[_N]

gen shrtax = sum(ipcf*pondera)
replace 

similar al tp2



*** Indice

*ordenamos por ipcf

sort ipcf

summ txpcf [w=pondera]

local obs = r(sum_w)

local media = r(mean)

gen tmptmp = sum (pondera)
gen i = (2*tmptmp - pondera +1)

same as gini


* Indice de Kakwani

run gini-libro.dofile
gini ipcf [w=pondera]
local gini = r(gini)

local kakwani = `contac' - `gini'
+
**** Ejercicio 5: opcional, bebidas alcoholicas.

*** Punto 6: 


en los deciles mas bajos, mas escuela publica y mas estudiantes.


gen asisteg = 1  if cp19 == 1

gen asistepri = 1 if asisteg == 1 & nivel_ed = 1
gen asistesec = 1 if asisteg == 1 & nivel_ed = 3
gen asistesup = 1 if asisteg == 1 & nivel_ed = 5


table decipcf [w = pondera], ///
c(sum asistepri sum asistesec sum asistesup) row replace

* Cuanto mas alto es el decil, menor es la proporcion de alumnos que representa ese decil en el total.
*/