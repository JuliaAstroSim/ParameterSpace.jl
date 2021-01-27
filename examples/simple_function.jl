using ParameterSpace

@inline g(x::Real, y::Real) = x * y

function test()
    params = [Parameter("x", 1, 0:2),
              Parameter("y", 2, 0:2)]

    tuning = analyse_function(g, params)
    @show tuning

    ########################
    params = [Parameter("y", 2, 0:0.1:0.5)]

    tuning = analyse_function(g, params, 1.0)
    @show tuning
end

test()
