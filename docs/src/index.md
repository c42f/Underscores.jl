# Underscores.jl

```@meta
DocTestSetup = :(using Underscores)
```

`Underscores` provides a macro `@_` for passing closures to functions by
interpreting `_` *placeholders* as anonymous function arguments. For example
`@_ map(_+1, xs)` means `map(x->x+1, xs)`.

`Underscores` is useful for writing anonymous functions succinctly and without
naming the arguments. This is particular useful for data processing pipelines
such as
```julia
@_ people |> filter(_.age > 40, __) |> map(_.name, __)
```

## Tutorial

### Basic use of `_`

`@_` and `_` placeholders are for making functions *to pass to other
functions*. For example, to get the second last element of each array in a
collection, broadcasting syntax would be awkward. Instead we can use:

```jldoctest
julia> @_ map(_[end-1],  [[1,2,3], [4,5]])
2-element Vector{Int64}:
 2
 4
```

Repeated use of `_` refers to the argument of a single-argument anonymous
function. To sum the last two elements of the arrays from the previous example:

```jldoctest
julia> @_ map(_[end] + _[end-1],  [[1,2,3], [4,5]])
2-element Vector{Int64}:
 5
 9
```

### Multiple arguments

Multiple argument anonymous functions can be created with numbered placeholders
like `_1` can be useful when you need to repeat arguments or reorder them. For
example,

```jldoctest
julia> @_ map("X $_2 $(repeat(_1,_2))", ["a","b","c"], [1,2,3])
3-element Vector{String}:
 "X 1 a"
 "X 2 bb"
 "X 3 ccc"
```

### Tabular data

`@_` is handy for manipulating tabular data. Let's filter a list of named
tuples:

```jldoctest tabular
julia> table = [(x="a", y=1),
                (x="b", y=2),
                (x="c", y=3)];

julia> @_ filter(!startswith(_.x, "a"), table)
2-element Vector{NamedTuple{(:x, :y), Tuple{String, Int64}}}:
 (x = "b", y = 2)
 (x = "c", y = 3)
```

When combined with double underscore placeholders `__` and piping syntax this
becomes particularly neat. In the following, think of `__` as the table, and
`_` as an individual row:

```jldoctest tabular
julia> @_ table |>
          filter(!startswith(_.x, "a"), __) |>
          map(_.y, __)
2-element Vector{Int64}:
 2
 3
```


## Reference

```@docs
@_
```

## Design

Underscore syntax for Julia has been discussed at great length in
[#24990](https://github.com/JuliaLang/julia/pull/24990),
[#5571](https://github.com/JuliaLang/julia/issues/5571) and elsewhere in the
Julia community. The design for Underscores.jl grew out of this discussion.
A great many packages have had a go at macros for this, including at least
[`ChainMap.jl`](https://github.com/bramtayl/ChainMap.jl),
[`ChainRecursive.jl`](https://github.com/bramtayl/ChainRecursive.jl),
[`FunctionalData.jl`](https://github.com/rened/FunctionalData.jl),
[`Hose.jl`](https://github.com/FNj/Hose.jl/),
[`Lazy.jl`](https://github.com/MikeInnes/Lazy.jl),
[`LightQuery.jl`](https://github.com/bramtayl/LightQuery.jl),
[`LambdaFn.jl`](https://github.com/haberdashPI/LambdaFn.jl),
[`MagicUnderscores.jl`](https://github.com/c42f/MagicUnderscores.jl),
[`Pipe.jl`](https://github.com/oxinabox/Pipe.jl),
[`Query.jl`](https://github.com/queryverse/Query.jl) and
[`SplitApplyCombine.jl`](https://github.com/JuliaData/SplitApplyCombine.jl)

The key benefits of `_` placeholders are
* They avoid the need to come up with argument names (for example, the `x` in
  `x->x+1` may not be meaningful).
* Brevity. For example `_+1`.

One design difficulty is that much of the package work has focussed on the
piping and tabular data manipulation scenario. However as a language feature a
compelling general solution for `_` placeholders needs wider appeal.

Starting with the need to be useful outside of tabular data manipulation, we
observe that anonymous functions are generally passed directly to another
"outer" function. For example, in `map(x->x*y, A)` the outer function is `map`.
However, putting `@_` inside the function call leads to a lot of visual
clutter, especially because it needs to be parenthesized to avoid consuming the
remaining arguments to `map`. However, one can place the `@_` on the function
*receiving* the closure which results in less visual clutter and improved
clarity. Compare:

```julia
@_ map(_+1, A)   # This design

map(@_(_+1), A)  # The obvious alternative

map(x->x+1, A)   # Current status quo
```

With this "outermost-but-one" placement in mind, one can generalize to
pipelines where anonymous functions are generally used as arguments to filter
and map. This works in a particularly nice way for lazy versions of `Filter`
and `Map`, allowing expressions such as

```julia
Filter(f) = x->filter(f,x);   Map(f) = x->map(f,x);

@_  data         |>
    Filter(_>10) |>
    Map(_+1)
```

However, julia natively has non-lazy `filter` and `map` so we'd really like a
way to make these directly useable as well. For this we introduce the longer
placeholder `__` to escape the extra function call to the outer level. This is
also appealing because the larger data structure (ie, the full table) ends up
being represented by `__`, while the smaller row data structure is the smaller
placeholder `_`. Thus we get:

```julia
@_  data             |>
    filter(_>10, __) |>
    map(_+1, __)
```
