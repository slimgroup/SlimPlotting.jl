#######
# Julia implememtation of a wiggle plot for 2D shot records
######
export wiggle_plot

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
