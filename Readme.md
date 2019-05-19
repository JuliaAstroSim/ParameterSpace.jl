# ParameterSpace.jl

General tuning tools

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
result = analyse_function(g, params)
```

The returns are stored by `DataFrames` to give you enough freedom in data processing

```julia
result = 9×3 DataFrames.DataFrame
│ Row │ x   │ y   │ result │
│     │ Any │ Any │ Any    │
├─────┼─────┼─────┼────────┤
│ 1   │ 0   │ 0   │ 0      │
│ 2   │ 1   │ 0   │ 0      │
│ 3   │ 2   │ 0   │ 0      │
│ 4   │ 0   │ 1   │ 0      │
│ 5   │ 1   │ 1   │ 1      │
│ 6   │ 2   │ 1   │ 2      │
│ 7   │ 0   │ 2   │ 0      │
│ 8   │ 1   │ 2   │ 2      │
│ 9   │ 2   │ 2   │ 4      │
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
