*DOFILE SIM-OLDAGE

args name lp


fgt ipcf [w=pondera], a(0) z(`lp')

gen trnsfr01 = 0
replace trnsfr01 = 1 if ii<`lp' & edad > 60

gen trnsfr = `lp' - ii if trnsfr01 == 1

bysort id: egen trnsfrtf = total(trnsfr)

gen trnsfrpcf = trnsfrtf/miembros

gen ipcf_`name' = ipcf + trnsfrpcf

fgt ipcf_`name' [w=pondera], a(0) z(`lp')

summ trnsfrpcf [w=pondera]
local costo = r(sum)
summ ipcf [w=pondera]
local costo = `costo'/r(sum)*100
display as text "costo = " as result `costo' "%"

drop trnsfr01 trnsfr trnsfrtf trnsfrpcf

