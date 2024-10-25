using PythonPlot

deps = ("colorcet", "seiscm")

function install_pkg(pkg)
    if get(ENV, "JULIA_CONDAPKG_BACKEND", "conda") == "Null"
        pyexe = PythonPlot.PythonCall.python_executable_path()
        run(Cmd(`$(pyexe) -m pip install --user $(pkg)`))
    end
end

for pkg in deps
    install_pkg(pkg)
end