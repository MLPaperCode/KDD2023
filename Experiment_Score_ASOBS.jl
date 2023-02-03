directory = "./" # directory
data = "alarm" # dataset
N = 1000 # number of instances
m = 3 # maximum size of parent set
solver = "OBS" # "ASOBS" or "OBS"
running_time = 600.0 # running time [s]

using DataFrames, CSV
include(directory * "OBS.jl")
running_time_CPSD = CSV.read(directory * data * "/Time_CPSD_" * data * "_" * string(N) * "_" * string(m) * ".csv", DataFrame)
score_list = DataFrame([Float64[]], ["score"]) 
for num in 1:5
    W_list = CSV.read(directory * data * "/W_" * data * "_" * string(N) * "_" * string(m) * "_" * string(num) * ".csv", DataFrame)
    s = optimize(W_list, solver, running_time + running_time_CPSD[num,1])
    push!(score_list, s)
    println("score=", s)
end
CSV.write(directory * data * "/Score_" * solver * "_" * string(Int64(running_time)) * "_" * data * "_" * string(N) * "_" * string(m) * ".csv", score_list)