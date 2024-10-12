module ParameterSpace

using IterTools, DataFrames, Printf
using ProgressMeter

import Base: iterate, length

export Parameter, parameter_dimension, parameter_count
export write_parameter_file
export analyse_function, analyse_program

########## Basic Data Structure ##########
"""
    struct Parameter{A}

Defines the information of tuning parameter

# Fields
- `Name::String`: label of the parameter
- `Index::Int64`: The location of parameter in the target function. For example, the location of parameter `a` in function `f(x, a)` is `2`
-     `Range::A`: Tuning range of the parameter
"""
struct Parameter{A}
    Name::String
    Index::Int64
    Range::A
end

# Pretty printing
function Base.show(io::IO, p::Parameter)
    print(io, "Parameter ", p.Index, ": ", p.Name, " -->", p.Range)
end

@inline length(p::Parameter)  = 1
@inline iterate(p::Parameter)  = (p,nothing)
@inline iterate(p::Parameter,st)  = nothing

"""
    function parameter_dimension(a::AbstractArray{T,N}) where T<:Parameter where N

Return an array of lengths in each parameter dimension.
"""
function parameter_dimension(a::AbstractArray{T,N}) where T<:Parameter where N
    return [length(p.Range) for p in a]
end

"""
    function parameter_count(a::AbstractArray{T,N}) where T<:Parameter where N

Count the total number of combinations of parameters
"""
function parameter_count(a::AbstractArray{T,N}) where T<:Parameter where N
    return prod(parameter_dimension(a))
end

########## Analyse Functions ##########

"""
    function analyse_function(f::Function, Params::Array{Parameter,1}, arg...; kw...)

Tuning the function `f` over some of its arguments defined in `Params`. The outputs of `f` are stored in a `DataFrame`.

# Example
```julia
g(x::Real, y::Real) = x * y
params = [Parameter("x", 1, 0:2),
          Parameter("y", 2, 0:2)]
result = analyse_function(g, params)
```

If only tuning the second parameter y of function g, the other arguments should be set in order:
```julia
params = [Parameter("y", 2, 0:0.1:0.5)]
result = analyse_function(g, params, 1.0)
```
"""
function analyse_function(func::Function, Params, arg...;
    outputdir = "output",
    filename = "ParameterSpace_log.csv",
    kw...
)
    # Construct parameter space
    Cases = collect(Iterators.product([p.Range for p in Params]...))
    @info "Total parameter combinations: $(length(Cases))"

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

    # initiate data
    tuning = DataFrame()
    for p in Params
        tuning[!, Symbol(p.Name)] = Any[]
    end
    tuning[!, :result] = Any[]

    if !isnothing(outputdir)
        if !isdir(outputdir)
            mkpath(outputdir)
        end

        file = open(joinpath(outputdir, filename), "w")
        write(file, join(names(tuning), ";") * "\n")
    end

    try
        progress = Progress(length(Cases); desc = "Exploring parameter space: ")
        for c in eachindex(Cases)
            # Prepare for the argument list
            for i in 1:length(Params)
                args[Params[i].Index] = Cases[c][i]
            end
            result = func(args...; kw...)
            coord = (Cases[c]..., result)
            push!(tuning, coord)

            if !isnothing(outputdir)
                write(file, join(string.(coord), ";") * "\n")
            end

            next!(progress, showvalues = [
                ("case", c),
                ("params", Cases[c]),
                ("result", result),
            ])
        end
        close(file)
    catch e
        throw(e)
    finally
        close(file)
    end

    return tuning
end

########## Analyse Programs

"""
    function write_parameter_file(filename::String, formatstring::String, args)

Write formatted string into file.
"""
function write_parameter_file(filename::String, formatstring::String, args)
    args = [args...]
    c = Printf.format(Printf.Format(formatstring), args...)
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
    function analyse_program(command::Cmd, content::String, filename::String, Params::Array{Parameter,1}, analyse::Function = emptyfunction; args = [], OutputDir = "output")

Programs are tuned by altering the parameter files.

# Arguments
- `command::Cmd`: command line code to execute the program
- `content::String`: formatted string to write into the parameter file used by the program
- `filename::String`: filename of the parameter file.
- `Params::Array{Parameter,1}`
- `analyse::Function`: the callback function to analyse output files. There is no general way to pass data from a program to Julia, 
    however it's easy and convenient to analyse the output files automatically if you could provide an anlysis function.
    the parameters of analysis function could be set with keyword `args::Union{Tuple,Array}`

# Example
```julia
command = `julia E:/ParameterSpace.jl/examples/simple_program/print.jl`
content = "x = %d, y = %d"
params = [Parameter("x", 1, 0:2),
          Parameter("y", 2, 0:2)]
result = analyse_program(command, content, "param.txt", params)

function analyse(x::Int)
    f = readlines("param.txt")
    return length(f[1]) + x
end
result = analyse_program(command, content, "param.txt", params, analyse, args = [-15])
```
"""
function analyse_program(command::Cmd, content::String, filename::String, Params, analyse::Function = emptyfunction;
    args = [], outputdir = "output",
)
    # Construct parameter space
    Cases = collect(Iterators.product([p.Range for p in Params]...))
    @info "Total parameter combinations: $(length(Cases))"

    if !isdir(outputdir)
        mkpath(outputdir)
    end
    cd(outputdir)

    tuning = DataFrame()
    for p in Params
        tuning[!,Symbol(p.Name)] = Any[]
    end
    tuning[!,:result] = Any[]

    try
        progress = Progress(length(Cases); desc = "Exploring parameter space: ")
        for c in eachindex(Cases)
            folder = join(map(string, Cases[c]), ", ")
            mkdir(folder)
            cd(folder)
            write_parameter_file(filename, content, Cases[c])
            run(command)
            push!(tuning, (Cases[c]..., analyse(args...)))
            cd("../")

            next!(progress, showvalues = [
                ("case", c),
                ("params", Cases[c]),
            ])
        end
    catch e
        throw(e)
    finally
    end

    cd("../")
    return tuning
end

end # module