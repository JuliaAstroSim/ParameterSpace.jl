using Test
using ParameterSpace

@testset "ParamDim basic" begin
    pdim = ParamDim("x", values=[1,2,3])
    @test length(pdim) == 3
    @test collect(pdim) == [1,2,3]
    @test pdim.name == :x
end

@testset "ParamDim range constructor" begin
    pdim = ParamDim("x", range=(0, 10, 5))
    @test pdim.values == [0, 5, 10]
    @test length(pdim) == 3
end

@testset "ParamDim linspace constructor" begin
    pdim = ParamDim("x", linspace=(0, 1, 5))
    @test length(pdim.values) == 5
    @test pdim.values[1] == 0.0
    @test pdim.values[end] == 1.0
end

@testset "ParamDim logspace constructor" begin
    pdim = ParamDim("x", logspace=(-1, 1, 3))
    @test length(pdim.values) == 3
    @test isapprox(pdim.values[1], 0.1)
    @test isapprox(pdim.values[end], 10.0)
end

@testset "ParamDim with mask" begin
    pdim = ParamDim("x", values=[1,2,3], mask=[true, false, true])
    @test length(pdim) == 2
    @test collect(pdim) == [1, 3]
end

@testset "ParamDim default value" begin
    pdim = ParamDim("x", values=[1,2,3], default=2)
    @test pdim.default == 2
end

@testset "ParamDim Symbol name" begin
    pdim = ParamDim(:y, values=[1,2,3])
    @test pdim.name == :y
end
