using Documenter, SlimPlotting, Weave

plpath = dirname(pathof(SlimPlotting))
# Convert example to documentation markdown file
ex_path = "$(plpath)/../examples"
doc_path = "$(plpath)/../docs"

weave("$(ex_path)/plot_example.jl"; out_path="$(doc_path)/src/examples.md", doctype="github")

makedocs(sitename="Slim Plotting toolbox",
         doctest=false, clean=true,
         authors="Mathias Louboutin",
         pages = Any[
             "Home" => "index.md",
             "About" => "README.md",
             "Examples" => "examples.md",
             "API reference" => "API.md",
         ])

deploydocs(repo="github.com/slimgroup/SlimPlotting.jl")
