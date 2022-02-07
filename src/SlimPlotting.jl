module SlimPlotting

using PyPlot, Statistics, ColorSchemes

const cc = PyPlot.PyNULL()


function __init__()
    try
        copy!(cc, PyPlot.pyimport_conda("colorcet", "colorcet"))
    catch e
        # Not using julia's conda and not installed. Installing and loading
        run(Cmd([PyPlot.PyCall.pyprogramname, "-m", "pip", "install", "-U", "--user", "colorcet"]))
        copy!(cc, PyPlot.pyimport("colorcet"))
    end
end

export plot_fslice, plot_velocity, plot_simage, plot_sdata, wiggle_plot
export colorschemes

"""
    _plot_with_units(image, spacing; perc=95, cmap=:cet_CET_L1, 
                     o=(0, 0), interp="hanning", aspect=nothing, d_scale=0,
                     positive=false, labels=(:X, :Depth), cbar=false,
                     units=(:m, :m), name="RTM", new_fig=true, save=nothing)

Plot a 2D grided image with physical units defined by the grid spacing `spacing`.

# Arguments
  - `image::Array{T, 2}`: image to be plotted
  - `spacing::Tuple`: grid spacing in physical units
  - `perc::Int`: (Optional) Clipping percentile, default=95
  - `cmap::Symbol`: (Optional) Color map, default=:linear_grey_10_95_c0_n256
  - `o::Tuple`: (Optional) Origin of the image, default=(0, 0)
  - `interp::String`: (Optional) Interpolation method, default="hanning"
  - `aspect::Symbol`: (Optional) Aspect ratio, default=:auto
  - `d_scale::Float`: (Optional) Depth scaling, default=1.5. Applied scaling is `(1:max_depth).^d_scale`.
  - `positive::Bool`: (Optional) Plot positive only image (clip `[0:max(image)]`), default=false
  - `labels::Tuple`: (Optional) Labels for the axes, default=(:X, :Depth)
  - `name::String`: (Optional) Figure title, default="RTM"
  - `units::Tuple(String)`: (Optional) Physical units of each axis, default=(:m, :m).
  - `new_fig::Bool`: (Optional) Create a new figure, default=true
  - `save::String`: (Optional) Save figure to file, default=nothing doesn't save the figure
  - `cbar::Bool`: (Optional) Show colorbar, default=false
"""
function _plot_with_units(image, spacing; perc=95, cmap=:cet_CET_L1, 
                          o=(0, 0), interp="hanning", aspect=nothing, d_scale=0,
                          positive=false, labels=(:X, :Depth), cbar=false,
                          units=(:m, :m), name="RTM", new_fig=true, save=nothing)
    nz, nx = size(image)
    dz, dx = spacing
    oz, ox = o
    depth = range(oz, oz + (nz - 1)*spacing[2], length=nz).^d_scale
    scaled = image .* depth

    a = positive ? maximum(scaled) : quantile(abs.(vec(scaled)), perc/100)
    ma = positive ? minimum(scaled) : -a
    extent = [ox, ox+ (nx-1)*dx, oz+(nz-1)*dz, oz]
    isnothing(aspect) && (aspect = :auto)

    # color map
    cmap = try ColorMap(cmap); catch; ColorMap(colorschemes[cmap].colors); end
    new_fig && figure()
    # Plot
    imshow(scaled, vmin=ma, vmax=a, cmap=cmap, aspect=aspect, interpolation=interp, extent=extent)
    xlabel("$(labels[1]) [$(units[1])]")
    ylabel("$(labels[2]) [$(units[2])]")
    title("$name")
    cbar && colorbar(fraction=0.046, pad=0.04)

    if ~isnothing(save)
    save == true ? filename=name : filename=save
    savefig(filename, bbox_inches="tight", dpi=150)
    end
end


"""
    plot_simage(image, spacing; perc=98, cmap=:linear_grey_10_95_c0_n256,
                o=(0, 0), interp="hanning", aspect=nothing, d_scale=1.5,
                labels=(:X, :Depth), name="RTM", units=(:m, :m), new_fig=true,
                save=nothing, cbar=false)

Plot a 2D seismic image with a grid spacing `spacing`. Calls [`_plot_with_units`](@ref).

# Arguments
  - `image::Array{T, 2}`: image to be plotted
  - `spacing::Tuple`: grid spacing in physical units
  - `perc::Int`: (Optional) Clipping percentile, default=95
  - `cmap::Symbol`: (Optional) Color map, default=:linear_grey_10_95_c0_n256
  - `o::Tuple`: (Optional) Origin of the image, default=(0, 0)
  - `interp::String`: (Optional) Interpolation method, default="hanning"
  - `aspect::Symbol`: (Optional) Aspect ratio, default=:auto
  - `d_scale::Float`: (Optional) Depth scaling, default=1.5. Applied scaling is `(1:max_depth).^d_scale`.
  - `labels::Tuple`: (Optional) Labels for the axes, default=(:X, :Depth)
  - `name::String`: (Optional) Figure title, default="RTM"
  - `units::Tuple(String)`: (Optional) Physical units of each axis, default=(:m, :m).
  - `new_fig::Bool`: (Optional) Create a new figure, default=true
  - `save::String`: (Optional) Save figure to file, default=nothing doesn't save the figure
  - `cbar::Bool`: (Optional) Show colorbar, default=false

"""
function plot_simage(image; kw...)
    d = try image.d; catch nothing; end
    if isnothing(d)
        @warn "No grid spacing specified, plotting with a 1m grid spacing"
        d = (1, 1)
    end
    plot_simage(image.data, d; kw...)
