# Underscores

[![Stable Docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://c42f.github.io/Underscores.jl/stable)
[![Dev Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://c42f.github.io/Underscores.jl/dev)
[![Build Status](https://github.com/c42f/Underscores.jl/workflows/CI/badge.svg)](https://github.com/c42f/Underscores.jl/actions?query=workflow%3ACI)

`Underscores` provides simple syntax for passing closures to functions with a
macro `@_`. This enables use like `@_ map(_+1, xs)` and `@_ people |>
filter(_.age > 40, __) |> map(_.name, __)`.

Read the [documentation](https://c42f.github.io/Underscores.jl/dev) for
more information, or see the online help for the `@_` macro.
