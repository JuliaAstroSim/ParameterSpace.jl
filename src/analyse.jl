"""
$(TYPEDSIGNATURES)

Execute a function over all parameter combinations and collect results.

# Arguments
- `func`: Function taking `params::NamedTuple` as first argument
- `pspace`: Parameter space to explore
- `args...`: Additional positional arguments passed to `func`
- `strategy`: Sampling strategy (nothing for full grid)
- `n_samples`: Number of samples when using sampling strategy
- `parallel`: `:none`, `:threads`, or `:distributed`
- `folder`: Output folder for log file
- `filename`: Log filename
- `kw...`: Keyword arguments passed to `func`

# Returns
DataFrame with parameter columns and `result` column.

# Example
```julia
f(params) = params.x * params.y
pspace = ParamSpace([ParamDim("x", values=[1,2,3]), ParamDim("y", values=[1,2])])
result = analyse_function(f, pspace)

# With sampling
result = analyse_function(f, pspace; strategy=RandomSampling(seed=42), n_samples=10)

# Multi-threaded
result = analyse_function(f, pspace; parallel=:threads)
```
"""
function analyse_function(func::Function, pspace::ParamSpace, args...;
    strategy::Union{AbstractSamplingStrategy,Nothing}=nothing,
    n_samples::Union{Int,Nothing}=nothing,
    parallel::Symbol=:none,
    folder::AbstractString="output",
    filename::AbstractString="ParameterSpace_log.csv",
    writemode::AbstractString="w",
    kw...
)
    if strategy === nothing
        points = collect(pspace)
    else
        n = n_samples === nothing ? 100 : n_samples
        points = sample(pspace, strategy; n=n)
    end

    n_points = length(points)
    @info "Total parameter combinations: $n_points"

    names = dim_names(pspace)

    if parallel == :threads && Threads.nthreads() > 1
        return analyse_function_threads(func, points, names, args...;
            folder=folder, filename=filename, writemode=writemode, kw...)
    else
        return analyse_function_sequential(func, points, names, args...;
            folder=folder, filename=filename, writemode=writemode, kw...)
    end
end

function analyse_function_threads(func::Function, points::Vector{<:NamedTuple},
    names::Vector{Symbol}, args...;
    folder::AbstractString="output",
    filename::AbstractString="ParameterSpace_log.csv",
    writemode::AbstractString="w",
    kw...
)
    n_points = length(points)
    results = Vector{Any}(undef, n_points)

    if !isdir(folder)
        mkpath(folder)
    end

    progress = Progress(n_points; desc="Exploring parameter space (threads): ")
    completed = Threads.Atomic{Int}(0)
    lock_obj = ReentrantLock()

    Threads.@threads for i in 1:n_points
        params = points[i]
        results[i] = func(params, args...; kw...)

        Threads.atomic_add!(completed, 1)
        lock(lock_obj) do
            next!(progress, showvalues=[
                ("completed", completed[]),
                ("current", i),
                ("params", params),
                ("result", results[i]),
            ])
        end
    end

    tuning = DataFrame()
    for name in names
        tuning[!, name] = [getfield(points[i], name) for i in 1:n_points]
    end
    tuning[!, :result] = results

    file = open(joinpath(folder, filename), writemode)
    if writemode == "w"
        header = join([string(n) for n in names] |> x -> push!(x, "result"), ";")
        write(file, header * "\n")
    end

    for i in 1:n_points
        row = [[getfield(points[i], n) for n in names]..., results[i]]
        write(file, join(string.(row), ";") * "\n")
    end
    close(file)

    return tuning
end

function analyse_function_sequential(func::Function, points::Vector{<:NamedTuple},
    names::Vector{Symbol}, args...;
    folder::AbstractString="output",
    filename::AbstractString="ParameterSpace_log.csv",
    writemode::AbstractString="w",
    kw...
)
    n_points = length(points)

    tuning = DataFrame()
    for name in names
        tuning[!, name] = Any[]
    end
    tuning[!, :result] = Any[]

    if !isdir(folder)
        mkpath(folder)
    end

    file = open(joinpath(folder, filename), writemode)
    if writemode == "w"
        header = join([string(n) for n in names] |> x -> push!(x, "result"), ";")
        write(file, header * "\n")
    end

    try
        progress = Progress(n_points; desc="Exploring parameter space: ")

        for (i, params) in enumerate(points)
            result = func(params, args...; kw...)

            row = [getfield(params, n) for n in names]
            push!(row, result)

            for (j, name) in enumerate(names)
                push!(tuning[!, name], row[j])
            end
            push!(tuning[!, :result], result)

            write(file, join(string.(row), ";") * "\n")
            flush(file)

            next!(progress, showvalues=[
                ("case", i),
                ("params", params),
                ("result", result),
            ])
        end

    catch e
        throw(e)
    finally
        close(file)
    end

    return tuning
end

function execute_function(func::Function, params::NamedTuple, args...; kw...)
    return func(params, args...; kw...)
end

