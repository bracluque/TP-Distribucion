*	Setting Up

	clear all			
	set more off		
	set seed 20240924
	version 16

*	Set working directory
	
	global cwd  	= "C:\Users\Emiliano\Documents\FCE - UNLP\Economia de la Distribucion\TP-Distribucion\TP7" 

*	Globals

	global data 	= "${cwd}/data"
	global dofile 	= "${cwd}/do"
	global output 	= "${cwd}/output"

	
	
* Corremos los dofiles de apoyo

  run "${dofile}\gcuan.do"
  run "${dofile}\fgt-libro.do"
  run "${dofile}\gini-libro.do"
	
  

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


graph export "${output}\grafico_ipcf_10.png", as(png) replace

* 1.b

local tasa 0.25

gen ipcf_adm = ipcf*(1+`tasa') if ciiu2d_alt == 84
replace ipcf_adm = ipcf if ciiu2d_alt != 84

do "${dofile}\rep-cic.do" "inc_adm_pub" ipcf ipcf_adm

graph export "${output}\grafico_ipcf_adm_pub.png", as(png) replace

*1.c 
do "${dofile}\sim-oldage.do" "oldage" 125000

do "${dofile}\rep-cic.do" "oldage" ipcf ipcf_oldage

graph export "${output}\grafico_ipcf_oldage.png", as(png) replace

*### Punto 2 --------------------------------------------------------


run "${dofile}\estimate-occup.do"

do "${dofile}\estimate-mincer.do"

* 2.a
do "${dofile}\sim-secc.do" "secc1" 18 40

do "${dofile}\rep-cic.do" "secc1" ipcf ipcf_secc1

gen lipcf = ln(ipcf)
gen lipcf_secc1 = ln(ipcf_secc1)
twoway (kdensity lipcf if ocup!=1) (kdensity lipcf_secc1 if ocup!=1, lwidth(medium) lcolor(red) ), xline(11.74, lcolor(black)) legend(label(1 "Original") label(2 "Modificado")) xtitle("Logaritmo de salario") ytitle("Densidad")

graph export "${output}\grafico_secc1.png", as(png) replace


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

graph export "${output}\grafico_secc2.png", as(png) replace

* 2.c
do "${dofile}\sim-secc.do" "secc3" 18 80

do "${dofile}\rep-cic.do" "secc3" ipcf ipcf_secc3

gini ipcf [w=pondih] if ipcf>0
gini ipcf_secc3 [w=pondih] if ipcf>0

* 2.d
do "${dofile}\sim-secc.do" "secc4" 18 999

do "${dofile}\rep-cic.do" "secc4" ipcf ipcf_secc4

graph export "${output}\grafico_secc4.png", as(png) replace

*### Punto 3 --------------------------------------------------------







