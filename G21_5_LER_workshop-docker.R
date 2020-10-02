##------------- GLEON G21.5 meeting Workshop: LakeEnsemblR   -----------------##

## copy example files from the package to current working directory
template_folder <- system.file("extdata/feeagh", package= "LakeEnsemblR")
file.copy(from = template_folder, to = ".", recursive = TRUE)

## change working diorectory to the feeagh folder
setwd("./feeagh")

## Load required libraries for the workshop
library(gotmtools)
library(LakeEnsemblR)
library(ggplot2)
library(ggpubr)
library(rLakeAnalyzer)
library(reshape)
library(RColorBrewer)


## Have a look at the feeagh folder. There will be six files
list.files()

## looc at the meteorological variables dictionary 
print(met_var_dic)

## creat all model subfolders, configuration and forcing files
export_config("LakeEnsemblR.yaml", model = c("FLake", "GLM", "GOTM",
                                             "Simstrat", "MyLake"))

## now there are five additional folders, one for each model
list.files()

## run the ensemble
run_ensemble("LakeEnsemblR.yaml", model = c("FLake", "GLM", "GOTM",
                                            "Simstrat", "MyLake"))

## now there is an additional folder called output which contains the netcdf file
list.files("output")

## change output to csv files and rerun the ensemble
input_yaml_multiple("LakeEnsemblR.yaml", value = "text", key1 = "output",
                    key2 = "format")
run_ensemble("LakeEnsemblR.yaml", model = c("FLake", "GLM", "GOTM",
                                            "Simstrat", "MyLake"))

## now there are additional csv output files in the output folder
list.files("output")

## change output format pack to netcdf
input_yaml_multiple("LakeEnsemblR.yaml", value =  "netcdf", key1 = "output",
                    key2 = "format")

## create heatmap plot from the netcdf file
plot_heatmap("output/ensemble_output.nc")+
  scale_colour_gradientn(limits = c(0, 21),
                         colours = rev(RColorBrewer::brewer.pal(11, "Spectral")))+
  theme_light()

## create a plot with time series and time series of residuals at 2.5 m depth
p1 <- plot_ensemble("output/ensemble_output.nc", model = c("FLake", "GLM",
                                                           "GOTM", "Simstrat",
                                                           "MyLake"),
                    var = "temp", depth = 2.5,
                    residuals = TRUE)
# arrange the two plots above each other
ggarrange(p1[[1]] + theme_light(),
          p1[[2]] + theme_light(),ncol = 1, nrow = 2)

## create a depth profile plot of the ensemble amd boxplot of the profiles for
## the date 2010-05-27
p2 <- plot_ensemble("output/ensemble_output.nc", model = c("FLake", "GLM",
                                                           "GOTM", "Simstrat",
                                                           "MyLake"),
                    var = "temp", date = "2010-05-27 00:00:00",
                    boxwhisker = TRUE, residuals = FALSE)
# arrange the two plots above each other
ggarrange(p2[[1]] + theme_light(),
          p2[[2]] + theme_light(), ncol = 1, nrow = 2)


## add density to the output
input_yaml_multiple("LakeEnsemblR.yaml", value = c("temp", "ice_height",
                                                   "dens"),
                    key1 = "output", key2 = "variables")

## re run the ensemble
run_ensemble("LakeEnsemblR.yaml",
             model = c("FLake", "GLM", "GOTM", "Simstrat", "MyLake"),
             parallel = TRUE,
             add = FALSE)

## plot the result
p3 <- plot_heatmap("output/ensemble_output.nc", var = "dens") +
  theme_light() + scale_colour_gradientn(limits = c(998, 1001),
                                         colours = rev(brewer.pal(11, "Spectral")))
p4 <- plot_ensemble("output/ensemble_output.nc", model = c("FLake", "GLM",
                                                           "GOTM", "Simstrat",
                                                           "MyLake"),
                    var = "dens", date = "2010-05-27 00:00:00") +
  theme_light()

