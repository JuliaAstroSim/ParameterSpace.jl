module ParameterSpace

using IterTools, DataFrames, Printf
using OrderedCollections
using ProgressMeter
using Random
using DocStringExtensions
using YAML
using TOML

import Base: iterate, length, eltype, show, getindex

include("paramdim.jl")
include("coupled.jl")
include("paramspace.jl")
include("sampling.jl")
include("mask.jl")
include("config.jl")
include("compat.jl")
include("analyse.jl")

export Parameter, parameter_dimension, parameter_count
export write_parameter_file, emptyfunction, mkoutputdir
export analyse_function, analyse_program

export ParamDim, effective_values, all_values
export ParamSpace, volume, shape, dim_names, state_no, set_state!, reset!, get_point
export linear_index, multi_index
export to_paramdim, to_paramspace
export CoupledParamDim, add_coupled!, get_coupled, has_coupled, remove_coupled!
export AbstractSamplingStrategy
export RandomSampling, LatinHypercubeSampling, SobolSampling, GridSampling, StratifiedGridSampling
export sample, sample_indices, validate_sample_size, set_seed!, sample_unique
export SobolSampler, next_sample!, next_n_samples!
export Masked, set_mask!, clear_mask!, clear_all_masks!, get_mask, activate_subspace!
export load_yaml, save_yaml, load_toml, save_toml

end
