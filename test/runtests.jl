using Test
using ParameterSpace

@testset "Tuning function" begin
    g(x::Real, y::Real) = x * y

    params = [Parameter("x", 1, 0:2),
              Parameter("y", 2, 0:2)]

    tuning = analyse_function(g, params)
    @test sum(tuning.result) == 9


    params = [Parameter("y", 2, 0:2)]
    tuning = analyse_function(g, params, 1)
    @test sum(tuning.result) == 3
end

@testset "Tuning program" begin
    script = joinpath(pwd(), "program.jl")
    command = `julia --startup-file=no $script`

    params = [Parameter("x", 1, [1,10,100]),
              Parameter("y", 2, [1000,10000])]

    content = "x = %d, y = %d"

    # param.txt is writen before running the program, we simply read the file
    function analyse(x::Int)
        f = readlines("param.txt")
        return length(f[1]) + x
    end

    tuning = analyse_program(command, content, "param.txt", params, analyse, args = [-15])
    @test sum(tuning.result) == 9
end