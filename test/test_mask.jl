using Test
using ParameterSpace

@testset "set_mask! single dimension" begin
    pspace = ParamSpace([
        ParamDim("x", values=[1,2,3]),
        ParamDim("y", values=[1,2])
    ])
    set_mask!(pspace, :x, [true, false, true])
    @test get_mask(pspace, :x) == [true, false, true]
    @test length(collect(pspace)) == 4
end

@testset "set_mask! multiple dimensions" begin
    pspace = ParamSpace([
        ParamDim("x", values=[1,2,3]),
        ParamDim("y", values=[1,2,3])
    ])
    set_mask!(pspace, Dict(:x => [true, false, true], :y => [false, true, false]))
    @test length(collect(pspace)) == 2
end

@testset "clear_mask!" begin
    pspace = ParamSpace([ParamDim("x", values=[1,2,3])])
    set_mask!(pspace, :x, [true, false, true])
    clear_mask!(pspace, :x)
    @test get_mask(pspace, :x) == [true, true, true]
    @test length(collect(pspace)) == 3
end

@testset "clear_all_masks!" begin
    pspace = ParamSpace([
        ParamDim("x", values=[1,2,3]),
        ParamDim("y", values=[1,2])
    ])
    set_mask!(pspace, :x, [true, false, true])
    set_mask!(pspace, :y, [false, true])
    clear_all_masks!(pspace)
    @test length(collect(pspace)) == 6
end

@testset "activate_subspace! with vector condition" begin
    pspace = ParamSpace([
        ParamDim("x", values=[1,2,3]),
        ParamDim("y", values=[1,2])
    ])
    activate_subspace!(pspace, Dict("x" => [1, 3]))
    results = collect(pspace)
    @test all(r -> r.x in [1, 3], results)
    @test length(results) == 4
end

@testset "activate_subspace! with scalar condition" begin
    pspace = ParamSpace([
        ParamDim("x", values=[1,2,3]),
        ParamDim("y", values=[1,2])
    ])
    activate_subspace!(pspace, Dict(:x => 2))
    results = collect(pspace)
    @test all(r -> r.x == 2, results)
    @test length(results) == 2
end

@testset "activate_subspace! multiple conditions" begin
    pspace = ParamSpace([
        ParamDim("x", values=[1,2,3]),
        ParamDim("y", values=[1,2,3])
    ])
    activate_subspace!(pspace, Dict("x" => [1,2], "y" => [2,3]))
    results = collect(pspace)
    @test all(r -> r.x in [1,2] && r.y in [2,3], results)
    @test length(results) == 4
end

@testset "Masked type" begin
    m1 = Masked(5, true)
    m2 = Masked(5, false)
    @test m1.value == 5
    @test m1.active == true
end
