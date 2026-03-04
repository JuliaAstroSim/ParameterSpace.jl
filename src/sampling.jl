"""
    abstract type AbstractSamplingStrategy end

Abstract base for parameter space sampling strategies.

Implementations must provide `sample(pspace, strategy)` or `sample_indices(pspace, strategy, n)`.
"""
abstract type AbstractSamplingStrategy end

"""
    struct RandomSampling <: AbstractSamplingStrategy

Random uniform sampling with optional seed for reproducibility.

# Fields
- `seed::Union{Int,Nothing}`: Random seed (nothing for non-deterministic)

# Example
```julia
sample(pspace, RandomSampling(seed=42), n=100)
```
"""
struct RandomSampling <: AbstractSamplingStrategy
    seed::Union{Int,Nothing}
end

RandomSampling(; seed=nothing) = RandomSampling(seed)

"""
    struct LatinHypercubeSampling <: AbstractSamplingStrategy

Latin Hypercube Sampling (LHS) for uniform coverage in high dimensions.

Each dimension is divided into n equal intervals, with one sample per interval.
Provides better space-filling than pure random sampling.

# Fields
- `seed::Union{Int,Nothing}`: Random seed for reproducibility

# Example
```julia
sample(pspace, LatinHypercubeSampling(seed=42), n=100)
```
"""
struct LatinHypercubeSampling <: AbstractSamplingStrategy
    seed::Union{Int,Nothing}
end

LatinHypercubeSampling(; seed=nothing) = LatinHypercubeSampling(seed)

"""
    struct SobolSampling <: AbstractSamplingStrategy

Sobol quasi-random sequence sampling for low-discrepancy coverage.

Provides deterministic, well-distributed samples. Better uniformity than LHS
for the same number of points in high dimensions.

# Example
```julia
sample(pspace, SobolSampling(), n=100)
```
"""
struct SobolSampling <: AbstractSamplingStrategy end

"""
    struct GridSampling <: AbstractSamplingStrategy

Complete grid traversal (equivalent to `collect(pspace)`).

Use for exhaustive parameter space exploration.
"""
struct GridSampling <: AbstractSamplingStrategy end

"""
$(TYPEDSIGNATURES)

Sample points from parameter space using specified strategy.

# Arguments
- `pspace`: Parameter space to sample
- `strategy`: Sampling strategy (RandomSampling, LatinHypercubeSampling, SobolSampling, GridSampling)
- `n`: Number of samples (ignored for GridSampling)

# Returns
Vector of NamedTuples, each representing a parameter configuration.
"""
function sample(pspace::ParamSpace, strategy::AbstractSamplingStrategy; n::Int=100)
    if strategy isa GridSampling
        return collect(pspace)
    end

    indices = sample_indices(pspace, strategy, n)
    return [get_point(pspace, i) for i in indices]
end

"""
$(TYPEDSIGNATURES)

Return indices of sampled points. Override for custom sampling strategies.
"""
function sample_indices(pspace::ParamSpace, strategy::AbstractSamplingStrategy, n::Int)
    error("sample_indices not implemented for $(typeof(strategy))")
end

function sample_indices(pspace::ParamSpace, strategy::RandomSampling, n::Int)
    total = volume(pspace)
    if strategy.seed !== nothing
        Random.seed!(strategy.seed)
    end
    return rand(1:total, n)
end

function sample_indices(pspace::ParamSpace, ::GridSampling, n::Union{Int,Nothing}=nothing)
    total = volume(pspace)
    return 1:total
end

"""
$(TYPEDSIGNATURES)

Validate and cap sample size to parameter space volume.
"""
function validate_sample_size(pspace::ParamSpace, n::Int)
    total = volume(pspace)
    if n > total
        @warn "Requested $n samples but parameter space only has $total points. Using all points."
        return total
    end
    return n
end

"""
$(TYPEDSIGNATURES)

Set random seed for strategies with seed field.
"""
function set_seed!(strategy::Union{RandomSampling,LatinHypercubeSampling})
    if strategy.seed !== nothing
        Random.seed!(strategy.seed)
    end
end

function sample_indices(pspace::ParamSpace, strategy::LatinHypercubeSampling, n::Int)
    set_seed!(strategy)
    n = validate_sample_size(pspace, n)
    total = volume(pspace)
    
    if n == total
        return collect(1:total)
    end
    
    shp = shape(pspace)
    dim = length(shp)
    
    indices = Vector{Int}(undef, n)
    
    for i in 1:n
        multi_idx = zeros(Int, dim)
        for d in 1:dim
            multi_idx[d] = rand(1:shp[d])
        end
        indices[i] = linear_index(pspace, Tuple(multi_idx))
    end
    
    return indices
end

