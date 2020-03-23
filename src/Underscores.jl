module Underscores

@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), "```julia" => "```jldoctest")
end Underscores

export @_

isquoted(ex) = ex isa Expr && ex.head in (:quote, :inert, :meta)

function _replacesyms(sym_map, ex)
    if ex isa Symbol
        return sym_map(ex)
    elseif ex isa Expr
        if isquoted(ex)
            return ex
        end
        args = map(e->_replacesyms(sym_map, e), ex.args)
        return Expr(ex.head, args...)
    else
        return ex
    end
end

function add_closures(ex, prefix, pattern)
    if ex isa Expr && (ex.head == :kw || ex.head == :parameters)
        return Expr(ex.head, map(e->add_closures(e,prefix,pattern), ex.args)...)
    end
    plain_nargs = 0
    numbered_nargs = 0
    body = _replacesyms(ex) do sym
        m = match(pattern, string(sym))
        if m === nothing
            sym
        else
            argnum_str = m[1]
            if isempty(argnum_str)
                plain_nargs += 1
                argnum = plain_nargs
            else
                argnum = parse(Int, argnum_str)
                numbered_nargs = max(numbered_nargs, argnum)
            end
            Symbol(prefix, argnum)
        end
    end
    if plain_nargs > 0 && numbered_nargs > 0
        throw(ArgumentError("Cannot mix plain and numbered `$prefix` placeholders in `$ex`"))
    end
    nargs = max(plain_nargs, numbered_nargs)
    if nargs == 0
        return ex
    end
    argnames = map(i->Symbol(prefix,i), 1:nargs)
    return :(($(argnames...),) -> $body)
end

replace_(ex)  = add_closures(ex, "_", r"^_([0-9]*)$")
replace__(ex) = add_closures(ex, "__", r"^__([0-9]*)$")

# In principle this can be extended locally by a package for use within the
# package and for prototyping purposes. However note that this will interact
# badly with precompilation. (If it makes sense we could fix this per-package
# by storing a per-module _pipeline_ops in the module using @_.)
const _pipeline_ops = [:|>, :<|, :∘]

function lower_underscores(ex)
    if ex isa Expr
        if isquoted(ex)
            return ex
        elseif ex.head == :call && length(ex.args) > 1 &&
               ex.args[1] in _pipeline_ops
            # Special case for pipelining and composition operators
            return Expr(ex.head, ex.args[1],
                        map(lower_underscores, ex.args[2:end])...)
        elseif ex.head == :.       && length(ex.args) == 2 &&
               ex.args[2] isa Expr && ex.args[2].head == :tuple
            # Broadcast calls treated as normal calls for underscore lowering
            return replace__(Expr(ex.head, ex.args[1],
                                  Expr(:tuple, map(replace_, ex.args[2].args)...)))
        else
            # For other syntax, replace _ in args individually and __ over the
            # entire expression.
            return replace__(Expr(ex.head, map(replace_, ex.args)...))
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

The placeholder `__` (and numbered versions `__1,__2,...`) may be used to
expand the closure scope to the whole expression. That is, the following are
equivalent:

    @_ func(a,__)
    x->func(a,x)

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

If you need to repeat an argument more than once the numbered form can be
useful:

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

It's especially useful when combined with double underscore placeholders `__`
and piping syntax. Think of `__` as the table, and `_` as an individual row:

```jldoctest
julia> @_ data |>
          filter(!startswith(_.x, "a"), __) |>
          map(_.y, __)
2-element Array{Int64,1}:
 2
 3
```
"""
macro _(ex)
    esc(lower_underscores(ex))
end

end
