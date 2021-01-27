using ParameterSpace

command = `julia E:/ParameterSpace.jl/examples/simple_program/print.jl`

params = [Parameter("x", 1, [1,10,100]),
          Parameter("y", 2, [1000,10000,100000])]

content = "x = %d, y = %d"

println("\nAnalyse a program without returns")
analyse_program(command, content, "param.txt", params)

function analyse(x::Int)
    f = readlines("param.txt")
    return length(f[1]) + x
end

println("\nAnalyse a program with returns")
tuning = analyse_program(command, content, "param.txt", params, analyse, args = [-15])

@show tuning
