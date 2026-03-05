struct CoverageReport
    total_points::Int
    coverage_ratio::Float64
    covered_dims::Vector{Symbol}
    uncovered_regions::Vector{NamedTuple}
    dim_coverage::Dict{Symbol,Float64}
end

function Base.show(io::IO, r::CoverageReport)
    print(io, "CoverageReport($(round(r.coverage_ratio*100, digits=1))% covered, $(r.total_points) points)")
end

function find_point_index(pspace::ParamSpace, params::NamedTuple)
    dims = dim_names(pspace)
    
    multi_idx = zeros(Int, length(dims))
    for (i, d) in enumerate(dims)
        if !haskey(params, d)
            return nothing
        end
        val = getfield(params, d)
        pdim = pspace.dims[d]
        idx = findfirst(==(val), effective_values(pdim))
        if idx === nothing
            return nothing
        end
        multi_idx[i] = idx
    end
    
    return linear_index(pspace, Tuple(multi_idx))
end

function find_uncovered_regions(pspace::ParamSpace, covered::Set{Int})
    total = volume(pspace)
    uncovered = setdiff(Set(1:total), covered)
    
    if isempty(uncovered)
        return NamedTuple[]
    end
    
    regions = NamedTuple[]
    for idx in uncovered
        point = get_point(pspace, idx)
        push!(regions, point)
    end
    
    return regions
end

function analyze_coverage(ds::DataSet{ExperimentData}, pspace::ParamSpace; resolution::Int=100)
    if isempty(ds.data)
        return CoverageReport(0, 0.0, Symbol[], NamedTuple[], Dict{Symbol,Float64}())
    end
    
    total = volume(pspace)
    dims = dim_names(pspace)
    
    covered = Set{Int}()
    for point in ds.data
        idx = find_point_index(pspace, point.params)
        if idx !== nothing
            push!(covered, idx)
        end
    end
    
    coverage_ratio = length(covered) / total
    
    covered_dims = Symbol[]
    for d in dims
        for point in ds.data
            if haskey(point.params, d)
                push!(covered_dims, d)
                break
            end
        end
    end
    
    dim_coverage = Dict{Symbol,Float64}()
    for d in dims
        pdim = pspace.dims[d]
        values = Set{Any}()
        for point in ds.data
            if haskey(point.params, d)
                push!(values, getfield(point.params, d))
            end
        end
        dim_coverage[d] = length(values) / length(pdim)
    end
    
    uncovered_regions = find_uncovered_regions(pspace, covered)
    
    return CoverageReport(
        length(ds.data),
        coverage_ratio,
        covered_dims,
        uncovered_regions,
        dim_coverage
    )
end

struct GapRegion
    center::NamedTuple
    extent::NamedTuple
    distance_to_nearest::Float64
    priority::Float64
end

function Base.show(io::IO, g::GapRegion)
    print(io, "GapRegion(", g.center, ", priority=", round(g.priority, digits=2), ")")
end

function euclidean_distance(p1::NamedTuple, p2::NamedTuple)
    keys1 = keys(p1)
    keys2 = keys(p2)
    common_keys = intersect(keys1, keys2)
    
    if isempty(common_keys)
        return Inf
    end
    
    sum_sq = 0.0
    for k in common_keys
        v1 = getfield(p1, k)
        v2 = getfield(p2, k)
        sum_sq += (v1 - v2)^2
    end
    
    return sqrt(sum_sq)
end

function min_distance_to_data(point::NamedTuple, data::Vector{ExperimentData})
    if isempty(data)
        return Inf
    end
    
    min_dist = Inf
    for d in data
        dist = euclidean_distance(point, d.params)
        min_dist = min(min_dist, dist)
    end
    
    return min_dist
end

function estimate_density(point::NamedTuple, data::Vector{ExperimentData}, pspace::ParamSpace)
    bandwidth = 1.0
    density = 0.0
    
    for d in data
        dist = euclidean_distance(point, d.params)
        density += exp(-dist^2 / (2 * bandwidth^2))
    end
    
    return density / length(data)
