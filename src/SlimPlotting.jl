module SlimPlotting

using Statistics, ColorSchemes, Reexport
@reexport using PyPlot

const cc = PyPlot.PyNULL()
scm = Dict()


function tryimport(pkg::String)
    pyi = try
        PyPlot.pyimport(pkg)
    catch e
        PyPlot.PyCall.Conda.pip_interop(true)
        PyPlot.PyCall.Conda.pip("install", pkg)
        PyPlot.pyimport(pkg)
    end
    return pyi
end

function __init__()
    # import seiscm
    scmp = tryimport("seiscm")
    global scm[:seismic] = scmp.seismic()
    global scm[:bwr] = scmp.bwr()
    global scm[:phase] = scmp.phase()
    global scm[:frequency] = scmp.frequency()
    # Import colorcet
    copy!(cc, tryimport("colorcet"))
end

export plot_fslice, plot_velocity, plot_simage, plot_sdata, wiggle_plot, compare_shots
export colorschemes, seiscm

"""
    seiscm(name)

Return the colormap `name` for seiscm. These colormap are preimported as a dictionnary
"""
seiscm(s::Symbol) = scm[s]

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
function _plot_with_units(image, spacing; perc=95, cmap=:cet_CET_L1, vmax=nothing,
                          o=(0, 0), interp="hanning", aspect=nothing, d_scale=0,
                          positive=false, labels=(:X, :Depth), cbar=false, alpha=nothing,
                          units=(:m, :m), name="RTM", new_fig=true, save=nothing)
    nz, nx = size(image)
    dz, dx = spacing
    oz, ox = o
    depth = range(oz, oz + (nz - 1)*spacing[2], length=nz).^d_scale
    scaled = image .* depth

    a = positive ? maximum(scaled) : quantile(abs.(vec(scaled)), perc/100)
    isnothing(vmax) || (a = vmax)
    ma = positive ? minimum(scaled) : -a
    extent = [ox, ox+ (nx-1)*dx, oz+(nz-1)*dz, oz]
    isnothing(aspect) && (aspect = :auto)

    # color map
    cmap = try ColorMap(cmap); catch; ColorMap(colorschemes[cmap].colors); end
    new_fig && figure()
    # Plot
    if !isnothing(alpha)
        imshow(scaled, vmin=ma, vmax=a, cmap=cmap, aspect=aspect, interpolation=interp, extent=extent, alpha=alpha)
    else
        imshow(scaled, vmin=ma, vmax=a, cmap=cmap, aspect=aspect, interpolation=interp, extent=extent)
    end
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
    kwd = Dict(kw)
    cmap = pop!(kwd, :cmap, scm[:seismic])
    plot_simage(image.data, d; cmap=cmap, kwd...)
end


"""
    plot_fslice(image, spacing; perc=98, cmap=:diverging_bwr_20_95_c54_n256,
                o=(0, 0), interp="hanning", aspect=nothing, d_scale=1.5,
                name="Frequency slice", units="m", new_fig=true, save=nothing)

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
                name="Velocity", units="m", new_fig=true, save=nothing)

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
                name="Shot", units="m", new_fig=true, save=nothing)

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
    dt, dx = try 
        geom = try image.geometry; catch nothing; end
        geom = hasproperty(geom, :xloc) ? geom : Geometry(geom)
        geom.dt[1], diff(geom.xloc[1])[1]
    catch
        nothing, nothing
    end
    if isnothing(dt)
        @warn "No grid spacing specified, plotting with a 1m grid spacing"
        d = (1, 1)
    else
        d = (dt, dx)
    end
    shot = hasproperty(image, :data) ? image.data[1] : image
    plot_sdata(shot, d; kw...)
end


"""
    compare_shots(image1, image2, spacing; perc=98, cmap=:linear_grey_10_95_c0_n256,
                  o=(0, 0), interp="hanning", aspect=nothing, d_scale=1.5, side_by_side=false,
                  chunksize=20, name="Data match", units="m", new_fig=true, save=nothing)


