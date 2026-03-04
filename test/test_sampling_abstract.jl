using Test
using ParameterSpace

@testset "AbstractSamplingStrategy types" begin
    @test RandomSampling() isa AbstractSamplingStrategy
    @test RandomSampling(42) isa AbstractSamplingStrategy
    @test RandomSampling(42).seed == 42

    @test LatinHypercubeSampling() isa AbstractSamplingStrategy
    @test LatinHypercubeSampling(42) isa AbstractSamplingStrategy

    @test SobolSampling() isa AbstractSamplingStrategy
    @test GridSampling() isa AbstractSamplingStrategy
end

@testset "sample function signature" begin
    pspace = ParamSpace([
        ParamDim("x", values=[1,2,3]),
        ParamDim("y", values=[1,2])
    ])

    samples = sample(pspace, RandomSampling(), n=3)
    @test length(samples) == 3
    @test all(s -> s isa NamedTuple, samples)
end

@testset "GridSampling returns all points" begin
    pspace = ParamSpace([
        ParamDim("x", values=[1,2,3]),
        ParamDim("y", values=[1,2])
    ])

    samples = sample(pspace, GridSampling())
    @test length(samples) == 6
    @test samples == collect(pspace)
end

@testset "RandomSampling basic" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:10),
        ParamDim("y", values=1:10)
    ])

    samples = sample(pspace, RandomSampling(seed=42), n=50)
    @test length(samples) == 50
    @test all(s -> 1 <= s.x <= 10 && 1 <= s.y <= 10, samples)
end

@testset "RandomSampling with seed reproducibility" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:100)
    ])

    samples1 = sample(pspace, RandomSampling(seed=123), n=10)
    samples2 = sample(pspace, RandomSampling(seed=123), n=10)

    @test [s.x for s in samples1] == [s.x for s in samples2]
end

@testset "sample_indices returns valid indices" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:10),
        ParamDim("y", values=1:10)
    ])

    indices = sample_indices(pspace, RandomSampling(), 20)
    @test length(indices) == 20
    @test all(i -> 1 <= i <= 100, indices)
end

@testset "validate_sample_size" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:5)
    ])

    @test validate_sample_size(pspace, 3) == 3
    @test validate_sample_size(pspace, 10) == 5
end
