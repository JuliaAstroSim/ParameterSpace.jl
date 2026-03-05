using Test
using ParameterSpace

@testset "ExperimentData basic" begin
    ds = DataSource(citekey="test", year=2020)
    e = ExperimentData(ds, (x=1, y=2), (result=3.0,))
    @test e.params == (x=1, y=2)
    @test e.results == (result=3.0,)
    @test e.uncertainty == NamedTuple()
end

@testset "ExperimentData with uncertainty" begin
    ds = DataSource()
    e = ExperimentData(ds, (x=1,), (result=3.0,); uncertainty=(result=0.1,))
    @test e.uncertainty == (result=0.1,)
end

@testset "ExperimentData accessors" begin
    ds = DataSource()
    e = ExperimentData(ds, (x=1, y=2), (power=3.0, fwhm=100.0))
    @test param_names(e) == [:x, :y]
    @test result_names(e) == [:power, :fwhm]
    @test get_param(e, :x) == 1
    @test get_result(e, :power) == 3.0
end

@testset "ExperimentData to_paramspace" begin
    ds = DataSource()
    data = [
        ExperimentData(ds, (x=1, y=1), (result=1.0,)),
        ExperimentData(ds, (x=1, y=2), (result=2.0,)),
        ExperimentData(ds, (x=2, y=1), (result=3.0,)),
    ]
    pspace = to_paramspace(data)
    @test :x in dim_names(pspace)
    @test :y in dim_names(pspace)
end

@testset "ExperimentData to_namedtuple" begin
    ds = DataSource()
    e = ExperimentData(ds, (x=1,), (result=3.0,))
    nt = to_namedtuple(e)
    @test nt == (x=1, result=3.0)
end