end


"""
    plot_fslice(image, spacing; perc=98, cmap=:diverging_bwr_20_95_c54_n256,
                o=(0, 0), interp="hanning", aspect=nothing, d_scale=1.5,
                name="RTM", units="m", new_fig=true, save=nothing)

Plot a 2D frequency slice of seismic data. Calls [`_plot_with_units`](@ref).

# Arguments
  - `image::Array{T, 2}`: image to be plotted
  - `spacing::Tuple`: grid spacing in physical units
  - `perc::Int`: (Optional) Clipping percentile, default=95
  - `cmap::Symbol`: (Optional) Color map, default=:diverging_bwr_20_95_c54_n256
  - `o::Tuple`: (Optional) Origin of the image, default=(0, 0)
  - `interp::String`: (Optional) Interpolation method, default="hanning"
  - `aspect::Symbol`: (Optional) Aspect ratio, default=:auto
  - `d_scale::Float`: (Optional) Depth scaling, default=1.5. Applied scaling is `(1:max_depth).^d_scale`.
  - `labels::Tuple`: (Optional) Labels for the axes, default=(:X, :Depth)
  - `name::String`: (Optional) Figure title, default="RTM"
  - `units::Tuple(String)`: (Optional) Physical units of each axis, default=(:m, :m).
  - `new_fig::Bool`: (Optional) Create a new figure, default=true
  - `save::String`: (Optional) Save figure to file, default=nothing doesn't save the figure
  - `cbar::Bool`: (Optional) Show colorbar, default=false

"""
function plot_fslice(image; kw...)
    @warn "No grid spacing specified, plotting with a 1m grid spacing"
    d = (1, 1)
    plot_fslice(image.data, d; kw...)
end

plot_fslice(image::AbstractArray{T}, args...; kw...) where {T<:Complex} = plot_fslice(real.(image), args...; kw...)

"""
    plot_velocity(image, spacing; perc=98, cmap=:cet_rainbow,
                o=(0, 0), interp="hanning", aspect=nothing, d_scale=1.5,
                name="RTM", units="m", new_fig=true, save=nothing)

Plot a velocity model. Calls [`_plot_with_units`](@ref).

# Arguments
  - `image::Array{T, 2}`: image to be plotted
  - `spacing::Tuple`: grid spacing in physical units
  - `perc::Int`: (Optional) Clipping percentile, default=95
  - `cmap::Symbol`: (Optional) Color map, default=:cet_rainbow
  - `o::Tuple`: (Optional) Origin of the image, default=(0, 0)
  - `interp::String`: (Optional) Interpolation method, default="hanning"
  - `aspect::Symbol`: (Optional) Aspect ratio, default=:auto
  - `d_scale::Float`: (Optional) Depth scaling, default=1.5. Applied scaling is `(1:max_depth).^d_scale`.
  - `labels::Tuple`: (Optional) Labels for the axes, default=(:X, :Depth)
  - `name::String`: (Optional) Figure title, default="RTM"
  - `units::Tuple(String)`: (Optional) Physical units of each axis, default=(:m, :m).
  - `new_fig::Bool`: (Optional) Create a new figure, default=true
  - `save::String`: (Optional) Save figure to file, default=nothing doesn't save the figure
  - `cbar::Bool`: (Optional) Show colorbar, default=false

"""
function plot_velocity(image; kw...)
    d = try image.d; catch nothing; end
    if isnothing(d)
        @warn "No grid spacing specified, plotting with a 1m grid spacing"
        d = (1, 1)
    end
    plot_velocity(image.data, d; kw...)
end


