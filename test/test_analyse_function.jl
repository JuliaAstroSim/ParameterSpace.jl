using Test
using ParameterSpace
using DataFrames

@testset "analyse_function with ParamSpace" begin
    g(params) = params.x * params.y
    pspace = ParamSpace([
        ParamDim("x", values=[1,2,3]),
        ParamDim("y", values=[1,2])
    ])

    result = analyse_function(g, pspace; folder="output/test_func1")
    @test nrow(result) == 6
    @test sum(result.result) == 18
end

@testset "analyse_function with sampling" begin
    g(params) = params.x * params.y
    pspace = ParamSpace([
        ParamDim("x", values=1:100),
        ParamDim("y", values=1:100)
    ])

    result = analyse_function(g, pspace;
        strategy=RandomSampling(seed=42),
        n_samples=50,
        folder="output/test_func2"
    )
    @test nrow(result) == 50
end

@testset "analyse_function backward compatibility" begin
    g(x, y) = x * y
    params = [Parameter("x", 1, 0:2), Parameter("y", 2, 0:2)]

    result = analyse_function(g, params; folder="output/test_func3")
    @test nrow(result) == 9
    @test sum(result.result) == 9
end

@testset "analyse_function with GridSampling" begin
    g(params) = params.x + params.y
    pspace = ParamSpace([
        ParamDim("x", values=[1,2]),
        ParamDim("y", values=[3,4])
    ])

    result = analyse_function(g, pspace;
        strategy=GridSampling(),
        folder="output/test_func4"
    )
    @test nrow(result) == 4
end

@testset "analyse_function with kwargs" begin
    g(params; scale=1) = params.x * scale
    pspace = ParamSpace([ParamDim("x", values=[1,2,3])])

    result = analyse_function(g, pspace; scale=2, folder="output/test_func5")
    @test result.result == [2, 4, 6]
end

@testset "analyse_function with extra args" begin
    g(params, base) = params.x + base
    pspace = ParamSpace([ParamDim("x", values=[1,2,3])])

    result = analyse_function(g, pspace, 10; folder="output/test_func6")
    @test result.result == [11, 12, 13]
end
