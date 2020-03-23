var documenterSearchIndex = {"docs":
[{"location":"#Underscores.jl-1","page":"Home","title":"Underscores.jl","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"Underscores provides simple syntax for passing closures to functions by interpreting _ placeholders as anonymous function arguments. For example @_ map(_+1, xs) to mean map(x->x+1, xs).","category":"page"},{"location":"#","page":"Home","title":"Home","text":"This is helpful when you want to write anonymous functions succinctly without naming the arguments, for example in data processing pipelines such as","category":"page"},{"location":"#","page":"Home","title":"Home","text":"@_ people |> filter(_.age > 40, __) |> map(_.name, __)","category":"page"},{"location":"#Tutorial-1","page":"Home","title":"Tutorial","text":"","category":"section"},{"location":"#Basic-use-of-_-1","page":"Home","title":"Basic use of _","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"@_ and _ placeholders are for making functions to pass to other functions. This can be very convenient for simple uses of map in cases where broadcasting syntax is awkward. For example, to get the second last element of each array in a collection:","category":"page"},{"location":"#","page":"Home","title":"Home","text":"julia> @_ map(_[end-1],  [[1,2,3], [4,5]])\n2-element Array{Int64,1}:\n 2\n 4","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Repeated use of _ creates functions with multiple arguments. For example,","category":"page"},{"location":"#","page":"Home","title":"Home","text":"julia> @_ map(\"X $(repeat(_,_))\", [\"a\",\"b\",\"c\"], [1,2,3])\n3-element Array{String,1}:\n \"X a\"\n \"X bb\"\n \"X ccc\"","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Numbered placeholders like _1 can be useful when you need to repeat arguments or reorder them. For example,","category":"page"},{"location":"#","page":"Home","title":"Home","text":"julia> @_ map(\"X $_2 $(repeat(_1,_2))\", [\"a\",\"b\",\"c\"], [1,2,3])\n3-element Array{String,1}:\n \"X 1 a\"\n \"X 2 bb\"\n \"X 3 ccc\"","category":"page"},{"location":"#Tabular-data-1","page":"Home","title":"Tabular data","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"@_ can be helpful for manipulating tabular data, especially when combined with piping. Let's filter a list of named tuples:","category":"page"},{"location":"#","page":"Home","title":"Home","text":"julia> table = [(x=\"a\", y=1),\n                (x=\"b\", y=2),\n                (x=\"c\", y=3)];\n\njulia> @_ filter(!startswith(_.x, \"a\"), table)\n2-element Array{NamedTuple{(:x, :y),Tuple{String,Int64}},1}:\n (x = \"b\", y = 2)\n (x = \"c\", y = 3)","category":"page"},{"location":"#","page":"Home","title":"Home","text":"@_ is especially useful when combined with double underscore placeholders __ and piping syntax. In the following, think of __ as the table, and _ as an individual row:","category":"page"},{"location":"#","page":"Home","title":"Home","text":"julia> @_ table |>\n          filter(!startswith(_.x, \"a\"), __) |>\n          map(_.y, __)\n2-element Array{Int64,1}:\n 2\n 3","category":"page"},{"location":"#Reference-1","page":"Home","title":"Reference","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"@_","category":"page"},{"location":"#Underscores.@_","page":"Home","title":"Underscores.@_","text":"@_ func(ex1, [ex2 ...])\n\nConvert ex1,ex2,... into anonymous functions when they have _ placeholders, and pass them along to func.\n\nWhen multiple _ are present in a single sub-expression they become successive arguments to a single anonymous function. That is, @_ map(_+2^_, A) is equivalent to @_ map((x,y)->x+2^y, A).\n\nNumbered placeholders _1,_2,... may be used if you need to reorder,repeat or omit arguments. For example @_ map(_2+_1, A, B) is equivalent to map((x,y)->y+x, A, B).\n\nPiping and composition chains are treated as a special case where the replacement recurses into sub-expressions. That is, the following two are equivalent:\n\n@_ f1(ex1)  |>     f2(ex1)\n@_(f1(ex1)) |>  @_(f2(ex1))\n\nThe placeholder __ (and numbered versions __1,__2,...) may be used to expand the closure scope to the whole expression. That is, the following are equivalent:\n\n@_ func(a,__)\nx->func(a,x)\n\nExamples\n\n@_ can be very convenient for simple mapping operations in cases where broadcasting syntax is awkward. For example, to get the second last element of each array in a collection:\n\njulia> @_ map(_[end-1],  [[1,2,3], [4,5]])\n2-element Array{Int64,1}:\n 2\n 4\n\nIf you need to repeat an argument more than once the numbered form can be useful:\n\njulia> @_ map(_1^_1,  [1,2,3])\n3-element Array{Int64,1}:\n  1\n  4\n 27\n\nFor manipulating tabular data @_ provides convenient syntax:\n\njulia> data = [(x=\"a\", y=1),\n               (x=\"b\", y=2),\n               (x=\"c\", y=3)];\n\njulia> @_ filter(!startswith(_.x, \"a\"), data)\n2-element Array{NamedTuple{(:x, :y),Tuple{String,Int64}},1}:\n (x = \"b\", y = 2)\n (x = \"c\", y = 3)\n\nIt's especially useful when combined with double underscore placeholders __ and piping syntax. Think of __ as the table, and _ as an individual row:\n\njulia> @_ data |>\n          filter(!startswith(_.x, \"a\"), __) |>\n          map(_.y, __)\n2-element Array{Int64,1}:\n 2\n 3\n\n\n\n\n\n","category":"macro"},{"location":"#Design-1","page":"Home","title":"Design","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"Underscore syntax for Julia has been discussed at great length in #24990, #5571 and elsewhere in the Julia community. The design for Underscores.jl grew out of this discussion. A great many packages have had a go at macros for this, including at least ChainMap.jl, ChainRecursive.jl, FunctionalData.jl, Hose.jl, Lazy.jl, LightQuery.jl, LambdaFn.jl, MagicUnderscores.jl, Pipe.jl, Query.jl and SplitApplyCombine.jl","category":"page"},{"location":"#","page":"Home","title":"Home","text":"The key benefits of _ placeholders are","category":"page"},{"location":"#","page":"Home","title":"Home","text":"They avoid the need to come up with argument names (for example, the x in x->x+1 may not be meaningful).\nBrevity. For example _+1.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"One design difficulty is that much of the package work has focussed on the piping and tabular data manipulation scenario. However as a language feature a compelling general solution for _ placeholders needs wider appeal.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Starting with the need to be useful outside of tabular data manipulation, we observe that anonymous functions are generally passed directly to another \"outer\" function. For example, in map(x->x*y, A) the outer function is map. However, putting @_ inside the function call leads to a lot of visual clutter, especially because it needs to be parenthesized to avoid consuming the remaining arguments to map. However, one can place the @_ on the function receiving the closure which results in less visual clutter and improved clarity. Compare:","category":"page"},{"location":"#","page":"Home","title":"Home","text":"@_ map(_+1, A)   # This design\n\nmap(@_(_+1), A)  # The obvious alternative\n\nmap(x->x+1, A)   # Current status quo","category":"page"},{"location":"#","page":"Home","title":"Home","text":"With this \"outermost-but-one\" placement in mind, one can generalize to pipelines where anonymous functions are generally used as arguments to filter and map. This works in a particularly nice way for lazy versions of Filter and Map, allowing expressions such as","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Filter(f) = x->filter(f,x);   Map(f) = x->map(f,x);\n\n@_  data         |>\n    Filter(_>10) |>\n    Map(_+1)","category":"page"},{"location":"#","page":"Home","title":"Home","text":"However, julia natively has non-lazy filter and map so we'd really like a way to make these directly useable as well. For this we introduce the longer placeholder __ to escape the extra function call to the outer level. This is also appealing because the larger data structure (ie, the full table) ends up being represented by __, while the smaller row data structure is the smaller placeholder _. Thus we get:","category":"page"},{"location":"#","page":"Home","title":"Home","text":"@_  data             |>\n    filter(_>10, __) |>\n    map(_+1, __)","category":"page"}]
}