end

function find_gaps_grid(ds::DataSet{ExperimentData}, pspace::ParamSpace, n_gaps::Int)
    total = volume(pspace)
    covered = Set{Int}()
    
    for point in ds.data
        idx = find_point_index(pspace, point.params)
        if idx !== nothing
            push!(covered, idx)
        end
    end
    
    uncovered = collect(setdiff(Set(1:total), covered))
    
    if isempty(uncovered)
        return GapRegion[]
    end
    
    dims = dim_names(pspace)
    gaps = GapRegion[]
    for idx in uncovered
        point = get_point(pspace, idx)
        dist = min_distance_to_data(point, ds.data)
        priority = dist
        
        extent = NamedTuple{Tuple(dims)}(Tuple(1.0 for _ in dims))
        
        push!(gaps, GapRegion(point, extent, dist, priority))
    end
    
    sort!(gaps, by=g -> g.priority, rev=true)
    
    return gaps[1:min(n_gaps, length(gaps))]
end

function find_gaps_kde(ds::DataSet{ExperimentData}, pspace::ParamSpace, n_gaps::Int)
    dims = dim_names(pspace)
    
    sample_points = sample(pspace, RandomSampling(), n=1000)
    
    gaps = GapRegion[]
    for point in sample_points
        density = estimate_density(point, ds.data, pspace)
        if density < 0.1
            dist = min_distance_to_data(point, ds.data)
            extent = NamedTuple{Tuple(dims)}(Tuple(1.0 for _ in dims))
            push!(gaps, GapRegion(point, extent, dist, 1.0 - density))
        end
    end
    
    sort!(gaps, by=g -> g.priority, rev=true)
    
    return gaps[1:min(n_gaps, length(gaps))]
end

function find_gaps_voronoi(ds::DataSet{ExperimentData}, pspace::ParamSpace, n_gaps::Int)
    return find_gaps_grid(ds, pspace, n_gaps)
end

function find_gaps(ds::DataSet{ExperimentData}, pspace::ParamSpace; 
    n_gaps::Int=10, 
    method::Symbol=:grid
)
    if isempty(ds.data)
        return GapRegion[]
    end
    
    if method == :grid
        return find_gaps_grid(ds, pspace, n_gaps)
    elseif method == :kde
        return find_gaps_kde(ds, pspace, n_gaps)
    elseif method == :voronoi
        return find_gaps_voronoi(ds, pspace, n_gaps)
    else
        error("Unknown method: $method")
    end
end

function recommend_points(ds::DataSet{ExperimentData}, pspace::ParamSpace; 
    n_points::Int=10,
    strategy::Symbol=:max_distance
)
    gaps = find_gaps(ds, pspace; n_gaps=n_points * 2)
    
    if isempty(gaps)
        return sample(pspace, RandomSampling(), n=n_points)
    end
    
    if strategy == :max_distance
        sort!(gaps, by=g -> g.distance_to_nearest, rev=true)
    elseif strategy == :max_entropy
        sort!(gaps, by=g -> g.priority, rev=true)
    end
    
    return [g.center for g in gaps[1:min(n_points, length(gaps))]]
end

struct ConstraintIntersection
    param::Symbol
    lower::Float64
    upper::Float64
    n_constraints::Int
    sources::Vector{String}
    excluded_regions::Vector{Tuple{Float64,Float64}}
end

function Base.show(io::IO, ci::ConstraintIntersection)
    print(io, "ConstraintIntersection(:", ci.param, ", [", ci.lower, ", ", ci.upper, "]")
    if !isempty(ci.excluded_regions)
        print(io, ", excluded=", ci.excluded_regions)
    end
    print(io, ")")
end

function is_valid(ci::ConstraintIntersection)
    return ci.lower <= ci.upper
