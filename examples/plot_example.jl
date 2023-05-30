#' # Plotting data and models with SlimPlotting
#' ---
#' title: Overview of SlimPlotting utilities
#' author: Mathias Louboutin
#' date: April 2023
#' ---

#' This example script is written using [Weave.jl](https://github.com/JunoLab/Weave.jl) and can be converted to different format for documentation and usage
#' This example is converted to a markdown file for the documentation.

#' # Import SlimPlotting, SegyIO to read seismic data, JLD2 for hdf5-like files
using SlimPlotting, SegyIO, JLD2

#' # Initialize all needed data

#' Close all figures if any existing
SlimPlotting.PyPlot.close(:all)

#' Path to the files and data used for these examples
data_path = dirname(pathof(SlimPlotting))*"/../data/";

#' Read the data
# Pure array
vp = Float32.(segy_read("$(data_path)2dVP.sgy").data);
dm = diff(vp, dims=1);
shot = Float32.(segy_read("$(data_path)2dshot.segy").data);
xloc = get_header(segy_read("$(data_path)2dshot.segy"), "GroupX")
fslice = JLD2.load("$(data_path)2dfslice.jld");

#' # Create structures to mimic JUDI-like inputs
#' In the future this should be instead converted into an extension rather than implicit knowledge of the structure

# Dummy structures to check plot with metadata
struct geometry
    xloc
end

struct shotrec
  data
  dt
  geometry
end

struct Phys
    data
    d
end

## Make physical objects
dmp = Phys(dm, (10, 20))
vpp = Phys(vp, (10, 20))
fslicep = Phys(fslice["Freq"][1, :, :], (12.5, 12.5))
shotp = shotrec([shot], 0.008, geometry([xloc]));

#' # Model perturbation
#' We plot here a model perturbation (i.e a Reverse-time Migrated image) and compare a few colormaps:
#' - The `seiscm.seimic` colormap
#' - The standard matplotlib `Greys` colormap
#' - The perceptually accurate `Greys` colormap from colorcet

figure(figsize=(10, 10))
subplot(311)
plot_simage(dmp; new_fig=false, name="Seismic")
subplot(312)
plot_simage(dm, (10, 20); cmap="Greys", new_fig=false, name="Greys")
subplot(313)
plot_simage(dm, (10, 20); cmap=:cet_CET_L1, new_fig=false, name="Colorcet Greys")
tight_layout();display(gcf())


#' #  Veclocity
#' We plot here a velocity model and compare a few colormaps:
#' - The `seiscm.frequency` colormap
#' - The ColorSchemes `vik` colormap
#' - The perceptually accurate `jet` colormap from colorcet named `cet_rainbow4`

figure(figsize=(10, 10))
subplot(311)
plot_velocity(vpp; new_fig=false, name="colorcet jet", cmap="cet_rainbow4")
subplot(312)
plot_velocity(vp, (10, 20); cmap=:vik, new_fig=false, name="ColorSchemes's vik")
subplot(313)
plot_velocity(vp, (10, 20); cmap=seiscm(:frequency), new_fig=false, name="Seiscm")
tight_layout();display(gcf())


#' #  Frequency slice
#' We plot here a frequency slice for a seismic dataset and compare a few colormaps:
#' - The `seiscm.bwr` colormap
#' - The standard matplotlib `bwr` colormap
#' - The perceptually accurate `bwr` colormap from colorcet named `cet_CET_D1A`

# Frequency slice
figure(figsize=(10, 5))
subplot(131)
plot_fslice(fslice["Freq"][1, :, :], (12.5, 12.5); new_fig=false, name="colorcet bwr")
subplot(132)
plot_fslice(fslicep; cmap=:bwr, new_fig=false, name="bwr")
subplot(133)
plot_fslice(fslicep; cmap=seiscm(:bwr), new_fig=false, name="Seiscm bwr")
tight_layout();display(gcf())



#' #  Shot record
#' ## Seismic blue-white-red
#' 
#' We plot here a frequency slice for a seismic dataset and compare a few colormaps for the `bwr` colormap:
#' - The `seiscm.bwr` colormap
#' - The standard matplotlib `bwr` colormap
#' - The perceptually accurate `bwr` colormap from colorcet named `cet_CET_D1A`

# Shot record
figure(figsize=(10, 5))
subplot(131)
plot_sdata(shotp; new_fig=false, name="matplotlib seismic", cmap="bwr")
subplot(132)
plot_sdata(shot, (12.5, 0.008); cmap=:cet_CET_D1A, new_fig=false, name="Colorcet bwr")
subplot(133)
plot_sdata(shot, (12.5, 0.008); cmap=seiscm(:bwr), new_fig=false, name="Seismic bwr")
tight_layout();display(gcf())


#' ## Seismic greys
#' We plot here a frequency slice for a seismic dataset and compare a few colormaps for the `greys` colormap:
#' - The standard matplotlib `gray` colormap
#' - The perceptually accurate `greys` colormap from colorcet named `cet_CET_L1`

# Shot record
figure(figsize=(10, 5))
subplot(121)
plot_sdata(shotp; new_fig=false, name="colorcet gray", cmap="cet_CET_L1")
subplot(122)
plot_sdata(shot, (12.5, 0.008); cmap="gray", new_fig=false, name="Greys")
tight_layout();display(gcf())


#' # Wiggle traces
#' We finally show the traditional wiggle plot for a shot record used in seismic.

# Wiggle plot
figure(figsize=(5, 5))
wiggle_plot(shot[1:5:end, 1:10:end], xloc[1:10:end], 0:0.02:4.6; new_fig=false)
tight_layout();display(gcf())
