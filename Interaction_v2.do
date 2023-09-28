sysuse auto.dta, clear

*overall
reg price mpg 

*subsamples
reg price mpg if foreign==1
reg price mpg if foreign==0

tabstat price, by(foreign)

*interaction
reg price c.mpg##foreign

reg price foreign c.mpg#foreign
test 1.foreign#c.mpg = 0.foreign#c.mpg

