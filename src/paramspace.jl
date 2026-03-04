"""
$(TYPEDEF)

Multi-dimensional parameter space supporting iteration, masking, and coupled dimensions.

# Fields
$(TYPEDFIELDS)

# Example
```julia
pspace = ParamSpace([
    ParamDim("x", values=[1,2,3]),
    ParamDim("y", values=[1,2])
])

for params in pspace
    println(params)  # NamedTuple like (x=1, y=1)
end
```
"""
mutable struct ParamSpace
    dims::OrderedDict{Symbol,ParamDim}
    dim_order::Vector{Symbol}
    current_state::Int
    coupled::Vector{CoupledParamDim}
end

"""
$(TYPEDSIGNATURES)

Construct from ordered dictionary of dimensions.
"""
function ParamSpace(dims::OrderedDict{Symbol,ParamDim})
    dim_order = collect(keys(dims))
    return ParamSpace(dims, dim_order, 1, CoupledParamDim[])
end

"""
$(TYPEDSIGNATURES)

Construct from string-keyed dictionary.
"""
function ParamSpace(dims::Dict{String,<:ParamDim})
    ordered = OrderedDict{Symbol,ParamDim}()
    for (k, v) in dims
        ordered[Symbol(k)] = v
    end
    return ParamSpace(ordered)
end

"""
$(TYPEDSIGNATURES)

Construct from vector of dimensions.
"""
function ParamSpace(dims::Vector{<:ParamDim})
    ordered = OrderedDict{Symbol,ParamDim}()
    for d in dims
        ordered[d.name] = d
    end
    return ParamSpace(ordered)
end

"""
$(TYPEDSIGNATURES)

Construct from variadic arguments.
"""
ParamSpace(dims::Vararg{ParamDim}) = ParamSpace(collect(dims))

function Base.length(pspace::ParamSpace)
    return prod(length(pspace.dims[d]) for d in pspace.dim_order)
end

function Base.eltype(pspace::ParamSpace)
    names = Symbol[pspace.dim_order...]
    types = Any[eltype(pspace.dims[d]) for d in pspace.dim_order]
    
    for cp in pspace.coupled
        push!(names, cp.name)
        push!(types, eltype(cp))
    end
    
    return NamedTuple{Tuple(names), Tuple{types...}}
end

"""
$(TYPEDSIGNATURES)

Total number of parameter combinations.
"""
function volume(pspace::ParamSpace)
    return length(pspace)
end

"""
$(TYPEDSIGNATURES)

Return tuple of dimension lengths.
"""
function shape(pspace::ParamSpace)
    return Tuple(length(pspace.dims[d]) for d in pspace.dim_order)
end

"""
$(TYPEDSIGNATURES)

Return dimension names in order.
"""
function dim_names(pspace::ParamSpace)
    return pspace.dim_order
end

"""
$(TYPEDSIGNATURES)

Get current iteration state (1-indexed).
"""
function state_no(pspace::ParamSpace)
    return pspace.current_state
end

"""
$(TYPEDSIGNATURES)

Set iteration state for resumable iteration.
"""
function set_state!(pspace::ParamSpace, state::Int)
    pspace.current_state = clamp(state, 1, length(pspace))
    return pspace
end

"""
$(TYPEDSIGNATURES)

Reset iteration state to beginning.
"""
function reset!(pspace::ParamSpace)
    pspace.current_state = 1
    return pspace
end

"""
$(TYPEDSIGNATURES)

Get parameter combination at given linear index.
"""
function get_point(pspace::ParamSpace, index::Int)
    shp = shape(pspace)
    multi_idx = CartesianIndices(shp)[index].I

    names = Symbol[]
    values = Any[]

    for (i, d) in enumerate(pspace.dim_order)
        push!(names, d)
        push!(values, pspace.dims[d][multi_idx[i]])
    end

    for cp in pspace.coupled
        push!(names, cp.name)
        target_idx = findfirst(==(cp.target), pspace.dim_order)
        if target_idx !== nothing
            push!(values, cp.values[multi_idx[target_idx]])
        end
    end

    return NamedTuple{Tuple(names)}(Tuple(values))
end

function Base.iterate(pspace::ParamSpace, state::Int=pspace.current_state)
    total = length(pspace)
    if state > total
        return nothing
    end

    point = get_point(pspace, state)
    return (point, state + 1)
end

"""
$(TYPEDSIGNATURES)

Convert multi-dimensional index to linear index.
"""
function linear_index(pspace::ParamSpace, multi_idx::Tuple)
    shp = shape(pspace)
    cart_idx = CartesianIndex(multi_idx)
    return LinearIndices(shp)[cart_idx]
end

"""
$(TYPEDSIGNATURES)

Convert linear index to multi-dimensional index.
"""
function multi_index(pspace::ParamSpace, linear_idx::Int)
    shp = shape(pspace)
    return CartesianIndices(shp)[linear_idx].I
end

"""
$(TYPEDSIGNATURES)

Add a coupled dimension to the parameter space.
"""
function add_coupled!(pspace::ParamSpace, cp::CoupledParamDim)
    if !haskey(pspace.dims, cp.target)
        error("Target dimension $(cp.target) not found in ParamSpace")
    end
    target_dim = pspace.dims[cp.target]
    if length(cp) != length(all_values(target_dim))
        error("Coupled dimension length ($(length(cp))) must match target dimension length ($(length(all_values(target_dim))))")
    end
    push!(pspace.coupled, cp)
    return pspace
end

"""
$(TYPEDSIGNATURES)

Check if a coupled dimension with given name exists.
"""
function has_coupled(pspace::ParamSpace, name::Symbol)
    return any(cp -> cp.name == name, pspace.coupled)
end

"""
$(TYPEDSIGNATURES)

Get coupled dimension by name, or nothing if not found.
"""
function get_coupled(pspace::ParamSpace, name::Symbol)
    for cp in pspace.coupled
        if cp.name == name
            return cp
        end
    end
    return nothing
end

"""
$(TYPEDSIGNATURES)

Remove a coupled dimension by name.
"""
function remove_coupled!(pspace::ParamSpace, name::Symbol)
    filter!(cp -> cp.name != name, pspace.coupled)
    return pspace
end
