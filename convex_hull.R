#-+-+-+-+-+-+-+ CONVEX HULL +-+-+-+-+-+-+-    #This script has to be set for looping


#Load packacges
library(SpatialGraph)
library(rgeos)
library(sp)
library(raster)
library(rgdal)
library(sf)
library(dplyr)
#library(terra)

#Read data
setwd("/Users/Onki/Desktop/multispecies_modelling5_mask")
obs_list = list.files(pattern="_thin1.csv")
model_list = list.files(pattern="ensemble.asc")

world = readOGR("world.shp")


for(i in 1:length(obs_list)){
setwd("/Users/Onki/Desktop/multispecies_modelling5_mask")
  obs = read.csv(paste0(obs_list[i]))
  model = raster(paste0(model_list[i]))

#Turn csv to spatial points
  var_buff = data.frame(ID=1, dissolve=1000)
  
  
  crs = crs(world)
  crs@projargs = ifelse(is.na(crs@projargs), "+proj=longlat +datum=WGS84 +no_defs",crs@projargs )
  ext = as.vector(extent(model))
  obs_sp = SpatialPointsDataFrame(obs[,3:2],
                                  obs,
                                  proj4string = crs)
  obs_sp2 = crop(obs_sp, (ext+c(0,5,-5,0)))
  sp.name = substring(sub("_ensemble_masked","",paste0(names(model),"_masked")),14,500)

#Make convex hull

  z = chull(obs_sp2$coords.x1,obs_sp2$coords.x2)              ##calculates the convex hull --this is just a list of x-y points, N vertex 
  dfHull = cbind(obs_sp2$coords.x1[z],obs_sp2$coords.x2[z])   ##the convex hull expressed as a list of selected x-y points                                             ##this plots the vertex of the polygon, just a check
  env <- SpatialPolygons(list(Polygons(list(Polygon(dfHull)), ID=1)))

#Make distance variable convex hull
  
  centroids = coordinates(env)
  x = centroids[,1]
  y = x = centroids[,2]
  sp_chull = SpatialPolygonsDataFrame(env,data=data.frame(1))
  sp_chull$dissolve = 1
  
  lines = as(sp_chull,"SpatialLinesDataFrame")
  
  p_lines = spsample(lines,type="regular",SpatialLinesLengths(lines)/res(model)[1])
  df_plines = SpatialPointsDataFrame(p_lines, data.frame(row.names=row.names(p_lines),ID=1:length(p_lines)))
  df_plines$value = extract(model,p_lines)
  df_plines$value[which(is.na(df_plines$value))] = min(df_plines$value[which(!is.na(df_plines$value))])
  
  
  
  if(nrow(obs_sp2) < 10){
    div = 1000/3.5}else{
      if(nrow(obs_sp2) < 20){
        div = 1000/3}else{
          if(nrow(obs_sp2) < 50){
            div = 1000/2.5}else{
                div = 1000/2}
        }}
  
  var_buff = gBuffer(df_plines, byid=TRUE, width = ifelse(df_plines$value>= 0, df_plines$value/div,0))    # Here you can limit the limit pixel value to make the buffer
  
  
#  var_buff = gBuffer(df_plines, byid=TRUE, width = ifelse(df_plines$value>= 0, df_plines$value/500,0))    # Here you can limit the limit pixel value to make the buffer
  var_buff$dissolve = rep(1, times=length(var_buff))
  buffer = gUnaryUnion(var_buff,id=var_buff$dissolve)
  buffer2 = gUnion(buffer,sp_chull)
  buffer2$dissolve = rep(1,times=length(buffer2))
  buffer3 = gUnaryUnion(buffer2,id=buffer2$dissolve)
  buffer4 = crop(buffer3,extent(model))
  buffer5 = SpatialPolygonsDataFrame(buffer4, data = data.frame(sp.name))
  writeOGR(buffer5,dsn=paste0('chull_',sp.name,'.shp'),layer=1, driver="ESRI Shapefile", overwrite_layer=T)

#Mask external values

  output = mask(model,buffer4,updatevalue=0)
  #plot(output)

  crs(output) = crs(world)
  names(output) = paste0(names(model),"_masked")
  
  setwd(paste0(getwd(),"/results/"))
  
  writeRaster(output, filename = paste0(names(output),".asc"),driver = "ASCII",overwrite=TRUE)

  
  
  
  

#Make pdf to visualize hull performance
  pdf(paste0(names(output),".pdf"),width=15, height= 10)
  plot(output,main=sp.name)
  plot(obs_sp,pch=19, main = sp.name,add=T)
  lines(world,add=T,lwd=0.5,col="darkgrey")
  lines(buffer4,add=T,lty=1)
  lines(sp_chull,ad=T,lty=2)
  plot(obs_sp,add=T,pch=19,col="blue")
  plot(obs_sp2,add=T,pch=19,col="red")
  legend("topright",
         c("Outside model Area","Inside model area"," Buffered convex hull"," Original convex hull"),
         col=c("blue","red","black","black"),
         lty=c(NA,NA,1,2),
         pch=c(19,19,NA,NA)
         )
  

  dev.off()   
  cat(sp.name,"===> OK","\n")
}




# OneHull = T 
#   
#   if(OneHull==T){
#    z = chull(obs_sp2$coords.x1,obs_sp2$coords.x2)           ##calculates the convex hull --this is just a list of x-y points, N vertex 
#    dfHull = cbind(obs_sp2$coords.x1[z],obs_sp2$coords.x2[z])
#    ##the convex hull expressed as a list of selected x-y points                                             ##this plots the vertex of the polygon, just a check
#    env <- SpatialPolygons(list(Polygons(list(Polygon(dfHull)), ID=1)))
#    centroids = coordinates(env)
#    x = centroids[,1]
#    y = x = centroids[,2]
#    sp_chull = SpatialPolygonsDataFrame(env,data=data.frame(1))
#    sp_chull = SpatialPolygonsDataFrame(env,data=data.frame(1))
#    sp_chull$dissolve = 1
#   }else{
#      convHull(data.frame(obs_sp2$coords.x1,obs_sp2$coords.x2),latlon=T,n=3) # <==== Set the number of hulls (always more than 1)
#      sp_chull = z@polygons
#      sp_chull$dissolve = 1
#     }      
# 