end

function width(ci::ConstraintIntersection)
    return ci.upper - ci.lower
end

function intersect_include_constraints(constraints::Vector{ConstraintData})
    if isempty(constraints)
        return (-Inf, Inf)
    end
    
    lower = maximum(c.lower for c in constraints)
    upper = minimum(c.upper for c in constraints)
    
    return (lower, upper)
end

function compute_excluded_regions(constraints::Vector{ConstraintData})
    excluded = Tuple{Float64,Float64}[]
    for c in constraints
        if c.constraint_type == :exclude
            push!(excluded, (c.lower, c.upper))
        end
    end
    return excluded
end

function intersect_constraints(constraints::Vector{ConstraintData}, param::Symbol)
    relevant = filter(c -> c.param == param, constraints)
    
    if isempty(relevant)
        return nothing
    end
    
    include_constraints = filter(c -> c.constraint_type == :include, relevant)
    exclude_constraints = filter(c -> c.constraint_type == :exclude, relevant)
    
    if isempty(include_constraints)
        lower, upper = -Inf, Inf
    else
        lower, upper = intersect_include_constraints(include_constraints)
    end
    
    excluded_regions = compute_excluded_regions(exclude_constraints)
    
    sources = String[]
    for c in relevant
        if !isempty(c.source.citekey)
            push!(sources, c.source.citekey)
        elseif !isempty(c.source.paper)
            push!(sources, c.source.paper)
        end
    end
    unique!(sources)
    
    return ConstraintIntersection(param, lower, upper, length(relevant), sources, excluded_regions)
end

function intersect_constraints(constraints::Vector{ConstraintData})
    params = unique([c.param for c in constraints])
    intersections = Dict{Symbol,ConstraintIntersection}()
    
    for p in params
        result = intersect_constraints(constraints, p)
        if result !== nothing
            intersections[p] = result
        end
    end
    
    return intersections
end

function allowed_region(constraints::Vector{ConstraintData}, param::Symbol)
    ci = intersect_constraints(constraints, param)
    
    if ci === nothing
        return (-Inf, Inf)
    end
    
    return (ci.lower, ci.upper)
end

function is_allowed(constraints::Vector{ConstraintData}, param::Symbol, value::Real)
    ci = intersect_constraints(constraints, param)
    
    if ci === nothing
        return true
    end
    
    if !(ci.lower <= value <= ci.upper)
        return false
    end
    
    for (ex_lower, ex_upper) in ci.excluded_regions
        if ex_lower <= value <= ex_upper
            return false
        end
    end
    
    return true
end

function filter_by_constraints(data::Vector{ExperimentData}, constraints::Vector{ConstraintData})
    intersections = intersect_constraints(constraints)
    
    return filter(data) do e
        for (param, ci) in intersections
            if haskey(e.params, param)
                val = getfield(e.params, param)
                if !is_allowed(constraints, param, val)
                    return false
                end
            end
        end
        return true
    end
end

function constraint_summary(constraints::Vector{ConstraintData})
    params = unique([c.param for c in constraints])
    summary = Dict{Symbol,NamedTuple}()
    
    for p in params
        relevant = filter(c -> c.param == p, constraints)
        include_c = filter(c -> c.constraint_type == :include, relevant)
        exclude_c = filter(c -> c.constraint_type == :exclude, relevant)
        
        if isempty(include_c)
            lower, upper = -Inf, Inf
        else
            lower = maximum(c.lower for c in include_c)
            upper = minimum(c.upper for c in include_c)
        end
        
        excluded = [(c.lower, c.upper) for c in exclude_c]
        
        summary[p] = (
            n_constraints = length(relevant),
            n_include = length(include_c),
            n_exclude = length(exclude_c),
            lower = lower,
            upper = upper,
            excluded = excluded,
            methods = unique([c.source.method for c in relevant if !isempty(c.source.method)])
        )
    end
    
    return summary
end
