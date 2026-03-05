function data_point_to_dict(p::AbstractDataPoint)
    if p isa ConstraintData
        return Dict(
            "type" => "ConstraintData",
            "source" => Dict(
                "citekey" => p.source.citekey,
                "paper" => p.source.paper,
                "year" => p.source.year,
                "method" => p.source.method,
                "type" => string(p.source.type),
                "notes" => p.source.notes
            ),
            "param" => string(p.param),
            "lower" => p.lower,
            "upper" => p.upper,
            "confidence" => p.confidence,
            "constraint_type" => string(p.constraint_type)
        )
    elseif p isa ExperimentData
        return Dict(
            "type" => "ExperimentData",
            "source" => Dict(
                "citekey" => p.source.citekey,
                "paper" => p.source.paper,
                "year" => p.source.year,
                "method" => p.source.method,
                "type" => string(p.source.type),
                "notes" => p.source.notes
            ),
            "params" => Dict(string(k) => v for (k, v) in pairs(p.params)),
            "results" => Dict(string(k) => v for (k, v) in pairs(p.results)),
            "uncertainty" => Dict(string(k) => v for (k, v) in pairs(p.uncertainty))
        )
    else
        error("Unknown data point type")
    end
end

function dict_to_source(d::Dict)
    return DataSource(
        get(d, "citekey", ""),
        get(d, "paper", ""),
        get(d, "year", 0),
        get(d, "method", ""),
        Symbol(get(d, "type", "literature")),
        get(d, "notes", "")
    )
end

function dict_to_constraint(d::Dict)
    source = dict_to_source(d["source"])
    constraint_type = Symbol(get(d, "constraint_type", "include"))
    return ConstraintData(source, Symbol(d["param"]); 
        lower=d["lower"], upper=d["upper"], 
        confidence=d["confidence"], constraint_type=constraint_type)
end

function dict_to_experiment(d::Dict)
    source = dict_to_source(d["source"])
    params_dict = get(d, "params", Dict{String,Any}())
    results_dict = get(d, "results", Dict{String,Any}())
    uncertainty_dict = get(d, "uncertainty", Dict{String,Any}())
    
    params = NamedTuple{Tuple(Symbol.(keys(params_dict)))}(Tuple(values(params_dict)))
    results = NamedTuple{Tuple(Symbol.(keys(results_dict)))}(Tuple(values(results_dict)))
    uncertainty = NamedTuple{Tuple(Symbol.(keys(uncertainty_dict)))}(Tuple(values(uncertainty_dict)))
    
    return ExperimentData(source, params, results; uncertainty=uncertainty)
end

function save_yaml_dataset(ds::DataSet, filepath::String)
    data_dict = Dict(
        "name" => ds.name,
        "description" => ds.description,
        "type" => string(eltype(ds.data)),
        "data" => [data_point_to_dict(p) for p in ds.data]
    )
    YAML.write_file(filepath, data_dict)
end

function load_yaml_dataset(filepath::String)
    data_dict = YAML.load_file(filepath)
    ds_type = data_dict["type"]
    
    if ds_type == "ConstraintData"
        data = [dict_to_constraint(d) for d in data_dict["data"]]
        return DataSet{ConstraintData}(data_dict["name"], get(data_dict, "description", ""), data)
    elseif ds_type == "ExperimentData"
        data = [dict_to_experiment(d) for d in data_dict["data"]]
        return DataSet{ExperimentData}(data_dict["name"], get(data_dict, "description", ""), data)
    else
        error("Unknown dataset type: $ds_type")
    end
end

function save_toml_dataset(ds::DataSet, filepath::String)
    data_dict = Dict(
        "name" => ds.name,
        "description" => ds.description,
        "type" => string(eltype(ds.data)),
        "data" => [data_point_to_dict(p) for p in ds.data]
    )
    open(filepath, "w") do f
        TOML.print(f, data_dict)
    end
end

function load_toml_dataset(filepath::String)
    data_dict = TOML.parsefile(filepath)
    ds_type = data_dict["type"]
    
    if ds_type == "ConstraintData"
        data = [dict_to_constraint(d) for d in data_dict["data"]]
        return DataSet{ConstraintData}(data_dict["name"], get(data_dict, "description", ""), data)
    elseif ds_type == "ExperimentData"
        data = [dict_to_experiment(d) for d in data_dict["data"]]
        return DataSet{ExperimentData}(data_dict["name"], get(data_dict, "description", ""), data)
    else
        error("Unknown dataset type: $ds_type")
    end
end

function save_dataset(ds::DataSet, filepath::String; format::Symbol=:auto)
    ext = lowercase(splitext(filepath)[2])
    
    if format == :auto
        format = if ext == ".yaml" || ext == ".yml"
            :yaml
        elseif ext == ".toml"
            :toml
        else
            error("Unsupported file format: $ext")
        end
    end
    
    if format == :yaml
        save_yaml_dataset(ds, filepath)
    elseif format == :toml
        save_toml_dataset(ds, filepath)
    else
        error("Unsupported format: $format")
    end
    return filepath
end

function load_dataset(filepath::String; format::Symbol=:auto)
    ext = lowercase(splitext(filepath)[2])
    
    if format == :auto
        format = if ext == ".yaml" || ext == ".yml"
            :yaml
        elseif ext == ".toml"
            :toml
        else
            error("Unsupported file format: $ext")
        end
    end
    
    if format == :yaml
        return load_yaml_dataset(filepath)
    elseif format == :toml
        return load_toml_dataset(filepath)
    else
        error("Unsupported format: $format")
    end
end
