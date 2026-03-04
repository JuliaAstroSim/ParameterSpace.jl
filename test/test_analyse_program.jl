using Test
using ParameterSpace
using DataFrames

@testset "analyse_program with ParamSpace" begin
    script = joinpath(@__DIR__, "program.jl")
    command = `julia --startup-file=no $script`

    pspace = ParamSpace([
        ParamDim("x", values=[1,10,100]),
        ParamDim("y", values=[1000,10000])
    ])

    content = "x = %d, y = %d"

    function analyse_fn(x::Int)
        f = readlines("param.txt")
        return length(f[1]) + x
    end

    result = analyse_program(command, content, "param.txt", pspace, analyse_fn,
        args=[-15], folder="output/test_prog_new1")
    @test nrow(result) == 6
end

@testset "analyse_program backward compatibility" begin
    script = joinpath(@__DIR__, "program.jl")
    command = `julia --startup-file=no $script`

    params = [Parameter("x", 1, [1,10,100]),
              Parameter("y", 2, [1000,10000])]

    content = "x = %d, y = %d"

    function analyse_fn(x::Int)
        f = readlines("param.txt")
        return length(f[1]) + x
    end

    result = analyse_program(command, content, "param.txt", params, analyse_fn,
        args=[-15], folder="output/test_prog_new2")
    @test nrow(result) == 6
end

@testset "analyse_program with sampling" begin
    script = joinpath(@__DIR__, "program.jl")
    command = `julia --startup-file=no $script`

    pspace = ParamSpace([
        ParamDim("x", values=1:100),
        ParamDim("y", values=1:10)
    ])

    content = "x = %d, y = %d"

    result = analyse_program(command, content, "param.txt", pspace, emptyfunction;
        strategy=RandomSampling(seed=42),
        n_samples=10,
        folder="output/test_prog_new3")
    @test nrow(result) == 10
end

@testset "write_parameter_file" begin
    filepath = tempname() * ".txt"
    write_parameter_file(filepath, "x = %d, y = %f", [10, 3.14])

    content = read(filepath, String)
    @test occursin("x = 10", content)
    @test occursin("y = 3.14", content)

    rm(filepath)
end
