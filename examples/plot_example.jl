# Add JLD2 and SegyIO to load the data if needed
using SlimPlotting, SegyIO, JLD2, PyPlot
SlimPlotting.PyPlot.close(:all)
data_path = dirname(pathof(SlimPlotting))*"/../data/";

# Pure array
vp = Float32.(segy_read("$(data_path)2dVP.sgy").data);
dm = 1f0 .* vp; dm[2:end, :] .-= dm[1:end-1, :];
shot = Float32.(segy_read("$(data_path)2dshot.segy").data);
xloc = get_header(segy_read("$(data_path)2dshot.segy"), "GroupX")
fslice = load("$(data_path)2dfslice.jld");

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
shotp = shotrec(shot, 0.004, geometry([xloc]))

# plots
# RTM/perturbation
figure(figsize=(10, 10))
subplot(211)
plot_simage(dmp; new_fig=false, name="colorcet gray", cmap="cet_CET_L1")
subplot(212)
plot_simage(dm, (10, 20); cmap="Greys", new_fig=false, name="Greys")
tight_layout()

# Velocity/physical parameter
figure(figsize=(10, 10))
subplot(211)
plot_velocity(vpp; new_fig=false, name="colorcet jet", cmap="cet_rainbow4")
subplot(212)
plot_velocity(vp, (10, 20); cmap=:vik, new_fig=false, name="ColorSchemes's vik")
tight_layout()

# Frequency slice
figure(figsize=(10, 5))
subplot(121)
plot_fslice(fslice["Freq"][1, :, :], (12.5, 12.5); new_fig=false, name="colorcet bwr")
subplot(122)
plot_fslice(fslicep; cmap=:bwr, new_fig=false, name="bwr")
tight_layout()

# Shot record
figure(figsize=(10, 5))
subplot(121)
plot_sdata(shotp; new_fig=false, name="colorcet gray", cmap="cet_CET_L1")
subplot(122)
plot_sdata(shot, (0.004, 12.5); cmap="gray", new_fig=false, name="Greys")
tight_layout()

# Wiggle plot
figure(figsize=(10, 5))
wiggle_plot(shot[1:5:end, 1:10:end], xloc[1:10:end], 0:0.02:4.6; new_fig=false)
