using Test
using ParameterSpace

@testset "Parameter struct unchanged" begin
    p = Parameter("x", 1, 0:2)
    @test p.Name == "x"
    @test p.Index == 1
    @test p.Range == 0:2
end

@testset "Parameter to ParamDim conversion" begin
    p = Parameter("x", 1, 0:2)
    pdim = to_paramdim(p)
    @test pdim.name == :x
    @test pdim.values == [0, 1, 2]
end

@testset "Parameter array to ParamSpace conversion" begin
    params = [Parameter("x", 1, 0:2), Parameter("y", 2, 0:1)]
    pspace = to_paramspace(params)
    @test volume(pspace) == 6
    @test dim_names(pspace) == [:x, :y]
end

@testset "Parameter array sorted by Index" begin
    params = [Parameter("y", 2, 0:1), Parameter("x", 1, 0:2)]
    pspace = to_paramspace(params)
    @test dim_names(pspace) == [:x, :y]
end

@testset "parameter_dimension unchanged" begin
    params = [Parameter("x", 1, 0:2), Parameter("y", 2, 0:1)]
    @test parameter_dimension(params) == [3, 2]
end

@testset "parameter_count unchanged" begin
    params = [Parameter("x", 1, 0:2), Parameter("y", 2, 0:1)]
    @test parameter_count(params) == 6
end
