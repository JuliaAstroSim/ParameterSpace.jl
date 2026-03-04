"""
    struct Parameter{A}

Legacy parameter type for backward compatibility.

# Fields
- `Name::String`: Parameter name
- `Index::Int64`: Sort order index
- `Range::A`: Value range (any iterable)

# Example
```julia
params = [
    Parameter("x", 1, 0:2),
    Parameter("y", 2, [0.1, 0.5, 1.0])
]
```

See also [`to_paramdim`](@ref), [`to_paramspace`](@ref).
"""
struct Parameter{A}
    Name::String
    Index::Int64
    Range::A
end

Base.length(p::Parameter) = 1
Base.iterate(p::Parameter) = (p, nothing)
Base.iterate(p::Parameter, st) = nothing

function Base.show(io::IO, p::Parameter)
    print(io, "Parameter ", p.Index, ": ", p.Name, " -->", p.Range)
end

"""
$(TYPEDSIGNATURES)

Convert legacy Parameter to new ParamDim type.
"""
function to_paramdim(p::Parameter)
    return ParamDim(p.Name, values=collect(p.Range))
end

"""
$(TYPEDSIGNATURES)

Convert vector of Parameters to ParamSpace. Parameters are sorted by Index.
"""
function to_paramspace(params::Vector{<:Parameter})
    sorted_params = sort(params, by=x -> x.Index)
    dims = [to_paramdim(p) for p in sorted_params]
    return ParamSpace(dims)
end

"""
$(TYPEDSIGNATURES)

Return the number of values for each parameter (legacy API).
"""
function parameter_dimension(a::AbstractArray{T,N}) where {T<:Parameter} where {N}
    return [length(p.Range) for p in a]
end

"""
$(TYPEDSIGNATURES)

Return total number of parameter combinations (legacy API).
"""
function parameter_count(a::AbstractArray{T,N}) where {T<:Parameter} where {N}
    return prod(parameter_dimension(a))
end
