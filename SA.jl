using DataFrames, Dates, Random

function minimize(H_list::DataFrame, running_time::Float64, solver::String="SAG", T0::Float64=100.0)
    a_list = Vector{Float64}([0.0 for i in 1:max(maximum(H_list[:,1]), maximum(H_list[:,2]))])
    for i in 1:nrow(H_list)
        if H_list[i, 1] == H_list[i, 2]
            a_list[H_list[i, 1]] = H_list[i, 3]
        end
    end
    b_list = Vector{Vector{Int64}}([Vector{Int64}([]) for i in 1:max(maximum(H_list[:,1]), maximum(H_list[:,2]))])
    c_list = Vector{Vector{Float64}}([Vector{Float64}([]) for i in 1:max(maximum(H_list[:,1]), maximum(H_list[:,2]))])
    for j in 1:nrow(H_list)
        if H_list[j, 1] != H_list[j, 2]
            append!(b_list[H_list[j, 1]], H_list[j, 2])
            append!(c_list[H_list[j, 1]], H_list[j, 3])
            append!(b_list[H_list[j, 2]], H_list[j, 1])
            append!(c_list[H_list[j, 2]], H_list[j, 3])
        end
    end
    state = Vector{Int64}([0 for i in 1:max(maximum(H_list[:,1]), maximum(H_list[:,2]))])
    state_max = Vector{Int64}([0 for i in 1:max(maximum(H_list[:,1]), maximum(H_list[:,2]))])
    s = 0.0
    s_max = 0.0
    time0 = now()
    sec = (now() - time0).value / 1000
    while sec <= running_time
        for k in shuffle(Vector{Int64}([j for j in 1:max(maximum(H_list[:,1]), maximum(H_list[:,2]))]))
            delta = a_list[k]
            b_list_ = b_list[k]
            c_list_ = c_list[k]
            if length(b_list_) > 0
                for i in 1:length(b_list_)
                    delta += c_list_[i] * state[b_list_[i]]
                end
            end
            if state[k] == 1
                delta *= - 1
            end
            sec = (now() - time0).value / 1000
            if sec > running_time
                break
            end
            if solver == "SAL"
                T = T0 * max(1 - sec / running_time, 1 / T0)
            elseif solver == "SAG"
                T = T0 * max(T0^(- sec / running_time), 1 / T0)
            else
                println("Set SAL or SAG")
            end
            if rand() < exp(- delta / T)
                state[k] = 1 - state[k]
                s += delta
                if s_max < - s
                    state_max = copy(state)
                    s_max = - s
                end
            end
        end
        sec = (now() - time0).value / 1000
    end
    return state_max
end