using Test
using ParameterSpace

@testset "SobolSampling basic" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:100),
        ParamDim("y", values=1:100)
    ])

    samples = sample(pspace, SobolSampling(), n=50)
    @test length(samples) == 50
    @test all(s -> 1 <= s.x <= 100 && 1 <= s.y <= 100, samples)
end

@testset "SobolSampling low discrepancy" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:1000),
        ParamDim("y", values=1:1000)
    ])

    samples = sample(pspace, SobolSampling(), n=100)

    x_vals = [s.x for s in samples]
    y_vals = [s.y for s in samples]

    @test length(unique(x_vals)) > 50
    @test length(unique(y_vals)) > 50
end

@testset "SobolSampling reproducibility" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:100),
        ParamDim("y", values=1:100)
    ])

    samples1 = sample(pspace, SobolSampling(), n=20)
    samples2 = sample(pspace, SobolSampling(), n=20)

    @test [s.x for s in samples1] == [s.x for s in samples2]
    @test [s.y for s in samples1] == [s.y for s in samples2]
end

@testset "SobolSampling incremental" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:100),
        ParamDim("y", values=1:100)
    ])

    sampler = SobolSampler(pspace)

    batch1 = next_n_samples!(sampler, pspace, 20)
    batch2 = next_n_samples!(sampler, pspace, 20)

    all_samples = sample(pspace, SobolSampling(), n=40)

    @test vcat(batch1, batch2) == all_samples
end

@testset "SobolSampling small space" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:5),
        ParamDim("y", values=1:3)
    ])

    samples = sample(pspace, SobolSampling(), n=10)
    @test length(samples) == 10
end

@testset "SobolSampling single dimension" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:100)
    ])

    samples = sample(pspace, SobolSampling(), n=20)
    @test length(samples) == 20
end

@testset "SobolSampling high dimension" begin
    pspace = ParamSpace([
        ParamDim("x1", values=1:10),
        ParamDim("x2", values=1:10),
        ParamDim("x3", values=1:10),
        ParamDim("x4", values=1:10)
    ])

    samples = sample(pspace, SobolSampling(), n=100)
    @test length(samples) == 100
    @test all(s -> all(1 .<= [s.x1, s.x2, s.x3, s.x4] .<= 10), samples)
end
