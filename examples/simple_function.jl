include("../src/ParameterSpace.jl")

using .ParameterSpace

@inline g(x::Real, y::Real) = x * y

function test()
    params = [Parameter("x", 1, 0:2),
              Parameter("y", 2, 0:2)]

    result = analyse_function(g, params)
    @show result

    ########################
    params = [Parameter("y", 2, 0:0.1:0.5)]

    result = analyse_function(g, params, 1.0)
    @show result
end

test()
