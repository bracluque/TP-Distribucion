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
	
	global cwd  	= "C:\Users\Agustin\Documents\2024\UNLP\Economía de la Distribución\TP6" 

*	Globals

	global data 	= "${cwd}\data"
	global output	= "${cwd}\outputs"
	global dofile 	= "${cwd}\do"


/*	Check and install packages

	foreach package in unique mdesc fre missings labvars univar orth_out {
		cap which `package'
		if _rc ssc install `package'
	}
*/

*------------------------------------------------------------------------------*
**# SECTION 1: SET UP														   *
*------------------------------------------------------------------------------*

run "${dofile}\gcuan"

run "${dofile}\prepara-db"

run "${dofile}\curva-engel"

* abrir EPH
import delimited "${data}\usu_individual_T124.txt", clear

* selección observaciones
drop if deccfr<1 | deccfr>10
drop if nro_hogar==51 | nro_hogar==71

* identificador de hogar
egen id = group(codusu nro_hogar)

* miembros
bysort id: gen miembros = _N

* generar percentiles ipcf
gcuan ipcf [w=pondera], n(100) g(percentil)

* agregar información contenida en shfood_percentil
merge m:1 percentil using "${data}\shfood_percentil"



* ### definir escenario

* pass through
local alpha_pt = 0.75
* cambio precios
local delta_p = 0.25
* cambio transferencias
local delta_tr = 0.15

* ### simulación efectos

*+++ efecto consumo
gen ef_c = -shfood * `delta_p'

*+++ efecto ingreso laboral mercado

* start: calcular ingreso laboral per cápita familiar de industria agroalimentaria

* ingreso laboral; ??tickets??
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

* end: calcular ingreso laboral per cápita familiar de industria agroalimentaria

gen ef_w = ilafoodpcf/ipcf * `alpha_pt'  * `delta_p' if emp01==1
replace ef_w = 0 if ef_w==.

*+++ efecto ingreso transferencias

gen trnsfr = v5_m
bysort id: egen trnsfrtf = total(trnsfr)
gen trnsfrpcf = trnsfrtf/miembros

gen ef_tr = trnsfrpcf/ipcf * `delta_tr' if trnsfrpcf != 0
replace ef_tr = 0 if ef_tr ==.

*+++ efecto total
egen ef_tot = rowtotal(ef_c ef_w ef_tr)

* ### reportar resultados

* PIC ef_c
preserve
table percentil [w=pondera], c(mean ef_c) replace
line table1 percentil, saving("${output}\ef_c", replace)
restore

* PIC ef_w
preserve
table percentil [w=pondera], c(mean ef_w) replace
line table1 percentil, saving("${output}\ef_w", replace)
restore

* PIC ef_tr
preserve
table percentil [w=pondera], c(mean ef_tr) replace
line table1 percentil, saving("${output}\ef_tr", replace)
restore

* PIC ef_tot
preserve
table percentil [w=pondera], c(mean ef_tot) replace
line table1 percentil, saving("${output}\ef_tot", replace)
restore