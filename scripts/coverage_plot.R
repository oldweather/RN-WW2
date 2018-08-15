# Plot the distribution of no. of obs 
library(PP.map)

# Convert from a fraction to a categorical scale
reLabel = function(data) {
    for(i in 1:length(data)) {
        if(!is.na(data[i])) {
            if(data[i] > 20) { data[i]=4 }
            else {
                if(data[i] >= 1) { data[i]=3 }
                else {
                    if(data[i] >=0.5) { data[i]=2 }
                    else { data[i]=1 }
                }
            }
        }
    }
    return(data)
}

# Convert from fractional to categorical scale
# +ve means new obs raise a category
# -ve meand just as good without new obs
reLabel2 = function(data1,data2) {
    for(i in 1:length(data1)) {
        if(!is.na(data1[i]) && !is.na(data2[i]) ) {
            if(data1[i]+data2[i] > 20) {
                if( data1[i] > 20 ) { data1[i]=-4 }
                else { data1[i] = 4 }
            }
            else {
                if(data1[i]+data2[i] >= 1) {
                    if( data1[i] >=1 ) { data1[i]=-3 }
                    else { data1[i] = 3 }
                }
                else {
                    if(data1[i] +data2[i] >=0.5) {
                        if( data1[i] >=0.5 ) { data1[i]=-2 }
                        else { data1[i] = 2 }
                    }
                    else {
                        data1[i]=-1
                        
                    }
                }
            }
        }
        else {
            if(!is.na(data1[i])) {
                if(data1[i] > 20) { data1[i]=-4 }
                else {
                    if(data1[i] >= 1) { data1[i]=-3 }
                    else {
                        if(data1[i] >=0.5) { data1[i]=-2 }
                        else { data1[i]=-1 }
                    }
                }
            }
            if(!is.na(data2[i])) {
                if(data2[i] > 20) { data1[i]=-4 }
                else {
                    if(data2[i] >= 1) { data1[i]=-3 }
                    else {
                        if(data2[i] >=0.5) { data1[i]=-2 }
                        else { data1[i]=-1 }
                    }
                }
            }
        }
            
    }
    return(data1)
}

# Define four sequential colours
sequential=
       c(
         rgb( 204, 250, 255 ,maxColorValue = 255 ),
         rgb( 153, 229, 255 ,maxColorValue = 255 ),
         rgb( 76,  165, 255 ,maxColorValue = 255 ),
         rgb( 0,   63,  255 ,maxColorValue = 255 )
        )


# define 9 diverging colours
diverging=
       c(
         rgb( 0,   63,  255 ,maxColorValue = 255 ),
         rgb( 76,  165, 255 ,maxColorValue = 255 ),
         rgb( 153, 229, 255 ,maxColorValue = 255 ),
         rgb( 204, 250, 255 ,maxColorValue = 255 ),
         rgb( 255, 255, 255 ,maxColorValue = 255 ),  # White - 0
         rgb( 255, 241, 188 ,maxColorValue = 255 ),
         rgb( 255, 172, 117 ,maxColorValue = 255 ),
         rgb( 247,  39,  53 ,maxColorValue = 255 ),
         rgb( 165,   0,  33 ,maxColorValue = 255 )
         )

# New map function to use specified colours and labels
ppd.map <-function(pp,palette="diverging",ncols=17,levels=NA,lat_range=c(-90,90),
                  lon_range=c(-180,180),contour=FALSE,region=TRUE,pretty=FALSE) {

  mappanel <- function(x,y,...) {
      panel.contourplot(x,y,...)
      llines(pp.map.internal.wm$x,pp.map.internal.wm$y,col="black")
  }

  lats<-pp.get.lats(pp)
  longs<-pp.get.longs(pp)

      contourplot(pp@data ~ longs * lats,
         ylab="Latitude",xlab="Longitude",
         xlim=lon_range,
         ylim=lat_range,
         scales=list(x=list(at=c(-135,-90,-45,0,45,90,135)),
                     y=list(at=c(-60,-30,0,30,60))
                    ),
         panel=mappanel,
         aspect="iso",
         region=region,
         contour=contour,
         pretty=pretty,
         at=c(-4.5,-3.5,-2.5,-1.5,-.5,.5,1.5,2.5,3.5,4.5),
         col.regions=diverging,
         colorkey=list(
                  space = "right", 
                  labels=list(
                    at=c(-4.5,-3.5,-2.5,-1.5,-.5,.5,1.5,2.5,3.5,4.5),
                    lab=c("","20","1","0.5","0","0","0.5","1","20","")
                  )
                )
      )
}
pps.map <-function(pp,palette="diverging",ncols=17,levels=NA,lat_range=c(-90,90),
                  lon_range=c(-180,180),contour=FALSE,region=TRUE,pretty=FALSE) {

  mappanel <- function(x,y,...) {
      panel.contourplot(x,y,...)
      llines(pp.map.internal.wm$x,pp.map.internal.wm$y,col="black")
  }

  lats<-pp.get.lats(pp)
  longs<-pp.get.longs(pp)

      contourplot(pp@data ~ longs * lats,
         ylab="Latitude",xlab="Longitude",
         xlim=lon_range,
         ylim=lat_range,
         scales=list(x=list(at=c(-135,-90,-45,0,45,90,135)),
                     y=list(at=c(-60,-30,0,30,60))
                    ),
         panel=mappanel,
         aspect="iso",
         region=region,
         contour=contour,
         pretty=pretty,
         at=c(.5,1.5,2.5,3.5,4.5),
         col.regions=sequential
      )
}

# Make the plot
#o=pp.ppa('../gridded_fields/sst/2x2/nobs_old_mean.pp')
#o[[1]]@data=reLabel(o[[1]]@data)
#pps.map(o[[1]])

o=pp.ppa('../gridded_fields/sst/2x2/nobs_old_mean.pp')
n=pp.ppa('../gridded_fields/sst/2x2/nobs_new_mean.pp')
o[[1]]@data=reLabel2(o[[1]]@data,n[[1]]@data)
postscript(file="../docs/coverage.ps",pointsize=14)
ppd.map(o[[1]])

q('no')
