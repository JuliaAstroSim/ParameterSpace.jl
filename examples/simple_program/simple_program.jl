include("../../src/ParameterSpace.jl")

using .ParameterSpace

command = `julia E:/ParameterSpace.jl/examples/simple_program/print.jl`

params = [Parameter("x", 1, 0:2),
          Parameter("y", 2, 0:2)]

content = "x = %d, y = %d"

analyse_program(command, content, "param.txt", params)
