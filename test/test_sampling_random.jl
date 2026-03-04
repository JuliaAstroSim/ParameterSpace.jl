using Test
using ParameterSpace

@testset "RandomSampling basic" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:10),
        ParamDim("y", values=1:10)
    ])

    samples = sample(pspace, RandomSampling(seed=42), n=50)
    @test length(samples) == 50
    @test all(s -> 1 <= s.x <= 10 && 1 <= s.y <= 10, samples)
end

@testset "RandomSampling reproducibility" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:100)
    ])

    samples1 = sample(pspace, RandomSampling(seed=123), n=10)
    samples2 = sample(pspace, RandomSampling(seed=123), n=10)

    @test [s.x for s in samples1] == [s.x for s in samples2]
end

@testset "RandomSampling without seed" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:10)
    ])

    samples1 = sample(pspace, RandomSampling(), n=5)
    samples2 = sample(pspace, RandomSampling(), n=5)

    @test [s.x for s in samples1] != [s.x for s in samples2]
end

@testset "RandomSampling capped at total" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:5)
    ])

    samples = sample(pspace, RandomSampling(seed=42), n=100)
    @test length(samples) == 100
end

@testset "RandomSampling single dimension" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:1000)
    ])

    samples = sample(pspace, RandomSampling(seed=42), n=100)
    @test length(samples) == 100
    @test all(s -> 1 <= s.x <= 1000, samples)
end

@testset "RandomSampling multi dimension" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:5),
        ParamDim("y", values=1:4),
        ParamDim("z", values=1:3)
    ])

    samples = sample(pspace, RandomSampling(seed=42), n=20)
    @test length(samples) == 20
    @test all(s -> 1 <= s.x <= 5 && 1 <= s.y <= 4 && 1 <= s.z <= 3, samples)
end

@testset "RandomSampling with masked dimensions" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:10, mask=[true, false, true, false, true, false, true, false, true, false]),
        ParamDim("y", values=1:5)
    ])

    samples = sample(pspace, RandomSampling(seed=42), n=10)
    @test length(samples) == 10
    @test all(s -> s.x in [1, 3, 5, 7, 9], samples)
end

@testset "sample_unique basic" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:100)
    ])

    samples = sample_unique(pspace, RandomSampling(seed=42), n=10)
    @test length(samples) == 10
    @test length(unique([s.x for s in samples])) == 10
end

@testset "sample_unique capped at total" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:5)
    ])

    samples = sample_unique(pspace, RandomSampling(seed=42), n=10)
    @test length(samples) == 5
end
