using Test
using ParameterSpace

@testset "YAML load basic" begin
    yaml_content = """
    parameters:
      x:
        values: [1, 2, 3]
      y:
        range: [0, 10, 2]
    """
    filepath = tempname() * ".yaml"
    write(filepath, yaml_content)

    pspace = load_yaml(filepath)
    @test volume(pspace) == 18
    @test :x in dim_names(pspace)
    @test :y in dim_names(pspace)

    rm(filepath)
end

@testset "YAML load with default" begin
    yaml_content = """
    parameters:
      x:
        values: [1, 2, 3]
        default: 2
    """
    filepath = tempname() * ".yaml"
    write(filepath, yaml_content)

    pspace = load_yaml(filepath)
    @test pspace.dims[:x].default == 2

    rm(filepath)
end

@testset "YAML load linspace" begin
    yaml_content = """
    parameters:
      x:
        linspace: [0.0, 1.0, 11]
    """
    filepath = tempname() * ".yaml"
    write(filepath, yaml_content)

    pspace = load_yaml(filepath)
    @test length(all_values(pspace.dims[:x])) == 11

    rm(filepath)
end

@testset "YAML load logspace" begin
    yaml_content = """
    parameters:
      x:
        logspace: [-1, 1, 5]
    """
    filepath = tempname() * ".yaml"
    write(filepath, yaml_content)

    pspace = load_yaml(filepath)
    @test length(all_values(pspace.dims[:x])) == 5

    rm(filepath)
end

@testset "YAML load with mask" begin
    yaml_content = """
    parameters:
      x:
        values: [1, 2, 3]
        mask: [true, false, true]
    """
    filepath = tempname() * ".yaml"
    write(filepath, yaml_content)

    pspace = load_yaml(filepath)
    @test length(pspace.dims[:x]) == 2

    rm(filepath)
end

@testset "YAML save and load roundtrip" begin
    pspace = ParamSpace([
        ParamDim("x", values=[1,2,3], default=1),
        ParamDim("y", range=(0, 10, 2))
    ])

    filepath = tempname() * ".yaml"
    save_yaml(pspace, filepath)

    loaded = load_yaml(filepath)
    @test volume(loaded) == volume(pspace)
    @test dim_names(loaded) == dim_names(pspace)

    rm(filepath)
end

@testset "YAML missing parameters key error" begin
    yaml_content = """
    other:
      x: [1, 2, 3]
    """
    filepath = tempname() * ".yaml"
    write(filepath, yaml_content)

    @test_throws ErrorException load_yaml(filepath)

    rm(filepath)
end

@testset "YAML missing value specification error" begin
    yaml_content = """
    parameters:
      x: {}
    """
    filepath = tempname() * ".yaml"
    write(filepath, yaml_content)

    @test_throws ErrorException load_yaml(filepath)

    rm(filepath)
end
