# ParameterSpace.jl

General tuning tools for julia. Dive into the parameter space of functions or external programs.

[![codecov](https://codecov.io/gh/JuliaAstroSim/ParameterSpace.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaAstroSim/ParameterSpace.jl)

## Install

```julia
]add ParameterSpace
using ParameterSpace
```

## Usage

Examples could be found in folder `examples`

### Tuning a function

Let's take a simple function for example:

```julia
@inline g(x::Real, y::Real) = x * y
```

First construct the parameter space:

```julia
params = [Parameter("x", 1, 0:2),
          Parameter("y", 2, 0:2)]
```

which means there would be $3 \times 3 = 9$ combination of parameters in total, and `ParameterSpace` would help you run tests over all of them by calling the target function iterately:

```julia
tuning = analyse_function(g, params)
```

The returns are stored by `DataFrames` to give you enough freedom in data processing

```julia
julia> tuning = analyse_function(g, params)
9×3 DataFrame
 Row │ x    y    result 
     │ Any  Any  Any    
─────┼──────────────────
   1 │ 0    0    0
   2 │ 1    0    0
   3 │ 2    0    0
   4 │ 0    1    0
   5 │ 1    1    1
   6 │ 2    1    2
   7 │ 0    2    0
   8 │ 1    2    2
   9 │ 2    2    4
```

If only tuning the second parameter `y` of function `g`, the other parameters should be set in order:
```julia
params = [Parameter("y", 2, 0:0.1:0.5)]
```

```julia
julia>     result = analyse_function(g, params, 1.0)
6×2 DataFrame
 Row │ y    result 
     │ Any  Any    
─────┼─────────────
   1 │ 0.0  0.0
   2 │ 0.1  0.1
   3 │ 0.2  0.2
   4 │ 0.3  0.3
   5 │ 0.4  0.4
   6 │ 0.5  0.5
```

### Tuning a program

It is assumed that all of the parameters are passed through parameter file. First you need to tell `ParameterSpace` how to run your program, by define a `Cmd`:

```julia
command = `julia E:/ParameterSpace.jl/examples/simple_program/print.jl`
```

It may cause issues if you do not run the program from an absolute path.

Then write down the content of parameter file in formatted string:

```julia
content = "x = %d, y = %d"
```

Construct parameter space and use the tuning tool:

```julia
params = [Parameter("x", 1, 0:2),
          Parameter("y", 2, 0:2)]

analyse_program(command, content, "param.txt", params)
```

where `"param.txt"` defines the name of parameter file.

Each set of parameters would be handled in a seperate sub-folder

There is no general way to pass data from a program to Julia, however it's easy and convenient to analyse the output files automatically if you could provide an anlysis function. The procedure has no difference from tuning a function, and the parameters of analysis function could be set with keyword `args::Union{Tuple,Array}`:

```julia
function analyse(args...)
    ...
    return ...
end

analyse_program(command, content, "param.txt", params, analyse, args = [])
```

more details in `examples/simple_program/`
