using Test
using ParameterSpace

@testset "analyze_coverage empty" begin
    ds = DataSet{ExperimentData}("test")
    pspace = ParamSpace([ParamDim("x", values=[1,2,3])])
    report = analyze_coverage(ds, pspace)
    @test report.total_points == 0
    @test report.coverage_ratio == 0.0
end

@testset "analyze_coverage partial" begin
    ds = DataSet{ExperimentData}("test")
    add!(ds, ExperimentData(DataSource(), (x=1,), (y=1.0,)))
    add!(ds, ExperimentData(DataSource(), (x=2,), (y=2.0,)))
    
    pspace = ParamSpace([ParamDim("x", values=[1,2,3])])
    report = analyze_coverage(ds, pspace)
    
    @test report.total_points == 2
    @test report.coverage_ratio ≈ 2/3
    @test :x in report.covered_dims
end

@testset "analyze_coverage full" begin
    ds = DataSet{ExperimentData}("test")
    add!(ds, ExperimentData(DataSource(), (x=1,), (y=1.0,)))
    add!(ds, ExperimentData(DataSource(), (x=2,), (y=2.0,)))
    add!(ds, ExperimentData(DataSource(), (x=3,), (y=3.0,)))
    
    pspace = ParamSpace([ParamDim("x", values=[1,2,3])])
    report = analyze_coverage(ds, pspace)
    
    @test report.coverage_ratio == 1.0
    @test isempty(report.uncovered_regions)
end

@testset "analyze_coverage multi_dim" begin
    ds = DataSet{ExperimentData}("test")
    add!(ds, ExperimentData(DataSource(), (x=1, y=1), (z=1.0,)))
    add!(ds, ExperimentData(DataSource(), (x=2, y=2), (z=2.0,)))
    
    pspace = ParamSpace([
        ParamDim("x", values=[1,2]),
        ParamDim("y", values=[1,2])
    ])
    report = analyze_coverage(ds, pspace)
    
    @test report.total_points == 2
    @test report.coverage_ratio == 0.5
    @test report.dim_coverage[:x] == 1.0
    @test report.dim_coverage[:y] == 1.0
end
