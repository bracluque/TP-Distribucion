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

* Participación de cada decil en el consumo de cigarrillos

* Para consumo:

preserve

	version 16: table deccpcf [w=pondera], c(sum cpcf sum cigarpcf) replace row
	
	gen shr_cpcf = table1/table1[1]*100
	gen shr_cigar = table2/table2[1]*100

	twoway connect shr_cpcf shr_cigar deccpcf if deccpcf!=., ///
	xlabel(1(1)10) ///

	* Generamos la presión tributaria
	gen presion = shr_cigar/shr_cpcf
	
	twoway connect presion deccpcf if deccpcf!=., ///
			xlabel(1(1)10) ///
			ytitle("Presión tributaria") ///
			xtitle("Deciles del consumo per cápita familiar") ///
			name(cigarconsumo, replace) ///
			graphregion(color(white))

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

	* Genramos la presión tributaria
	gen presion = shr_cigar/shr_ipcf
	
	twoway (connect presion decipcf if decipcf!=.), ///
		   xlabel(1(1)10) ///
	       ytitle("Presión tributaria") ///
	       xtitle("Deciles del ingreso per cápita familiar")  ///
	       name(cigaringreso, replace) ///
	       graphregion(color(white))

	export excel using "${outputs}/reports.xlsx", ///
		sheetmodify sheet("CigarIngreso") firstrow(var)

restore

graph combine cigarconsumo cigaringreso, graphregion(color(white))
graph export "${outputs}\presion_cigar.png", replace

*## Calculamos la curva de concentracion

	gen txpcf_4 = cigarpcf

	* Ordenamos
	sort ipcf

	* Población acumulada
	gen 	shrpop_4 = sum(pondera)
	replace	shrpop_4 = shrpop_4/shrpop_4[_N]
	
	* Ingreso acumulado
	gen		shrinc_4 = sum(ipcf*pondera)
	replace	shrinc_4 = shrinc_4/shrinc_4[_N]
	
	* Recaudación tributaria acumulada
	gen		shrtax_4 = sum(txpcf_4*pondera)
	replace	shrtax_4 = shrtax_4/shrtax_4[_N]
	
	* Graficamos
	
	line shrinc_4 shrtax_4 shrpop_4, ///
	xtitle("Proporción de la población acumulada") ///
	legend(	label(1 "Curva de Lorenz") ///
			label(2 "Curva de concentración de impuestos") ///
			position(6)) ///
			graphregion(color(white))
			
	graph export "${outputs}\concentracion_cigar.png", replace
			
