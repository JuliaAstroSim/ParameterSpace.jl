using Test
using ParameterSpace

@testset "find_gaps empty data" begin
    ds = DataSet{ExperimentData}("test")
    pspace = ParamSpace([ParamDim("x", values=[1,2,3])])
    gaps = find_gaps(ds, pspace)
    @test isempty(gaps)
end

@testset "find_gaps partial coverage" begin
    ds = DataSet{ExperimentData}("test")
    add!(ds, ExperimentData(DataSource(), (x=1,), (y=1.0,)))
    add!(ds, ExperimentData(DataSource(), (x=3,), (y=3.0,)))
    
    pspace = ParamSpace([ParamDim("x", values=[1,2,3])])
    gaps = find_gaps(ds, pspace; n_gaps=5)
    
    @test length(gaps) == 1
    @test gaps[1].center.x == 2
end

@testset "find_gaps full coverage" begin
    ds = DataSet{ExperimentData}("test")
    for x in [1,2,3]
        add!(ds, ExperimentData(DataSource(), (x=x,), (y=Float64(x),)))
    end
    
    pspace = ParamSpace([ParamDim("x", values=[1,2,3])])
    gaps = find_gaps(ds, pspace)
    
    @test isempty(gaps)
end

@testset "recommend_points" begin
    ds = DataSet{ExperimentData}("test")
    add!(ds, ExperimentData(DataSource(), (x=1, y=1), (z=1.0,)))
    
    pspace = ParamSpace([
        ParamDim("x", values=[1,2,3]),
        ParamDim("y", values=[1,2,3])
    ])
    
    points = recommend_points(ds, pspace; n_points=5)
    @test length(points) == 5
    @test all(p -> haskey(p, :x) && haskey(p, :y), points)
end

@testset "GapRegion priority" begin
    ds = DataSet{ExperimentData}("test")
    add!(ds, ExperimentData(DataSource(), (x=1,), (y=1.0,)))
    
    pspace = ParamSpace([ParamDim("x", values=[1,2,3,4,5])])
    gaps = find_gaps(ds, pspace; n_gaps=3)
    
    @test gaps[1].priority >= gaps[2].priority
end
