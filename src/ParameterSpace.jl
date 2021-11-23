module ParameterSpace

using IterTools, DataFrames, Printf

import Base: iterate, length

export
    Parameter,

    write_parameter_file,
    analyse_function, analyse_program

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
Parameter(Name::String, Index::Int64, Range) = Parameter(Name, Index, Range)

@inline length(p::Parameter)  = 1
@inline iterate(p::Parameter)  = (p,nothing)
@inline iterate(p::Parameter,st)  = nothing

########## Analyse Functions ##########

"""
    function analyse_function(f::Function, Params::Array{Parameter,1}, arg...;)

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