ggarrange(p3, p4, ncol = 1, nrow = 2)

## plotting text outputs
plot_model <- "MyLake" # Model names are case-sensitive
plot_depth <- 5 # In our example, output is given every 0.5 m 
# read in the data
df <- read.csv(paste0("./output/Feeagh_", plot_model, "_temp.csv"))
df$datetime <- as.POSIXct(df$datetime)
# plot
ggplot(df)+
  geom_line(aes_string(x = "datetime", y = paste0("wtr_", plot_depth)))+
  theme_light()

## calibrating the models
cali_result <- cali_ensemble("LakeEnsemblR.yaml",
                             model = c("FLake", "GLM", "GOTM", "Simstrat", "MyLake"),
                             num = 10,
                             cmethod = "MCMC",
                             parallel = FALSE)

## get best parameter sets
cali_result[["GLM"]][["bestpar"]]

## manually change the values in the LakeEnsemblR.yaml file and re run the ensemble
export_config("LakeEnsemblR.yaml", model = c("FLake", "GLM", "GOTM",
                                             "Simstrat", "MyLake"))
run_ensemble("LakeEnsemblR.yaml", model = c("FLake", "GLM", "GOTM",
                                            "Simstrat", "MyLake"))


## addin ensemble members
# change light atenuation coefficient
input_yaml_multiple("LakeEnsemblR.yaml", value = 2.0,
                    key1 = "input", key2 = "light", key3 = "Kw")

# Now run export_config and run_ensemble again, but add "add = TRUE" 
export_config("LakeEnsemblR.yaml", model = c("FLake", "GLM", "GOTM",
                                             "Simstrat", "MyLake"))
run_ensemble("LakeEnsemblR.yaml",
             model = c("FLake", "GLM", "GOTM", "Simstrat", "MyLake"),
             parallel = TRUE,
             add = TRUE)

# plot heatmap
plot_heatmap("output/ensemble_output.nc", dim = "member", dim_index = 2)


## post processing
# analyse stratification and ice dynamic
out_res <- analyse_ncdf(ncdf = "output/ensemble_output.nc",
                        model = c("FLake", "GLM", "GOTM","Simstrat", "MyLake"))
# look at returned values
names(out_res)

print(out_res[["stats"]])
print(out_res[["strat"]])

## calculate model fits
calc_fit(ncdf = "output/ensemble_output.nc", model = c("FLake", "GLM", "GOTM",
                                                       "Simstrat", "MyLake"))
## plot residuals
plot_resid(ncdf = "output/ensemble_output.nc", var = "temp")

## calculate Schmidt Stability using rLakeAnalyzer
out <- load_var(ncdf = "output/ensemble_output.nc", var = "temp")
bathy <- read.csv('LakeEnsemblR_bathymetry_standard.csv')
colnames(bathy) <- c("depths", "areas")
ts.sch <- lapply(out, function(x) {
  ts.schmidt.stability(x, bathy = bathy, na.rm = TRUE)
})
## reshape to data.frame
df <- melt(ts.sch, id.vars = 1)
colnames(df)[4] <- "model"
## plot results
ggplot(df, aes(datetime, value, colour = model)) +
  geom_line() +
  labs(y = "Schmidt stability (J/m2)") +
  theme_classic() + ylim(-50, 750)

## Same for thermocline depth
ts.td <- lapply(out, function(x) {
  ts.thermo.depth(x, Smin = 0.1, na.rm = TRUE)
})

df <- melt(ts.td, id.vars = 1)
colnames(df)[4] <- "model"

ggplot(df, aes(datetime, value, colour = model)) +
  geom_line() +
  labs(y = "Thermocline depth (m)") +
  scale_y_continuous(trans = "reverse") +
  theme_classic() 



## setiign LakeEnsemblR up for your own lake

# get template for initial temperature profile
get_template("Initial temperature profile")

# get names of all possible templates
get_template()
