using Documenter, SlimPlotting

makedocs(sitename="Slim Plotting toolbox",
         doctest=false, clean=true,
         authors="Mathias Louboutin",
         pages = Any[
             "Home" => "index.md",
             "About" => "README.md",
             "API reference" => "API.md",
         ])

deploydocs(repo="github.com/slimgroup/SlimPlotting.jl")