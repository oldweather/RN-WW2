# R script to make a box and whisker plot of the pressure anomalies

library(grid)
library(lattice)
sts<-read.table('pre_anoms.out',header=T)
x=rep(0,0)
y=rep(0,0)
for(i in seq(2,length(sts))) { 
   sety = paste(c("yd=sts$",names(sts)[i]),collapse="")
   eval(parse(text=sety))
   year = sub ('/.*','',sts$Date)
   x=append(x,rep(gsub('_',' ',names(sts)[i]),length(yd)))
   y=append(y,yd)
}
postscript(file="pre_anom_bwplot_byShip.ps",paper="a4",horizontal=F)

trellis.par.set(list(fontsize=list(text=10)))
bwplot(x~y,
           xlab='Pressure anomaly (hPa)',
           xlim=c(-40,40),
           panel=function(x,y) {
             panel.lines(c(0,0),c(0.5,length(x)-0.5))
             panel.bwplot(x,y) }
      )