*## Indice de concentracion

	sort ipcf
	qui {
		summ txpcf_4 [w=pondera]
		local obs_4 	= r(sum_w) // pob. de referencia
		local media_4   = r(mean) // tax per capita promedio
		
		gen tmptmp_4 = sum(pondera)
		gen i_4 	 = (2*tmptmp_4 - pondera + 1)/2
		gen tmp_4	 = txpcf_4*(`obs_4'- i_4 + 1)
		summ tmp_4 [w=pondera]
		local contax_4 = 1 + (1/`obs_4') - (2/(`media_4'*`obs_4'^2))*r(sum)
	}

	
	display "contax = " `contax_4' // .15076372
	
*## Indice de Kakwani

	do "${dofile}/gini.do" 
	
	gini ipcf [w=pondera]
	local gini_4 = r(gini)
	
	local kakwani_4 = `contax_4' - `gini_4'
	display "Índice de Kakwani = " `kakwani_4'
	
/*Nota:
	- Kakwani > 0 : Impuesto progresivo
	- Kakwani < 0 : Impuesto regresivo
*/
	

	xxxx
*------------------------------------------------------------------------------*
**# Pregunta 5: Opcional					
*------------------------------------------------------------------------------*

* Abrimos el dataset de gastos
preserve
	import delimited using "${data}/engho2018_gastos.txt", delimiters("|") clear
	
	keep if articulo == "A0211101" | /// Ginebra, caña, grapa
			articulo == "A0211102" | /// Whisky
			articulo == "A0211103" | /// Licores
			articulo == "A0211104" | /// Otras bebidas destiladas
			articulo == "A0211105" | /// Surtidos de bebidas destiladas
			articulo == "A0212201" | /// Vino común
			articulo == "A0212202" | /// Vino fino
			articulo == "A0212203" | /// Vinos dulces o postre o espirituosos
			articulo == "A0212204" | /// Aperitivos 
			articulo == "A0212205" | /// Sidra
			articulo == "A0212206" | /// Vino espumante
			articulo == "A0212207" | /// Otros vinos espumantes
			articulo == "A0212208" | /// Surtido de vinos
			articulo == "A0213301" | /// Cerveza
			articulo == "A0214401" /// Gastos en bebidas alcoholicas sin discriminar
	
	collapse (sum) monto, by(id)
		
	tempfile alcohol
	save `alcohol'
restore

* Unimos las bases de datos
	merge m:1 id using `alcohol', nogen // 17327 matched

* Variable de consumo en tabaco
	rename monto alcohol
	replace alcohol = 0 if alcohol == . // hh sin consumo de bebidas alcohólicas
	
	gen alcoholpcf = alcohol/cantmiem // cantmiem: cantidad de miembros en el hogar

	version 16: table decipcf [w=pondera], c(freq mean ipcf mean alcoholpcf)

* Participación de cada decil en el consumo de bebidas alcohólicas

* Para consumo:

preserve
	
	version 16: table deccpcf [w=pondera], c(sum cpcf sum alcoholpcf) replace row
	
	gen shr_cpcf = table1/table1[1]*100
	gen shr_alcohol = table2/table2[1]*100

	twoway connect shr_cpcf shr_alcohol deccpcf if deccpcf!=., ///
	       xlabel(1(1)10) ///
	       legend(	label(1 "Proporción del consumo per cápita familiar") ///
			        label(2 "Proporcion del consumo de bebidas alcohólicas per cápita familiar") ///
			        position(6))
			
	* Generamos la presión tributaria
	gen presion = shr_alcohol/shr_cpcf
	
	twoway connect presion deccpcf if deccpcf!=., ///
			xlabel(1(1)10) ///
			ytitle("Presión tributaria") ///
			xtitle("Deciles del consumo per cápita familiar") ///
			name(alcoholconsumo, replace) ///
			graphregion(color(white)) 

	export excel using "${outputs}/reports.xlsx", ///
		sheetmodify sheet("AlcoholConsumo") firstrow(var)

restore

* Para ingreso:

preserve
	
	version 16: table decipcf [w=pondera], c(sum ipcf sum alcoholpcf) replace row
	
	gen shr_ipcf = table1/table1[1]*100
	gen shr_alcohol = table2/table2[1]*100

	twoway connect shr_ipcf shr_alcohol decipcf if decipcf!=., ///
		   xlabel(1(1)10) ///
	       legend(	label(1 "Proporción del consumo per cápita familiar") ///
			        label(2 "Proporcion del consumo de bebidas alcohólicas per cápita familiar") ///
			        position(6))

	* Generamos la presión tributaria
	gen presion = shr_alcohol/shr_ipcf
	
	twoway connect presion decipcf if decipcf!=., ///
			xlabel(1(1)10) ///
			ytitle("Presión tributaria") ///
			xtitle("Deciles del ingreso per cápita familiar") ///
			name(alcoholingreso, replace) ///
			graphregion(color(white)) 

	export excel using "${outputs}/reports.xlsx", ///
		sheetmodify sheet("AlcoholIngreso") firstrow(var)

restore

graph combine alcoholconsumo alcoholingreso, graphregion(color(white))
graph export "${outputs}\presion_alcohol.png", replace

*## Calculamos la curva de concentracion

	gen txpcf_5 = alcoholpcf

	* Ordenamos
	sort ipcf

	* Población acumulada
	gen 	shrpop_5 = sum(pondera)
	replace	shrpop_5 = shrpop_5/shrpop_5[_N]
	
	* Ingreso acumulado
	gen		shrinc_5 = sum(ipcf*pondera)
	replace	shrinc_5 = shrinc_5/shrinc_5[_N]
	
	* Recaudación tributaria acumulada
	gen		shrtax_5 = sum(txpcf_5*pondera)
	replace	shrtax_5 = shrtax_5/shrtax_5[_N]
	
	* Graficamos
	line shrinc_5 shrtax_5 shrpop_5, ///
	xtitle("Proporción de la población acumulada") ///
	     legend(	label(1 "Curva de Lorenz") ///
			        label(2 "Curva de concentración de impuestos") ///
			        position(6)) ///
		 graphregion(color(white))
			
	graph export "${outputs}\concentracion_alcohol.png", replace
			
*## Indice de concentracion

	sort ipcf
	qui {
		summ txpcf_5 [w=pondera]
		local obs_5   = r(sum_w) // pob. de referencia
		local media_5 = r(mean) // tax per capita promedio
		
		gen tmptmp_5 = sum(pondera)
		gen i_5 	     = (2*tmptmp_5 - pondera + 1)/2
		gen tmp_5	 = txpcf_5*(`obs_5'- i_5 + 1)
		summ tmp_5 [w=pondera]
		local contax_5 = 1 + (1/`obs_5') - (2/(`media_5'*`obs_5'^2))*r(sum)
	}

	
	display "contax = " `contax_5'
	
*## Indice de Kakwani

	do "${dofile}/gini.do" 
	
	gini ipcf [w=pondera]
	local gini_5 = r(gini)
	
	local kakwani_5 = `contax_5' - `gini_5'
	display "Índice de Kakwani = " `kakwani_5'
	
/*Nota:
	- Kakwani > 0 : Impuesto progresivo
	- Kakwani < 0 : Impuesto regresivo
*/

*------------------------------------------------------------------------------*
**# Pregunta 6					
*------------------------------------------------------------------------------*

* Genero una variable que me permita identificar la base imponible (trabajadores asalariados formales)
	gen formal = 0
	replace formal = 1 if estado == 1 & /// Trabajador ocupado
						  cat_ocup == 3 & /// Es asalariado (obrero o empleado)
						  cp39 == 1 /// Es un trabajador formal (le hacen descuentos por aportes jubilatorios)

* Genero una variable que compute el ingreso de los asalariados formales a partir de su ocupación principal
	gen ingasalfor = 0 if formal == 0
	replace ingasalfor = ingocpal if formal == 1

* Para consumo:

preserve

	version 16: table deccpcf [w=pondera], c(sum cpcf sum ingasalfor) replace row
	
	gen shr_cpcf = table1/table1[1]*100
	gen shr_ingasalfor = table2/table2[1]*100

	twoway connect shr_cpcf shr_ingasalfor deccpcf if deccpcf!=., ///
	xlabel(1(1)10) ///
	legend(	label(1 "Proporción del consumo per cápita familiar") ///
			label(2 "Proporcion del consumo del ingreso formal") ///
			position(6))
			
	* Generamos la presión tributaria
	gen presion = shr_ingasalfor/shr_cpcf
	
	twoway connect presion deccpcf if deccpcf!=., ///
			xlabel(1(1)10) ///
			ytitle("Presión tributaria") ///
			xtitle("Deciles del consumo per cápita familiar") ///
			name(formalconsumo, replace) ///
			graphregion(color(white))

	export excel using "${outputs}/reports.xlsx", ///
		sheetmodify sheet("ContSegSoc-Consumo") firstrow(var)

restore
	
* Para ingreso:

preserve

	version 16: table decipcf [w=pondera], c(sum ipcf sum ingasalfor) replace row
	
	gen shr_ipcf = table1/table1[1]*100
	gen shr_ingasalfor = table2/table2[1]*100

	twoway connect shr_ipcf shr_ingasalfor decipcf if decipcf!=., ///
	xlabel(1(1)10) ///
	legend(	label(1 "Proporción del ingreso per cápita familiar") ///
			label(2 "Proporcion del ingreso formal") ///
			position(6))

	* Generamos la presión tributaria
	gen presion = shr_ingasalfor/shr_ipcf
	
	twoway connect presion decipcf if decipcf!=., ///
			xlabel(1(1)10) ///
			ytitle("Presión tributaria") ///
			xtitle("Deciles del ingreso per cápita familiar") ///
			name(formalingreso, replace) ///
			graphregion(color(white)) 

	export excel using "${outputs}/reports.xlsx", ///
		sheetmodify sheet("ContSegSoc-Ingreso") firstrow(var)

restore

graph combine formalconsumo formalingreso, graphregion(color(white))
graph export "${outputs}\presion_formal.png", replace

*## Calculamos la curva de concentracion

	gen txpcf_6 = ingasalfor

	* Ordenamos
	sort ipcf

	* Población acumulada
	gen 	shrpop_6 = sum(pondera)
	replace	shrpop_6 = shrpop_6/shrpop_6[_N]
	
	* Ingreso acumulado
	gen		shrinc_6 = sum(ipcf*pondera)
	replace	shrinc_6 = shrinc_6/shrinc_6[_N]
	
	* Recaudación tributaria acumulada
	gen		shrtax_6 = sum(txpcf_6*pondera)
	replace	shrtax_6 = shrtax_6/shrtax_6[_N]
	
	* Graficamos
	line shrinc_6 shrtax_6 shrpop_6, ///
		 xtitle("Proporción de la población acumulada") ///
	     legend(	label(1 "Curva de Lorenz") ///
			        label(2 "Curva de concentración de impuestos") ///
			        position(6)) ///
		 graphregion(color(white))
			
	graph export "${outputs}\concentracion_formal.png", replace
			
*## Indice de concentracion

	sort ipcf
	qui {
		summ txpcf_6 [w=pondera]
		local obs_6   = r(sum_w) // pob. de referencia
		local media_6 = r(mean) // tax per capita promedio
		
		gen tmptmp_6     = sum(pondera)
		gen i_6 	     = (2*tmptmp_6 - pondera + 1)/2
		gen tmp_6	 = txpcf_6*(`obs_6'- i_6 + 1)
		summ tmp_6 [w=pondera]
		local contax_6 = 1 + (1/`obs_6') - (2/(`media_6'*`obs_6'^2))*r(sum)
	}
	
	display "contax = " `contax_6'
	
*## Indice de Kakwani

	do "${dofile}/gini.do" 
	
	gini ipcf [w=pondera]
	local gini_6 = r(gini)
	
	local kakwani_6 = `contax_6' - `gini_6'
	display "Índice de Kakwani = " `kakwani_6'
	
/*Nota:
	- Kakwani > 0 : Impuesto progresivo
	- Kakwani < 0 : Impuesto regresivo
*/

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
