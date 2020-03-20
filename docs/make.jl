using Documenter, Underscore

makedocs(;
    modules=[Underscore],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/c42f/Underscore.jl/blob/{commit}{path}#L{line}",
    sitename="Underscore.jl",
    authors="Chris Foster <chris42f@gmail.com>"
)

deploydocs(;
    repo="github.com/c42f/Underscore.jl",
    push_preview=true
)
