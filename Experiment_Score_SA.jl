directory = "./" # directory
data = "alarm" # dataset
N = 1000 # number of instances
m = 3 # maximum size of parent set
solver = "SA1" # SA1 = SA with Decomposition or SA2 = SA without Decomposition
running_time = 600.0 # running time [s]

using DataFrames, CSV, LightGraphs
include(directory * "SA.jl")
score_list = DataFrame([Float64[]], ["score"]) 
for num in 1:5
    if solver == "SA1"
        A_list = CSV.read(directory * data * "/A_" * data * "_" * string(N) * "_" * string(m) * "_" * string(num) * ".csv", DataFrame)
        U_list = CSV.read(directory * data * "/U_" * data * "_" * string(N) * "_" * string(m) * "_" * string(num) * ".csv", DataFrame)
        H_list = CSV.read(directory * data * "/H_" * data * "_" * string(N) * "_" * string(m) * "_" * string(num) * ".csv", DataFrame)
        state = minimize(H_list, running_time)
    elseif solver == "SA2"
        A_list = CSV.read(directory * data * "/A2_" * data * "_" * string(N) * "_" * string(m) * "_" * string(num) * ".csv", DataFrame)
        W_list = CSV.read(directory * data * "/W_" * data * "_" * string(N) * "_" * string(m) * "_" * string(num) * ".csv", DataFrame)
        H_list = CSV.read(directory * data * "/H2_" * data * "_" * string(N) * "_" * string(m) * "_" * string(num) * ".csv", DataFrame)
        U_list = DataFrame([(if (i == ncol(W_list)) Float64[] else Int64[] end) for i in 1:ncol(W_list)], [W for W in names(W_list)])
        for h in 1:nrow(W_list)
            if sum(W_list[h, 2:(ncol(W_list) - 1)]) > 0
                push!(U_list, [W_list[h, i] for i in 1:ncol(W_list)])
            end
        end    
        running_time_CPSD = CSV.read(directory * data * "/Time_CPSD_" * data * "_" * string(N) * "_" * string(m) * ".csv", DataFrame)
        state = minimize(H_list, running_time + running_time_CPSD[num,1])
    end
    n = ncol(U_list) - 2
    for i in 1:n
        count = 0
        for h in 1:nrow(U_list)
            if (state[h] == 1) & (U_list[h, 1] == i)
                count += 1
            end
        end
        if count > 2
            println("Constraint Error")
        end
    end
    G = SimpleDiGraph(n)
    for h in 1:nrow(U_list)
        if state[h] == 1
            for i in 1:n
                if U_list[h, 1 + i] == 1
                    add_edge!(G, i, U_list[h, 1])
                end
            end
        end
    end
    if is_cyclic(G) == true
        println("Constraint Error")
    end
    s = 0.0
    for h in 1:nrow(A_list)
        if (state[A_list[h, 1]] == 1) & (state[A_list[h, 2]] == 1)
            s -= A_list[h, 3]
        end
    end
    println("score=", s)
    push!(score_list, s)
end
CSV.write(directory * data * "/Score_" * solver * "_" * string(Int64(running_time)) * "_" * data * "_" * string(N) * "_" * string(m) * ".csv", score_list)