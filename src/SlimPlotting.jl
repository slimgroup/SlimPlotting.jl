module SlimPlotting

using PyPlot, Statistics, ColorSchemes

const cc = PyPlot.PyNULL()

__init__() = copy!(cc, PyPlot.pyimport("colorcet"))

export plot_fslice, plot_velocity, plot_simage, plot_sdata
export colorschemes

"""
    _plot_with_units(image, spacing; perc=98, cmap=:cet_CET_L1,
                o=(0, 0), interp="hanning", aspect=nothing, d_scale=1.5,
                name="RTM", units="m", new_fig=true, save=nothing)

Plot a 2D grided image with physical units defined by the grid spacing `spacing`.
"""
function _plot_with_units(image, spacing; perc=95, cmap=:cet_CET_L1, 
                          o=(0, 0), interp="hanning", aspect=nothing, d_scale=0, positive=false,
                          labels=(:X, :Depth), units=(:m, :m), name="RTM", new_fig=true, save=nothing)
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
    colorbar(fraction=0.046, pad=0.04)

    if ~isnothing(save)
    save == true ? filename=name : filename=save
    savefig(filename, bbox_inches="tight", dpi=150)
    end
end


"""
    plot_simage(image, spacing; perc=98, cmap=:linear_grey_10_95_c0_n256,
                o=(0, 0), interp="hanning", aspect=nothing, d_scale=1.5,
                name="RTM", units="m", new_fig=true, save=nothing)

Plot a 2D seismic image with a grid spacing `spacing`.
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

Plot a 2D frequency slice of seismic data.
"""
function plot_fslice(image; kw...)
    @warn "No grid spacing specified, plotting with a 1m grid spacing"
    d = (1, 1)
    plot_fslice(image.data, d; kw...)
end

plot_fslice(image::AbstractArray{T}, args...; kw...) where {T<:Complex} = plot_fslice(real.(image), args...; kw...)

"""
    plot_velocity(image, spacing; perc=98, cmap=:diverging_bwr_20_95_c54_n256,
                o=(0, 0), interp="hanning", aspect=nothing, d_scale=1.5,
                name="RTM", units="m", new_fig=true, save=nothing)

Plot a velocity model.
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

Plot seismic data gather (i.e shot record).
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
        d = (dx, dt)
    end
    plot_sdata(image.data, d; kw...)
end


# Defaults
_funcs = [:plot_simage, :plot_fslice, :plot_velocity, :plot_sdata]
_default_colors = [:cet_CET_L1, :cet_CET_D1A, :cet_rainbow4, :cet_CET_L1]
_names = ["RTM", "Frequency slice", "Velocity", "Shot record"]
_units = [(:m, :m), (:m, :m), (:m, :m), (:s, :m)]
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

include("wiggles.jl")

end # module