"""
    plot_sdata(image, spacing; perc=98, cmap=:linear_grey_10_95_c0_n256,
                o=(0, 0), interp="hanning", aspect=nothing, d_scale=1.5,
                name="RTM", units="m", new_fig=true, save=nothing)

Plot seismic data gather (i.e shot record). Calls [`_plot_with_units`](@ref).

# Arguments
  - `image::Array{T, 2}`: image to be plotted
  - `spacing::Tuple`: grid spacing in physical units
  - `perc::Int`: (Optional) Clipping percentile, default=95
  - `cmap::Symbol`: (Optional) Color map, default=:linear_grey_10_95_c0_n256
  - `o::Tuple`: (Optional) Origin of the image, default=(0, 0)
  - `interp::String`: (Optional) Interpolation method, default="hanning"
  - `aspect::Symbol`: (Optional) Aspect ratio, default=:auto
  - `d_scale::Float`: (Optional) Depth scaling, default=1.5. Applied scaling is `(1:max_depth).^d_scale`.
  - `labels::Tuple`: (Optional) Labels for the axes, default=(:X, :Depth)
  - `name::String`: (Optional) Figure title, default="RTM"
  - `units::Tuple(String)`: (Optional) Physical units of each axis, default=(:m, :m).
  - `new_fig::Bool`: (Optional) Create a new figure, default=true
  - `save::String`: (Optional) Save figure to file, default=nothing doesn't save the figure
  - `cbar::Bool`: (Optional) Show colorbar, default=false

"""
function plot_sdata(image; kw...)
    dt = try image.dt; catch nothing; end
    dx = try 
        geom = try image.geometry; catch nothing; end
        geom = hasproperty(geom, :xloc) ? geom : Geometry(geom)
        diff(geom.xloc[1])[1]
    catch
        nothing
    end
    if isnothing(dt)
        @warn "No grid spacing specified, plotting with a 1m grid spacing"
        d = (1, 1)
    else
        d = (dt, dx)
    end
    plot_sdata(image.data, d; kw...)
end


# Defaults
_funcs = [:plot_simage, :plot_fslice, :plot_velocity, :plot_sdata]
_default_colors = [:cet_CET_L1, :cet_CET_D1A, :cet_rainbow4, :cet_CET_L1]
_names = ["RTM", "Frequency slice", "Velocity", "Shot record"]
_units = [(:m, :m), (:m, :m), (:m, :m), (:m, :s)]
_labels = [(:X, :Depth), (:Xsrc, :Xrec), (:X, :Depth), (:Xrec, :T)]

for (func, cmap, pname, u ,l) ∈ zip(_funcs, _default_colors, _names, _units, _labels)
    @eval begin
        function $func(image, spacing; kw...)
            cmap = haskey(kw, :cmap) ? kw[:cmap] : $(Meta.quot(cmap))
            pname = haskey(kw, :name) ? kw[:name] : $(Meta.quot(pname))
            u = haskey(kw, :units) ? [:units] : $(Meta.quot(u))
            l = haskey(kw, :labels) ? [:labels] : $(Meta.quot(l))
            positive = $func == plot_velocity
            _plot_with_units(image, spacing; kw...,positive=positive, cmap=cmap, name=pname, units=u, labels=l)
        end
    end
end


"""
    wiggle_plot(image, xrec, time_axis; t_scale=1.5,
                new_fig=true)

wiggle_plot of a seismic traces.

# Arguments
  - `image::Array{T, 2}`: Shot record to be plotted
  - `xrec::Array{T, 1}`: Receiver coordinates
  - `time_axis::Array{T, 1}`: Time axis
  - `t_scale::Float`: (Optional) Time scaling, default=1.5. Applied scaling is `(1:max_time).^t_scale`.
  - `new_fig::Bool`: (Optional) Create a new figure, default=true
"""
function wiggle_plot(data::Array{Td, 2}, xrec=nothing, time_axis=nothing;
                     t_scale=1.5, new_fig=true) where Td
    # X axis
    if isnothing(xrec)
        @info "No X coordinates prvided, using 1:ntrace"
        xrec = range(0, size(data, 2), length=size(data, 2))
    end
    length(xrec) == size(data, 2) || error("xrec must be the same length as the number of columns in data");
    dx = diff(xrec); dx = 2 .* vcat(dx[1], dx)
    # time axis
    if isnothing(time_axis)
        @info "No time axis provided, using 1:ntime"
        time_axis = range(0, size(data, 1), length=size(data, 1))
    end
    length(time_axis) == size(data, 1) || error("time_axis must be the same length as the number of rows in data");
    # Time gain
    tg = time_axis .^ t_scale;
    ax = new_fig ? subplots()[2] : gca()

    ax.set_ylim(maximum(time_axis), minimum(time_axis))
    ax.set_xlim(minimum(xrec), maximum(xrec))
    for (i, xr) ∈ enumerate(xrec)
        x = tg.* data[:, i]
        x = dx[i] * x ./ maximum(x) .+ xr
        # rescale to avoid large spikes
        ax.plot(x, time_axis, "k-")
        ax.fill_betweenx(time_axis, xr, x, where=(x.>xr), color="k")
    end
    ax.set_xlabel("X")
    ax.set_ylabel("Time")
end

end # module
