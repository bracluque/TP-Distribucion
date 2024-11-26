* rep-cic.do

args scen v0 v1 


* start: selected indicators for graphs

gen welf0 = `v0'
gen welf1 = `v1' 

gen lwelf0 = log(welf0)
gen lwelf1 = log(welf1)

* end: selected indicators for graphs


* start: growth-incidence curves


preserve

* exclude outliers

/*
gen welfxp = welf1/welf0 - 1
summ welfxp, detail
//drop if welfxp>r(p99) & welfxp!=.
//drop if welfxp>welfxp[10]
gsort -welfxp
*/



gcuan welf0 [w=pondiio], n(100) g(percentile)
//xtile percentile = welf0 [w=pondiio], nq(100)


table percentile [w=pondiio], c(mean welf0 mean welf1) replace

gen `v1'xp = 100 * (table2/table1 - 1)

twoway (line `v1'xp percentile) if percentile>1

restore


* end: growth-incidence curves


* start: clean

drop welf0 welf1 lwelf0 lwelf1

* end: clean

/*
twoway (kdensity lwelf0 [w=popwt]) ///
       (kdensity lwelf1 [w=popwt])
*/

