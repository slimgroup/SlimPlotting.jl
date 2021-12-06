# Add JLD2 and SegyIO to load the data if needed
using SlimPlotting, SegyIO, JLD2
SlimPlotting.PyPlot.close(:all)
data_path = dirname(pathof(SlimPlotting))*"/../data/";

# Pure array
vp = Float32.(segy_read("$(data_path)2dVP.sgy").data);
dm = 1f0 .* vp; dm[2:end, :] .-= dm[1:end-1, :];
shot = Float32.(segy_read("$(data_path)2dShot.segy").data);
xloc = get_header(segy_read("$(data_path)2dShot.segy"), "GroupX")
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
plot_simage(dmp)
plot_simage(dm, (10, 20))

plot_velocity(vpp)
plot_velocity(vp, (10, 20))

plot_fslice(fslice["Freq"][1, :, :], (12.5, 12.5))
plot_fslice(fslicep)

plot_sdata(shotp)
plot_sdata(shot, (0.004, 12.5))
