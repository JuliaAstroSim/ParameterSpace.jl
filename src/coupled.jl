"""
$(TYPEDEF)

A parameter dimension coupled to another dimension's values.

When iterating, coupled dimensions move in sync with their target dimension,
providing one-to-one correspondence between values.

# Fields
- `name::Symbol`: This dimension's identifier
- `target::Symbol`: Name of the dimension to couple with
- `values::Vector{T}`: Values corresponding to target's values

# Example
```julia
pspace = ParamSpace([
    ParamDim("x", values=[1, 2, 3])
])
add_coupled!(pspace, CoupledParamDim("x_squared", target=:x, values=[1, 4, 9]))
# When x=1, x_squared=1; when x=2, x_squared=4; when x=3, x_squared=9
```
"""
struct CoupledParamDim{T}
    name::Symbol
    target::Symbol
    values::Vector{T}
end

"""
$(TYPEDSIGNATURES)

Construct a coupled dimension.

# Arguments
- `name`: Dimension name (Symbol or String)
- `target`: Target dimension name to couple with
- `values`: Values corresponding to target's values (must match target's length)
"""
function CoupledParamDim(name::Union{Symbol,AbstractString}, target::Union{Symbol,AbstractString}, values)
    return CoupledParamDim(Symbol(name), Symbol(target), collect(values))
end

"""
$(TYPEDSIGNATURES)

Keyword argument constructor.
"""
function CoupledParamDim(name::Union{Symbol,AbstractString}; target::Union{Symbol,AbstractString}, values)
    return CoupledParamDim(Symbol(name), Symbol(target), collect(values))
end

Base.length(cp::CoupledParamDim) = length(cp.values)
Base.eltype(cp::CoupledParamDim{T}) where {T} = T

function Base.show(io::IO, cp::CoupledParamDim)
    print(io, """CoupledParamDim(:$(cp.name) -> :$(cp.target), $(length(cp)) values)""")
end
