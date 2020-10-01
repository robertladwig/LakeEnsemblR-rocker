FROM rocker/verse:3.6.3-ubuntu18.04

MAINTAINER "ARYAN ADHLAKHA" aryan@cs.wisc.edu "Robert Ladwig" 

RUN apt-get update -qq && apt-get -y --no-install-recommends install \
	gfortran-8 \
	gfortran \ 
	libgd-dev \
	git \
	build-essential \
	libnetcdf-dev \
	ca-certificates \
	&& update-ca-certificates 

RUN 	Rscript -e 'install.packages("ncdf4")' \
	&& Rscript -e 'install.packages("devtools")' \
	&& Rscript -e 'devtools::install_github("GLEON/GLM3r",ref="GLMv.3.1.0a3")' \
	&& Rscript -e 'devtools::install_github("USGS-R/glmtools", ref = "ggplot_overhaul")' \
	&& Rscript -e 'devtools::install_github("GLEON/rLakeAnalyzer")' \
	&& Rscript -e 'devtools::install_github("aemon-j/FLakeR", ref = "inflow")' \
	&& Rscript -e 'devtools::install_github("aemon-j/GOTMr")' \
	&& Rscript -e 'devtools::install_github("aemon-j/gotmtools")' \
	&& Rscript -e 'devtools::install_github("aemon-j/SimstratR")' \
	&& Rscript -e 'devtools::install_github("aemon-j/MyLakeR")' \
	&& Rscript -e 'install.packages("configr")' \
	&& Rscript -e 'install.packages("import")' \
	&& Rscript -e 'install.packages("FME")' \
	&& Rscript -e 'install.packages("lubridate")' \
	&& Rscript -e 'install.packages("plyr")' \
	&& Rscript -e 'install.packages("reshape2")' \
	&& Rscript -e 'install.packages("zoo")' \
	&& Rscript -e 'install.packages("ggplot2")' \
	&& Rscript -e 'install.packages("dplyr")' \
	&& Rscript -e 'install.packages("RColorBrewer")' \
	&& Rscript -e 'install.packages("tools")' \
	&& Rscript -e 'install.packages("akima")' \
	&& Rscript -e 'install.packages("lazyeval")' \
	&& Rscript -e 'install.packages("hydroGOF")' \
	&& Rscript -e 'install.packages("RSQLite")' \
	&& Rscript -e 'install.packages("XML")' \
	&& Rscript -e 'install.packages("MBA")' \
	&& Rscript -e 'install.packages("colorRamps")' \
	&& Rscript -e 'install.packages("gridExtra")' \
	&& Rscript -e 'install.packages("readr")' \
	&& Rscript -e 'devtools::install_github("aemon-j/LakeEnsemblR")'

RUN 	echo "rstudio  ALL=(ALL) NOPASSWD:ALL">>/etc/sudoers

COPY rserver.conf /etc/rstudio/rserver.conf
RUN apt-get update && apt-get install -y python3-pip
RUN pip3 install py-cdrive-api
