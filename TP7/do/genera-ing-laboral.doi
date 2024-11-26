* genera-ing-laboral.doi

matrix score xbeta_aux = beta 

* add residuals
gen lila_sim = xbeta_aux + resid

gen ila_`nombre' = exp(lila_sim)


* overwrite ylab_sim for individuals outside sample
replace ila_`nombre' = ila if sampsel!=1




drop xbeta_aux lila_sim




