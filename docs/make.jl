using Documenter, Underscores

makedocs(;
    modules=[Underscores],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/c42f/Underscores.jl/blob/{commit}{path}#L{line}",
    sitename="Underscores.jl",
    authors="Chris Foster <chris42f@gmail.com>"
)

deploydocs(;
    repo="github.com/c42f/Underscores.jl",
    push_preview=true
)
