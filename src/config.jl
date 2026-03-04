using YAML
using TOML

"""
    load_yaml(filepath::String) -> ParamSpace

Load parameter space from YAML configuration file.

# YAML Format
```yaml
parameters:
  x:
    values: [1, 2, 3]
    default: 2
  y:
    range: [0, 10, 2]  # start, stop, step
  z:
    linspace: [0.0, 1.0, 11]  # start, stop, n
  w:
    logspace: [-1, 1, 5]  # 10^a to 10^b, n points
```

# Example
```julia
pspace = load_yaml("params.yaml")
```
"""
function load_yaml(filepath::String)
    data = YAML.load_file(filepath)
    return parse_config_dict(data)
end

"""
    save_yaml(pspace::ParamSpace, filepath::String)

Save parameter space to YAML file.
"""
function save_yaml(pspace::ParamSpace, filepath::String)
    data = paramspace_to_dict(pspace)
    YAML.write_file(filepath, data)
end

"""
    load_toml(filepath::String) -> ParamSpace

Load parameter space from TOML configuration file.

# TOML Format
```toml
[parameters.x]
values = [1, 2, 3]
default = 2

[parameters.y]
range = [0, 10, 2]
```

# Example
```julia
pspace = load_toml("params.toml")
```
"""
function load_toml(filepath::String)
    data = TOML.parsefile(filepath)
    return parse_config_dict(data)
end

"""
    save_toml(pspace::ParamSpace, filepath::String)

Save parameter space to TOML file.
"""
function save_toml(pspace::ParamSpace, filepath::String)
    data = paramspace_to_dict(pspace)
    open(filepath, "w") do f
        TOML.print(f, data)
    end
end

function parse_config_dict(data::Dict)
    if !haskey(data, "parameters")
        error("Config must have 'parameters' key")
    end

    params = data["parameters"]
    dims = ParamDim[]

    for (name, spec) in params
        pdim = parse_paramdim(name, spec)
        push!(dims, pdim)
    end

    return ParamSpace(dims)
end

function parse_paramdim(name::String, spec::Dict)
    kwargs = Dict{Symbol,Any}()

    if haskey(spec, "values")
        kwargs[:values] = spec["values"]
    elseif haskey(spec, "range")
        r = spec["range"]
        kwargs[:range] = (r[1], r[2], r[3])
    elseif haskey(spec, "linspace")
        l = spec["linspace"]
        kwargs[:linspace] = (l[1], l[2], l[3])
    elseif haskey(spec, "logspace")
        lg = spec["logspace"]
        kwargs[:logspace] = (lg[1], lg[2], lg[3])
    else
        error("ParamDim '$name' must have one of: values, range, linspace, logspace")
    end

    if haskey(spec, "default")
        kwargs[:default] = spec["default"]
    end

    if haskey(spec, "order")
        kwargs[:order] = Symbol(spec["order"])
    end

    if haskey(spec, "mask")
        kwargs[:mask] = convert(Vector{Bool}, spec["mask"])
    end

    return ParamDim(name; kwargs...)
end

function paramspace_to_dict(pspace::ParamSpace)
    params = Dict{String,Any}()

    for name in dim_names(pspace)
        pdim = pspace.dims[name]
        params[string(name)] = paramdim_to_dict(pdim)
    end

    return Dict("parameters" => params)
end

function paramdim_to_dict(pdim::ParamDim)
    spec = Dict{String,Any}()

    spec["values"] = collect(all_values(pdim))

    if pdim.default !== nothing
        spec["default"] = pdim.default
    end

    if pdim.order != :sequential
        spec["order"] = string(pdim.order)
    end

    if !all(pdim.mask)
        spec["mask"] = pdim.mask
    end

    return spec
end
