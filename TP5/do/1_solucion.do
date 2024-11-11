/*------------------------------------------------------------------------------
					UNLP - Economía de la Distribucion

	* File name		: solution.do
	* Authors		: Emiliano Bohorquez, Brayan A. Condori, Agustin Deniard
	* Date			: 20241020 
	* Objective		: Este do-file resuelve el TP5 de Distribucion 

*-----------------------------------------------------------------------------*/
	log using "${cwd}/log_solucion", smcl replace

*------------------------------------------------------------------------------*
**# PREGUNTA 1						
*------------------------------------------------------------------------------*
	
	preserve
		 version 16: table educ_max [w=f_calib3], c(mean ithpc) replace
	restore

	preserve
		version 16: table mujer educ_max [w=f_calib3], c(mean ithpc) replace
	restore

	preserve
		version 16: table etnia educ_max [w=f_calib3], c(mean ithpc) replace
	restore


*------------------------------------------------------------------------------*
**# PREGUNTA 2: Estimación paramétrica	
*------------------------------------------------------------------------------*
* Obtenemos las distribución predichas para cada tipo

* Sexo
	reg lipcf mujer [pw = f_calib3], robust
	predict yhat1, xb
	replace yhat1 = exp(yhat1)

*Sexo etnia
	reg lipcf mujer etnia [pw = f_calib3], robust
	predict yhat2, xb
	replace yhat2 = exp(yhat2)

*Sexo etnia educación
	reg lipcf mujer etnia i.educ_max [pw = f_calib3], robust
	predict yhat3, xb
	replace yhat3 = exp(yhat3)

*Sexo etnia educación lugar de nacimiento
	reg lipcf mujer etnia i.educ_max i.nacimiento [pw = f_calib3], robust
	predict yhat4, xb
	replace yhat4 = exp(yhat4)

* Calculamos el Gini con las distribuciones predichas

	gini yhat1 [w = f_calib3], reps(200) bs
	local gini_yhat1 = r(gini)

	gini yhat1 [w = f_calib3], reps(200) bs
	local gini_yhat2 = r(gini)

	gini yhat1 [w = f_calib3], reps(200) bs
	local gini_yhat3 = r(gini)

	gini yhat1 [w = f_calib3], reps(200) bs
	local gini_yhat4 = r(gini)

* La desigualdad de oportunidades es:
* Recordemos que esto es una medida absoluta para cada grupo

	di " D. de oportunidades (sexo) =" `gini_yhat1'
	di " D. de oportunidades (sexo y etnia) =" `gini_yhat2'
	di " D. de oportunidades (sexo, etnia y educación) =" `gini_yhat3'
	di " D. de oportunidades (sexo, etnia, educacion y region de nacimiento) =" `gini_yhat4'

* Ahora calculamos cúanto de esta desigualdad es producto de la desigualdad de oportunidades.

* Para ello, calculamos la desigualdad total:

	gini ithpc [w = f_calib3], reps(200) bs
	local gini_ipcf = r(gini)

* Calculamos la desigualdad relativa

	di " D. de oportunidades relativa (sexo) =" `gini_yhat1'/`gini_ipcf'
	di " D. de oportunidades relativa (sexo y etnia) =" `gini_yhat1'/`gini_ipcf'
	di " D. de oportunidades relativa (sexo, etnia y educación) =" `gini_yhat1'/`gini_ipcf'
	di " D. de oportunidades relativa (sexo, etnia, educacion y region de nacimiento) =" `gini_yhat1'/`gini_ipcf'

	drop yhat1 yhat2 yhat3
	rename yhat4 yhat
*------------------------------------------------------------------------------*
**# PREGUNTA 3: Estimación NO paramétrica	
*------------------------------------------------------------------------------*

	gen ipcf2 = .

* Iteramos por cada uno de los posibles grupos. Recordemos la madlcion de la dimensionalidad como el mayor problema. Intensivo en datos.
	qui {
		forval nac = 1(1)9 {
			forval edu = 1(1)6 {
				forval  muj = 0(1)1 {
					forval etn = 0(1)1 {
						sum ithpc [w=f_calib3] if ///
							nacimiento == `nac' & ///
							educ_max == `edu' & ///
							mujer == `muj' & ///
							etnia == `etn'
						replace ipcf2 = r(mean) if ///
							nacimiento == `nac' & ///
							educ_max == `edu' & ///
							mujer == `muj' & ///
							etnia == `etn'
					}
				}
			}
		}
	}

* Gini de yhat 
	gini ipcf2 [w=f_calib3], reps(200) bs
	local gini_ipcf2 = r(gini)

*  Desigualdad de oportunidades:

	di " D. de oportunidades (no parametrica) =" `gini_ipcf2'
	di " D. de oportunidades (parametrica) =" `gini_yhat4'

* Desigualdad de oportunidades relativa:

	di " D. de oportunidades relativa (no parametrica) =" `gini_ipcf2'/`gini_ipcf'
	di " D. de oportunidades relativa (parametrica) =" `gini_yhat4'/`gini_ipcf'

*Botton line:  NO hay mucha diferencia entre la esti,ación paramétrica y no parametrica.

*------------------------------------------------------------------------------*
**# PREGUNTA 4
*------------------------------------------------------------------------------*

	gen gini_iop = .
	gen gini_iop_se = .
	gen gini_t =.


* Por regiones:

	forval i = 1(1)8 {
		gini yhat [w=f_calib3] if region == `i', reps(200) bs
		replace gini_iop = r(gini) if region == `i'
		replace gini_iop_se = _se[_bs_1] if region == `i'
		
		/* Para la desigualdad relativa*/
		gini ithpc [w = f_calib3] if region == `i'
		replace gini_t = r(gini) if region == `i'
	}

preserve
	version 16: table region, c(mean gini_iop mean gini_iop_se) replace
	serrbar table1 table2 region, ///
		scale(2) ytitle("Desigualdad de Oportunidades") xtitle("") xlabel(1(1)8, valuelabel) ///
		ylabel(, angle(horizontal)) legend(position(6)) scale(1.3)
	graph export "${output}/iop_region.pdf", replace
	graph export "${output}/iop_region.png", replace
restore

*------------------------------------------------------------------------------*
**# PREGUNTA 5
*------------------------------------------------------------------------------*

*Gini relativo

	gen gini_r = gini_iop/gini_t

preserve
	version 16: table region, c(mean gini_r) replace
	replace table1 = table1*100
	graph hbar table1, over(region) ytitle("Desigualdad Relativa(%)") ///
		ylabel(, angle(horizontal)) legend(position(6)) scale(1.3)
	graph export "${output}/iop_region_relativa.pdf", replace
	graph export "${output}/iop_region_relativa.png", replace
restore

log close _all