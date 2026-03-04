"""
$(TYPEDEF)

Wrapper for masked parameter values.

# Fields
- `value::T`: The actual value
- `active::Bool`: Whether this value is active
"""
struct Masked{T}
    value::T
    active::Bool
end

Base.show(io::IO, m::Masked) = print(io, m.active ? string(m.value) : "masked($(m.value))")

"""
$(TYPEDSIGNATURES)

Set mask for one or more dimensions to filter parameter values.

Only values where mask is `true` will be included in iteration.

# Example
```julia
pspace = ParamSpace([ParamDim("x", values=[1,2,3,4,5])])
set_mask!(pspace, :x, [true, false, true, false, true])  # Only 1, 3, 5
set_mask!(pspace, Dict(:x => [true, true, false, false, false]))  # Only 1, 2
```
"""
function set_mask!(pspace::ParamSpace, dim_name::Union{Symbol,AbstractString}, mask::Vector{Bool})
    key = Symbol(dim_name)
    if !haskey(pspace.dims, key)
        error("Dimension $dim_name not found in ParamSpace")
    end
    pdim = pspace.dims[key]
    if length(mask) != length(all_values(pdim))
        error("Mask length ($(length(mask))) must match dimension length ($(length(all_values(pdim))))")
    end
    pdim.mask .= mask
    return pspace
end

function set_mask!(pspace::ParamSpace, masks::Dict{<:Union{Symbol,AbstractString},Vector{Bool}})
    for (dim_name, mask) in masks
        set_mask!(pspace, dim_name, mask)
    end
    return pspace
end

"""
$(TYPEDSIGNATURES)

Clear mask for a dimension (all values become active).
"""
function clear_mask!(pspace::ParamSpace, dim_name::Union{Symbol,AbstractString})
    key = Symbol(dim_name)
    if !haskey(pspace.dims, key)
        error("Dimension $dim_name not found in ParamSpace")
    end
    pdim = pspace.dims[key]
    pdim.mask .= true
    return pspace
end

"""
$(TYPEDSIGNATURES)

Clear masks for all dimensions.
"""
function clear_all_masks!(pspace::ParamSpace)
    for (key, pdim) in pspace.dims
        pdim.mask .= true
    end
    return pspace
end

"""
$(TYPEDSIGNATURES)

Get current mask for a dimension.
"""
function get_mask(pspace::ParamSpace, dim_name::Union{Symbol,AbstractString})
    key = Symbol(dim_name)
    if !haskey(pspace.dims, key)
        error("Dimension $dim_name not found in ParamSpace")
    end
    return copy(pspace.dims[key].mask)
end

"""
$(TYPEDSIGNATURES)

Activate a subspace by setting masks based on value conditions.

# Arguments
- `conditions`: Dict mapping dimension names to:
  - A vector of allowed values
  - A single allowed value

# Example
```julia
pspace = ParamSpace([
    ParamDim("x", values=[1,2,3,4,5]),
    ParamDim("y", values=[10,20,30])
])
activate_subspace!(pspace, Dict("x" => [1, 3, 5]))  # Only odd x values
activate_subspace!(pspace, Dict("x" => [1,2], "y" => 10))  # x in [1,2] and y=10
```
"""
function activate_subspace!(pspace::ParamSpace, conditions::Dict)
    for (dim_name, condition) in conditions
        key = Symbol(dim_name)
        if !haskey(pspace.dims, key)
            error("Dimension $dim_name not found in ParamSpace")
        end
        pdim = pspace.dims[key]
        vals = all_values(pdim)

        if condition isa AbstractVector
            mask = [v in condition for v in vals]
        else
            mask = [v == condition for v in vals]
        end

        set_mask!(pspace, key, mask)
    end
    return pspace
end
