directory = "./" # directory
data = "pathfinder" # dataset
N = 1000 # number of instances
m = 3 # maximum size of parent set

using DataFrames, Feather, CSV, Dates
include(directory * "CPSD.jl")
running_time = DataFrame([Float64[]], ["running_time"])
for num in 1:5
    println("num=", string(num), " start")
    D = CSV.read(directory * data * "/D_" * data * "_" * string(N) * "_" * string(num) * ".csv", DataFrame)
    W_list = CSV.read(directory * data * "/W_" * data * "_" * string(N) * "_" * string(m) * "_" * string(num) * ".csv", DataFrame)
    time0 = now()
    U_list = fit(D, W_list, 1.0)
    push!(running_time, (now() - time0).value / 1000)
    CSV.write(directory * data * "/U_" * data * "_" * string(N) * "_" * string(m) * "_" * string(num) * ".csv", U_list)
    println("num=", string(num), " completed")
end
CSV.write(directory * data * "/Time_CPSD_" * data * "_" * string(N) * "_" * string(m) * ".csv", running_time)