function sample(pspace::ParamSpace, strategy::LatinHypercubeSampling; n::Int=100)
    set_seed!(strategy)
    n = validate_sample_size(pspace, n)
    shp = shape(pspace)
    dim = length(shp)
    
    if n == volume(pspace)
        return collect(pspace)
    end
    
    samples = Vector{NamedTuple}(undef, n)
    
    perm_matrix = Matrix{Int}(undef, dim, n)
    for d in 1:dim
        perm_matrix[d, :] = randperm(n)
    end
    
    for i in 1:n
        multi_idx = zeros(Int, dim)
        for d in 1:dim
            interval_size = shp[d] / n
            interval_start = (perm_matrix[d, i] - 1) * interval_size
            interval_end = perm_matrix[d, i] * interval_size
            
            idx = ceil(Int, interval_start + rand() * (interval_end - interval_start))
            multi_idx[d] = clamp(idx, 1, shp[d])
        end
        
        samples[i] = get_point(pspace, linear_index(pspace, Tuple(multi_idx)))
    end
    
    return samples
end

"""
$(TYPEDSIGNATURES)

Random sampling without replacement (each point sampled at most once).
"""
function sample_unique(pspace::ParamSpace, strategy::RandomSampling; n::Int=100)
    set_seed!(strategy)
    total = volume(pspace)
    n = min(n, total)

    if n == total
        return collect(pspace)
    end

    indices = Random.shuffle(1:total)[1:n]
    return [get_point(pspace, i) for i in indices]
end

import Sobol: SobolSeq, next! as sobol_next!

function sample(pspace::ParamSpace, ::SobolSampling; n::Int=100)
    n = validate_sample_size(pspace, n)
    shp = shape(pspace)
    dim = length(shp)

    if n == volume(pspace)
        return collect(pspace)
    end

    s = SobolSeq(dim)

    samples = Vector{NamedTuple}(undef, n)

    for i in 1:n
        point = sobol_next!(s)

        multi_idx = zeros(Int, dim)
        for d in 1:dim
            idx = ceil(Int, point[d] * shp[d])
            multi_idx[d] = clamp(idx, 1, shp[d])
        end

        samples[i] = get_point(pspace, linear_index(pspace, Tuple(multi_idx)))
    end

    return samples
end

function sample_indices(pspace::ParamSpace, ::SobolSampling, n::Int)
    n = validate_sample_size(pspace, n)
    shp = shape(pspace)
    dim = length(shp)

    if n == volume(pspace)
        return collect(1:volume(pspace))
    end

    s = SobolSeq(dim)
    indices = Vector{Int}(undef, n)

    for i in 1:n
        point = sobol_next!(s)

        multi_idx = zeros(Int, dim)
        for d in 1:dim
            idx = ceil(Int, point[d] * shp[d])
            multi_idx[d] = clamp(idx, 1, shp[d])
        end

        indices[i] = linear_index(pspace, Tuple(multi_idx))
    end

    return indices
end

"""
    mutable struct SobolSampler

Stateful Sobol sampler for incremental sampling.

# Fields
- `seq::SobolSeq`: Sobol sequence generator
- `dim::Int`: Number of dimensions
- `shp::Tuple`: Shape of parameter space

# Example
```julia
sampler = SobolSampler(pspace)
point1 = next_sample!(sampler, pspace)
more_points = next_n_samples!(sampler, pspace, 10)
```
"""
mutable struct SobolSampler
    seq::SobolSeq
    dim::Int
    shp::Tuple

    function SobolSampler(pspace::ParamSpace)
        shp = shape(pspace)
        dim = length(shp)
        return new(SobolSeq(dim), dim, shp)
    end
end

"""
$(TYPEDSIGNATURES)

Get next Sobol sample point.
"""
function next_sample!(sampler::SobolSampler, pspace::ParamSpace)
    point = sobol_next!(sampler.seq)

    multi_idx = zeros(Int, sampler.dim)
    for d in 1:sampler.dim
        idx = ceil(Int, point[d] * sampler.shp[d])
        multi_idx[d] = clamp(idx, 1, sampler.shp[d])
    end

    return get_point(pspace, linear_index(pspace, Tuple(multi_idx)))
end

"""
$(TYPEDSIGNATURES)

Get next n Sobol sample points.
"""
function next_n_samples!(sampler::SobolSampler, pspace::ParamSpace, n::Int)
    return [next_sample!(sampler, pspace) for _ in 1:n]
end

"""
$(TYPEDEF)

Sparse grid sampling with configurable resolution.

Samples every `dim_length ÷ resolution` points along each dimension.
Useful for quick exploration of large parameter spaces.

# Fields
- `resolution::Int`: Number of strata per dimension

# Example
```julia
sample(pspace, StratifiedGridSampling(10))  # ~10 points per dimension
```
"""
struct StratifiedGridSampling <: AbstractSamplingStrategy
    resolution::Int
end

function sample(pspace::ParamSpace, strategy::StratifiedGridSampling; n::Union{Int,Nothing}=nothing)
    shp = shape(pspace)
    dim = length(shp)
    res = strategy.resolution
    
    step_sizes = [max(1, shp[d] ÷ res) for d in 1:dim]
    
    samples = NamedTuple[]
    
    multi_idx = ones(Int, dim)
    
    while true
        point = get_point(pspace, linear_index(pspace, Tuple(multi_idx)))
        push!(samples, point)
        
        d = 1
        while d <= dim
            multi_idx[d] += step_sizes[d]
            if multi_idx[d] > shp[d]
                multi_idx[d] = 1
                d += 1
            else
                break
            end
        end
        
        if d > dim
            break
        end
    end
    
    return samples
end
