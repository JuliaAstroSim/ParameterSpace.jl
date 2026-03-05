using Test
using ParameterSpace

@testset "intersect_constraints single include" begin
    constraints = [
        ConstraintData(DataSource(citekey="a", paper="Paper A", year=2020), :mass, lower=1e-23, upper=1e-21)
    ]
    
    ci = intersect_constraints(constraints, :mass)
    @test ci.lower == 1e-23
    @test ci.upper == 1e-21
    @test ci.n_constraints == 1
    @test isempty(ci.excluded_regions)
end

@testset "intersect_constraints multiple include" begin
    constraints = [
        ConstraintData(DataSource(citekey="a", paper="Paper A", year=2020), :mass, lower=1e-23, upper=1e-21),
        ConstraintData(DataSource(citekey="b", paper="Paper B", year=2021), :mass, lower=1e-22, upper=1e-20)
    ]
    
    ci = intersect_constraints(constraints, :mass)
    @test ci.lower == 1e-22
    @test ci.upper == 1e-21
    @test ci.n_constraints == 2
end

@testset "intersect_constraints no intersection" begin
    constraints = [
        ConstraintData(DataSource(citekey="a", paper="Paper A", year=2020), :mass, lower=1e-23, upper=1e-22),
        ConstraintData(DataSource(citekey="b", paper="Paper B", year=2021), :mass, lower=1e-21, upper=1e-20)
    ]
    
    ci = intersect_constraints(constraints, :mass)
    @test !is_valid(ci)
end

@testset "intersect_constraints with exclude" begin
    constraints = [
        ConstraintData(DataSource(), :x, lower=0, upper=10, constraint_type=:include),
        ConstraintData(DataSource(), :x, lower=4, upper=6, constraint_type=:exclude)
    ]
    
    ci = intersect_constraints(constraints, :x)
    @test ci.lower == 0
    @test ci.upper == 10
    @test length(ci.excluded_regions) == 1
    @test ci.excluded_regions[1] == (4.0, 6.0)
end

@testset "intersect_constraints all params" begin
    constraints = [
        ConstraintData(DataSource(citekey="a", paper="Paper A", year=2020), :mass, lower=1e-23, upper=1e-21),
        ConstraintData(DataSource(citekey="b", paper="Paper B", year=2021), :coupling, lower=1e-12, upper=1e-8)
    ]
    
    intersections = intersect_constraints(constraints)
    @test haskey(intersections, :mass)
    @test haskey(intersections, :coupling)
end

@testset "allowed_region" begin
    constraints = [
        ConstraintData(DataSource(), :mass, lower=1e-23, upper=1e-21)
    ]
    
    lower, upper = allowed_region(constraints, :mass)
    @test lower == 1e-23
    @test upper == 1e-21
end

@testset "is_allowed include only" begin
    constraints = [
        ConstraintData(DataSource(), :x, lower=0, upper=10)
    ]
    
    @test is_allowed(constraints, :x, 5)
    @test is_allowed(constraints, :x, 0)
    @test is_allowed(constraints, :x, 10)
    @test !is_allowed(constraints, :x, -1)
    @test !is_allowed(constraints, :x, 11)
end

@testset "is_allowed with exclude" begin
    constraints = [
        ConstraintData(DataSource(), :x, lower=0, upper=10),
        ConstraintData(DataSource(), :x, lower=4, upper=6, constraint_type=:exclude)
    ]
    
    @test is_allowed(constraints, :x, 2)
    @test is_allowed(constraints, :x, 8)
    @test !is_allowed(constraints, :x, 5)
    @test !is_allowed(constraints, :x, -1)
    @test !is_allowed(constraints, :x, 15)
end

@testset "filter_by_constraints" begin
    constraints = [
        ConstraintData(DataSource(), :x, lower=0, upper=10)
    ]
    
    data = [
        ExperimentData(DataSource(), (x=5,), (y=1.0,)),
        ExperimentData(DataSource(), (x=15,), (y=2.0,))
    ]
    
    filtered = filter_by_constraints(data, constraints)
    @test length(filtered) == 1
    @test filtered[1].params.x == 5
end

@testset "filter_by_constraints with exclude" begin
    constraints = [
        ConstraintData(DataSource(), :x, lower=0, upper=10),
        ConstraintData(DataSource(), :x, lower=4, upper=6, constraint_type=:exclude)
    ]
    
    data = [
        ExperimentData(DataSource(), (x=2,), (y=1.0,)),
        ExperimentData(DataSource(), (x=5,), (y=2.0,)),
        ExperimentData(DataSource(), (x=8,), (y=3.0,)),
        ExperimentData(DataSource(), (x=15,), (y=4.0,))
    ]
    
    filtered = filter_by_constraints(data, constraints)
    @test length(filtered) == 2
    @test filtered[1].params.x == 2
    @test filtered[2].params.x == 8
end

@testset "constraint_summary" begin
    constraints = [
        ConstraintData(DataSource(citekey="a", paper="Paper A", year=2020, method="Ly-α"), :mass, lower=1e-23, upper=1e-21),
        ConstraintData(DataSource(citekey="b", paper="Paper B", year=2021, method="CMB"), :mass, lower=1e-22, upper=1e-20),
        ConstraintData(DataSource(citekey="c", paper="Paper C", year=2022, method="BBN"), :mass, lower=5e-22, upper=7e-22, constraint_type=:exclude)
    ]
    
    summary = constraint_summary(constraints)
    @test haskey(summary, :mass)
    @test summary[:mass].n_constraints == 3
    @test summary[:mass].n_include == 2
    @test summary[:mass].n_exclude == 1
    @test "Ly-α" in summary[:mass].methods
    @test "CMB" in summary[:mass].methods
    @test length(summary[:mass].excluded) == 1
end
