using Documenter, Underscores

DocMeta.setdocmeta!(Underscores, :DocTestSetup, :(using Underscores); recursive=true)
makedocs(;
    modules=[Underscores],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/c42f/Underscores.jl/blob/{commit}{path}#L{line}",
    sitename="Underscores.jl",
    authors="Chris Foster <chris42f@gmail.com>",
    doctest=true
)

deploydocs(;
    repo="github.com/c42f/Underscores.jl",
    push_preview=true
)
