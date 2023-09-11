########################
# get overlayed probability rasters for all, present and absent plants in butterfly locations
#########################

library(climateStability)
library(raster)
library(sdmvspecies)


#load rasters

raster("raster_plant1.asc") -> raster_plant1

#rescale 0to1
raster_plant1	= setMinMax(raster_plant1)
rescale0to1(raster_plant1)->raster_plant1
writeRaster(raster_plant1, filename="raster_plant1", format="ascii")
raster("raster_plant1.asc")->raster_plant1
raster(raster_plant1)
#...

#################################################
##### STACK RASTERS BY SPATIOTEMPORAL GROUP #####
#################################################

library(RColorBrewer)
my.palette <- brewer.pal(n = 9, name = "OrRd")


####### SPATIOTEMPORAL GROUP 1 #######

stack_present <- stack(raster_plant1,raster_plant2,...)

present<-mean(stack_present)
pdf(file="SP1_present.pdf")
plot(present, main ="SP1 PRESENT")
plot(present, breaks = c(200, 300, 400, 500, 600, 700, 800, 900, 1000), col = my.palette, main ="SP1 PRESENT")

present <- calc(stack_present, sum)
plot(present, main ="SP1 PRESENT")
rescale0to1(present)->present2
plot(present2, main ="SP1 PRESENT")
plot(present2, breaks = c(0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1), col = my.palette, main ="SP1 PRESENT")

dev.off()


writeRaster(present, filename="SP1 PRESENT_mean", format="ascii")
writeRaster(present2, filename="SP1 PRESENT_sum", format="ascii")


stack_absent <- stack(raster_plant1,raster_plant2,...)

absent<-mean(stack_absent)
pdf(file="SP1 ASBENT.pdf")
plot(absent, main ="SP1 ASBENT")
plot(absent, breaks = c(200, 300, 400, 500, 600, 700, 800, 900, 1000), col = my.palette, main ="SP1 ASBENT")

absent <- calc(stack_absent, sum)
plot(absent, main ="SP1 ASBENT")
rescale0to1(absent)->absent2
plot(absent2, main ="SP1 ASBENT")
plot(absent2, breaks = c(0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1), col = my.palette, main ="SP1 ASBENT")

dev.off()


writeRaster(absent, filename="SP1 ASBENT_mean", format="ascii")
writeRaster(absent2, filename="SP1 ASBENT_sum", format="ascii")


stack_all <- stack(raster_plant1,raster_plant2,...)


all<-mean(stack_all)
pdf(file="SP1 ALL.pdf")
plot(all, main ="SP1 ALL")
plot(all, breaks = c(200, 300, 400, 500, 600, 700, 800, 900, 1000), col = my.palette, main ="SP1 ALL")

all <- calc(stack_all, sum)
plot(all, main ="SP1 ALL")
rescale0to1(all)->all2
plot(all2, main ="SP1 ALL")
plot(all2, breaks = c(0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1), col = my.palette, main ="SP1 ALL")

dev.off()

writeRaster(all, filename="SP1 ALL_mean", format="ascii")
writeRaster(all2, filename="SP1 ALL_sum", format="ascii")


