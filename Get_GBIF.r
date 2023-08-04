rm(list=ls())

#setwd("/MyDir")
#Data retrieval example for "Solanum_dulcamara"

library(devtools)
library(rgbif)
install_github("ropensci/CoordinateCleaner")
library(countrycode)
library(CoordinateCleaner)
library(dplyr)
library(ggplot2)
library(sp)
library(raster)
library(sf)
library(rnaturalearthdata)

library(rgdal)
library(rgeos)
library(dismo)
library(xlsx)
source("https://raw.githubusercontent.com/briatte/ggcorr/master/ggcorr.R")
library(ade4)
library(biomod2)
library(spThin)


#########################################################
################## GET RGBIF DATA #######################
#########################################################

#download data from rgbif
Solanum_dulcamara_gbif <- occ_search(scientificName = 'Solanum_dulcamara ', hasCoordinate = TRUE, hasGeospatialIssue = FALSE, limit = 10000) 

Solanum_dulcamara_data <- Solanum_dulcamara_gbif$data
Solanum_dulcamara_data <- Solanum_dulcamara_data %>%
  dplyr::select(species, decimalLongitude, decimalLatitude, countryCode, individualCount,
                gbifID, family, taxonRank, coordinateUncertaintyInMeters, month, year,
                basisOfRecord, institutionCode, datasetName) #species

Solanum_dulcamara_xy<-Solanum_dulcamara_data %>%
  dplyr::select(decimalLongitude, decimalLatitude)

Solanum_dulcamara_data <- Solanum_dulcamara_data%>% #remove no location 
  filter(!is.na(decimalLongitude))%>%
  filter(!is.na(decimalLatitude))

write.csv(Solanum_dulcamara_data,file="Solanum_dulcamara_data_gbif_nocleaned.csv")


#plot data to get an overview
pdf(file="Solanum_dulcamara_overview_map.pdf")
wm <- borders("world", colour="gray50", fill="gray50")
print(ggplot()+ coord_fixed()+ wm +
  geom_point(data = Solanum_dulcamara_data, aes(x = decimalLongitude, y = decimalLatitude),
             colour = "darkred", size = 0.5)+
  theme_bw())
dev.off()

#convert country code from ISO2c to ISO3c
Solanum_dulcamara_data$countryCode <-  countrycode(Solanum_dulcamara_data$countryCode, origin =  'iso2c', destination = 'iso3c')

#prob with data
flags <- clean_coordinates(x = Solanum_dulcamara_data,
                           lon = "decimalLongitude",
                           lat = "decimalLatitude",
                           countries = "countryCode",
                           species = "species",
                           tests = c("capitals", "centroids", "equal","gbif", "institutions",
                                     "zeros", "countries")) # most test are on by default

summary(flags)
pdf(file="Solanum_dulcamara_flags.pdf")
print(plot(flags, lon = "decimalLongitude", lat = "decimalLatitude"))
dev.off()

#Exclude problematic records
dat_cl <- Solanum_dulcamara_data[flags$.summary,]
write.csv(dat_cl,file="Solanum_dulcamara_dat_cleaned.csv")

#The flagged records
dat_fl <- Solanum_dulcamara_data[!flags$.summary,]


########## Explore the sampling repartition ##########

pdf(file="Solanum_dulcamara_sampling.pdf")
barplot(table(dat_cl$month))
barplot(table(dat_cl$year),las=2)
barplot(table(dat_cl$countryCode),las=2)
tab_melt = data.frame(Month=dat_cl$month,Year=dat_cl$year)
print(ggplot(tab_melt,aes(factor(Year),fill=factor(Month))) +
  geom_bar())
table(tab_melt$year,tab_melt$month)
dev.off()

#######################################################

Solanum_dulcamara_xy<-dat_cl %>%
  dplyr::select(species,decimalLongitude, decimalLatitude)

############ SPATIAL THINING ########### 
#thin occurrence by proximity
as.data.frame(Solanum_dulcamara_xy)
thin(Solanum_dulcamara_xy, lat.col="decimalLongitude", long.col="decimalLatitude", spec.col="species",thin.par=10, rep=1, write.files=TRUE,
     out.dir="./getGBIF", out.base="Solanum_dulcamara", write.log.file=TRUE, log.file="Solanum_dulcamara_spatial_thin_log.txt")

read.csv("Solanum_dulcamara_thin1.csv")->Solanum_dulcamara_xy

#plot data to get an overview
pdf(file="Solanum_dulcamara_overview_map_thinned.pdf")
wm <- borders("world", colour="gray50", fill="gray50")
print(ggplot()+ coord_fixed()+ wm +
  geom_point(data = Solanum_dulcamara_xy, aes(x = decimalLongitude, y = decimalLatitude),
             colour = "darkred", size = 0.5)+
  theme_bw())
dev.off()

coordinates(Solanum_dulcamara_xy)<-cbind(Solanum_dulcamara_xy$decimalLongitude,Solanum_dulcamara_xy$decimalLatitude)

WGS84 <- CRS("+init=epsg:4326") #WGS84
proj4string(Solanum_dulcamara_xy)<-WGS84
#Solanum_dulcamara_xy <- spTransform(Solanum_dulcamara_xy, lamaz)
Solanum_dulcamara_xy<-coordinates(Solanum_dulcamara_xy)
#Solanum_dulcamara_xy<-SpatialPoints(Solanum_dulcamara_xy, lamaz)
Solanum_dulcamara_xy<-SpatialPoints(Solanum_dulcamara_xy, WGS84)
write.csv(Solanum_dulcamara_xy,file="Solanum_dulcamara_xy.csv")

