using Test
using ParameterSpace

@testset "YAML save/load roundtrip ConstraintData" begin
    ds = DataSet{ConstraintData}("test")
    c1 = ConstraintData(DataSource(citekey="test", paper="Paper", year=2020, method="exp", type=:literature), :x, lower=0, upper=10)
    c2 = ConstraintData(DataSource(citekey="test", paper="Paper", year=2020, method="exp", type=:literature), :y, lower=0, upper=5)
    add!(ds, c1)
    add!(ds, c2)
    
    filepath = tempname() * ".yaml"
    save_dataset(ds, filepath)
    
    loaded = load_dataset(filepath)
    @test name(loaded) == "test"
    @test length(loaded) == 2
    @test loaded[1].param == :x
    @test loaded[2].param == :y
    
    rm(filepath)
end

@testset "TOML save/load roundtrip ConstraintData" begin
    ds = DataSet{ConstraintData}("test")
    c1 = ConstraintData(DataSource(), :x, lower=0, upper=10)
    add!(ds, c1)
    
    filepath = tempname() * ".toml"
    save_dataset(ds, filepath)
    
    loaded = load_dataset(filepath)
    @test length(loaded) == 1
    @test loaded[1].param == :x
    
    rm(filepath)
end

@testset "YAML save/load roundtrip ExperimentData" begin
    ds = DataSet{ExperimentData}("test")
    e = ExperimentData(DataSource(), (x=1, y=2), (z=3.0,))
    add!(ds, e)
    
    filepath = tempname() * ".yaml"
    save_dataset(ds, filepath)
    
    loaded = load_dataset(filepath)
    @test length(loaded) == 1
    @test loaded[1].params.x == 1
    @test loaded[1].results.z == 3.0
    
    rm(filepath)
end

@testset "auto format detection" begin
    ds = DataSet{ConstraintData}("test")
    c = ConstraintData(DataSource(), :x, lower=0, upper=10)
    add!(ds, c)
    
    yaml_path = tempname() * ".yaml"
    toml_path = tempname() * ".toml"
    yml_path = tempname() * ".yml"
    
    save_dataset(ds, yaml_path)
    save_dataset(ds, toml_path)
    save_dataset(ds, yml_path; format=:yaml)
    
    @test load_dataset(yaml_path)[1].param == :x
    @test load_dataset(toml_path)[1].param == :x
    @test load_dataset(yml_path)[1].param == :x
    
    rm(yaml_path)
    rm(toml_path)
    rm(yml_path)
end

@testset "unsupported format error" begin
    ds = DataSet{ConstraintData}("test")
    c = ConstraintData(DataSource(), :x, lower=0, upper=10)
    add!(ds, c)
    
    @test_throws ErrorException save_dataset(ds, "test.txt")
    @test_throws ErrorException load_dataset("test.txt")
end
