include("../src/ParameterSpace.jl")

using .ParameterSpace

function test()
    command = `bash ./test.sh`

    dir = "/home/mry1234/mry1234/Gadget2-MOND/Gadget2-MOND/build"
    content = "export OMP_NUM_THREADS=%d
               mpirun -np %d $dir/Gadget2-MOND /home/mry1234/ParameterSpace.jl/examples/galaxy.param"

    params = [Parameter("proc_mpi", 1, 1:6),
              Parameter("proc_openmp", 2, 2:5)]

    function analyse()
        f = readlines("qumond_timing.txt")
        t, dt = split(f[2])
        return parse(Float64, dt)
    end

    return result = analyse_program(command, content, "test.sh", params, analyse)
end
