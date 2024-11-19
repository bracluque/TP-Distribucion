* curva-engel.do

use "${data}\data-1", clear

* share food promedio
summ shfood [w=pondera]
local mu_shfood = r(mean)

* generar percentiles ipcf
gcuan ipcf [w=pondera], n(100) g(percentil)

preserve

table percentil [w=pondera], c(mean shfood) replace
line table1 percentil, ///
	title("Curva Engel") ///
	xtitle("percentil ipcf") ///
	ytitle("cons de alimentos como % del cons total") ///
	yline(`mu_shfood')
	
rename table1 shfood
* guardar base de datos con participación alimentos en cons total por percentiles
save "${data}\shfood_percentil", replace

restore
	