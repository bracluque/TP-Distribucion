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

graph export "${output}\grafico_secc1.png", as(png) replace


* 2.b

do "${dofile}\sim-secc.do" "secc2" 18 60

do "${dofile}\rep-cic.do" "secc2" ipcf ipcf_secc2

graph export "${output}\grafico_secc2.png", as(png) replace

* 2.c
do "${dofile}\sim-secc.do" "secc3" 18 80

do "${dofile}\rep-cic.do" "secc3" ipcf ipcf_secc3

graph export "${output}\grafico_secc3.png", as(png) replace

* 2.d
do "${dofile}\sim-secc.do" "secc4" 18 999

do "${dofile}\rep-cic.do" "secc4" ipcf ipcf_secc4

graph export "${output}\grafico_secc4.png", as(png) replace

  
*### Punto 3 --------------------------------------------------------







