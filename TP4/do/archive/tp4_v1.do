****************************** TP4 ****************************** 

*	Setting Up

	clear all			
	cap log close		
	set maxvar 32767	
	set more off		
	set seed 20240924
	set varabbrev off
*	set scheme ipaplots
	version 16
*	Set working directory
	
	global cwd  	= "C:\Users\Emiliano\Documents\FCE - UNLP\Economia de la Distribucion\TP-Distribucion\TP4" 

*	Globals

	global data 	= "${cwd}/data"
	global dofile 	= "${cwd}/do"
	global output 	= "${cwd}/output"


*----------------------- DATA CLEANING
*** EPH 2024

import delimited using "${data}/EPH_ind_T124.txt", delimiters(";") clear
destring _all, replace

destring ipcf, dpcomma replace
keep if inrange(deccfr, 1, 10)
drop if nro_hogar == 51 | nro_hogar == 71

save "${data}/EPH_ind_T124", replace

*** EPH 2023

import delimited using "${data}/EPH_ind_T123.txt", delimiters(";") clear
destring _all, replace

destring ipcf, dpcomma replace
keep if inrange(deccfr, 1, 10)
drop if nro_hogar == 51 | nro_hogar == 71

save "${data}/EPH_ind_T123", replace

tempfile arg23
save `arg23', replace

*----------------------- PUNTO 1

use "${data}/EPH_ind_T124", replace

* Se genera una variable para la Escala de Adulto Equivalente

gen ae = 0
replace ae = 0.35 if ch06 <1
replace ae = 0.37 if ch06 == 1
replace ae = 0.46 if ch06 == 2
replace ae = 0.51 if ch06 == 3
replace ae = 0.55 if ch06 == 4
replace ae = 0.60 if ch06 == 5
replace ae = 0.64 if ch06 == 6
replace ae = 0.66 if ch06 == 7
replace ae = 0.68 if ch06 == 8
replace ae = 0.69 if ch06 == 9
replace ae = 0.79 if (ch06 == 10 & ch04 == 1)
replace ae = 0.70 if (ch06 == 10 & ch04 == 2)
replace ae = 0.82 if (ch06 == 11 & ch04 == 1)
replace ae = 0.72 if (ch06 == 11 & ch04 == 2)
replace ae = 0.85 if (ch06 == 12 & ch04 == 1)
replace ae = 0.74 if (ch06 == 12 & ch04 == 2)
replace ae = 0.90 if (ch06 == 13 & ch04 == 1)
replace ae = 0.76 if (ch06 == 13 & ch04 == 2)
replace ae = 0.96 if (ch06 == 14 & ch04 == 1)
replace ae = 0.76 if (ch06 == 14 & ch04 == 2)
replace ae = 1 if (ch06 == 15 & ch04 == 1)
replace ae = 0.77 if (ch06 == 15 & ch04 == 2)
replace ae = 1.03 if (ch06 == 16 & ch04 == 1)
replace ae = 0.77 if (ch06 == 16 & ch04 == 2)
replace ae = 1.04 if (ch06 == 17 & ch04 == 1)
replace ae = 0.77 if (ch06 == 17 & ch04 == 2)
replace ae = 1.02 if ((ch06 >= 18 & ch06 <= 29) & ch04 == 1)
replace ae = 0.76 if ((ch06 >= 18 & ch06 <= 29) & ch04 == 2)
replace ae = 1 if ((ch06 >= 30 & ch06 <= 45) & ch04 == 1)
replace ae = 0.77 if ((ch06 >= 30 & ch06 <= 45) & ch04 == 2)
replace ae = 1 if ((ch06 >= 46 & ch06 <= 60) & ch04 == 1)
replace ae = 0.76 if ((ch06 >= 46 & ch06 <= 60) & ch04 == 2)
replace ae = 0.83 if ((ch06 >= 61 & ch06 <= 75) & ch04 == 1)
replace ae = 0.67 if ((ch06 >= 61 & ch06 <= 75) & ch04 == 2)
replace ae = 0.74 if (ch06 > 75 & ch04 == 1)
replace ae = 0.63 if (ch06 > 75 & ch04 == 2)

* Genero cantidad de adulto equivalente

egen aef = total(ae), by(codusu nro_hogar)

bysort codusu nro_hogar: gen miembros = _N

local alpha1 = 0
local alpha2 = 0.8
local alpha3 = 1

forvalues a = 1/3{
	gen ie_`a' = itf/(aef)^`alpha`a''
}


run "${dofile}/gini.do"

