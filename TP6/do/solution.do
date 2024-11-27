/*------------------------------------------------------------------------------
					UNLP - Economía de la Distribucion

	* File name		: solution.do
	* Authors		: Emiliano Bohorquez, Brayan A. Condori, Agustin Deniard
	* Date			: 20241020 
	* Objective		: Este do-file resuelve el TP6 de Distribucion 

*-----------------------------------------------------------------------------*/

*------------------------------------------------------------------------------*
**# SECTION 0.0: SET UP														   *
*------------------------------------------------------------------------------*

*	Setting Up

	clear all			
	cap log close		
	set maxvar 32767	
	set more off		
	set seed 20240924
	set varabbrev off
	version 16
	
*	Set working directory
	
*	global cwd  	= "C:\Users\Agustin\Documents\2024\UNLP\Economía de la Distribución\TP6" 
	global cwd  	= "D:\UNLP_Maeco\Distribucion\TP-Distribucion\TP6" 
*	Globals

	global data 	= "${cwd}\data"
	global output	= "${cwd}\output"
	global dofile 	= "${cwd}\do"


/*	Check and install packages

	foreach package in unique mdesc fre missings labvars univar orth_out {
		cap which `package'
		if _rc ssc install `package'
	}
*/

*------------------------------------------------------------------------------*
**# SECTION 1: CURVA DE ENGEL											   *
*------------------------------------------------------------------------------*

run "${dofile}\gini"

run "${dofile}\gcuan"

run "${dofile}\prepara-db"

run "${dofile}\fgt-libro.do"

run "${dofile}\curva-engel"

*------------------------------------------------------------------------------*
**# SECTION 2: EFECTOS DISTRIBUTIVOS DE UN CAMBIO EN PRECIOS INTERNACIONALES 												   *
*------------------------------------------------------------------------------*

* Abro la EPH 1° Trim. para individuos
import delimited "${data}\usu_individual_T124.txt", clear

* Limpio la base
drop if deccfr<1 | deccfr>10
drop if nro_hogar==51 | nro_hogar==71


destring ipcf, replace force

* Genero un id para cada hogar de la base
egen id = group(codusu nro_hogar)

* Creo una variable que compute el número de miembros al interior de un hogar
bysort id: gen miembros = _N

* Genero los percentiles de la distribución del IPCF
gcuan ipcf [w=pondih], n(100) g(percentil)

* Agrego la información contenida en shfood_percentil
merge m:1 percentil using "${data}\shfood_percentil"

*# Defino escenarios (a) y (b):

** Cambio en precio mundial de los alimentos
local delta_p = 0.25
** Pass-Through de precios a salarios en industria agroalimentaria
local alpha_pt = 0.75
** Cambio en transferencias del Gobierno
local delta_tr = 0.15

* 

** Efecto consumo
gen ef_c = -shfood * `delta_p'

* Inicio: calcular ingreso laboral per cápita familiar de industria agroalimentaria

* Ingreso laboral
egen ila = rowtotal(p21 tot_p12)
replace ila = 0 if ila<0

* CAES-MERCOSUR = dos dígitos = CIIU/ISIC Rev. 4
/*
PP04B_COD
¿A qué se dedica o produce el negocio / empresa / 
institución? (Ver Clasificador de Actividades Económicas
para Encuestas Sociodemográficas del Mercosur - CAES-
MERCOSUR 1.0)
*/

* aux2 contiene número de dígitos en pp04b_cod original
gen aux1 = strofreal(pp04b_cod)
gen aux2 = strlen(aux1)

* se requiere clasificación a 2 dígitos

* si 3 o 4 dígitos, reporta código CIIU 4 dígitos
gen ciiu2d = strofreal(pp04b_cod, "%04.0f") if aux2 == 3 | aux2 == 4
replace ciiu2d = substr(ciiu2d,1,2) if aux2 == 3 | aux2 == 4
* si 1 o 2 dígitos, reporta código CIIU 2 dígitos
replace ciiu2d = strofreal(pp04b_cod, "%02.0f") if aux2 == 1 | aux2 == 2

gen emp01 = 1 if estado==1 & (ciiu2d=="01" | ciiu2d=="10")
replace emp01 = 0 if emp01==. & estado==1

* estadísticas descriptivas
tab emp01 [w=pondera]
table emp01 [w=pondera], c(mean ila)

gen ilafood = ila if emp01==1
bysort id: egen ilafoodtf = total(ilafood)
gen ilafoodpcf = ilafoodtf/miembros 

* Fin: calcular ingreso laboral per cápita familiar de industria agroalimentaria

** Efecto ingreso laboral
gen ef_w = ilafoodpcf/ipcf * `alpha_pt'  * `delta_p' if emp01==1
replace ef_w = 0 if ef_w==.

* Incio: calcular 
gen trnsfr = v5_m
bysort id: egen trnsfrtf = total(trnsfr)
gen trnsfrpcf = trnsfrtf/miembros
* Fin: calcular

** Efecto transferencia
gen ef_tr = trnsfrpcf/ipcf * `delta_tr' if trnsfrpcf != 0
replace ef_tr = 0 if ef_tr ==.
 

** Efecto Total
egen ef_tot = rowtotal(ef_c ef_w ef_tr)

* Reporto los resultados

** Efecto consumo
preserve
table percentil [w=pondera], c(mean ef_c) replace
line table1 percentil, saving("${output}\ef_c.png", replace)
restore

** Efecto ingreso laboral
preserve
table percentil [w=pondera], c(mean ef_w) replace
line table1 percentil, saving("${output}\ef_w.png", replace)
restore

** Efecto transferencia
preserve
table percentil [w=pondera], c(mean ef_tr) replace
line table1 percentil, saving("${output}\ef_tr.png", replace)
restore

** Efecto total
preserve
table percentil [w=pondera], c(mean ef_tot) replace
line table1 percentil, saving("${output}\ef_tot.png", replace)
restore

* Calculo el IPCF que resulta de los efectos
gen ipcf_c = ipcf*(1+ef_c)
gen ipcf_w = ipcf*(1+ef_w)
gen ipcf_tr = ipcf*(1+ef_tr)
gen ipf_tot = ipcf*(1+ef_tot)

sum ipcf*

* Cálculo de la pobreza utilizando la línea de pobreza = al 50% del ingreso mediano
summ ipcf [w=pondih], detail
local lp = 0.5*r(p50)

foreach j of varlist ipcf* {
	display "j = `j'"
	forvalues i = 0(1)2 {
		fgt `j' [w=pondih], a(`i') z(`lp')
	}
}

* Computo algún otro indicador (yo usaría el Gini)
foreach j of varlist ipcf* {
	gini `j' [w=pondih]
}