module PyPlotSlimExt

import SlimPlotting: seiscm, getcmap

isdefined(Base, :get_extension) ? (using PyPlot) : (using ..PyPlot)
isdefined(Base, :get_extension) ? (using PyPlot.PyCall) : (using ..PyPlot.PyCall)

function tryimport(pkg::String)
    pyi = try
        PyPlot.pyimport(pkg)
    catch e
        if PyPlot.PyCall.conda
            PyPlot.PyCall.Conda.pip_interop(true)
            PyPlot.PyCall.Conda.pip("install", pkg)
        else
            run(PyPlot.PyCall.python_cmd(`-m pip install --user $(pkg)`))
        end
        PyPlot.pyimport(pkg)
    end
    return pyi
end

const cc = PyNULL()

pypltref = PyPlot

function __init__()
    @info "Initializing PyPlotSlimExt"
    # Import colorcet
    copy!(cc, tryimport("colorcet"))
end

getcmap(s) = ColorMap(s)

end