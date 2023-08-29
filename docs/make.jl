using ComplexPlots
using Documenter

DocMeta.setdocmeta!(ComplexPlots, :DocTestSetup, :(using ComplexPlots); recursive=true)

makedocs(;
    modules=[ComplexPlots],
    authors="Toby Driscoll",
    repo="https://github.com/complexvariables/ComplexPlots.jl.git",
    sitename="ComplexPlots.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://complexvariables.github.io/ComplexPlots.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Makie examples" => "makie.md",
        "Plots examples" => "plots.md",
    ],
)

deploydocs(;
    repo="github.com/complexvariables/ComplexPlots.jl",
    devbranch="main",
)
