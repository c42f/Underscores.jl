# Underscores.jl

Underscores provides a single macro `@_` to make it easier to pass closures to
higher order functions. This is done by translating "placeholder expressions"
containing placeholders `_` or `_1,_2,...` . The key benefits of `_`
placeholders are
* They avoid the need to come up with argument names (for example, the `x` in
  `x->x+1` may not be meaningful).
* Brevity. For example `_+1`.

## Tutorial

### Basic use of `_`

`@_` and `_` placeholders are for making functions *to pass to other
functions*. This can be very convenient for simple uses of `map` in cases where
broadcasting syntax is awkward. For example, to get the second last element of
each array in a collection:

```jldoctest
julia> @_ map(_[end-1],  [[1,2,3], [4,5]])
2-element Array{Int64,1}:
 2
 4
```

Repeated use of `_` creates functions with multiple arguments. For example,

```jldoctest
julia> @_ map("X $(repeat(_,_))", ["a","b","c"], [1,2,3])
3-element Array{String,1}:
 "X a"
 "X bb"
 "X ccc"
```

Numbered placeholders like `_1` can be useful when you need to repeat arguments
or reorder them. For example,

```jldoctest
julia> @_ map("X $_2 $(repeat(_1,_2))", ["a","b","c"], [1,2,3])
3-element Array{String,1}:
 "X 1 a"
 "X 2 bb"
 "X 3 ccc"
```

### Tabular data

`@_` can be particularly helpful for manipulating tabular data, especially when
combined with piping. Let's filter a list of named tuples:

```jldoctest
julia> table = [(x="a", y=1),
                (x="b", y=2),
                (x="c", y=3)];

julia> @_ filter(!startswith(_.x, "a"), table)
2-element Array{NamedTuple{(:x, :y),Tuple{String,Int64}},1}:
 (x = "b", y = 2)
 (x = "c", y = 3)
```

`@_` is especially useful when combined with double underscore placeholders
`__` and piping syntax. In the following, think of `__` as the table, and `_`
as an individual row:

```jldoctest
julia> @_ table |>
          filter(!startswith(_.x, "a"), __) |>
          map(_.y, __)
2-element Array{Int64,1}:
 2
 3
```

## Reference

```@docs
@_
```

## Design

Underscore syntax for Julia has been discussed at great length in
[#24990](https://github.com/JuliaLang/julia/pull/24990) and elsewhere in the
Julia community. The design for Underscores.jl grew out of this discussion.
A great many packages have had a go at macros for this, including at least
`Lazy.jl`, `LightQuery.jl`, `LambdaFn.jl`, `Query.jl` and
`SplitApplyCombine.jl`.

One design difficulty is that much of the package work has focussed on the
tabular data manipulation scenario. However, as a language feature a compelling
general solution for `_` placeholders must have wider appeal.

Starting with the need to be useful outside of tabular data manipulation, we
observe that anonymous functions are generally passed directly to another
"outer" function. For example, in `map(x->x*y, A)` the outer function is `map`.
However, putting `@_` inside the function call leads to a lot of visual
clutter, especially because it often must be parenthesized to avoid consuming
the remaining arguments to `map`. However, one can place the `@_` on the
function *receiving* the closure which results in less visual clutter and
improved clarity. Compare:

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