Compares the two shot records image1 and image2. This plotting utility supports two modes: `side_by_side` that plot the shot records next two each other with the second one having its traces reversed
, and `overlap` (default) where the two shots are overlapped selecting `chunksize` (Default 20) traces from each shot alternatively.

# Arguments
- `image1::Array{T, 2}`: First image
- `image2::Array{T, 2}`: Second image to comapre against the first image
- `spacing::Tuple`: grid spacing in physical units
- `perc::Int`: (Optional) Clipping percentile, default=95
- `cmap::Symbol`: (Optional) Color map, default=:linear_grey_10_95_c0_n256. Can provide a tuple of colormap for the `overlap` mode
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
- `chunksize::Integer`: Numberof trace in the chunk for the overlap comparison
- `side_by_side::Bool`: Whether to plot a side-by-side (true) or overlap (false, default) comaprison

"""
function compare_shots(image, image2, spacing; chunksize=20, kw...)
    kwd = Dict(kw)
    if pop!(kwd, :side_by_side, false)
        plot_sdata(hcat(image, zeros(size(image, 1), 5), image2[:, end:-1:1]), spacing; kwd...)
        return
    end
    # Get colormap
    cmap1 = pop!(kwd, :cmap, :cet_CET_L1)
    if isa(cmap1, Tuple)
        cmap1, cmap2 = cmap1
    else
        cmap2 = pop!(kwd, :cmap, :cet_CET_D1A)
        if cmap2 == cmap1
            cmap2 = ColorMap(cmap1).reversed()
        end
    end
    # Zero out to alternate
    nrec = size(image, 2)
    inds1 = vcat(collect(i:min(nrec, i+chunksize-1) for i in range(1, nrec, step=2*chunksize))...)
    inds2 = vcat(collect(i:min(nrec, i+chunksize-1) for i in range(chunksize+1, nrec, step=2*chunksize))...)
    shot1 = zeros(size(image))
    shot1[:, inds1] .= image[:, inds1]
    shot2 = zeros(size(image2))
    shot2[:, inds2] .= image2[:, inds2]
    plot_sdata(shot1, spacing; cmap=cmap1, kwd...)
    pop!(kwd, :new_fig, false)
    plot_sdata(shot2, spacing; cmap=cmap2, new_fig=false, alpha=.25, kwd...)
end

function compare_shots(image, image2; kw...)
    dt, dx = try 
        geom = try image.geometry; catch nothing; end
        geom = hasproperty(geom, :xloc) ? geom : Geometry(geom)
        geom.dt[1], diff(geom.xloc[1])[1]
    catch
        nothing, nothing
    end
    if isnothing(dt)
        @warn "No grid spacing specified, plotting with a 1m grid spacing"
        d = (1, 1)
    else
        d = (dt, dx)
    end
    shot1 = hasproperty(image, :data) ? image.data[1] : image
    shot2 = hasproperty(image2, :data) ? image2.data[1] : image2
    compare_shots(shot1, shot2, d; kw...)
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
            kwd = Dict(kw)
            cmap = pop!(kwd, :cmap, $(Meta.quot(cmap)))
            pname = pop!(kwd, :name, $(Meta.quot(pname)))
            u = pop!(kwd, :units, $(Meta.quot(u)))
            l = pop!(kwd, :labels, $(Meta.quot(l)))
            positive = $func == plot_velocity
            _plot_with_units(image, spacing; kwd..., positive=positive, cmap=cmap, name=pname, units=u, labels=l)
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
    new_fig && figure()

    ylim(maximum(time_axis), minimum(time_axis))
    xlim(minimum(xrec), maximum(xrec))
    for (i, xr) ∈ enumerate(xrec)
        x = tg.* data[:, i]
        x = dx[i] * x ./ maximum(x) .+ xr
        # rescale to avoid large spikes
        plot(x, time_axis, "k-")
        fill_betweenx(time_axis, xr, x, where=(x.>xr), color="k")
    end
    xlabel("X")
    ylabel("Time")
end

end # module
