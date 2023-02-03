directory = "./" # directory
data = "alarm" # dataset
N = 1000 # number of instances
m = 3 # maximum size of parent set

using DataFrames, Feather, CSV
include(directory * "Encode.jl")
for num in 1:5
    println("num=", string(num), " start")
    W_list = CSV.read(directory * data * "/W_" * data * "_" * string(N) * "_" * string(m) * "_" * string(num) * ".csv", DataFrame)
    U_list = CSV.read(directory * data * "/U_" * data * "_" * string(N) * "_" * string(m) * "_" * string(num) * ".csv", DataFrame)
    H_list, A_list, C_list = fit(W_list, U_list, 1.1)
    U2_list = DataFrame([(if (i == ncol(W_list)) Float64[] else Int64[] end) for i in 1:ncol(W_list)], [W for W in names(W_list)])
    for h in 1:nrow(W_list)
        if sum(W_list[h, 2:(ncol(W_list) - 1)]) > 0
            push!(U2_list, [W_list[h, i] for i in 1:ncol(W_list)])
        end
    end
    H2_list, A2_list, C2_list = fit(W_list, U2_list, 1.1)
    CSV.write(directory * data * "/H_" * data * "_" * string(N) * "_" * string(m) * "_" * string(num) * ".csv", H_list)
    CSV.write(directory * data * "/A_" * data * "_" * string(N) * "_" * string(m) * "_" * string(num) * ".csv", A_list)
    CSV.write(directory * data * "/C_" * data * "_" * string(N) * "_" * string(m) * "_" * string(num) * ".csv", C_list)
    CSV.write(directory * data * "/H2_" * data * "_" * string(N) * "_" * string(m) * "_" * string(num) * ".csv", H2_list)
    CSV.write(directory * data * "/A2_" * data * "_" * string(N) * "_" * string(m) * "_" * string(num) * ".csv", A2_list)
    CSV.write(directory * data * "/C2_" * data * "_" * string(N) * "_" * string(m) * "_" * string(num) * ".csv", C2_list)
    println("num=", string(num), " completed")
end