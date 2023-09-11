######## R Code for SDM using BIOMOD2 for an example of a plant species #########

rm(list=ls())

setwd("your_path")


library(raster)
library(biomod2)

read.csv("./pollen_csvs_thinned/Centaurea_diluta_thin.csv/Centaurea_diluta_thin1.csv")->Centaurea_diluta_xy

print(Centaurea_diluta_xy)

coordinates(Centaurea_diluta_xy)<-cbind(Centaurea_diluta_xy$coords.x1,Centaurea_diluta_xy$coords.x2)

WGS84 <- CRS("+init=epsg:4326") #WGS84
proj4string(Centaurea_diluta_xy)<-WGS84
#Centaurea_diluta_xy <- spTransform(Centaurea_diluta_xy, lamaz)
Centaurea_diluta_xy<-coordinates(Centaurea_diluta_xy)
#Centaurea_diluta_xy<-SpatialPoints(Centaurea_diluta_xy, lamaz)
Centaurea_diluta_xy<-SpatialPoints(Centaurea_diluta_xy, WGS84)
write.csv(Centaurea_diluta_xy,file="Centaurea_diluta_xy.csv")



##############################################################################################################################
### BIOMOD2
##############################################################################################################################

###############################################
# Prepare  data

myRespName <- "Centaurea_diluta"
myExpl = stack("crop_2.asc","crop_15.asc","crop_7.asc","crop_9.asc","crop_16.asc")
nrep = 5

###############################################
# Prepare model

myBiomodData <- BIOMOD_FormatingData(
  resp.var = Centaurea_diluta_xy, 
  expl.var = myExpl,
  resp.name= myRespName,
  PA.nb.rep= 5,
  PA.nb.absences=1000,
  PA.strategy='random')

sink(file="Centaurea_diluta_MyBiomodData.txt")
print(myBiomodData)
sink()

pdf(file="Centaurea_diluta_BiomodData.pdf")
plot(myBiomodData)
dev.off()

###########START MODELING###########

myBiomodOption <- BIOMOD_ModelingOptions(GAM=list(algo='GAM_mgcv',k=4))

myBiomodModelOut <- BIOMOD_Modeling(
  myBiomodData,
  models = c('GLM','GAM','MARS','CTA','FDA','RF'),
  models.options = myBiomodOption,
  NbRunEval=nrep,
  DataSplit=80,
  Prevalence=0.5,
  VarImport=5,
  models.eval.meth = c('TSS','ROC','KAPPA'),
  SaveObj = TRUE,
  rescal.all.models = FALSE,
  do.full.models = FALSE,
  modeling.id = paste(myRespName,"FirstModeling",sep=""))

myBiomodModelOut

###########MODELING EVALUATION###########

#get all models evaluation
myBiomodModelEval <- get_evaluations(myBiomodModelOut)
write.csv(myBiomodModelEval,file="Centaurea_diluta_model_evaluations.csv")

dimnames(myBiomodModelEval)

#print TSS scores of RF
sink("Centaurea_diluta_TSS_scores.txt")
myBiomodModelEval["TSS","Testing.data","GLM",,]
myBiomodModelEval["TSS","Testing.data","GAM",,]
myBiomodModelEval["TSS","Testing.data","MARS",,]
myBiomodModelEval["TSS","Testing.data","CTA",,]
myBiomodModelEval["TSS","Testing.data","GBM",,]
myBiomodModelEval["TSS","Testing.data","FDA",,]
sink()

#print ROC scores of all selected models
myBiomodModelEval["ROC","Testing.data",,,]
write.csv(myBiomodModelEval["ROC","Testing.data",,,],file="Centaurea_diluta_model_evaluations_ROC.csv")


#print variable importances
sink("Centaurea_diluta_variables_importance.txt")
get_variables_importance(myBiomodModelOut)
sink()


#############ENSEMBLE MODELING##############

myBiomodEM <- BIOMOD_EnsembleModeling(
  modeling.output = myBiomodModelOut,
  chosen.models = 'all',
  em.by='all',
  eval.metric = c('TSS'), 
  eval.metric.quality.threshold = c(0.7), 
  prob.mean = T,  
  prob.cv = T,
  prob.ci = T,
  prob.ci.alpha = 0.05,
  prob.median = T,
  committee.averaging = T,
  prob.mean.weight = T, 
  prob.mean.weight.decay = 'proportional')

myBiomodEM

###########START PROJECTION CURRENT###########
myBiomodProj <- BIOMOD_Projection(
  
  modeling.output = myBiomodModelOut,
  new.env =  myExpl, 
  proj.name = 'current',
  selected.models = 'all',
  binary.meth = 'TSS',
  compress = 'xz', 
  clamping.mask = F,
  output.format = '.grd')


########### ENSEMBLE FORECASTING ###########


myBiomodEF <- BIOMOD_EnsembleForecasting(
  EM.output = myBiomodEM,
  total.consensus = TRUE,
  filtered.meth=NULL,
  projection.output = myBiomodProj)

plot(myBiomodEF)

######## CONVERT OUTPUT FORMATS ##########

raster("./Centaurea_diluta/proj_current/proj_current_Centaurea.diluta_ensemble.gri")->current_output
writeRaster(current_output, filename="./Centaurea_diluta/proj_current_Centaurea.diluta_ensemble.asc", datatype="INT4S", format="ascii", overwrite=TRUE)
Centaurea.diluta <- raster("./Centaurea_diluta/proj_current_Centaurea.diluta_ensemble.asc")

#######################################################
###################### Plot Maps ######################

pdf("./Centaurea_diluta/Centaurea_diluta.pdf")
plot(Centaurea_diluta)
#points(Centaurea_diluta_xy, pch=1, col="red4",cex = 0.5)
dev.off()

pdf("./Centaurea_diluta/Centaurea_diluta_points.pdf")
plot(Centaurea_diluta)
points(Centaurea_diluta_xy, pch=1, col="red4",cex = 0.5)
dev.off()



######## SAVE OBJECT ##########

save.image(file="Centaurea_diluta.RData")




