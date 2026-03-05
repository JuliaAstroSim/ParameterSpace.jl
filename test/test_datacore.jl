using Test
using ParameterSpace

@testset "DataSource basic" begin
    ds = DataSource(citekey="xxx2020", paper="Author et al., 2020", year=2020)
    @test ds.citekey == "xxx2020"
    @test ds.year == 2020
    @test ds.type == :literature
end

@testset "DataSource type validation" begin
    @test_throws ErrorException DataSource(type=:invalid)
    @test DataSource(type=:own_experiment).type == :own_experiment
    @test DataSource(type=:simulation).type == :simulation
end

@testset "DataSource defaults" begin
    ds = DataSource()
    @test ds.citekey == ""
    @test ds.year == 0
    @test ds.notes == ""
end

@testset "AbstractDataPoint" begin
    @test AbstractDataPoint isa Type
end
