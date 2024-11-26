***************** Trabajo Práctico 7 **********************

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


* EDICIÓN DE LOS DATOS


	* Genero un número aleatorio para cada individuo

	gen rnd = runiform()

	* PUNTO 1

	* Clonación de variables

	clonevar ipcf_obs = ipcf 

	clonevar ii = p47t

	egen id = group(codusu nro_hogar)

	sort id rnd
	by id: gen miembros = _N

	clonevar edad = ch06

	gen edad2 = edad*edad

	gen hombre = 1 if ch04 == 1
	replace hombre = 0 if ch04 == 2

	gen gender = hombre + 1

	gen ocupado = 1 if estado == 1

	gen desocupado = 1 if estado == 2

	egen ila = rowtotal(p21 tot_p12)

	replace ila = 0 if ila<0 & ocupado == 1

	replace ila = . if ocupado != 1

	gen lila = log(ila)

	gen muestra = 1 if edad >= 15 & edad <= 64

	gen prii = 1 if nivel_ed == 1 | nivel_ed ==7
	gen pric = 1 if nivel_ed == 2
	gen seci = 1 if nivel_ed == 3
	gen secc = 1 if nivel_ed == 4
	gen supi = 1 if nivel_ed == 5
	gen supc = 1 if nivel_ed == 6

	egen aux = rsum(prii pric seci secc supi supc)
	replace prii = 0 if prii != 1 & aux == 1
	replace pric = 0 if pric != 1 & aux == 1
	replace seci = 0 if seci != 1 & aux == 1
	replace secc = 0 if secc != 1 & aux == 1
	replace supi = 0 if supi != 1 & aux == 1
	replace supc = 0 if supc != 1 & aux == 1

	drop if aux != 1
	drop aux

	gen asiste = 1 if ch10 == 1
	replace asiste = 0 if asiste != 1 & !missing(ch10)

	gen edulev = .
	replace edulev = 1 if prii ==1
	replace edulev = 2 if pric ==1
	replace edulev = 3 if seci ==1
	replace edulev = 4 if secc ==1
	replace edulev = 5 if supi ==1
	replace edulev = 6 if supc ==1

	* PP04B_COD
	* aux2 contiene número de digitos en pp04b_cod original

	gen aux1 = strofreal(pp04b_cod)
	gen aux2 = strlen(aux1)

	* Se requiere clasificacion a 2 digitos

	* Si 3 0 4 digitos, reporta codigo CIIU 4 digitos
	gen ciiu2d = strofreal(pp04b_cod, "%04.0f") if aux2 ==3 | aux2 ==4
	replace ciiu2d = substr(ciiu2d, 1, 2) if aux2 == 3 | aux2 == 4
	replace ciiu2d = strofreal(pp04b_cod, "%02.0f") if aux2 == 1 | aux2 == 2

	gen ciiu2d_alt = real(ciiu2d)


	gen ocup = 1 if ocupado != 1
	replace ocup = 2 if cat_ocup == 3
	replace ocup = 3 if cat_ocup == 1 | cat_ocup == 2 | cat_ocup == 4
	label define ocup 1 "not working" 2 "wage worker" 3 "self_employed"
	label values ocup ocup

	tab ocup, gen(ocupdum)

	gen jefe = 1 if ch03 == 1
	replace jefe = 0 if jefe != 1 & ch03 !=.


	gen casado = 1 if ch07 == 1 | ch07 == 2
	replace casado = 0 if casado != 1 & ch07 != .
	levelsof gender
	local aux = r(levels)
	global n_gender : word count `aux'
	display "gender categories = " $n_gender

	levelsof ocupado
	local aux = r(levels)
	global n_ocup : word count `aux'
	display "ocup categories = " $n_ocup



do "${dofile}\sim-oldage.do" "oldage" 125000

do "${dofile}\rep-cic.do" "oldage" ipcf ipcf_oldage

* PUNTO 2

do "${dofile}\estimate-mincer.do"

* 2.a
do "${dofile}\sim-secc.do" "secc1" 18 40

* 2.b
do "${dofile}\sim-secc.do" "secc2" 18 60

* 2.c
do "${dofile}\sim-secc.do" "secc3" 18 80

* 2.d
do "${dofile}\sim-secc.do" "secc4" 18 999

do "rep-cic.do" "secc4" ipcf ipcf_secc4



