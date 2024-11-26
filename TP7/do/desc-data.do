* desc-data.do


* start: desc stat



tabulate hombre ocup [iw=pondiio] if sampocup==1, row

tabulate edulev ocup [iw=pondiio] if sampocup==1, row

* average labor income by gender and occupation
table hombre ocup [iw=pondiio] if sampocup==1, c(mean ila) row




* end: desc stat


