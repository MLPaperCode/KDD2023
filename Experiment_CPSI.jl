directory = "./" # directory
data = "alarm" # dataset
N = 1000 # number of instances
m = 3 # maximum size of parent set

using DataFrames, Feather, CSV
include(directory * "CPSI.jl")
for num in 1:5
    println("num=", string(num), " start")
    D = CSV.read(directory * data * "/D_" * data * "_" * string(N) * "_" * string(num) * ".csv", DataFrame)
    W_list = fit(D, m, 1.0)
    CSV.write(directory * data * "/W_" * data * "_" * string(N) * "_" * string(m) * "_" * string(num) * ".csv", W_list)
    println("num=", string(num), " completed")
end