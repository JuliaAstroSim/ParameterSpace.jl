# ParameterSpace.jl

Parameter space exploration and tuning tools for Julia. Supports function tuning, program tuning, and various sampling strategies.

[![codecov](https://codecov.io/gh/JuliaAstroSim/ParameterSpace.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaAstroSim/ParameterSpace.jl)

## Installation

```julia
using Pkg
Pkg.add("ParameterSpace")
using ParameterSpace
```

## Quick Start

### Basic Usage with ParamSpace

```julia
using ParameterSpace

# Define parameter dimensions
pspace = ParamSpace([
    ParamDim("x", values=[1, 2, 3]),
    ParamDim("y", range=(0, 10, 2))  # 0, 2, 4, 6, 8, 10
])

# Iterate over all combinations
for params in pspace
    println("x=$(params.x), y=$(params.y)")
end

# Analyze a function
f(params) = params.x * params.y
result = analyse_function(f, pspace)
```

### Sampling Strategies

For large parameter spaces, use sampling strategies:

```julia
# Random sampling
result = analyse_function(f, pspace; strategy=RandomSampling(seed=42), n_samples=100)

# Latin Hypercube Sampling (better coverage)
result = analyse_function(f, pspace; strategy=LatinHypercubeSampling(), n_samples=100)

# Sobol sequence (low discrepancy, deterministic)
result = analyse_function(f, pspace; strategy=SobolSampling(), n_samples=100)

# Grid sampling (full enumeration)
result = analyse_function(f, pspace; strategy=GridSampling())
```

### Configuration Files

Define parameter spaces in YAML or TOML:

```yaml
# params.yaml
parameters:
  x:
    values: [1, 2, 3]
    default: 2
  y:
    range: [0, 10, 2]
  z:
    linspace: [0.0, 1.0, 11]
```

```julia
pspace = load_yaml("params.yaml")
```

## Detailed Usage

### ParamDim: Parameter Dimension

`ParamDim` defines a single parameter dimension with multiple construction methods:

```julia
# Direct values
ParamDim("x", values=[1, 2, 3, 4, 5])

# Arithmetic sequence: start, stop, step
ParamDim("y", range=(0, 10, 2))  # [0, 2, 4, 6, 8, 10]

# Linearly spaced: start, stop, n points
ParamDim("z", linspace=(0.0, 1.0, 11))  # 11 points from 0 to 1

# Logarithmically spaced: 10^a to 10^b, n points
ParamDim("w", logspace=(-1, 1, 5))  # [0.1, 1.0, 10.0]

# With default value and mask
ParamDim("x", values=[1,2,3,4,5], default=3, mask=[true, false, true, true, false])
```

### ParamSpace: Multi-dimensional Parameter Space

```julia
# From vector
pspace = ParamSpace([
    ParamDim("x", values=[1, 2, 3]),
    ParamDim("y", values=[1, 2])
])

# From dictionary
pspace = ParamSpace(Dict(
    "x" => ParamDim("x", values=[1, 2, 3]),
    "y" => ParamDim("y", values=[1, 2])
))

# Properties
volume(pspace)   # Total combinations: 6
shape(pspace)    # (3, 2)
dim_names(pspace) # [:x, :y]

# State management for resumable iteration
set_state!(pspace, 10)  # Jump to state 10
state_no(pspace)        # Current state number
reset!(pspace)          # Reset to beginning
```

### Masking and Subspace Selection

Filter parameter values using masks:

```julia
pspace = ParamSpace([
    ParamDim("x", values=[1, 2, 3, 4, 5]),
    ParamDim("y", values=[10, 20, 30])
])

# Mask specific values
set_mask!(pspace, :x, [true, false, true, false, true])  # Only 1, 3, 5

# Activate a subspace by conditions
activate_subspace!(pspace, Dict("x" => [1, 3, 5]))  # Only odd x values
activate_subspace!(pspace, Dict("x" => [1, 2], "y" => 10))  # x in [1,2] and y=10

# Clear masks
clear_mask!(pspace, :x)
clear_all_masks!(pspace)
```

### Coupled Parameters

Synchronize parameters with coupled dimensions:

```julia
pspace = ParamSpace([
    ParamDim("x", values=[1, 2, 3])
])

# Add coupled dimension: x_squared follows x
add_coupled!(pspace, CoupledParamDim("x_squared", target=:x, values=[1, 4, 9]))

for params in pspace
    # params.x and params.x_squared are synchronized
    # x=1 → x_squared=1, x=2 → x_squared=4, x=3 → x_squared=9
end
```

### Analyzing Functions

```julia
# New API: function receives NamedTuple
f(params) = params.x * params.y + params.z

pspace = ParamSpace([
    ParamDim("x", values=[1, 2]),
    ParamDim("y", values=[1, 2]),
    ParamDim("z", values=[0, 1])
])

result = analyse_function(f, pspace; folder="output", filename="results.csv")

# With parallel execution (multi-threaded)
result = analyse_function(f, pspace; parallel=:threads)

# With extra arguments and keyword arguments
g(params, scale=1) = params.x * scale
result = analyse_function(g, pspace; scale=2)
```

### Analyzing External Programs

```julia
# Define command to run
command = `julia simulation.jl`

# Parameter file format (printf-style)
content = "x = %d, y = %d"

# Analysis function to extract results
function analyse()
    data = readlines("output.txt")
    return parse(Float64, data[1])
end

pspace = ParamSpace([
    ParamDim("x", values=[1, 10, 100]),
    ParamDim("y", values=[1000, 10000])
])

result = analyse_program(command, content, "param.txt", pspace, analyse;
    folder="output", filename="results.csv")
```

### Experiment Data Management

Manage experimental data, constraints, and analysis results:

```julia
using ParameterSpace

# Create a dataset for experimental data
ds = DataSet{ExperimentData}("axion-mass-constraints")

# Add experiment data points
add!(ds, ExperimentData(
    DataSource(citekey="Smith2020", paper="Axion Search", 
               year=2020, method="Haloscope"),
    params=(mass=1e-6, coupling=1e-12),
    results=(sigma=2.5,),
    uncertainty=(sigma=0.3,)
))

# Add constraint data
add!(ds, ConstraintData(
    DataSource(citekey="Jones2021", paper="Dark Matter Limits", 
               year=2021, method="CMB"),
    param=:mass,
    lower=1e-9, upper=1e-7,
    constraint_type=:exclude
))

# Query and filter data
subset = filter(ds) do e
    e.source.year >= 2020 && haskey(e.params, :mass)
end

# Statistical analysis
stats = compute_statistics(ds, :sigma)
# Returns: mean, std, median, min, max, count

# Find gaps in parameter space coverage
gaps = find_gaps(ds, pspace; n_gaps=10)
```

### Data Sources and Citations

Track data provenance with `DataSource`:

```julia
source = DataSource(
    citekey="Smith2020",
    paper="Axion Dark Matter Search",
    year=2020,
    method="Haloscope",
    notes="First results from new detector"
)

# Access source information
source.citekey  # "Smith2020"
source.year     # 2020
source.method   # "Haloscope"
```

## Legacy API (Backward Compatibility)

The original `Parameter` type is still supported:

```julia
# Legacy parameter definition
params = [
    Parameter("x", 1, 0:2),  # name, index, range
    Parameter("y", 2, 0:2)
]

# Function receives arguments in order specified by Parameter.Index
g(x, y) = x * y
result = analyse_function(g, params)

# Partial tuning (fix some parameters)
params = [Parameter("y", 2, 0:0.1:0.5)]
result = analyse_function(g, params, 1.0)  # x is fixed at 1.0
```

## Sampling Strategies Comparison

| Strategy | Use Case | Pros | Cons |
|----------|----------|------|------|
| `GridSampling` | Small spaces, exhaustive search | Complete coverage | Exponential growth |
| `RandomSampling` | Quick exploration | Simple, fast | Uneven coverage |
| `LatinHypercubeSampling` | Medium-dimensional spaces | Good 1D projection | Not optimal for high dimensions |
| `SobolSampling` | High-dimensional spaces | Low discrepancy, deterministic | Requires Sobol.jl |
| `StratifiedGridSampling` | Large spaces, quick overview | Sparse but uniform | May miss important regions |

## API Reference

### Types
- `ParamDim{T}`: Parameter dimension
- `ParamSpace`: Multi-dimensional parameter space
- `CoupledParamDim{T}`: Coupled parameter dimension
- `Parameter{A}`: Legacy parameter type

### Experiment Data Types
- `DataSet{T}`: Generic dataset container
- `ExperimentData`: Experimental data point with params, results, and uncertainty
- `ConstraintData`: Constraint data with parameter bounds
- `DataSource`: Source metadata (citekey, paper, year, method, notes)
- `GapRegion`: Gap region in parameter space with center and priority

### Sampling Strategies
- `AbstractSamplingStrategy`: Abstract base type
- `RandomSampling(seed=nothing)`: Random uniform sampling
- `LatinHypercubeSampling(seed=nothing)`: Latin Hypercube Sampling
- `SobolSampling()`: Sobol quasi-random sequence
- `GridSampling()`: Complete grid traversal
- `StratifiedGridSampling(resolution)`: Sparse grid sampling

### Functions
- `analyse_function(f, pspace; strategy, n_samples, parallel, ...)`: Analyze function over parameter space
- `analyse_program(cmd, content, paramfile, pspace, analyse; ...)`: Analyze external program
- `sample(pspace, strategy; n)`: Sample points from parameter space
- `load_yaml(filepath)`, `load_toml(filepath)`: Load from config files
- `save_yaml(pspace, filepath)`, `save_toml(pspace, filepath)`: Save to config files

### Experiment Data Functions
- `add!(dataset, data)`: Add data to dataset
- `filter(f, dataset)`: Filter dataset with predicate
- `compute_statistics(dataset, field)`: Compute statistics for a field
- `find_gaps(dataset, pspace; n_gaps)`: Find gaps in parameter space coverage
- `get_param(data, param)`: Get parameter value
- `get_result(data, result)`: Get result value
- `source(data)`: Get data source information

## Examples

See the `examples/` directory for more detailed examples:
- `simple_function.jl`: Basic function tuning
- `simple_program/`: External program tuning

