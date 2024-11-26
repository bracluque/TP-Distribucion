* prepara-db.do

* limpieza inicial
destring deccfr ipcf pp07h p47t pp04b_cod itf, replace force

* seleccion observaciones
drop if deccfr >10
drop if nro_hogar==51 | nro_hogar==71


* random numbers; used for sorting
gen rnd = runiform()

* clon ipcf
clonevar ipcf_obs = ipcf

* ingreso individual
clonevar ii = p47t

* identificador de hogar
egen id = group(codusu nro_hogar)

* miembros
* NOTA: es fundamental ordenar tambien por rnd
sort id rnd
by id: gen miembros = _N

* edad
clonevar edad = ch06

* edad sq
gen edad2 = edad*edad

* sexo
gen hombre = 1 if ch04 == 1
replace hombre = 0 if ch04 == 2

gen gender = hombre + 1

* ocupado
gen ocupado = 1 if estado == 1

* desocupado 
gen desocupado = 1 if estado == 2


/*
P21
MONTO DE INGRESO DE LA OCUPACIÓN PRINCIPAL.

TOT_P12
MONTO DE INGRESO DE OTRAS OCUPACIONES.
(Incluye: ocupación secundaria, ocupación previa a la semana de referencia, deudas/retroactivos por ocupaciones anteriores al mes de referencia, etc)

PP3E_TOT 
Total de horas que trabajó en la semana en la ocupación principal. 

PP3F_TOT 
Total de horas que trabajó en la semana en otras Ocupaciones.
*/


* ingreso laboral
* to do: agregar ingresos como tickets
egen ila = rowtotal(p21 tot_p12)
replace ila = 0 if ila<0 & ocupado==1
replace ila = . if ocupado!=1

* logaritmo ingreso laboral
gen lila = log(ila)


* pertenencia a la muestra para ecuación mincer
gen muestra = 1 if edad >=15 & edad <=64 

* dummies niveles educativos
gen prii=1 if nivel_ed==1 | nivel_ed==7
gen pric=1 if nivel_ed==2
gen seci=1 if nivel_ed==3
gen secc=1 if nivel_ed==4
gen supi=1 if nivel_ed==5
gen supc=1 if nivel_ed==6
egen aux = rsum(prii pric seci secc supi supc)
replace prii=0 if prii!=1 & aux==1
replace pric=0 if pric!=1 & aux==1
replace seci=0 if seci!=1 & aux==1
replace secc=0 if secc!=1 & aux==1
replace supi=0 if supi!=1 & aux==1
replace supc=0 if supc!=1 & aux==1
* contar individuos sin nivel educativo
drop if aux!=1
drop aux

* asistencia escolar
gen asiste = 1 if ch10 == 1
replace asiste = 0 if asiste !=1 & !missing(ch10)

* nivel educativo
gen edulev = .
replace edulev = 1 if prii==1
replace edulev = 2 if pric==1
replace edulev = 3 if seci==1
replace edulev = 4 if secc==1
replace edulev = 5 if supi==1
replace edulev = 6 if supc==1


/*
PP04B_COD
¿A qué se dedica o produce el negocio / empresa /
institución? (Ver   Clasificador de    Actividades   Económicas
para Encuestas Sociodemográficas del Mercosur – CAES-
MERCOSUR 1.0)
*/

* aux2 contiene numero de digitos en pp04b_cod original
gen aux1 = strofreal(pp04b_cod)
gen aux2 = strlen(aux1)

* se requiere clasificacion a 2 dígitos

* si 3 o 4 digitos, reporta codigo CIIU 4 digitos
gen ciiu2d = strofreal(pp04b_cod,"%04.0f") if aux2 == 3 | aux2 == 4
replace ciiu2d = substr(ciiu2d,1,2) if aux2 == 3 | aux2 == 4
* si 1 o 2 digitos, reporta codigo CIIU 2 digitos
replace ciiu2d = strofreal(pp04b_cod,"%02.0f") if aux2 == 1 | aux2 == 2

gen ciiu2d_alt = real(ciiu2d)


* start: used in ocup 

* note: to be flexible, not working must be ocup=1
* trabajador familiar en non-salaried
gen     ocup = 1 if ocupado != 1
replace ocup = 2 if cat_ocup==3
replace ocup = 3 if cat_ocup==1 | cat_ocup==2 | cat_ocup==4
label define ocup 1 "not working" 2 "wage worker" 3 "self-employed"
label values ocup ocup

* generate dummy variables from occup
tabulate ocup, generate(ocupdum)


* jefe de hogar
gen jefe=1 if ch03==1
replace jefe=0 if jefe!=1 & ch03!=.

* casado
gen casado = 1 if ch07==1 | ch07==2
replace casado = 0 if casado!=1 & ch07!=.


levelsof gender
local aux = r(levels)
global n_gender : word count `aux'
display "gender categories = " $n_gender

levelsof ocup
local aux = r(levels)
global n_ocup : word count `aux'
display "ocup categories = " $n_ocup  

* end: used in ocup 
