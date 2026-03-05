struct DataSource
    citekey::String
    paper::String
    year::Int
    method::String
    type::Symbol
    notes::String
end

function DataSource(;
    citekey::String="",
    paper::String="",
    year::Int=0,
    method::String="",
    type::Symbol=:literature,
    notes::String=""
)
    if type ∉ (:literature, :own_experiment, :simulation)
        error("type must be one of: :literature, :own_experiment, :simulation")
    end
    return DataSource(citekey, paper, year, method, type, notes)
end

function Base.show(io::IO, ds::DataSource)
    if !isempty(ds.citekey)
        print(io, "DataSource(@", ds.citekey, ", ", ds.year, ")")
    else
        print(io, "DataSource(", ds.paper, ", ", ds.year, ")")
    end
end

abstract type AbstractDataPoint end

function source end

function Base.show(io::IO, dp::AbstractDataPoint)
    print(io, typeof(dp).name.name, "(", source(dp).paper, ")")
end

struct ConstraintData <: AbstractDataPoint
    source::DataSource
    param::Symbol
    lower::Float64
    upper::Float64
    confidence::Float64
    constraint_type::Symbol
end

function ConstraintData(source::DataSource, param::Union{Symbol,AbstractString};
    lower::Real=-Inf,
    upper::Real=Inf,
    confidence::Real=1.0,
    constraint_type::Symbol=:include
)
    if constraint_type ∉ (:include, :exclude)
        error("constraint_type must be :include or :exclude")
    end
    return ConstraintData(source, Symbol(param), Float64(lower), Float64(upper), Float64(confidence), constraint_type)
end

source(c::ConstraintData) = c.source

function Base.show(io::IO, c::ConstraintData)
    type_str = c.constraint_type == :include ? "∈" : "∉"
    print(io, "ConstraintData(:", c.param, " ", type_str, " [", c.lower, ", ", c.upper, "])")
end

function is_valid(c::ConstraintData)
    return c.lower <= c.upper
end

function width(c::ConstraintData)
    return c.upper - c.lower
end

function in_constraint(c::ConstraintData, value::Real)
    in_range = c.lower <= value <= c.upper
    if c.constraint_type == :include
        return in_range
    else
        return !in_range
    end
end

function is_include_constraint(c::ConstraintData)
    return c.constraint_type == :include
end

function is_exclude_constraint(c::ConstraintData)
    return c.constraint_type == :exclude
end

function merge_constraints(c1::ConstraintData, c2::ConstraintData)
    if c1.param != c2.param
        error("Cannot merge constraints on different parameters")
    end
    if c1.constraint_type != c2.constraint_type
        error("Cannot merge include and exclude constraints")
    end
    
    lower = max(c1.lower, c2.lower)
    upper = min(c1.upper, c2.upper)
    confidence = min(c1.confidence, c2.confidence)
    merged_source = DataSource(
        citekey="",
        paper="Merged constraint",
        year=max(c1.source.year, c2.source.year),
        method="merged",
        type=:literature,
        notes="Merged from $(c1.source.citekey) and $(c2.source.citekey)"
    )
    return ConstraintData(merged_source, c1.param; lower=lower, upper=upper, confidence=confidence, constraint_type=c1.constraint_type)
end

struct ExperimentData <: AbstractDataPoint
    source::DataSource
    params::NamedTuple
    results::NamedTuple
    uncertainty::NamedTuple
end

function ExperimentData(source::DataSource, 
    params::NamedTuple, 
    results::NamedTuple;
    uncertainty::NamedTuple=NamedTuple()
)
    return ExperimentData(source, params, results, uncertainty)
end

source(e::ExperimentData) = e.source

function Base.show(io::IO, e::ExperimentData)
    param_str = join(["$k=$v" for (k, v) in pairs(e.params)], ", ")
    print(io, "ExperimentData(", param_str, ")")
end

function param_names(e::ExperimentData)
    return collect(keys(e.params))
end

function result_names(e::ExperimentData)
    return collect(keys(e.results))
end

function get_param(e::ExperimentData, name::Symbol)
    return getfield(e.params, name)
end

function get_result(e::ExperimentData, name::Symbol)
    return getfield(e.results, name)
end

function to_namedtuple(e::ExperimentData)
    return merge(e.params, e.results)
end

function extract_paramdim(data::Vector{ExperimentData}, param::Symbol)
    values = unique([get_param(e, param) for e in data])
    return ParamDim(param, values=values)
end

function to_paramspace(data::Vector{ExperimentData})
    if isempty(data)
        error("Cannot create ParamSpace from empty data")
    end
    param_names = collect(keys(data[1].params))
    dims = [extract_paramdim(data, p) for p in param_names]
    return ParamSpace(dims)
end
