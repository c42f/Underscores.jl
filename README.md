# Underscores

[![Stable Docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://c42f.github.io/Underscores.jl/stable)
[![Dev Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://c42f.github.io/Underscores.jl/dev)
[![Build Status](https://github.com/c42f/Underscores.jl/workflows/CI/badge.svg)](https://github.com/c42f/Underscores.jl/actions?query=workflow%3ACI)

`Underscores` provides a macro `@_` for passing closures to functions by
interpreting `_` *placeholders* as anonymous function arguments. For example
`@_ map(_+1, xs)` means `map(x->x+1, xs)`.

`Underscores` is useful for writing anonymous functions succinctly and without
naming the arguments. This is particular useful for data processing pipelines
such as
```julia
@_ people |> filter(_.age > 40, __) |> map(_.name, __)
```

Read the [documentation](https://c42f.github.io/Underscores.jl/stable) for
more information, or see the online help for the `@_` macro.