forvalues a = 1/3{
	gini ie_`a' [w=pondih]
}




*----------------------- PUNTO 2

*** Curva de Incidencia del Crecimiento

*** EPH 2024

local ipc23 = 1288.9
local ipc24 = 4814.8

keep ipcf pondih

tempfile arg24
save `arg24', replace


*** Iteramos por períodos
foreach i in 23 24 {
    drop _all
    use `arg`i'', clear  // Cambié `arg`i'' por arg`i', asegurándome de que use `arg23' y `arg24'

    // Asegúrate de que ipc24 y ipc23 estén definidos antes de esta sección
    if "`i'" == "23" {
        replace ipcf = ipcf * `ipc24' / `ipc23'
    }

    // Ordena y calcula el porcentaje de población acumulado
    sort ipcf
    gen shrpop = sum(pondih)
    replace shrpop = shrpop / shrpop[_N]

    // Crea el percentil basado en los rangos de `shrpop`
    gen percentil = .
    forvalues j = 1/100 { // Cambié (1)100 por /100, lo cual es más común
        replace percentil = `j' if shrpop > (`j' - 1) * 0.01 & shrpop <= `j' * 0.01
    }

    // Genera una tabla por percentiles de ingreso
    version 16: table percentil [w=pondih], c(mean ipcf) replace
    rename table1 ipcf`i'

    // Guarda la tabla temporalmente
    sort percentil
    tempfile percentil_arg`i'
    save `percentil_arg`i'', replace
}


merge 1:1 percentil using `percentil_arg23'
gen chg = 100*(ipcf24/ipcf23 - 1)
twoway line chg percentil if inrange(percentil, 5, 95), xlabel(#10)

// graph export "${graph}/cic_1.png", replace


*----------------------- PUNTO 3

use "${data}/EPH_ind_T124", replace

*** Defino variable region-aglomerado para separar CABA de GBA

replace region = 2 if aglomerado == 32

run "${dofile}/atk.do"

mat def W_24 = J(7, 5, .) /// Defino una matriz

local contador = 1

levelsof region, local(levels)

foreach i of local levels {
	preserve
	keep if region == `i'
	summ ipcf [w=pondih]
	local media = r(mean)
	
	mat W_24[`contador', 1] = `media'
	
	gini ipcf [w=pondih]
	
	* SEN
	
	local sen = `media'*(1-r(gini))
	mat W_24[`contador', 2] = `sen'
	
	*KAKWANI
	
	local kak = `media'/(1+r(gini))
	mat W_24[`contador', 3] = `kak'
	
	
	*ATIKSON(1)
	
	atk ipcf [w=pondih], e(1)
	local atk1 = `media'*(1-r(atk))
	mat W_24[`contador', 4] = `atk1'
	
	*ATIKSON(2)
	
	atk ipcf [w=pondih], e(2)
	local atk2 = `media'*(1-r(atk))
	mat W_24[`contador', 5] = `atk2'
	
	restore
	
	local ++ contador
	
}


tempfile arg24
save `arg24', replace


use "${data}/EPH_ind_T123", replace

local ipc23 = 1288.9
local ipc24 = 4814.8


replace region = 2 if aglomerado == 32
replace ipcf = ipcf * `ipc24' / `ipc23'

mat def W_23 = J(7, 5, .) /// Defino una matriz

local contador = 1

levelsof region, local(levels)

foreach i of local levels {
	preserve
	keep if region == `i'
	summ ipcf [w=pondih]
	local media = r(mean)
	
	mat W_23[`contador', 1] = `media'
	
	gini ipcf [w=pondih]
	
	* SEN
	
	local sen = `media'*(1-r(gini))
	mat W_23[`contador', 2] = `sen'
	
	*KAKWANI
	
	local kak = `media'/(1+r(gini))
	mat W_23[`contador', 3] = `kak'
	
	
	*ATIKSON(1)
	
	atk ipcf [w=pondih], e(1)
	local atk1 = `media'*(1-r(atk))
	mat W_23[`contador', 4] = `atk1'
	
	*ATIKSON(2)
	
	atk ipcf [w=pondih], e(2)
	local atk2 = `media'*(1-r(atk))
	mat W_23[`contador', 5] = `atk2'
	
	restore
	
	local ++ contador
	
}

tempfile arg23
save `arg23', replace

mat W = W_24, W_23
drop _all
svmat W 
export excel using "${output}/matrix_indicadores.xlsx", replace


*----------------------- PUNTO 4

* Armado de la Curva de Lorenz

use "${data}/EPH_ind_T124", replace

destring _all, replace
destring ipcf, dpcomma replace
keep if inrange(deccfr, 1, 10)
drop if nro_hogar == 51 | nro_hogar == 71

replace region = 2 if aglomerado == 32
keep ipcf pondih region

sort region ipcf
by region: gen pop = sum(pondih)
by region: gen shrpop = pop / pop[_N]
by region: gen glorenz = sum(ipcf * pondih)
by region: replace glorenz = glorenz / glorenz[_N]

twoway (line glorenz shrpop if region == 1) ///
       (line glorenz shrpop if region == 2) ///
       (line shrpop shrpop), ///
	   legend(label(1 "Partidos del GBA") label(2 "CABA")) ///
       title("Curva de Lorenz - 2024") ///
       name(Lorenz2024, replace)

	   
twoway (line glorenz shrpop if region == 41) ///
       (line glorenz shrpop if region == 43) ///
       (line shrpop shrpop), ///
	   legend(label(1 "NEA") label(2 "Patagonia")) ///
       title("Curva de Lorenz - 2024") ///
       name(Lorenz2024_2, replace)

use "${data}/EPH_ind_T123", replace

destring _all, replace
destring ipcf, dpcomma replace
keep if inrange(deccfr, 1, 10)
drop if nro_hogar == 51 | nro_hogar == 71

replace region = 2 if aglomerado == 32
keep ipcf pondih region

local ipc23 = 1288.9
local ipc24 = 4814.8

gen ipcf23 = ipcf * `ipc24' / `ipc23'
drop ipcf

sort region ipcf23
by region: gen pop = sum(pondih)
by region: gen shrpop = pop / pop[_N]
by region: gen glorenz = sum(ipcf23 * pondih)
by region: replace glorenz = glorenz / glorenz[_N]

twoway (line glorenz shrpop if region == 1) ///
       (line glorenz shrpop if region == 2) ///
       (line shrpop shrpop), ///
	   legend(label(1 "Partidos del GBA") label(2 "CABA")) ///
       title("Curva de Lorenz - 2023") ///
       name(Lorenz2023, replace)

	   
twoway (line glorenz shrpop if region == 41) ///
       (line glorenz shrpop if region == 43) ///
       (line shrpop shrpop), ///
	   legend(label(1 "NEA") label(2 "Patagonia")) ///
       title("Curva de Lorenz - 2023") ///
       name(Lorenz2023_2, replace)

graph combine Lorenz2023 Lorenz2024

graph combine Lorenz2023_2 Lorenz2024_2



