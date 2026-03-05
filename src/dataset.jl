mutable struct DataSet{T<:AbstractDataPoint}
    name::String
    description::String
    data::Vector{T}
    schema::NamedTuple
end

function DataSet(name::String, description::String=""; schema::NamedTuple=NamedTuple())
    return DataSet{AbstractDataPoint}(name, description, AbstractDataPoint[], schema)
end

function DataSet{T}(name::String) where {T<:AbstractDataPoint}
    return DataSet{T}(name, "", T[], NamedTuple())
end

function DataSet{T}(name::String, data::Vector{T}) where {T<:AbstractDataPoint}
    return DataSet{T}(name, "", data, NamedTuple())
end

function DataSet{T}(name::String, description::String, data::Vector{T}) where {T<:AbstractDataPoint}
    return DataSet{T}(name, description, data, NamedTuple())
end

function name(ds::DataSet)
    return ds.name
end

function add!(ds::DataSet, point::AbstractDataPoint)
    push!(ds.data, point)
    return ds
end

function remove!(ds::DataSet, index::Int)
    if 1 <= index <= length(ds.data)
        deleteat!(ds.data, index)
    end
    return ds
end

function query(ds::DataSet; kwargs...)
    if isempty(kwargs)
        return ds.data
    end
    result = filter(ds.data) do point
        all(kwargs) do (k, v)
            if hasproperty(point, k)
                getproperty(point, k) == v
            elseif point isa ExperimentData && hasproperty(point.params, k)
                getproperty(point.params, k) == v
            elseif point isa ExperimentData && hasproperty(point.results, k)
                getproperty(point.results, k) == v
            else
                false
            end
        end
    end
    return result
end

function Base.filter(predicate::Function, ds::DataSet)
    return filter(predicate, ds.data)
end

function Base.length(ds::DataSet)
    return length(ds.data)
end

function Base.iterate(ds::DataSet, state=1)
    return iterate(ds.data, state)
end

function Base.eltype(ds::DataSet{T}) where {T}
    return T
end

function Base.getindex(ds::DataSet, i::Int)
    return ds.data[i]
end

function Base.show(io::IO, ds::DataSet)
    print(io, """DataSet( $(ds.name), $(ds.description), $(length(ds)) points)""")
end
