using Underscores
using Test

@testset "Underscores Examples" begin
    @test [1,"a",2.0] == @_ map(_, [1,"a",2.0])

    strs = ["ab", "ca", "ad"]
    @test [true, false, true] == @_ map(startswith(_, "a"), strs)

    data = [(x="a", y=1),
            (x="b", y=2),
            (x="c", y=3)]

    @test data[1:1] == @_ filter(startswith(_.x, "a"), data)
    @test data[2:3] == @_ filter(_.y >= 2, data)

    # Use with indexing
    @test data[1] == @_ filter(startswith(_.x, "a"), data)[end]
    @test data[2:3] == @_ filter(_.y >= 2, data)[1:2]
    @test data[2] == @_ data[findfirst(_.y >= 2, data)]

    # Operators
    @test -2 == @_ -findfirst(_.x == "b", data)
    @test [14] == @_ [1 2 3] * map(_.y, data)
    @test (1:3)./3 == @_ data |> map(_.y, __) ./ length(__)

    # Multiple args
    @test [0,0] == @_ map(_-_, [1,2])

    # do syntax: _ is treated as the slot for do, rather than the identity
    @test ["aa","aa","bb","bb","cc","cc"] ==
        @_ mapreduce(_^2, _, ["a", "b", "c"], init=[]) do x,y
            vcat(x,y,y)
        end
    # When _ doesn't appear, it's just a normal do block
    @test [1,4] == @_ map([1,2]) do x
        x^2
    end
    # Use with __. Yikes :-/
    @test 14 == @_ function (x)
        x^2
    end |> mapreduce(__, _, [1,2,3]) do x,y
        x+y
    end

    # Use with piping and __
    @test [1] == @_ data |>
                    filter(startswith(_.x, "a"), __) |>
                    map(_.y, __)

    @test [3,2,1] == @_ data |>
                        sort(__, by=_.x, rev=true) |>
                        map(_.y, __)

    @test [1] == (@_ map(_.y, __) ∘
                     filter(startswith(_.x, "a"), __))(data)

    @test [0,0,0] == @_ data |> map(_1.y + _2, __, [-1,-2,-3])

    @test 3 == @_ [[1], [1,2], [1,2,3]] |>
                                map(_[_[end]], __) |>
                                __[end]

    # Use with piping and lazy versions of map and filter
    Filter(f) = x->filter(f,x)
    Map(f) = x->map(f,x)

    @test [1] == @_ data |>
                    Filter(startswith(_.x, "a")) |>
                    Map(_.y)

    @test [1] == @_(Map(_.y) ∘ Filter(startswith(_.x, "a")))(data)

    # Getproperty
    @test "a" == @_ data |> __[1].x
    @test "b" == @_ (x="a", y=(z="b", t="c")) |> __.y.z
    @test "c" == @_ (x="a", y=(z="b", t="c")) |> __.y[end]
    @test -3 == @_ [1+2im,3,4+5im] |> sum(_^2, __).re

    # Interpolation
    @test ["1","a","2.0"] == @_ map("$_", [1,"a",2.0])

    # Broadcasting
    @_ [[1],[2],[3]] == data |> filter.(_ isa Int, collect.(__))

    # Comprehensions
    @test [[],[],[3]] == @_ [[1], [1,2], [1,2,3]] |>
                                [filter(_>2, x) for x in __]
    @test fill(:y,3) == @_ data |>
                        Symbol[findfirst(_ isa Int, x) for x in __]

    # Matrix construction
    @test 4*ones(2,2) == @_ ones(4) |> [ sum(__)      sum(_^2, __)
                                         sum(_^3, __) sum(_^4, __) ]
end

