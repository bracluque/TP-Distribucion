* genera-ing-familiar.do

* ingreso laboral total familiar observado
bysort id: egen ilatf_obs = total(ila)

* ingreso laboral total familiar simulado
by id: egen ilatf_sim=total(ila_`nombre') 

* ingreso total familiar simulado
gen itf_`nombre' = itf - ilatf_obs + ilatf_sim

* ingreso per capita familiar simulado
gen ipcf_`nombre' = itf_`nombre'/miembros

drop ilatf_obs ilatf_sim




 


