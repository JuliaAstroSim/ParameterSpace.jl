using Test
using ParameterSpace

@testset "CoupledParamDim basic" begin
    cp = CoupledParamDim("z", target=:x, values=[10, 20, 30])
    @test cp.name == :z
    @test cp.target == :x
    @test cp.values == [10, 20, 30]
    @test length(cp) == 3
end

@testset "CoupledParamDim with Symbol" begin
    cp = CoupledParamDim(:z, :x, [10, 20, 30])
    @test cp.name == :z
    @test cp.target == :x
end

@testset "add_coupled!" begin
    pspace = ParamSpace([
        ParamDim("x", values=[1,2,3]),
        ParamDim("y", values=[1,2])
    ])
    add_coupled!(pspace, CoupledParamDim("z", target=:x, values=[10, 20, 30]))
    @test has_coupled(pspace, :z)
end

@testset "CoupledParamDim in iteration" begin
    pspace = ParamSpace([
        ParamDim("x", values=[1,2,3]),
        ParamDim("y", values=[1,2])
    ])
    add_coupled!(pspace, CoupledParamDim("z", target=:x, values=[10, 20, 30]))

    results = collect(pspace)
    @test all(r -> haskey(r, :z), results)
    @test results[1].z == 10
    @test results[1].x == 1
end

@testset "CoupledParamDim synchronization" begin
    pspace = ParamSpace([
        ParamDim("x", values=[1,2,3]),
        ParamDim("y", values=[1,2])
    ])
    add_coupled!(pspace, CoupledParamDim("z", target=:x, values=[10, 20, 30]))

    results = collect(pspace)
    for r in results
        expected_z = (r.x - 1) * 10 + 10
        @test r.z == expected_z
    end
end

@testset "Multiple coupled dimensions" begin
    pspace = ParamSpace([
        ParamDim("x", values=[1,2,3])
    ])
    add_coupled!(pspace, CoupledParamDim("y", target=:x, values=[10, 20, 30]))
    add_coupled!(pspace, CoupledParamDim("z", target=:x, values=[100, 200, 300]))

    results = collect(pspace)
    @test all(r -> r.y == r.x * 10, results)
    @test all(r -> r.z == r.x * 100, results)
end

@testset "remove_coupled!" begin
    pspace = ParamSpace([
        ParamDim("x", values=[1,2,3])
    ])
    add_coupled!(pspace, CoupledParamDim("y", target=:x, values=[10, 20, 30]))
    remove_coupled!(pspace, :y)
    @test !has_coupled(pspace, :y)
end

@testset "CoupledParamDim length mismatch error" begin
    pspace = ParamSpace([
        ParamDim("x", values=[1,2,3])
    ])
    @test_throws ErrorException add_coupled!(pspace, CoupledParamDim("y", target=:x, values=[10, 20]))
end

@testset "CoupledParamDim invalid target error" begin
    pspace = ParamSpace([
        ParamDim("x", values=[1,2,3])
    ])
    @test_throws ErrorException add_coupled!(pspace, CoupledParamDim("y", target=:z, values=[10, 20, 30]))
end
