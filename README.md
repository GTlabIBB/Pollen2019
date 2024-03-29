Code for GORKI et al (2023) "Pollen metabarcoding reveals the origin and multigenerational migratory pathway of an intercontinental-scale butterfly outbreak"

This repository includes code used for:

1) Calculating NDVI anomalies along a time-series (anomalies_npphen.R)
2) Classifying ITS2 reads from plant metabarcoding sequencing (sintax_pollen.sh)
3) Obtaining GBIF plant occurrence data and filtering (Get_GBIF.r)
4) Species distribution modelling of identified plants (plant_SDM.r)
5) Creating convex hulls for plant distributions based on reported occurrences and model-based buffer zone (convex_hull.R)
6) Overlay resulting rasters from models for a set of plants to build geolocated probability maps for each spatio-temporal group (overlay_rasters.R)

PIPELINE DIAGRAM

![Pollen_pipeline](https://github.com/GTlabIBB/Pollen2019/assets/91366581/3594e25a-2806-466c-8de8-192558d2ff94)

