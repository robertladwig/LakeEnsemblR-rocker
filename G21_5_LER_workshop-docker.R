##------------- GLEON G21.5 meeting Workshop: LakeEnsemblR   -----------------##
# Version: 0.1.0
# Authors: Jorrit Mesman, Johannes Feldbauer, Robert Ladwig, Tadhg Moore
# Date: 2020-10-09

# Check out our wiki for further info or FAQ https://github.com/aemon-j/LakeEnsemblR/wiki

###################################################################################
# For package installations see script "install_packages.R"

# For testing installations **BEFORE** the workshop see script "test_BEFORE_workshop.R"
###################################################################################

## set working directory to location the R script is stored - only in RStudio
setwd(dirname(rstudioapi::getSourceEditorContext()$path))
Sys.setenv(TZ = "UTC") # Set R timezone to UTC

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

# 1. Basic running of the model ensemble ----
## Have a look at the feeagh folder. There will be six files
list.files()

## Look at the meteorological variables dictionary 
print(met_var_dic)

## Create all model subfolders, configuration and forcing files
export_config("LakeEnsemblR.yaml", model = c("FLake", "GLM", "GOTM",
                                             "Simstrat", "MyLake"))

## Now there are five additional folders, one for each model
list.files()

## Run the ensemble
run_ensemble("LakeEnsemblR.yaml", model = c("FLake", "GLM", "GOTM",
                                            "Simstrat", "MyLake"))

## Now there is an additional folder called output which contains the netcdf file
list.files("output")

# 2. Changing output options ----
## Change output to .csv files and rerun the ensemble
input_yaml_multiple("LakeEnsemblR.yaml", value = "text", key1 = "output",
                    key2 = "format")
run_ensemble("LakeEnsemblR.yaml", model = c("FLake", "GLM", "GOTM",
                                            "Simstrat", "MyLake"))

## Now there are additional .csv output files in the output folder
list.files("output")

## Change output format back to netcdf
input_yaml_multiple("LakeEnsemblR.yaml", value =  "netcdf", key1 = "output",
                    key2 = "format")

# 3. Plotting ensemble output ----
## Create heatmap plot from the netcdf file
plot_heatmap("output/ensemble_output.nc")+
  scale_colour_gradientn(limits = c(0, 21),
                         colours = rev(RColorBrewer::brewer.pal(11, "Spectral")))+
  theme_light()

## Create a plot with time series and time series of residuals at 2.5 m depth
p1 <- plot_ensemble("output/ensemble_output.nc", model = c("FLake", "GLM",
                                                           "GOTM", "Simstrat",
                                                           "MyLake"),
                    var = "temp", depth = 2.5,
                    residuals = TRUE)
# Arrange the two plots above each other
ggarrange(p1[[1]] + theme_light(),
          p1[[2]] + theme_light(), ncol = 1, nrow = 2)

## Create a depth profile plot of the ensemble amd boxplot of the profiles for
## the date 2010-05-27
p2 <- plot_ensemble("output/ensemble_output.nc", model = c("FLake", "GLM",
                                                           "GOTM", "Simstrat",
                                                           "MyLake"),
                    var = "temp", date = "2010-05-27 00:00:00",
                    boxwhisker = TRUE, residuals = FALSE)
# Arrange the two plots above each other
ggarrange(p2[[1]] + theme_light(),
          p2[[2]] + theme_light(), ncol = 1, nrow = 2)

# 4. Adding other output variables ----
## Add density to the output
input_yaml_multiple("LakeEnsemblR.yaml", value = c("temp", "ice_height",
                                                   "dens"),
                    key1 = "output", key2 = "variables")

## Re-run the ensemble
run_ensemble("LakeEnsemblR.yaml",
             model = c("FLake", "GLM", "GOTM", "Simstrat", "MyLake"),
             parallel = FALSE,
             add = FALSE)

## Plot the result
p3 <- plot_heatmap("output/ensemble_output.nc", var = "dens") +
  theme_light() + scale_colour_gradientn(limits = c(998, 1001),
                                         colours = rev(brewer.pal(11, "Spectral")))
p4 <- plot_ensemble("output/ensemble_output.nc", model = c("FLake", "GLM",
                                                           "GOTM", "Simstrat",
                                                           "MyLake"),
                    var = "dens", date = "2010-05-27 00:00:00") +
  theme_light()

ggarrange(p3, p4, ncol = 1, nrow = 2)


# 5. Plotting text outputs ----
plot_model <- "MyLake" # Model names are case-sensitive
plot_depth <- 5 # In our example, output is given every 0.5 m 
# Read in the data
df <- read.csv(paste0("./output/Feeagh_", plot_model, "_temp.csv"))
df$datetime <- as.POSIXct(df$datetime)
# Plot
ggplot(df)+
  geom_line(aes_string(x = "datetime", y = paste0("wtr_", plot_depth)))+
  theme_light()


# 6. Calibrating the models ----
cali_result <- cali_ensemble("LakeEnsemblR.yaml",
                             model = c("FLake", "GLM", "GOTM", "Simstrat", "MyLake"),
                             num = 10,
                             cmethod = "MCMC",
                             parallel = FALSE)

## Get best parameter sets
cali_result[["GLM"]][["bestpar"]]

## Manually change the values in the LakeEnsemblR.yaml file and re run the ensemble
export_config("LakeEnsemblR.yaml", model = c("FLake", "GLM", "GOTM",
                                             "Simstrat", "MyLake"))
run_ensemble("LakeEnsemblR.yaml", model = c("FLake", "GLM", "GOTM",
                                            "Simstrat", "MyLake"))


# 7. Add ensemble members ----
# Change the light atenuation coefficient
input_yaml_multiple("LakeEnsemblR.yaml", value = 2.0,
                    key1 = "input", key2 = "light", key3 = "Kw")

# Now run export_config and run_ensemble again, but add "add = TRUE" 
export_config("LakeEnsemblR.yaml", model = c("FLake", "GLM", "GOTM",
                                             "Simstrat", "MyLake"))
run_ensemble("LakeEnsemblR.yaml",
             model = c("FLake", "GLM", "GOTM", "Simstrat", "MyLake"),
             parallel = FALSE,
             add = TRUE)

# Plot heatmap
plot_heatmap("output/ensemble_output.nc", dim = "member", dim_index = 2)


# 8. Further Post-processing
# Analyse stratification and ice dynamics
out_res <- analyse_ncdf(ncdf = "output/ensemble_output.nc",
                        model = c("FLake", "GLM", "GOTM","Simstrat", "MyLake"))
# look at returned values
names(out_res)

print(out_res[["stats"]])
print(out_res[["strat"]])

## Calculate model fits
calc_fit(ncdf = "output/ensemble_output.nc", model = c("FLake", "GLM", "GOTM",
                                                       "Simstrat", "MyLake"))
## Clot residuals
plot_resid(ncdf = "output/ensemble_output.nc", var = "temp")

## Calculate Schmidt Stability using rLakeAnalyzer
out <- load_var(ncdf = "output/ensemble_output.nc", var = "temp")
bathy <- read.csv('LakeEnsemblR_bathymetry_standard.csv')
colnames(bathy) <- c("depths", "areas")
ts.sch <- lapply(out, function(x) {
  ts.schmidt.stability(x, bathy = bathy, na.rm = TRUE)
})
## Reshape to data.frame
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



# 9. Setting LakeEnsemblR up for your own lake

# Get template for initial temperature profile
get_template("Initial temperature profile")

# Get names of all possible templates
get_template()

# END

