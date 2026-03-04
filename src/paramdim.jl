"""
$(TYPEDEF)

A single parameter dimension with optional masking.

# Fields
- `name::Symbol`: Dimension identifier
- `values::Vector{T}`: All possible values
- `default::Union{T, Nothing}`: Optional default value
- `order::Symbol`: Iteration order (`:sequential` or `:shuffle`)
- `mask::Vector{Bool}`: Active/inactive flags for each value

# Example
```julia
ParamDim("x", values=[1, 2, 3])
ParamDim("y", range=(0, 10, 2))  # [0, 2, 4, 6, 8, 10]
ParamDim("z", linspace=(0, 1, 5))  # 5 points from 0 to 1
ParamDim("w", logspace=(-1, 1, 3))  # [0.1, 1.0, 10.0]
```
"""
mutable struct ParamDim{T}
    name::Symbol
    values::Vector{T}
    default::Union{T, Nothing}
    order::Symbol
    mask::Vector{Bool}
end

"""
$(TYPEDSIGNATURES)

Construct a `ParamDim` using one of the value specification methods.

# Arguments
- `name`: Dimension name (Symbol or String)
- `values`: Direct value list
- `range`: Tuple `(start, stop, step)` for arithmetic sequence
- `linspace`: Tuple `(start, stop, n)` for n linearly spaced values
- `logspace`: Tuple `(a, b, n)` for n logarithmically spaced values (10^a to 10^b)
- `default`: Optional default value
- `order`: `:sequential` or `:shuffle`
- `mask`: Boolean vector for active values
"""
function ParamDim(name::Union{Symbol,AbstractString};
         values=nothing,
         range=nothing,
         linspace=nothing,
         logspace=nothing,
         default=nothing,
         order=:sequential,
         mask=nothing)

    name_sym = Symbol(name)

    if values !== nothing
        vals = collect(values)
    elseif range !== nothing
        start, stop, step = range
        vals = collect(start:step:stop)
    elseif linspace !== nothing
        start, stop, n = linspace
        vals = collect(Base.range(start, stop, length=n))
    elseif logspace !== nothing
        a, b, n = logspace
        vals = collect(10 .^ Base.range(a, b, length=n))
    else
        error("Must specify one of: values, range, linspace, logspace")
    end

    T = eltype(vals)
    actual_mask = mask === nothing ? fill(true, length(vals)) : collect(Bool, mask)
    actual_default = default === nothing ? nothing : convert(T, default)

    return ParamDim{T}(name_sym, vals, actual_default, order, actual_mask)
end

Base.length(pdim::ParamDim) = count(pdim.mask)

function Base.iterate(pdim::ParamDim, state=1)
    effective = effective_values(pdim)
    iterate(effective, state)
end

Base.eltype(pdim::ParamDim{T}) where T = T

function Base.show(io::IO, pdim::ParamDim)
    print(io, """ParamDim(:$(pdim.name), $(length(pdim)) values)""")
end

function Base.getindex(pdim::ParamDim, i::Int)
    effective = effective_values(pdim)
    return effective[i]
end

"""
$(TYPEDSIGNATURES)

Return values filtered by mask.
"""
function effective_values(pdim::ParamDim)
    return pdim.values[pdim.mask]
end

"""
$(TYPEDSIGNATURES)

Return all values ignoring mask.
"""
function all_values(pdim::ParamDim)
    return pdim.values
end
