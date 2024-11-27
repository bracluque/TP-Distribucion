*	Setting Up

	clear all			
	set more off		
	set seed 20240924
	version 16
	set scheme ipaplots
*	Set working directory
	
	global cwd  	= "D:\UNLP_Maeco\Distribucion\TP-Distribucion\TP7" 

*	Globals

	global data 	= "${cwd}/data"
	global dofile 	= "${cwd}/do"
	global output 	= "${cwd}/output"

	
	
* Corremos los dofiles de apoyo

  run "${dofile}\fgt-libro.do"
<<<<<<< HEAD
  run "${dofile}\gcuan.do"
	run "${dofile}\gini-libro.do"
=======
  run "${dofile}\gini-libro.do"
	
  

>>>>>>> 892a51ab52640de23a95694fcc9d822ff22111b2
* Importamos la base
use "${data}/EPH_ind_T124.dta" 


* preparar base de datos
do "${dofile}\prepara-db.do" 
  

*### Punto 1 --------------------------------------------------------

* 1.a

local tasa 0.05 // Tasa de crecimiento promedio
local  años 10   // Cantidad de años
gen ipcf_10 = ipcf * (1 + `tasa')^`años'

do "${dofile}\rep-cic.do" "años10" ipcf ipcf_10


graph export "${output}\grafico_ipcf_10.png", replace
*graph export "${output}\grafico_ipcf_10.pdf", replace



* 1.b

local tasa 0.25

gen ipcf_adm = ipcf*(1+`tasa') if ciiu2d_alt == 84
replace ipcf_adm = ipcf if ciiu2d_alt != 84

do "${dofile}\rep-cic.do" "inc_adm_pub" ipcf ipcf_adm

graph export "${output}\grafico_ipcf_adm_pub.png", replace
*graph export "${output}\grafico_ipcf_adm_pub.pdf", replace

*1.c 
do "${dofile}\sim-oldage.do" "oldage" 125000

do "${dofile}\rep-cic.do" "oldage" ipcf ipcf_oldage

graph export "${output}\grafico_ipcf_oldage.png", replace
*graph export "${output}\grafico_ipcf_oldage.pdf", replace

*### Punto 2 --------------------------------------------------------


run "${dofile}\estimate-occup.do"

do "${dofile}\estimate-mincer.do"

* 2.a
do "${dofile}\sim-secc.do" "secc1" 18 40

do "${dofile}\rep-cic.do" "secc1" ipcf ipcf_secc1

gen lipcf = ln(ipcf)
gen lipcf_secc1 = ln(ipcf_secc1)
twoway (kdensity lipcf if ocup!=1) (kdensity lipcf_secc1 if ocup!=1, lwidth(medium) lcolor(red) ), xline(11.74, lcolor(black)) legend(label(1 "Original") label(2 "Modificado")) xtitle("Logaritmo de salario") ytitle("Densidad")

<<<<<<< HEAD
graph export "${output}\grafico_secc1.png", replace
graph export "${output}\grafico_secc1_pd.pdf", replace

*graph export "${output}\grafico_secc1.pdf", replace
=======
graph export "${output}\grafico_secc1.png", as(png) replace
>>>>>>> 892a51ab52640de23a95694fcc9d822ff22111b2


* 2.b

do "${dofile}\sim-secc.do" "secc2" 18 60

do "${dofile}\rep-cic.do" "secc2" ipcf ipcf_secc2

* Ordeno
sort ipcf, stable


* Genero suma de la población en base al ponderador
gen sumpop = sum(pondih)

* Genero un share de la población
gen shrpop = sumpop/sumpop[_N]

* Genero suma de la totalidad de ingresos ponderado por PONDIH
gen suminc = sum(ipcf*pondih)
gen suminc2 = sum(ipcf_secc2*pondih)

* Genero un share de ingresos
gen shrinc = suminc/suminc[_N]
gen shrinc2 = suminc2/suminc2[_N]


* CURVA DE LORENZ
twoway (line shrpop shrpop) (line shrinc shrpop) (line shrinc2 shrpop), legend(label(2 "Original") label(3 "Modificado") title("Curva de Lorenz"))

<<<<<<< HEAD
graph export "${output}\grafico_secc2.png", replace
graph export "${output}\grafico_secc2_pd.pdf", replace

*graph export "${output}\grafico_secc2.pdf", replace
=======
graph export "${output}\grafico_secc2.png", as(png) replace
>>>>>>> 892a51ab52640de23a95694fcc9d822ff22111b2

* 2.c
do "${dofile}\sim-secc.do" "secc3" 18 80

do "${dofile}\rep-cic.do" "secc3" ipcf ipcf_secc3

gini ipcf [w=pondih] if ipcf>0
gini ipcf_secc3 [w=pondih] if ipcf>0
<<<<<<< HEAD

graph export "${output}\grafico_secc3.png", replace
*graph export "${output}\grafico_secc3.pdf", replace
=======
>>>>>>> 892a51ab52640de23a95694fcc9d822ff22111b2

* 2.d
do "${dofile}\sim-secc.do" "secc4" 18 999
	
do "${dofile}\rep-cic.do" "secc4" ipcf ipcf_secc4

graph export "${output}\grafico_secc4.png", replace
*graph export "${output}\grafico_secc4.pdf", replace

*### Punto 3 --------------------------------------------------------

* Importamos la base
use "${data}/EPH_ind_T124.dta" , clear
* preparar base de datos
do "${dofile}\prepara-db.do" 
  
* Dofiles de la parte anterior
do "${dofile}\punto3/estimate-mincer.do"
do "${dofile}\estimate-occup.do"

* describe data
do "${dofile}\punto3/desc-data.do"

* sim changes in determinants of occup categ: secc
do "${dofile}\punto3\sim-secc.do" "secc"



* start: sim-part parametric sorting


* do file with scenario definition: blank
include "${dofile}\punto3\scen-defn-blank.do"
do "${dofile}\punto3\sim-part.do" "blank" "shk_part" 15 999


* do file with scenario definition: unemp
include "${dofile}\punto3\scen-defn-unemp.do"
do "${dofile}\punto3\sim-part.do" "unemp" "shk_part" 15 999

* end: sim-part parametric sorting



* cic
do "${dofile}\rep-cic.do" "secc" "ipcf" "ipcf_secc"
graph export "${output}\grafico_3a.png", replace
*graph export "${output}\grafico_3a.pdf", replace


do "${dofile}\rep-cic.do" "unemp" "ipcf" "ipcf_unemp"
graph export "${output}\grafico_3b.png", replace
*graph export "${output}\grafico_3b.pdf", replace


* argumento = lp
do "${dofile}\calcula-indicadores.do" 125000



