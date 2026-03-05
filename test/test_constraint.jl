using Test
using ParameterSpace

@testset "ConstraintData basic" begin
    ds = DataSource(citekey="test", year=2020)
    c = ConstraintData(ds, :mass, lower=1e-23, upper=1e-21)
    @test c.param == :mass
    @test c.lower == 1e-23
    @test c.upper == 1e-21
    @test c.confidence == 1.0
    @test c.constraint_type == :include
end

@testset "ConstraintData unbounded" begin
    ds = DataSource()
    c = ConstraintData(ds, :x)
    @test c.lower == -Inf
    @test c.upper == Inf
end

@testset "ConstraintData in_constraint include" begin
    ds = DataSource()
    c = ConstraintData(ds, :x, lower=0, upper=10)
    @test in_constraint(c, 5)
    @test in_constraint(c, 0)
    @test in_constraint(c, 10)
    @test !in_constraint(c, -1)
    @test !in_constraint(c, 11)
end

@testset "ConstraintData in_constraint exclude" begin
    ds = DataSource()
    c = ConstraintData(ds, :x, lower=0, upper=10, constraint_type=:exclude)
    @test !in_constraint(c, 5)
    @test !in_constraint(c, 0)
    @test !in_constraint(c, 10)
    @test in_constraint(c, -1)
    @test in_constraint(c, 11)
end

@testset "ConstraintData width" begin
    ds = DataSource()
    c = ConstraintData(ds, :x, lower=0, upper=10)
    @test width(c) == 10
end

@testset "merge_constraints" begin
    ds1 = DataSource(citekey="a")
    ds2 = DataSource(citekey="b")
    c1 = ConstraintData(ds1, :mass, lower=1e-23, upper=1e-21)
    c2 = ConstraintData(ds2, :mass, lower=1e-22, upper=1e-20)
    merged = merge_constraints(c1, c2)
    @test merged.lower == 1e-22
    @test merged.upper == 1e-21
end

@testset "merge_constraints different params error" begin
    ds = DataSource()
    c1 = ConstraintData(ds, :x, lower=0, upper=10)
    c2 = ConstraintData(ds, :y, lower=0, upper=10)
    @test_throws ErrorException merge_constraints(c1, c2)
end

@testset "merge_constraints different types error" begin
    ds = DataSource()
    c1 = ConstraintData(ds, :x, lower=0, upper=10, constraint_type=:include)
    c2 = ConstraintData(ds, :x, lower=5, upper=15, constraint_type=:exclude)
    @test_throws ErrorException merge_constraints(c1, c2)
end

@testset "ConstraintData constraint_type validation" begin
    ds = DataSource()
    @test_throws ErrorException ConstraintData(ds, :x, lower=0, upper=10, constraint_type=:invalid)
    @test is_include_constraint(ConstraintData(ds, :x, constraint_type=:include))
    @test is_exclude_constraint(ConstraintData(ds, :x, constraint_type=:exclude))
end
