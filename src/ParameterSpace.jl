module ParameterSpace

using IterTools, DataFrames, Plots

import Base: iterate, length

export
    Parameter,

    analyse_function, analyse_program

########## Basic Data Structure ##########
struct Parameter
    Name::String
    Index::Int64 # The location in the target function
    Range # Array or range
    Parameter(Name::String, Index::Int64, Range) = new(Name, Index, Range)
end

@inline length(p::Parameter)  = 1
@inline iterate(p::Parameter)  = (p,nothing)
@inline iterate(p::Parameter,st)  = nothing

########## Analyse Functions ##########
function analyse_function(f::Function, Params::Array{Parameter,1}, arg...;)
    # Construct parameter space
    Space = (Params[1].Range, )
    for p in Params[2:end]
        Space = (Space..., p.Range)
    end
    @show Space
    Space = Iterators.product(Space...)
    @show Space

    # Prepare the argument array with undef
    # Must insert from small index to larger ones
    args = Array{Any,1}([arg...])
    for i in 1:(length(arg) + length(Params))
        for p in Params
            if i == p.Index
                insert!(args, i, undef)
            end
        end
    end

    # Iterate
    result = DataFrame()
    for p in Params
        result[Symbol(p.Name)] = Any[]
    end
    result[:result] = Any[]
    for s in Space
        # Prepare for the argument list
        for i in 1:length(Params)
            args[Params[i].Index] = s[i]
        end
        push!(result, (s..., f(args...)))
    end

    return result
end

function analyse_program()

end

########## Tools ##########
function find_result()

end

########## Plotting ##########

end # module