"""
$(TYPEDSIGNATURES)

Legacy API for backward compatibility with `Parameter` type.

The function receives arguments in order specified by `Parameter.Index`.
"""
function analyse_function(func::Function, params::Vector{<:Parameter}, args...;
    folder::AbstractString="output",
    filename::AbstractString="ParameterSpace_log.csv",
    writemode::AbstractString="w",
    kw...
)
    Cases = collect(Iterators.product([p.Range for p in params]...))
    @info "Total parameter combinations: $(length(Cases))"

    args_arr = Array{Any,1}([args...])
    for i in 1:(length(args) + length(params))
        for p in params
            if i == p.Index
                insert!(args_arr, i, undef)
            end
        end
    end

    tuning = DataFrame()
    for p in params
        tuning[!, Symbol(p.Name)] = Any[]
    end
    tuning[!, :result] = Any[]

    if !isdir(folder)
        mkpath(folder)
    end

    file = open(joinpath(folder, filename), writemode)
    if writemode == "w"
        write(file, join(names(tuning), ";") * "\n")
    end

    try
        progress = Progress(length(Cases); desc="Exploring parameter space: ")
        for c in eachindex(Cases)
            for i in 1:length(params)
                args_arr[params[i].Index] = Cases[c][i]
            end
            result = func(args_arr...; kw...)
            coord = (Cases[c]..., result)
            push!(tuning, coord)

            if !isnothing(folder)
                write(file, join(string.(coord), ";") * "\n")
                flush(file)
            end

            next!(progress, showvalues=[
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

"""
$(TYPEDSIGNATURES)

Write parameter values to file using printf-style format string.
"""
function write_parameter_file(filename::String, formatstring::String, args)
    args_vec = [args...]
    c = Printf.format(Printf.Format(formatstring), args_vec...)
    open(filename, "w") do f
        write(f, c)
    end
end

function emptyfunction()
end

"""
    mkoutputdir(dir::String)

Create or clean output directory.
"""
function mkoutputdir(dir::String)
    if isdir(dir)
        for d in readdir(dir)
            rm(joinpath(dir, d), force=true, recursive=true)
        end
    else
        mkdir(dir)
    end
end

"""
$(TYPEDSIGNATURES)

Execute an external program for each parameter combination.

# Arguments
- `command`: Command to run (e.g., `julia script.jl`)
- `content`: Printf-style format string for parameter file
- `paramfilename`: Name of parameter file to write
- `pspace`: Parameter space
- `analyse`: Function to extract results after program execution
- `strategy`: Sampling strategy (nothing for full grid)
- `n_samples`: Number of samples
- `args`: Additional arguments for `analyse` function
- `folder`: Output folder
- `kw...`: Keyword arguments for `analyse` function

# Example
```julia
pspace = ParamSpace([ParamDim("x", values=[1,2,3])])
result = analyse_program(`julia simulation.jl`, "x = %d", "params.txt", pspace;
    analyse = () -> parse_result("output.txt"))
```
"""
function analyse_program(command::Cmd, content::AbstractString,
    paramfilename::AbstractString, pspace::ParamSpace,
    analyse::Function=emptyfunction;
    strategy::Union{AbstractSamplingStrategy,Nothing}=nothing,
    n_samples::Union{Int,Nothing}=nothing,
    parallel::Symbol=:none,
    args=[],
    folder::AbstractString="output",
    filename::AbstractString="ParameterSpace_log.csv",
    writemode::AbstractString="w",
    kw...
)
    if strategy === nothing
        points = collect(pspace)
    else
        n = n_samples === nothing ? 100 : n_samples
        points = sample(pspace, strategy; n=n)
    end

    n_points = length(points)
    @info "Total parameter combinations: $n_points"

    if !isdir(folder)
        mkpath(folder)
    end
    cd(folder)

    names = dim_names(pspace)

    tuning = DataFrame()
    for name in names
        tuning[!, name] = Any[]
    end
    tuning[!, :result] = Any[]

    file = open(filename, writemode)
    if writemode == "w"
        header = join([string(n) for n in names] |> x -> push!(x, "result"), ";")
        write(file, header * "\n")
    end

    try
        progress = Progress(n_points; desc="Exploring parameter space: ")

        for (i, params) in enumerate(points)
            param_values = [getfield(params, n) for n in names]

            folder_tuning = join(map(string, param_values), ", ")
            mkdir(folder_tuning)
            cd(folder_tuning)

            write_parameter_file(paramfilename, content, param_values)
            run(command)

            result = analyse(args...; kw...)

            row = vcat(param_values, result)
            push!(tuning, row)

            cd("../")

            write(file, join(string.(row), ";") * "\n")
            flush(file)

            next!(progress, showvalues=[
                ("case", i),
                ("params", params),
                ("result", result),
            ])
        end

    catch e
        throw(e)
    finally
        close(file)
    end

    cd("../")
    return tuning
end

"""
$(TYPEDSIGNATURES)

Legacy API for backward compatibility with `Parameter` type.
"""
function analyse_program(command::Cmd, content::AbstractString,
    paramfilename::AbstractString, params::Vector{<:Parameter},
    analyse::Function=emptyfunction;
    args=[],
    folder::AbstractString="output",
    filename::AbstractString="ParameterSpace_log.csv",
    writemode::AbstractString="w",
    kw...
)
    Cases = collect(Iterators.product([p.Range for p in params]...))
    @info "Total parameter combinations: $(length(Cases))"

    if !isdir(folder)
        mkpath(folder)
    end
    cd(folder)

    tuning = DataFrame()
    for p in params
        tuning[!, Symbol(p.Name)] = Any[]
    end
    tuning[!, :result] = Any[]

    file = open(filename, writemode)
    if writemode == "w"
        write(file, join(names(tuning), ";") * "\n")
    end

    try
        progress = Progress(length(Cases); desc="Exploring parameter space: ")
        for c in eachindex(Cases)
            folder_tuning = join(map(string, Cases[c]), ", ")
            mkdir(folder_tuning)
            cd(folder_tuning)
            write_parameter_file(paramfilename, content, Cases[c])
            run(command)
            result = analyse(args...; kw...)
            coord = (Cases[c]..., result)
            push!(tuning, coord)
            cd("../")

            if !isnothing(folder)
                write(file, join(string.(coord), ";") * "\n")
                flush(file)
            end

            next!(progress, showvalues=[
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

    cd("../")
    return tuning
end
