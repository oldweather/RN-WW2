# Merge HadSST2 with the new data to make a long improved dataset
library(PP)

f<-pp.open.file('../../gridded_fields/sst/5x5/both_bc.pp')
nsst<-NULL
Dates<-list()
repeat {
    pp<-pp.read(f)
    if(is.null(pp)) { break }
    nsst<-c(nsst,pp)
    dstring <-sprintf("%4d%02d",pp@lbyr,pp@lbmon)
    Dates[[dstring]]<-length(nsst)
}
pp.close.file(f)    

f<-pp.open.file('/ibackup/cr1/hadobs/icoads/mds2.1_datasets/SST/5x5/ICSST4B.pp')
fo<-pp.open.file('../../gridded_fields/sst/5x5/HadSST3.pp',mode='w')
repeat {
    pp<-pp.read(f)
    if(is.null(pp)) { break }
    dstring <-sprintf("%4d%02d",pp@lbyr,pp@lbmon)
    if(!is.null(Dates[[dstring]])) {
        pp <- nsst[[Dates[[dstring]]]]
    }
    pp.write(pp,fo)
}
pp.close.file(f)
pp.close.file(fo)
