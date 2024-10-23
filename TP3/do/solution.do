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

import delimited using "${data}/engho2018_hogares.txt", delimiters("|") clear
destring _all, replace
tempfile hogares
save `hogares'


import delimited using "${data}/engho2018_personas.txt", delimiters("|") clear
destring _all, replace
tempfile personas
save `personas'


merge m:1 id using `hogares', nogen

* Gen vars

clonevar ipcf = ingpch
clonevar cpcf = gastotpc

drop if ipcf <= 0
drop if cpcf <= 0

*------------------------------------------------------------------------------*
**# Pregunta 1 y 2							
*------------------------------------------------------------------------------*
do "${dofile}/gcuan.do"

* Generamos los deciles por ipcf y cpcf

	gcuan ipcf [w=pondera], ncuant(10) gen(decipcf) // P1
	gcuan cpcf [w=pondera], ncuant(10) gen(deccpcf) // P2

* Apartados a), c): IPCF
* Calcular b) en excel

preserve
	version 16: table 	decipcf [w=pondera], c(freq sum ipcf mean ipcf) replace
	
	summ 	table2, meanonly
	gen 	shr_c = table2/r(sum)*100
	rename 	table3 media_c
	
	export excel using "${outputs}/reports.xlsx", ///
		sheetmodify sheet("IngresoShr") firstrow(var)
restore

* Apartados a), c): CPCF
* Calcular b) en excel
preserve
	version 16: table 	deccpcf [w=pondera], c(freq sum cpcf mean cpcf) replace
	
	summ 	table2, meanonly
	gen 	shr_c = table2/r(sum)*100
	rename 	table3 media_c
	
	export excel using "${outputs}/reports.xlsx", ///
		sheetmodify sheet("ConsumoShr") firstrow(var)
restore

	
*------------------------------------------------------------------------------*
**# Pregunta 3					
*------------------------------------------------------------------------------*

/* Curva de Engel
	- shr_food: Proporcion del gasto total destinado a alimentos
*/
	gen shr_food = gc_01/gastot
	egen aux = tag(id) // tag unique id por hh

* shr_food promedio por decil de cpcf

	version 16: table deccpcf [w=pondera] if aux == 1, c(mean shr_food) // copiar a excel

/*
					--------------------------
					  deccpcf | mean(shr_food)
					----------+---------------
							1 |       .3777112
							2 |       .3758298
							3 |       .3503409
							4 |       .3382658
							5 |       .3130811
							6 |       .3009315
							7 |       .2688707
							8 |       .2393954
							9 |       .2086253
						   10 |        .157667
					--------------------------
*/
	
*------------------------------------------------------------------------------*
**# Pregunta 4					
*------------------------------------------------------------------------------*
* Abrimos el dataset de gastos
preserve
	import delimited using "${data}/engho2018_gastos.txt", delimiters("|") clear
	
	keep if articulo == "A0221101" | ///
			articulo == "A0221102" | ///
			articulo == "A0221103" 
	
	collapse (sum) monto, by(id)
		
	tempfile tabaco
	save `tabaco'
restore

