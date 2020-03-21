# Underscores.jl

Underscores provides a single macro `@_` to make it easier to pass closures to
higher order functions. This is done by translating "placeholder expressions"
containing placeholders `_` or `_1,_2,...` . The key benefits of `_`
placeholders are
* They avoid the need to come up with argument names (for example, the `x` in
  `x->x+1` may not be meaningful).
* Brevity. For example `_+1`.


## API and Examples

```@docs
@_
```


## Design

We observe that anonymous functions are generally passed directly to another
"outer" function. For example, in `map(x->x*y, A)` the outer function is `map`.
Therefore one can place the `@_` outside the map which leads to less visual
clutter and improved clarity. This is particularly relevant because use of a
macro in a function argument list tends to need additional parenentheses.
Compare to the obvious alternatives:

```julia
    @_ map(_+1, A)
    map(@_(_+1), A)
    map(x->x+1, A)
```

With this "outermost-but-one" placement in mind, one can generalize to
pipelines where anonymous functions are generally used as arguments to filter
and map. This works in a particularly nice way for lazy versions of `Filter`
and `Map`, allowing expressions such as

```julia
    @_  data         |>
        Filter(_>10) |>
        Map(_+1)
```

Somewhat of a design conundrum is how to make this work more natively with
non-lazy `filter` and `map`. It might make sense to support double underscores
to "escape an extra level", allowing things such as

```julia
    @_  data             |>
        filter(_>10, __) |>
        map(_+1, __)
```

to mean what is desired.

