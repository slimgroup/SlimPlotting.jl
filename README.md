# SlimPlotting

Utitliy function to plot physically gridded data. The functions currently only supports 2D data.

## Features

### Functionalities

This package implement four main functions that rely on a base `_plot_with_units` internal function.

- `plot_simage` to plot a 2D seismic image (i.e RTM)
- `plot_sdata` to plot 2D seismic data such as a shot record
- `plot_fslice` to plot a 2D frequency slice of seismic data.
- `plot_velocity` to plot a 2D velocity model.

The functions `plot_simage, plot_sdata` and `plot_velocity` support abstract object with meta-data containing the grid spacing. For example, you can plot a 2D [JUDI](https://github.com/slimgroup/JUDI.jl) `PhysicalParameter` either via `plot_velocity(p.data, p.d)` or directyl via `plot_velocity(p)` that will extract the data and spacing automatically. While this supports [JUDI](https://github.com/slimgroup/JUDI.jl) since we are using it exensively, this package does not depend on it and only expect a Julia structure as an input (when the spacing is not specified) containg a `.d` attribute with the grid spacing. We show in the simple example how to setup such a simple strucure.

The expected inputs are:
- `plot_simage(array, tuple)` or `plot_simage(structure)` with `strucutre.d`
 containing the grid spacing and `structure.data` containing the 2D array.
- `plot_velocity(array, tuple)` or `plot_velocity(structure)` with `strucutre.d`
 containing the grid spacing and `structure.data` containing the 2D array.
- `plot_sdata(array, tuple)` or `plot_sdata(structure)` with `strucutre.dt`
 containing the time sampling rate and `structure.d` containing the receiver spacing (uniform sampling is assumed at the time) and `structure.data` containing the 2D array.

### Color maps
å
The colormap support is extensive as this uses [ColorShemes.jl](https://juliagraphics.github.io/ColorSchemes.jl/stable/) that implements a variery of colormaps from different packages including Matplotlib, Seaborn, GNUPlot, colorcet(Collection of perceptually accurate colormaps). You can provide the chosen colormap as a kewyword , i.e `plot_simage(array, tuple; cmap=:jet)`

# Authors

This package is developped and maintained by Mathias Louboutin<mlouboutin3@gatech.edu> and the ML4Seismic LAbe at Georgia Institute of Technology.

