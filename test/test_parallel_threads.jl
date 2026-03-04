using Test
using ParameterSpace
using DataFrames

@testset "parallel threads basic" begin
    if Threads.nthreads() > 1
        f(params) = params.x * params.y
        pspace = ParamSpace([
            ParamDim("x", values=1:10),
            ParamDim("y", values=1:10)
        ])

        result = analyse_function(f, pspace;
            parallel=:threads,
            folder="output/test_threads1")
        @test nrow(result) == 100
    else
        @warn "Skipping threads test: only 1 thread available"
    end
end

@testset "parallel threads vs sequential" begin
    if Threads.nthreads() > 1
        f(params) = sum([params.x, params.y, params.z])
        pspace = ParamSpace([
            ParamDim("x", values=1:5),
            ParamDim("y", values=1:5),
            ParamDim("z", values=1:5)
        ])

        result_seq = analyse_function(f, pspace;
            parallel=:none,
            folder="output/test_threads_seq")
        result_par = analyse_function(f, pspace;
            parallel=:threads,
            folder="output/test_threads_par")

        @test sort(result_seq.result) == sort(result_par.result)
    end
end

@testset "parallel threads with sampling" begin
    if Threads.nthreads() > 1
        f(params) = params.x ^ 2
        pspace = ParamSpace([
            ParamDim("x", values=1:1000)
        ])

        result = analyse_function(f, pspace;
            strategy=RandomSampling(seed=42),
            n_samples=100,
            parallel=:threads,
            folder="output/test_threads_sample")
        @test nrow(result) == 100
    end
end

@testset "parallel threads order preservation" begin
    if Threads.nthreads() > 1
        f(params) = params.x
        pspace = ParamSpace([
            ParamDim("x", values=1:10)
        ])

        result = analyse_function(f, pspace;
            parallel=:threads,
            folder="output/test_threads_order")

        @test result.x == collect(1:10)
        @test result.result == collect(1:10)
    end
end

@testset "parallel threads fallback to sequential" begin
    f(params) = params.x
    pspace = ParamSpace([ParamDim("x", values=[1,2,3])])

    result = analyse_function(f, pspace;
        parallel=:threads,
        folder="output/test_threads_fallback")
    @test nrow(result) == 3
end
