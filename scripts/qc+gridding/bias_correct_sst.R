# Apply bucket_corrections to the new gridded SST datasets
library(PP)

Corrections_file <-
   paste("/ibackup/cr1/hadobs/icoads/mds2.1_datasets/bias_corrections/SST/",
         "data/bucket_median_HadSST2_newclim_HadNAT2_1+allunc_WW2adj_stn.pp",
         sep="")
         
f<-pp.open.file(Corrections_file)
Corrections<-NULL
Dates<-list()
repeat {
    pp<-pp.read(f)
    if(is.null(pp)) { break }
    Corrections<-c(Corrections,pp)
    dstring <-sprintf("%4d%02d",pp@lbyr,pp@lbmon)
    Dates[[dstring]]<-length(Corrections)
}
pp.close.file(f)    

f<-pp.open.file('../../gridded_fields/sst/5x5/new.pp')
fo<-pp.open.file('../../gridded_fields/sst/5x5/new_bc.pp',mode='w')
repeat {
    pp<-pp.read(f)
    if(is.null(pp)) { break }
    dstring <-sprintf("%4d%02d",pp@lbyr,pp@lbmon)
    if(!is.null(Dates[[dstring]])) {
        pp@data <- pp@data + Corrections[[Dates[[dstring]]]]@data
    }
    pp.write(pp,fo)
}
pp.close.file(f)
pp.close.file(fo)
