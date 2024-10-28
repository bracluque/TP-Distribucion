
capture program drop atk

program define atk, rclass

   syntax varlist(max=1) [iweight] , Epsilon(real)

   display 	"varlist :  `varlist'"	_newline ///
			"weight  :  `weight'"  	_newline ///
			"exp	 :  `exp'"

   local wt : word 2 of `exp'
   if "`wt'"=="" {
      local wt = 1
   }
   
   tempvar aux1 aux3
   
   
   if `epsilon' == 1 {
   
   gen `aux1' = log(`varlist')
   
   qui sum `aux1' [`weight'`exp']
   local suma = r(sum)
   local obs = r(sum_w)
   
   local aux2 = exp(`suma'/`obs')
   
   qui sum `varlist' [`weight'`exp']
   local media = r(mean)
   
   local atkin = 1 - (`aux2'/`media')
   
   }
   else {
   
   gen `aux3' = `varlist'^(1-`epsilon')
   
   qui sum `aux3' [`weight'`exp']
   local suma = r(sum)
   local obs = r(sum_w)
   
   local aux4 = (`suma'/`obs')^(1/(1-`epsilon'))

   qui sum `varlist' [`weight'`exp']
   local media = r(mean)
   
   local atkin = 1 - (`aux4'/`media')
   
   }

   dis as text "Atkinson = " as result `atkin'

   return scalar atk = `atkin'
   
end

