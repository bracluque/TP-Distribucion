/*------------------------------------------------------------------------------
					UNLP - Economía de la Distribucion

	* File name		: solution.do
	* Authors		: Emiliano Bohorquez, Brayan A. Condori, Agustin Deniard
	* Date			: 20241020 
	* Objective		: Este do-file resuelve el TP3 de Distribucion 

*-----------------------------------------------------------------------------*/
*------------------------------------------------------------------------------*
**# SECTION 0: SET UP														   *
*------------------------------------------------------------------------------*

*	Setting Up

	clear all			
	cap log close		
	set maxvar 32767	
	set more off		
	set seed 20240924
	set varabbrev off
	set scheme ipaplots
	version 16
*	Set working directory
	
	global cwd  	= "D:\UNLP_Maeco\Distribucion\TP-Distribucion\TP3" 

*	Globals

	global data 	= "${cwd}/data"
	global outputs	= "${cwd}/outputs"
	global dofile 	= "${cwd}/do"


/*	Check and install packages

	foreach package in unique mdesc fre missings labvars univar orth_out {
		cap which `package'
		if _rc ssc install `package'
	}
*/

*------------------------------------------------------------------------------*
**# SECTION 0.0: CLEANING							
*------------------------------------------------------------------------------*


*------------------------------------------------------------------------------*
**# Pregunta 1					
*------------------------------------------------------------------------------*

* Computar el coeficiente de Gini

// ingreso familiar equivalente: cada miembro del hogar tiene una escala de equivalencia respecto a un adulto equivalente

// Usamos la escala de INDEC. Fundamente fijar en base a la edad y el sexo.
// Adulto equivalente: hombre entre 30-60 años

	// Denominador: unidades de adulto equivalente

	destring ipcf, dpcomma replace
	
	drop if nro_hogar == 51 | nro_hogar == 71 // hogares secundarios: servicio domestico y pensionistas
	keep if inrange(deccfr, 1, 10) // deciles del ingreso per capita familiar. Necesitamos los valores extremos
	
// Escala de adulto equivalente oficial

gen ae = 0

replace ae = 0.35 if ch06 < 1
replace ae = 0.35 if ch06 == 1
replace ae = 0.35 if ch06 == 2
replace ae = 0.35 if ch06 == 3
replace ae = 0.35 if ch06 == 4
replace ae = 0.35 if ch06 == 5
replace ae = 0.35 if ch06 == 6
replace ae = 0.35 if ch06 == 7
replace ae = 0.35 if ch06 == 8
replace ae = 0.35 if ch06 == 9
replace ae = 0.35 if ch06 == 10 & ch04 == 2 // genero
replace ae = 0.35 if ch06 == 11 & ch04 == 2
replace ae = 0.35 if ch06 == 12 & ch04 == 2

replace ae = 0.35 if ch06 == 1 & ch04 == 2
replace ae = 0.35 if ch06 == 1 & ch04 == 2


egen aef = total(ae), by (codusu nro_hogar)
// Economias de escala internas al hogar: 
// Tener mas miembros en un hogar le permite tener un ingreso mas alto que si tuviera menos miembros. Un mismo ingreso genera de escala al compartir con los miembros del hogar.

// Suponemos distintos valores del paramétro de economías de escala

local alpha1 = 0 // igual al ingreso total familiar, economias plenas de escala
local alpha2 = 0.8
local alpha3 = 1 // no varía el ingreso equivalente, no hay economías de escala. el ipcf se se deberia acercar al ingreso equivalente

// Intuicion: menor el parametro, mayor el ingreso. 

* En general menos adultos equivalentes que miembros

