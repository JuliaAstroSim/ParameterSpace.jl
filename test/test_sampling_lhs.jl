@testset "LatinHypercubeSampling basic" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:100),
        ParamDim("y", values=1:100)
    ])
    
    samples = sample(pspace, LatinHypercubeSampling(seed=42), n=50)
    @test length(samples) == 50
    @test all(s -> 1 <= s.x <= 100 && 1 <= s.y <= 100, samples)
end

@testset "LatinHypercubeSampling reproducibility" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:100),
        ParamDim("y", values=1:100)
    ])
    
    samples1 = sample(pspace, LatinHypercubeSampling(seed=123), n=20)
    samples2 = sample(pspace, LatinHypercubeSampling(seed=123), n=20)
    
    @test [s.x for s in samples1] == [s.x for s in samples2]
    @test [s.y for s in samples1] == [s.y for s in samples2]
end

@testset "LatinHypercubeSampling coverage" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:100),
        ParamDim("y", values=1:100)
    ])
    
    n = 10
    samples = sample(pspace, LatinHypercubeSampling(seed=42), n=n)
    
    x_vals = [s.x for s in samples]
    y_vals = [s.y for s in samples]
    
    for dim_vals in [x_vals, y_vals]
        sorted_vals = sort(dim_vals)
        for i in 1:n
            lower = (i - 1) * 10 + 1
            upper = i * 10
            @test any(lower <= v <= upper for v in sorted_vals)
        end
    end
end

@testset "LatinHypercubeSampling small space" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:5),
        ParamDim("y", values=1:3)
    ])
    
    samples = sample(pspace, LatinHypercubeSampling(seed=42), n=10)
    @test length(samples) == 10
end

@testset "LatinHypercubeSampling single dimension" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:100)
    ])
    
    samples = sample(pspace, LatinHypercubeSampling(seed=42), n=20)
    @test length(samples) == 20
    
    x_vals = [s.x for s in samples]
    @test length(unique(x_vals)) == 20
end

@testset "LatinHypercubeSampling vs RandomSampling" begin
    pspace = ParamSpace([
        ParamDim("x", values=1:100),
        ParamDim("y", values=1:100)
    ])
    
    lhs_samples = sample(pspace, LatinHypercubeSampling(seed=42), n=50)
    random_samples = sample(pspace, RandomSampling(seed=42), n=50)
    
    lhs_x = [s.x for s in lhs_samples]
    random_x = [s.x for s in random_samples]
    
    @test length(unique(lhs_x)) >= length(unique(random_x)) * 0.8
end
