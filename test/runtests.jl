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

    function analyse(x::Int)
        f = readlines("param.txt")
        return length(f[1]) + x
    end

    folder = mktempdir()
    tuning = analyse_program(command, content, "param.txt", params, analyse, args = [-15];
        folder = folder
    )
    @test sum(tuning.result) == 9
    rm(folder, recursive=true, force=true)
end

include("test_paramdim.jl")
include("test_paramspace.jl")
include("test_coupled.jl")
include("test_sampling_abstract.jl")
include("test_sampling_random.jl")
include("test_sampling_lhs.jl")
include("test_sampling_sobol.jl")
include("test_sampling_grid.jl")
include("test_mask.jl")
include("test_config_yaml.jl")
include("test_config_toml.jl")
include("test_analyse_function.jl")
include("test_analyse_program.jl")
include("test_parallel_threads.jl")
include("test_compat.jl")