@testset "Underscores lowering" begin
    cleanup!(ex) = Base.remove_linenums!(ex)
    cleanup!(ex, sym_rename::Pair) = _cleanup!(Base.remove_linenums!(ex), sym_rename)
    function _cleanup!(ex, sym_rename)
        if ex isa Symbol
            occursin(sym_rename[1], String(ex)) ? sym_rename[2] : ex
        elseif ex isa Expr
            Expr(ex.head, map(e->_cleanup!(e,sym_rename), ex.args)...)
        else
            ex
        end
    end
    lower(ex, args...) = cleanup!(Underscores.lower_underscores(ex), args...)

    # Simple cases
    # _
    @test lower(:(f(_))) == cleanup!(:(f((_1,)->_1)))
    @test lower(:(f(g(h(_))))) == cleanup!(:(f(((_1,)->g(h(_1))))))
    # __
    @test lower(:(f(__))) == cleanup!(:((__1,)->f(__1)))
    @test lower(:(f(g(h(__))))) == cleanup!(:((__1,)->f(g(h(__1)))))
    # Tricky case when function name is itself an underscore expression.
    # We want the function name to be also expanded here.
    @test lower(:(g(_)(x))) == cleanup!(:(((_1,)->g(_1))(x)))

    # Multiple arguments
    # _
    @test lower(:(f(_,a))) == cleanup!(:(f(((_1,)->_1), a)))
    @test lower(:(f(a,_))) == cleanup!(:(f(a, ((_1,)->_1))))
    @test lower(:(f(_,_))) == cleanup!(:(f(((_1,)->_1), ((_1,)->_1))))
    @test lower(:(f(g(_,_)))) == cleanup!(:(f(((_1,)->g(_1,_1)))))
    # __
    @test lower(:(f(__,__))) == cleanup!(:((__1,)->f(__1, __1)))

    # Numbered arguments
    # _
    @test lower(:(f(_1))) == cleanup!(:(f((_1,)->_1)))
    @test lower(:(f(_2))) == cleanup!(:(f((_1,_2)->_2)))
    @test lower(:(f(_2+_1))) == cleanup!(:(f((_1,_2)->_2+_1)))
    # __
    @test lower(:(f(__1))) == cleanup!(:((__1,)->f(__1)))
    @test lower(:(f(__2))) == cleanup!(:((__1,__2)->f(__2)))
    @test lower(:(f(__2+__1))) == cleanup!(:((__1,__2)->f(__2+__1)))

    # Cute subscript-numbered arguments
    @test lower(:(f(_₁))) == cleanup!(:(f((_1,)->_1)))
    @test lower(:(f(_₂))) == cleanup!(:(f((_1,_2)->_2)))
    @test lower(:(f(__₁))) == cleanup!(:((__1,)->f(__1)))

    # Can't mix numbered and non-numbered placeholders
    @test_throws ArgumentError lower(:(f(_+_1)))
    @test_throws ArgumentError lower(:(f(__+__1)))

    # piping and composition
    # _
    @test lower(:(f(_) |> g(_) |> h(_))) ==
          cleanup!(:(f((_1,)->_1) |>
                     g((_1,)->_1) |>
                     h((_1,)->_1)))
    @test lower(:(f(_) ∘ g(_) ∘ h(_))) ==
          cleanup!(:(f((_1,)->_1) ∘
                     g((_1,)->_1) ∘
                     h((_1,)->_1)))
    @test lower(:(f(_) <| g(_) <| h(_))) ==
          cleanup!(:(f((_1,)->_1) <|
                     g((_1,)->_1) <|
                     h((_1,)->_1)))
    # __
    @test lower(:(f(_, __) |> g(_, __))) ==
        cleanup!(:(((__1,)->f((_1,)->_1, __1)) |>
                   ((__1,)->g((_1,)->_1, __1))))

    # Keyword arguments
    @test lower(:(f(x, k=_+1))) == cleanup!(:(f(x, k=((_1,)->_1+1))))
    @test lower(:(f(x; k=_+1))) == cleanup!(:(f(x; k=((_1,)->_1+1))))

    # Broadcast notation
    @test lower(:(f.(_)))   == cleanup!(:(f.((_1,)->_1)))
    @test lower(:(f.(_,_))) == cleanup!(:(f.((_1,)->_1, (_1,)->_1)))
    @test lower(:(f.(__)))  == cleanup!(:((__1,)->f.(__1)))
    @test lower(:((_).(x)))  == cleanup!(:(((_1,)->_1).(x)))

    # Indexing
    @test lower(:(f(_)[2])) == cleanup!(:(f((_1,)->_1)[2]))
    @test lower(:(f(g(_[3]),h)[4])) == cleanup!(:(f((_1,)->g(_1[3]),h)[4]))
    @test lower(:(f(__)[5])) == cleanup!(:((__1,)->f(__1)[5]))

    # Random sample of other syntax
    @test lower(:([_]))  == cleanup!(:([(_1,)->_1]))
    @test lower(:((f(_), g(_))))  == cleanup!(:(((_1,)->f(_1)), ((_1,)->g(_1))))
    @test lower(:([__])) == cleanup!(:((__1,)->[__1]))
    @test lower(:(__.x)) == cleanup!(:((__1,)->__1.x))

    # do syntax
    # basic case
    @test lower(:(f(x,_) do ; body end), r"do_func"=>:do_func) ==
        cleanup!(:(let do_func = ()->body
                       f(x, do_func)
                   end))
    # do in second slot; first slot should be expanded too
    @test lower(:(f(g(_),_) do ; body end), r"do_func"=>:do_func) ==
        cleanup!(:(let do_func = ()->body
                       f((_1,)->g(_1), do_func)
                   end))
    # do in second and third slots
    @test lower(:(f(x,_,_) do ; body end), r"do_func"=>:do_func) ==
        cleanup!(:(let do_func = ()->body
                       f(x, do_func, do_func)
                   end))
    # do without _'s
    @test lower(:(f() do ; body end)) == cleanup!(:(f() do ; body end))
    # do with __, without _'s
    @test lower(:(f(__) do ; body end)) == cleanup!(:((__1,)->f(__1) do ; body end))
end

