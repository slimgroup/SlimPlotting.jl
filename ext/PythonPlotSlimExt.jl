module PythonPlotSlimExt

import SlimPlotting: seiscm, getcmap
isdefined(Base, :get_extension) ? (using PythonPlot) : (using ..PythonPlot)

function tryimport(pkg::String)
    pyi = try
        PythonPlot.pyimport(pkg)
    catch e
        if get(ENV, "JULIA_CONDAPKG_BACKEND", "conda") == "Null"
            pyexe = PythonPlot.PythonCall.python_executable_path()
            run(Cmd(`$(pyexe) -m pip install --user $(pkg)`))    
        else
            PythonPlot.CondaPkg.add_pip(pkg)
        end
        PythonPlot.pyimport(pkg)
    end
    return pyi
end

const cc = PythonPlot.PythonCall.pynew()

pypltref = PythonPlot

function __init__()
    @info "Initializing PythonPlotSlimExt"
    # Import colorcet
    PythonPlot.PythonCall.pycopy!(cc, tryimport("colorcet"))
end

getcmap(s) = ColorMap(s)
getcmap(c::PythonPlot.PythonCall.Py) = c

end
