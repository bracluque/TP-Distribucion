capture program drop gini
program define gini, rclass
    syntax varlist(max=1 numeric) [if] [iweight]
    
    preserve
    
    marksample touse
    keep if `touse'
    
    display "varlist: `varlist'" _newline ///
            "weight: `weight'" _newline ///
            "exp: `exp'"
    
    local wt : word 2 of `exp'
    if "`wt'" == "" {
        local wt = 1
    }
    
    summ `varlist' [`weight' `exp'] if `varlist' > 0
    
    local obs = r(sum_w)
    local media = r(mean)
    
    sort `varlist'
    
    tempvar aux i aux2
    
    gen `aux' = sum(`wt') if `varlist' > 0
    gen `i' = (2 * `aux' - `wt' + 1) / 2
    gen `aux2' = `varlist' * (`obs' - `i' + 1)
    
    summ `aux2' [`weight' `exp'] if `varlist' > 0
    
    local gini = 1 + (1 / `obs') - (2 / (`media' * `obs'^2)) * r(sum)
    
    display "gini = `gini'"
    
    restore
    
    return scalar gini = `gini'
end