forvalues a = 1/3 {
	
	gen ie_`a' = itf / (aef)^`alpha`a''
}

do "${dofile}/gini.do"

gini ipcf {w=pondih}

// El Gini se reduce en 4 puntos cuando hay economia de escala plena. Hogares de menores ingresos tienen mayor cantidad de miembros, al tener un ingreso familiar mayor, la desigualdad disminuye. Aprovechan en mayor medida las economias de escala. Diametralmente opuesto a los hogares de altos ingresos.

Ginis 0.4263
0.4387
0.4579




*------------------------------------------------------------------------------*
**# Pregunta 2					
*------------------------------------------------------------------------------*

*Computar la curva de incidencia del crecimiento

*grafica la tasa de varaicion por percentil/incluso por persona, entre dos periodos de tiempo
X quintiles
Y tasa de variacion

// Lo habitual es usar el ingreso per capita familiar

// Permite ver el cambio en la distribucion de forma desagregada.


* Deflactamos para algun año

primer trimestre de 2024 (promedio): 
local ipc24 = 4814.8
local ipc23 = 1288.9

preserve 

keep ipcf pondih

tempfile arg24
save `arg24', replace

**

* Abrir EPH primer trimestre de 2023

* Open
preserve
import delimited eph23_1t

	destring ipcf, dpcomma replace
	
	drop if nro_hogar == 51 | nro_hogar == 71 // hogares secundarios: servicio domestico y pensionistas
	keep if inrange(deccfr, 1, 10) // deciles del ingreso per capita familiar. Necesitamos los valores extremos
	keep ipcf pondih
	
	tempfile arg23
	save `arg23', replace
restore

* Iterar por perdiodo

foreach i in 23 24 {
	drop _all
	use `arg`i'', clear
	if "`i'" == 23 {
		replace ipcf * `ipc24'/`ipc23'
	}
	
	*Ordenamos por ipcf
	sort ipcf
	
	*% acumlado de la poblacion
	
	gen shrpop = sum(pondih)
	replace shrpop = shrpop/shrpop[_N]
	
	*Identificar percentil
	gen percentil = .
	
	forvalues j = 1(1)100 {
		replace percentil =  `j' if shrpop > (`j'- 1)*0.01 & shrpop <= `j'*0.01
	}
	
	version 16: table percentil [w=pondih], c(mean ipcf) replace // replace reemplaza en la base de datos
	
	rename table1 ipcf`i'
	sort percentil
	*tempfile percentil_arg`i'
	*sort percentil
	tempfile percentil_arg`i'
	save `percentil_arg`i'', replace

}

merge 1:1 percentil using `percentil_arg23'

gen chg = 100*(ipcf24/ipcf23 - 1)
twoway line chg percentil if inrange(percentil, 5, 95), xlabel(#10) // restringir la muestra quitando los extremos, mayor volatilidad

// La curva de incidencia del crecimiento si bien todos los percentiles perdieron, hay una pendiente positiva. Los percentiles mas bajos son los mas afectados.  Perfil pro rico

// Conduce a un aumento en los indicadores de desigualdad.

// Pierden todos, pero pierden lso mas pobres. La myor parte de los ingresos son los laborales. 
*------------------------------------------------------------------------------*
**# Pregunta 3				
*------------------------------------------------------------------------------*

* dos parametros de aaversion epsilon.
use eph24, clear

mismo clean

* Recodificacion: CABA y GBA

replace region = 2 if aglomerado == 32 // CABA

do "${dofile}/atk.do" // Proceso similar al coef gini, ver libro

* Computamos las medidas de bienestar por region para 2024

mat def w_24 = J(7, 5, .) // 7 rows, 5 cols.

local cnt = 1

// Lo usual es reportar con diferentes medidas de bienestar

// Dependiendo que pondera mas, las medidas de bienestar pueden indicar cosas diferentes. Ej. Filminas.

levelsof region, local(levels)

foreach i of local levels {
	preserve
	keep if region == `i'
	summ ipcf [w=pondih]
	local media  = r(mean)
	
	mat w_24[`cnt', 1] = `media'
	
	gini ipcf [w=pondih]
	
	*Sen
	
	local sen = `media'*(1-r(gini))
	mat w_24[`cnt', 2] = `sen'
	
	*Kakwani
	
	local kak  = `media'/(1+(r(gini))'
	mat w_24[,3]= `kak'
	
	*Atkinson
	
	atk ipcf [w=pondih], e(1)
	local aatk1 = `media'*(1-r(atk))
	mat w_24[,4] = àtk1
	
	atk ipcf [w=pondih], e(2)
	local aatk2 = `media'*(1-r(atk))
	mat w_24[,4] = àtk2
	
	restore
	
	local ++ cnt
}

* Para 2023: realizar lo mimso

Utilizando eph23_1t

deflacatacion


*Ver matriz

mat dir

mat list w_24

* Tasa de variacion para cada indicador por region

* Discutir que pasa en cada region. Como varia el bienestar en las regiones, en la magnitud y el signo.

*Exportar las matrices
mat w = w_24, w_23

drop _all
svmat w

export excel using ....


* 



*------------------------------------------------------------------------------*
**# Pregunta 4					
*------------------------------------------------------------------------------*


// En base de 


use 2024, dta

destrong ipcf, dpcomma replace



clean hasta recodificar  CABA Y GBA


sort region ipcf

by region: gen pop = sum(pondih)
by region: gen shrpop = pop/pop[_N]
by region: gen glorenz = sum(ipcf*pondih)
by region: replace glorez = glorenz/pop[_N]

twoway 	(line glorenz shrpop if region == 1) ///
		(line glorenz shrpop if region == 2), ///
		legend(label(1 "GBA") label(2 "CABA"))

//	Refleja dominancia distributiva de segundo orden. Funciones de bienestar cuasiconcava refleja mayor distriucion


// Pendiente para 2023 y comparar con las demas regiones.




