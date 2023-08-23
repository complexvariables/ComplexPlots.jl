using ComplexPlots
using Documenter

DocMeta.setdocmeta!(ComplexPlots, :DocTestSetup, :(using ComplexPlots); recursive=true)

makedocs(;
    modules=[ComplexPlots],
    authors="Toby Driscoll",
    repo="https://github.com/tobydriscoll/ComplexPlots.jl/blob/{commit}{path}#{line}",
    sitename="ComplexPlots.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://tobydriscoll.github.io/ComplexPlots.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/tobydriscoll/ComplexPlots.jl",
    devbranch="main",
)
