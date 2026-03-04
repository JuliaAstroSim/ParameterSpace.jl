using Test
using ParameterSpace

@testset "ParamSpace from Dict" begin
    pspace = ParamSpace(Dict(
        "x" => ParamDim("x", values=[1,2]),
        "y" => ParamDim("y", values=[3,4])
    ))
    @test volume(pspace) == 4
    @test length(pspace) == 4
end

@testset "ParamSpace from Vector" begin
    pspace = ParamSpace([
        ParamDim("x", values=[1,2]),
        ParamDim("y", values=[3,4])
    ])
    @test dim_names(pspace) == [:x, :y]
end

@testset "ParamSpace from Vararg" begin
    pspace = ParamSpace(
        ParamDim("x", values=[1,2]),
        ParamDim("y", values=[3,4])
    )
    @test volume(pspace) == 4
end

@testset "ParamSpace iteration" begin
    pspace = ParamSpace([
        ParamDim("x", values=[1,2]),
        ParamDim("y", values=[3,4])
    ])
    results = collect(pspace)
    @test length(results) == 4
    @test results[1] == (x=1, y=3)
    @test results[2] == (x=2, y=3)
    @test results[3] == (x=1, y=4)
    @test results[4] == (x=2, y=4)
end

@testset "ParamSpace state management" begin
    pspace = ParamSpace([
        ParamDim("x", values=[1,2,3]),
        ParamDim("y", values=[1,2])
    ])
    set_state!(pspace, 3)
    @test state_no(pspace) == 3
    point = first(pspace)
    @test point == get_point(pspace, 3)
end

@testset "ParamSpace shape" begin
    pspace = ParamSpace([
        ParamDim("x", values=[1,2,3]),
        ParamDim("y", values=[1,2])
    ])
    @test shape(pspace) == (3, 2)
end

@testset "ParamSpace get_point" begin
    pspace = ParamSpace([
        ParamDim("x", values=[10,20,30]),
        ParamDim("y", values=[1,2])
    ])
    @test get_point(pspace, 1) == (x=10, y=1)
    @test get_point(pspace, 2) == (x=20, y=1)
    @test get_point(pspace, 3) == (x=30, y=1)
    @test get_point(pspace, 4) == (x=10, y=2)
end

@testset "ParamSpace with masked dims" begin
    pspace = ParamSpace([
        ParamDim("x", values=[1,2,3], mask=[true, false, true]),
        ParamDim("y", values=[1,2])
    ])
    @test volume(pspace) == 4
    results = collect(pspace)
    @test all(r -> r.x in [1, 3], results)
end