* Unimos las bases de datos
	merge m:1 id using `tabaco', nogen // 15943 matched

* Variable de consumo en tabaco
	rename monto cigar
	replace cigar = 0 if cigar == . // hh sin consumo de cigarrillos
	
	gen cigarpcf = cigar/cantmiem // cantmiem: cantidad de miembros en el hogar

	version 16: table decipcf [w=pondera], c(freq mean ipcf mean cigarpcf)

* Incidencia: 

	local recaudacion = 216129*100000  // Consulta: Qué variable se mira para esto? Cual es el nombre de variable para impuestos?

* Participaci´on de cada decil en el consumo de cigarrillos

* Para consumo:
preserve
	version 16: table deccpcf [w=pondera], c(sum cpcf sum cigarpcf) replace row
	
	gen shr_cpcf = table1/table1[1]*100
	gen shr_cigar = table2/table2[1]*100

	twoway connect shr_cpcf shr_cigar deccpcf if deccpcf!=., ///
	xlabel(1(1)10) ///
	legend(	label(1 "Proporción del consumo per cápita familiar") ///
			label(2 "Proporcion del consumo de cigarrillos per cápita familiar") ///
			position(6))

* Genramos la presión tributaria

	gen presion = shr_cigar/shr_cpcf
	twoway connect presion deccpcf if deccpcf!=., ///
	xlabel(1(1)10) ///
	ytitle("Presión tributaria") ///
	xtitle("Deciles del consumo per cápita familiar") 

	export excel using "${outputs}/reports.xlsx", ///
		sheetmodify sheet("CigarConsumo") firstrow(var)
restore

* Para ingreso:
preserve
	version 16: table decipcf [w=pondera], c(sum ipcf sum cigarpcf) replace row
	
	gen shr_ipcf = table1/table1[1]*100
	gen shr_cigar = table2/table2[1]*100

	twoway connect shr_ipcf shr_cigar decipcf if decipcf!=., ///
	xlabel(1(1)10) ///
	legend(	label(1 "Proporción del consumo per cápita familiar") ///
			label(2 "Proporcion del consumo de cigarrillos per cápita familiar") ///
			position(6))

* Genramos la presión tributaria

	gen presion = shr_cigar/shr_ipcf
	
	twoway connect presion decipcf if decipcf!=., ///
	xlabel(1(1)10) ///
	ytitle("Presión tributaria") ///
	xtitle("Deciles del consumo per cápita familiar") 

	export excel using "${outputs}/reports.xlsx", ///
		sheetmodify sheet("CigarIngreso") firstrow(var)
restore

*## Calculamos la curva de concentracion

	gen txpcf = cigarpcf

	* Ordenamos
	sort ipcf

	* Población acumulada
	gen 	shrpop = sum(pondera)
	replace	shrpop = shrpop/shrpop[_N]
	
	* Ingreso acumulado
	gen		shrinc = sum(ipcf*pondera)
	replace	shrinc = shrinc/shrinc[_N]
	
	* Recaudación tributaria acumulada
	gen		shrtax = sum(txpcf*pondera)
	replace	shrtax = shrtax/shrtax[_N]
	
	* Graficamos
	
	line shrinc shrtax shrpop, ///
	xtitle("Proporcion de la población acumulada") ///
	legend(	label(1 "Proporción del ingreso acumulado") ///
			label(2 "Proporción de los impuestos acumulados") ///
			position(6)) 
			
*## Indice de concentracion

	sort ipcf
	qui {
		summ txpcf [w=pondera]
		local obs 	= r(sum_w) // pob. de referencia
		local media = r(mean) // tax per capita promedio
		
		gen tmptmp = sum(pondera)
		gen i 	= (2*tmptmp - pondera + 1)/2
		gen tmp	= txpcf*(`obs'- i + 1)
		summ tmp [w=pondera]
		local contax = 1 + (1/`obs') - (2/(`media'*`obs'^2))*r(sum)
	}

	
	display "contax = " `contax' // .15076372
	
*## Indice de Kakwani

	do "${dofile}/gini.do" 
	
	gini ipcf [w=pondera]
	local gini = r(gini)
	
	local kakwani = `contax' - `gini'
	display "Índice de Kakwani = " `kakwani'
	
/*Nota:
	- Kakwani > 0 : Impuesto progresivo
	- Kakwani < 0 : Impuesto regresivo
*/
	

	
*------------------------------------------------------------------------------*
**# Pregunta 5: Opcional					
*------------------------------------------------------------------------------*


*------------------------------------------------------------------------------*
**# Pregunta 6					
*------------------------------------------------------------------------------*


*------------------------------------------------------------------------------*
**# Pregunta 7					
*------------------------------------------------------------------------------*
	
* Tag la asistencia a un centro educativo
	gen asisteg = (cp19 == 1)
	
* Identificamos por nivel educativo

	gen asistepri = 1 if asisteg == 1 & niveled == 1
	gen asistesec = 1 if asisteg == 1 & niveled == 3
	gen asistesup = 1 if asisteg == 1 & niveled == 5
	
* Ingreso
preserve
	
	* Contar el total de alumnos
	version 16: table decipcf [w=pondera], ///
		c(sum asistepri sum asistesec sum asistesup) row replace
		
	* Calculamos el share
	gen shrpri = table1/table1[1]
	gen shrsec = table2/table2[1]
	gen shrsup = table3/table3[1]

	*Graficamente
	twoway connected shrpri shrsec shrsup decipcf if decipcf != ., ///
	xlabel(1(1)10) xtitle("Decil de ingreso per cápita familiar") ///
	legend(	label(1 "Proporción de estudiantes que asisten a primaria") ///
			label(2 "Proporción de estudiantes que asisten a secundaria") ///
			label(3 "Proporción de estudiantes que asisten a superior") ///
			position(6))
	graph export "${outputs}/icpf_education.pdf", replace
restore

* Consumo
preserve
	
	* Contar el total de alumnos
	version 16: table deccpcf [w=pondera], ///
		c(sum asistepri sum asistesec sum asistesup) row replace
		
	* Calculamos el share
	gen shrpri = table1/table1[1]
	gen shrsec = table2/table2[1]
	gen shrsup = table3/table3[1]

	*Graficamente
	twoway connected shrpri shrsec shrsup deccpcf if deccpcf != ., ///
	xlabel(1(1)10) xtitle("Decil de ingreso per cápita familiar") ///
	legend(	label(1 "Proporción de estudiantes que asisten a primaria") ///
			label(2 "Proporción de estudiantes que asisten a secundaria") ///
			label(3 "Proporción de estudiantes que asisten a superior") ///
			position(6))
	graph export "${outputs}/ccpf_education.pdf", replace
restore
