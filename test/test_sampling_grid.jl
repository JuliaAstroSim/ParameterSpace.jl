using Test
using ParameterSpace

@testset "GridSampling basic" begin
    pspace = ParamSpace([
        ParamDim("x", values=[1,2,3]),
        ParamDim("y", values=[1,2])
    ])
    
    samples = sample(pspace, GridSampling())
    @test length(samples) == 6
end

@testset "GridSampling equals iteration" begin
    pspace = ParamSpace([
        ParamDim("x", values=[1,2,3]),
        ParamDim("y", values=[1,2])
    ])
    
    grid_samples = sample(pspace, GridSampling())
    iter_samples = collect(pspace)
    
    @test grid_samples == iter_samples
end

@testset "GridSampling indices" begin
    pspace = ParamSpace([
        ParamDim("x", values=[1,2,3]),
        ParamDim("y", values=[1,2])
    ])
    
    indices = sample_indices(pspace, GridSampling())
    @test indices == 1:6
end

@testset "GridSampling single dimension" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:10)
    ])
    
    samples = sample(pspace, GridSampling())
    @test length(samples) == 10
    @test [s.x for s in samples] == collect(1:10)
end

@testset "GridSampling with masked dimensions" begin
    pspace = ParamSpace([
        ParamDim("x", values=[1,2,3], mask=[true, false, true]),
        ParamDim("y", values=[1,2])
    ])
    
    samples = sample(pspace, GridSampling())
    @test length(samples) == 4
    @test all(s -> s.x in [1, 3], samples)
end

@testset "GridSampling order" begin
    pspace = ParamSpace([
        ParamDim("x", values=[1,2]),
        ParamDim("y", values=[3,4])
    ])
    
    samples = sample(pspace, GridSampling())
    
    @test samples[1] == (x=1, y=3)
    @test samples[2] == (x=2, y=3)
    @test samples[3] == (x=1, y=4)
    @test samples[4] == (x=2, y=4)
end

@testset "GridSampling empty space" begin
    pspace = ParamSpace([
        ParamDim("x", values=[1,2,3], mask=[false, false, false])
    ])
    
    samples = sample(pspace, GridSampling())
    @test length(samples) == 0
end

@testset "StratifiedGridSampling basic" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:100),
        ParamDim("y", values=1:100)
    ])
    
    samples = sample(pspace, StratifiedGridSampling(10))
    @test length(samples) <= 100
end

@testset "StratifiedGridSampling resolution" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:100),
        ParamDim("y", values=1:100)
    ])
    
    samples_5 = sample(pspace, StratifiedGridSampling(5))
    samples_10 = sample(pspace, StratifiedGridSampling(10))
    
    @test length(samples_5) <= length(samples_10)
end

@testset "StratifiedGridSampling small space" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:5),
        ParamDim("y", values=1:3)
    ])
    
    samples = sample(pspace, StratifiedGridSampling(10))
    @test length(samples) >= 1
    @test all(s -> 1 <= s.x <= 5 && 1 <= s.y <= 3, samples)
end

@testset "StratifiedGridSampling single dimension" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:100)
    ])
    
    samples = sample(pspace, StratifiedGridSampling(5))
    @test length(samples) == 5
end
