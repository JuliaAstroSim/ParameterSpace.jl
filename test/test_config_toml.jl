using Test
using ParameterSpace

@testset "TOML load basic" begin
    toml_content = """
    [parameters.x]
    values = [1, 2, 3]

    [parameters.y]
    range = [0, 10, 2]
    """
    filepath = tempname() * ".toml"
    write(filepath, toml_content)

    pspace = load_toml(filepath)
    @test volume(pspace) == 18
    @test :x in dim_names(pspace)
    @test :y in dim_names(pspace)

    rm(filepath)
end

@testset "TOML load with default" begin
    toml_content = """
    [parameters.x]
    values = [1, 2, 3]
    default = 2
    """
    filepath = tempname() * ".toml"
    write(filepath, toml_content)

    pspace = load_toml(filepath)
    @test pspace.dims[:x].default == 2

    rm(filepath)
end

@testset "TOML load linspace" begin
    toml_content = """
    [parameters.x]
    linspace = [0.0, 1.0, 11]
    """
    filepath = tempname() * ".toml"
    write(filepath, toml_content)

    pspace = load_toml(filepath)
    @test length(all_values(pspace.dims[:x])) == 11

    rm(filepath)
end

@testset "TOML load logspace" begin
    toml_content = """
    [parameters.x]
    logspace = [-1, 1, 5]
    """
    filepath = tempname() * ".toml"
    write(filepath, toml_content)

    pspace = load_toml(filepath)
    @test length(all_values(pspace.dims[:x])) == 5

    rm(filepath)
end

@testset "TOML load with mask" begin
    toml_content = """
    [parameters.x]
    values = [1, 2, 3]
    mask = [true, false, true]
    """
    filepath = tempname() * ".toml"
    write(filepath, toml_content)

    pspace = load_toml(filepath)
    @test length(pspace.dims[:x]) == 2

    rm(filepath)
end

@testset "TOML save and load roundtrip" begin
    pspace = ParamSpace([
        ParamDim("x", values=[1,2,3], default=1),
        ParamDim("y", range=(0, 10, 2))
    ])

    filepath = tempname() * ".toml"
    save_toml(pspace, filepath)

    loaded = load_toml(filepath)
    @test volume(loaded) == volume(pspace)
    @test dim_names(loaded) == dim_names(pspace)

    rm(filepath)
end

@testset "TOML with order" begin
    toml_content = """
    [parameters.x]
    values = [1, 2, 3, 4, 5]
    order = "shuffle"
    """
    filepath = tempname() * ".toml"
    write(filepath, toml_content)

    pspace = load_toml(filepath)
    @test pspace.dims[:x].order == :shuffle

    rm(filepath)
end

@testset "TOML missing parameters key error" begin
    toml_content = """
    [other]
    x = [1, 2, 3]
    """
    filepath = tempname() * ".toml"
    write(filepath, toml_content)

    @test_throws ErrorException load_toml(filepath)

    rm(filepath)
end

@testset "TOML complex values" begin
    toml_content = """
    [parameters.x]
    values = [0.1, 0.5, 1.0, 2.0]

    [parameters.y]
    values = ["a", "b", "c"]
    """
    filepath = tempname() * ".toml"
    write(filepath, toml_content)

    pspace = load_toml(filepath)
    @test volume(pspace) == 12

    rm(filepath)
end
