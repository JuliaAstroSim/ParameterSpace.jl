# ParameterSpace.jl

## 1 功能需求

很多科研任务都需要处理一个高维参数空间。

以数值模拟领域为例，调参工作一般是**半经验性**的（类似二分法，根据经验分别取大中小三个参数进行模拟或拟合，然后根据需要的趋势选择下一组点，避免修改代码但可能十分低效）或**规范迭代**的（在一个区间内取多点进行试验，然后不断调整区间提高精度，需要修改代码，代码工作量较大）。
还有普通的参数研究工作，即仅研究参数之间的关系，无需寻找最优解，也需要手动处理。

这两种工作都需要用户手动实现参数空间的采样和后续结果的分析或选取，然而手动实现对于不熟悉数据分析和代码结构的用户来说是高成本的，比如用户需要找到所用程序中的函数接口，了解其输入输出，修改代码并重新编译和调试。在手动实现之后，用户还需要设计相应的数据处理算法

`ParameterSpace.jl`在提供必要函数接口的情况下，可以将参数空间的遍历和数据处理整合为自动流程，甚至借助自动微分、梯度下降等算法为用户提供最优参数的建议

## 2 架构设计

整体共三个主要模块
1. 目标模块（用户想要测试的函数、程序、系统，需要构建特定的输出接口）
2. 调参模块（在参数空间内调用目标模块，保留运行结果）
3. 分析模块（统计输出、绘图、寻找拐点和最优解等）

### 2.1 目标模块

#### 2.1.1 julia程序（源码）

至少要有一个可调参数，返回值最好为数值或数值数组，也可以输出文件，但要提供此类文件的分析函数

#### 2.1.2 c、python程序（源码）

可选功能，仅需增加一个调用接口

#### 2.1.3 任意外部程序（可执行）

共两种传参方式：

1. 用额外的独立函数来分析运行输出的文件
2. Linux可以在内存中使用文件传参（？）

打算支持的程序：DICE、Gadget2、FreeFem

### 2.2 调参模块

1. 函数结构、数据结构

    设目标函数共$n$个参数，要调试其中$m < n$个，所在位置为$\{a_i, i \in 1:m\}$，参数空间为$\{R_i, i \in 1:m\}$

    可以构建一个`struct`，定义`Name`是为了绘图，定义`result`是为了方便整理结果:

    ```julia
    mutable struct Parameter
        Name::String
        Index::Int64 # The location in the target function
        Range # Array or range
        result::Array{Any} # Stores the tuning result
        Parameter(Name::String, Index::Int64, Range) = new(Name, Index, Range, Any)
    end

    @inline length(p::Parameter)  = 1
    @inline iterate(p::Parameter)  = (p,nothing)
    @inline iterate(p::Parameter,st)  = nothing
    ```

    因此用户需要手动设置的有：

    1. `Params::Array{Parameter,1}`
    2. 调用目标模块的方式
        1. julia、c、python代码：函数指针
        2. 外部程序：shell命令
    3. 如果运行结果为文件，需要提供分析文件的函数指针

    与手动实现相比，十分方便

2. 参数文件

    对于`DICE`、`Gadget2`等需要依赖参数文件的程序，借助`Printf`包，在固定位置打印参数，并调用程序

3. 子文件夹输出

    对于`DICE`、`Gadget2`等会输出文件的程序，可以根据参数命名多个子文件夹

    该功能应该默认开启，但如果用户不介意文件覆盖，也可以关闭以节省磁盘空间，但不能与并行功能共存

4. **并行调参**

    大多数调参任务都可以毫无忧虑地并发运行，由于节点间数据传输极少，甚至可以通过Http并行

### 2.3 分析模块

#### 2.3.1 绘图

0. 传入`Parameter`变量，根据`result`类型选择可视化方式
1. 如果每次运行结果返回一个值，可构成$m+1$维的数据，根据三维坐标、颜色、大小、形状进行可视化
2. 对于数组型结果
    1. 一维数组（index也可以算作一维），比如旋转曲线，一般以多条曲线绘制在同一平面内
    2. 高维数组，比如坐标、场分布等，一般只能以绘图形式分析

#### 2.3.2 最优解

1. 自动微分
2. 梯度下降

### 2.4 可能遇见的问题

1. 随机性

    以n-body初始条件采样为例，同一组参数需要多次测试取平均

    参考`BenchmarkTools`，平均基数可以考虑运行时间，或手动设置

## 3 示例功能

名称、代码结构仅为粗略演示，部分代码结构甚至可能是错误的

### 3.1 黑匣子函数调参

假设有一个目标函数：

```julia
function f(args...)
    ...
    return Float64(something)
end
```

`ParameterSpace.jl`将会提供一个调参函数：

```julia
function analyse_function(f, Params::Array{Parameter,1})

end
```

显然用户仅仅需要提前设置一个`Parameter`数组：

```julia
Params = [Parameter("x", 1, [1,2,4,8])]
```

则模拟之后进行可视化:

```julia
analyse_function(f, Params)
plot(Params)
```

### 3.2 N-body初始条件调参（Gadget2）

参照上一个示例，这次的目标函数需要能够调用外部程序，以`Gadget2`为例

`ParameterSpace.jl`同样提供调参函数：

```julia
function analyse_program(command::Cmd, analyse, Params::Array{Parameter,1}; ParameterType = "file")
    if ParameterType == "file"
        ...
            # Already in the iteration body
            write_param(param)
            run(command)
            analyse(param, ...)
        ...
    end
end
```

用户需要提前设置`Parameter`数组，并告知程序调用的方式，以及分析数据的方式：

```julia
Params = [Parameter("x", 1, [1,2,4,8])]

command = `mpirun -np 4 ./Gadget2 ./galaxy.param`

function analyse(param::Parameter, ...)
    ...
end
```

则模拟之后进行可视化:

```julia
analyse_program(command, analyse, Params, ParameterType = "file")
plot(Params)
```

### 3.3 非线性拟合

可以迭代调用调参函数，自动调整参数区间和精度，以后再构思

## 4 开发计划

### 4.1 可行性试验（2019.5 - 2019.6）

基础代码架构，仅实现对julia简单函数的调参、可视化

### 4.2 扩展开发（2019.7-2019.8）

支持c、python源码调参，支持Gadget2等外部程序调参

### 4.3 科学性（after 2019.9）

最优解问题
