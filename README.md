[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://github.gatech.edu/pages/mlouboutin3/SlimPlotting.jl/)

# SlimPlotting

Utitliy function to plot physically gridded data. The functions currently only supports 2D data.

## Disclaimer

This is a small package that I started to make my life easier visualizing data and results easily. Not all functionalities are tested and some of the features may need additional options for better images.  This package is under developpement and weclomes contributions throug [Issues](https://github.com/slimgroup/SlimPlotting.jl/issues), [Pull Requests](https://github.com/slimgroup/SlimPlotting.jl/pulls) or [Discussions](https://github.com/slimgroup/SlimPlotting.jl/discussions)
 
## Functionalities

This package implement four main functions that rely on a base `_plot_with_units` internal function.

- `plot_simage` to plot a 2D seismic image (i.e RTM)
- `plot_sdata` to plot 2D seismic data such as a shot record
- `plot_fslice` to plot a 2D frequency slice of seismic data.
- `plot_velocity` to plot a 2D velocity model.
- `wiggle_plot` to make a 2D wiggle plot of a seismic data.

The functions `plot_simage, plot_sdata` and `plot_velocity` support abstract object with meta-data containing the grid spacing. For example, you can plot a 2D [JUDI](https://github.com/slimgroup/JUDI.jl) `PhysicalParameter` either via `plot_velocity(p.data, p.d)` or directyl via `plot_velocity(p)` that will extract the data and spacing automatically. While this supports [JUDI](https://github.com/slimgroup/JUDI.jl) since we are using it exensively, this package does not depend on it and only expect a Julia structure as an input (when the spacing is not specified) containg a `.d` attribute with the grid spacing. We show in the simple example how to setup such a simple strucure.

The expected inputs are:

- `plot_simage(array, tuple; kw...)` or `plot_simage(structure)` with `strucutre.d`
 containing the grid spacing and `structure.data` containing the 2D array.
- `plot_velocity(array, tuple; kw...)` or `plot_velocity(structure)` with `strucutre.d`
 containing the grid spacing and `structure.data` containing the 2D array.
- `plot_sdata(array, tuple; kw...)` or `plot_sdata(structure)` with `strucutre.dt`
 containing the time sampling rate and `structure.d` containing the receiver spacing (uniform sampling is assumed at the time) and `structure.data` containing the 2D array.
-  `wiggle_plot(array, xrec, time_axis; kw...)`. In this case, `xrec, time_axis` are optional and wil default to `1:size(array, 2)`, `1:size(array, 1)` respectively.

and you can check the doctring (julia `?`) for additional information on the optional keyword arguments.

## Color maps

The colormap support is extensive as this uses three sources:

- `matplotlib` standard colormaps.
-  [ColorShemes.jl](https://juliagraphics.github.io/ColorSchemes.jl/stable/) that implements a variery of colormaps from different packages including Matplotlib, Seaborn, GNUPlot, colorcet(Collection of perceptually accurate colormaps). You can provide the chosen colormap as a kewyword , i.e `plot_simage(array, tuple; cmap=:jet)`.
- [colorcet](https://colorcet.holoviz.org/index.html) perceptually accurate colormaps that are available through their colorcet names (i.e `cet_rainbow4` for a perceptually accurate `jet` colormap).

All functionality, with the exeption of `wiggle_plot` accept the keyword argument cmap, i.e `plot_velocity(array, spacing; cmap=:vik)`.

# Authors

This package is developped and maintained by Mathias Louboutin<mlouboutin3@gatech.edu> and the ML4Seismic Lab at Georgia Institute of Technology.

