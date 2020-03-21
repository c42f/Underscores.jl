module Underscore

export @_

argname(i) = Symbol("_", i)

function _toclosure(nargs, numbered_nargs, ex)
    if ex isa Symbol
        if ex === :_
            nargs[] += 1
            arg = argname(nargs[])
            return arg
        elseif occursin(r"^_[0-9]+$", string(ex))
            n = parse(Int, string(ex)[2:end])
            numbered_nargs[] = max(numbered_nargs[], n)
            return argname(n)
        else
            return ex
        end
    elseif ex isa Expr
        if ex.head == :quote || ex.head == :inert || ex.head == :meta
            return ex
        end
        args = map(e->_toclosure(nargs, numbered_nargs, e), ex.args)
        return Expr(ex.head, args...)
    else
        return ex
    end
end

function toclosure(ex)
    nargs = Ref(0)
    numbered_nargs = Ref(0)
    body = _toclosure(nargs, numbered_nargs, ex)
    if nargs[] > 0 && numbered_nargs[] > 0
        throw(ArgumentError("Cannot mix plain and numbered `_` placeholders in `$ex`"))
    end
    n = max(nargs[], numbered_nargs[])
    if n == 0
        return ex
    end
    argnames = map(argname, 1:n)
    return :(($(argnames...),) -> $body)
end

function lower_underscores(ex)
    if ex isa Expr && ex.head == :call && length(ex.args) > 1
        name = ex.args[1]
        if name == :|> || name == :<| || name == :∘
            Expr(ex.head, name, map(lower_underscores, ex.args[2:end])...)
        else
            Expr(ex.head, name, map(toclosure, ex.args[2:end])...)
        end
    else
        return ex
    end
end

"""
    @_ func(ex1, [ex2 ...])

Convert `ex1,ex2,...` into anonymous functions when they have `_` placeholders,
and *pass them along* to `func`.

When multiple `_` are present in a single sub-expression they become successive
arguments to a single anonymous function. That is, `@_ map(_+2^_, A)` is
equivalent to `@_ map((x,y)->x+2^y, A)`.

Numbered placeholders `_1,_2,...` may be used if you need to reorder,repeat or
omit arguments. For example `@_ map(_2+_1, A, B)` is equivalent to
`map((x,y)->y+x, A, B)`.

Piping and composition chains are treated as a special case where the
replacement recurses into sub-expressions. That is, the following two are
equivalent:

    @_ f1(ex1)  |>     f2(ex1)
    @_(f1(ex1)) |>  @_(f2(ex1))

# Examples

`@_` can be very convenient for simple mapping operations in cases where
broadcasting syntax is awkward. For example, to get the second last element of
each array in a collection:

```jldoctest
julia> @_ map(_[end-1],  [[1,2,3], [4,5]])
2-element Array{Int64,1}:
 2
 4
```

If you need to repeat an argument more than once the numbered form can be useful:

```jldoctest
julia> @_ map(_1^_1,  [1,2,3])
3-element Array{Int64,1}:
  1
  4
 27
```

For manipulating tabular data `@_` provides convenient syntax:

```jldoctest
julia> data = [(x="a", y=1),
               (x="b", y=2),
               (x="c", y=3)];

julia> @_ filter(!startswith(_.x, "a"), data)
2-element Array{NamedTuple{(:x, :y),Tuple{String,Int64}},1}:
 (x = "b", y = 2)
 (x = "c", y = 3)
```

Combined with a lazy Map and Filter it gives super simple but convenient
manipulation of tabular data:

```jldoctest
julia> Filter(f) = x->filter(f,x);   Map(f) = x->map(f,x);

julia> @_ data |>
          Filter(!startswith(_.x, "a")) |>
          Map(_.y)
2-element Array{Int64,1}:
 2
 3
```
"""
macro _(ex)
    esc(lower_underscores(ex))
end

end
