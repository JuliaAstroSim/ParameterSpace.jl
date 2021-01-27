module ParameterSpace

using IterTools, DataFrames, Printf

import Base: iterate, length

export
    Parameter,

    write_parameter_file,
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

"""
    function analyse_function(f::Function, Params::Array{Parameter,1}, arg...;)

    
"""
function analyse_function(f::Function, Params::Array{Parameter,1}, arg...;)
    # Construct parameter space
    Space = Iterators.product([p.Range for p in Params]...)

    # Prepare the argument array with undef
    # Must insert from small index to larger
    args = Array{Any,1}([arg...])
    for i in 1:(length(arg) + length(Params))
        for p in Params
            if i == p.Index
                insert!(args, i, undef)
            end
        end
    end

    # Iterate
    tuning = DataFrame()
    for p in Params
        tuning[!, Symbol(p.Name)] = Any[]
    end
    tuning[!, :result] = Any[]
    for s in Space
        # Prepare for the argument list
        for i in 1:length(Params)
            args[Params[i].Index] = s[i]
        end
        push!(tuning, (s..., f(args...)))
    end

    return tuning
end

########## Analyse Programs

"""
    function write_parameter_file(filename::String, content::String, args)


"""
function write_parameter_file(filename::String, content::String, args)
    args = [args...]
    c = @eval @sprintf($content, $args...)
    f = open(filename, "w")
    write(f, c)
    close(f)
end

"""
    function emptyfunction()

    A function that does nothing.
"""
function emptyfunction()
end

"""
    function mkoutputdir(dir::String)

Empty the directory if it exists. Create one if the directory does not exist.
"""
function mkoutputdir(dir::String)
    if isdir(dir)
        for d in readdir(dir)
            rm(joinpath(dir, d), force = true, recursive = true)
        end
    else
        mkdir(dir)
    end
end

"""
    function analyse_program(command::Cmd, content::String, filename::String, Params::Array{Parameter,1}, analyse::Function)


"""
function analyse_program(command::Cmd, content::String, filename::String, Params::Array{Parameter,1}, analyse::Function = emptyfunction; args = [], OutputDir = "output")
    # Construct parameter space
    Space = Iterators.product([p.Range for p in Params]...)

    mkoutputdir(OutputDir)
    cd(OutputDir)

    tuning = DataFrame()
    for p in Params
        tuning[!,Symbol(p.Name)] = Any[]
    end
    tuning[!,:result] = Any[]

    for s in Space
        folder = join(map(string, s), ", ")
        mkdir(folder)
        cd(folder)
        write_parameter_file(filename, content, s)
        run(command)
        push!(tuning, (s..., analyse(args...)))
        cd("../")
    end

    cd("../")
    return tuning
end

end # module