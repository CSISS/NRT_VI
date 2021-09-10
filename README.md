# Near-real-time MODIS-derived VI data products for CONUS

## Description

This project includes main code to produce Near-Real-Time (NRT) Vegetation Index (VI) data set for the Conterminous United States (CONUS) based on MODIS data from Land, Atmosphere Near-real-time Capability for EOS (LANCE), an openly accessible NASA near-real-time EO data repository. The data set includes a variety of commonly used VIs including Normalized Difference Vegetation Index (NDVI), Vegetation Condition Index (VCI), Mean-referenced Vegetation Condition Index (MVCI), Ratio to Median Vegetation Condition Index (RMVCI), and Ratio to Previous-year Vegetation Condition Index (RVCI). LANCE enables the NRT monitoring of U.S. cropland vegetation conditions within 24 hours of observation. Meanwhile, this continuous data set with more than 20 years of vegetation condition observation would be suitable for time series analysis and change detection in many research fields such as agriculture, remote sensing, geographical information science and systems, environmental modeling, and Earth system science.

The complete dataset is free to access through the VegScape web application ([https://nassgeodata.gmu.edu/VegScape/](https://nassgeodata.gmu.edu/VegScape/)) as well as distributed via Web Map Service and Web Coverage Service ([https://nassgeo.csiss.gmu.edu/VegScape/devhelp/help.html](https://nassgeo.csiss.gmu.edu/VegScape/devhelp/help.html)).


## Installation Note

The code has been tested in Ubuntu 20.04 LTS (Focal Fossa) 64-bit. The code depends on a suite of third-party programs of [GDAL](https://gdal.org/).

The latest GDAL package can be installed on Ubuntu with the following command:

```
apt install gdal-bin
```

Check the version of installed package using `gdalinfo --version`.
