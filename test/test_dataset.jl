using Test
using ParameterSpace

@testset "DataSet basic" begin
    ds = DataSet{ConstraintData}("test")
    @test length(ds) == 0
    @test name(ds) == "test"
end

@testset "DataSet add!" begin
    ds = DataSet{ConstraintData}("test")
    c = ConstraintData(DataSource(), :x, lower=0, upper=10)
    add!(ds, c)
    @test length(ds) == 1
    @test ds[1] == c
end

@testset "DataSet remove!" begin
    ds = DataSet{ConstraintData}("test")
    c1 = ConstraintData(DataSource(), :x, lower=0, upper=10)
    c2 = ConstraintData(DataSource(), :y, lower=0, upper=5)
    add!(ds, c1)
    add!(ds, c2)
    remove!(ds, 1)
    @test length(ds) == 1
    @test ds[1] == c2
end

@testset "DataSet query" begin
    ds = DataSet{ExperimentData}("test")
    e1 = ExperimentData(DataSource(), (x=1, y=2), (z=3.0,))
    e2 = ExperimentData(DataSource(), (x=1, y=3), (z=4.0,))
    e3 = ExperimentData(DataSource(), (x=2, y=2), (z=3.5,))
    add!(ds, e1)
    add!(ds, e2)
    add!(ds, e3)
    
    result = query(ds; x=1)
    @test length(result) == 2
end

@testset "DataSet filter" begin
    ds = DataSet{ConstraintData}("test")
    c1 = ConstraintData(DataSource(), :x, lower=0, upper=10)
    c2 = ConstraintData(DataSource(), :x, lower=5, upper=15)
    c3 = ConstraintData(DataSource(), :x, lower=10, upper=20)
    add!(ds, c1)
    add!(ds, c2)
    add!(ds, c3)
    
    result = filter(ds) do c
        c.upper <= 10
    end
    @test length(result) == 1
    @test result[1].upper == 10
end

@testset "DataSet iteration" begin
    ds = DataSet{ConstraintData}("test")
    for i in 1:5
        add!(ds, ConstraintData(DataSource(), :x, lower=i, upper=i+5))
    end
    @test length(ds) == 5
    @test [c.upper for c in ds] == [6, 7, 8, 9, 10]
end
