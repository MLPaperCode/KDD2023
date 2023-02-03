using DataFrames, Dates, Random

function ASOBS(W_list::DataFrame, V::Vector{Int64})
    s = 0.0
    s_ = 0.0
    arrow = zeros(Int64, length(V), length(V))
    for i_ in 1:length(V)
        i = V[i_]
        W_list_ = sort(W_list[W_list[:,1].==i, :], "score")
        for i__ in 1:nrow(W_list_)
            arrow_ = copy(arrow)
            parent = W_list_[i__, 2:(ncol(W_list_)-1)]
            for j in 1:length(parent)
                if parent[j] == 1
                    arrow_[j, i] = 1
                    for j_ in 1:length(V)
                        if arrow_[j_, j] == 1
                            arrow_[j_, i] = 1
                        end
                        if arrow_[i, j_] == 1
                            arrow_[j, j_] = 1
                        end
                        for j__ in 1:length(V)
                            if arrow_[j_, j] == 1 & arrow_[i, j__] == 1
                                arrow_[j_, j__] = 1
                            end
                        end
                    end
                end
            end
            if sum(arrow_ .* transpose(arrow_)) == 0
                s_ = W_list_[i__, ncol(W_list_)]
                arrow = copy(arrow_)
                break
            end
        end
        s = s + s_
    end
    return s
end

function OBS(W_list::DataFrame, V::Vector{Int64})
    s = 0.0
    for i_ in 1:length(V)
        i = V[i_]
        W_list_ = sort(W_list[W_list[:, 1].==i, :], "score")
        for i__ in 1:length(V)
            if i__ >= i_
                break
            else
                W_list_ = W_list_[W_list_[:, 1 + V[i__]].==0,:]
            end
        end
        s = s + W_list_[1, ncol(W_list_)]
    end
    return s
end

function optimize(W_list::DataFrame, solver::String, running_time::Float64)
    W_list[:, ncol(W_list)] = - W_list[:, ncol(W_list)]
    time0 = now()
    V = shuffle(Vector{Int64}([j for j in 1:ncol(W_list)-2]))
    if solver == "ASOBS"
        s = ASOBS(W_list, V)
    else
        s = OBS(W_list, V)
    end
    sec = (now() - time0).value / 1000
    while sec <= running_time
        V__ = copy(V)
        for c in 1:length(V)-1
            V_ = copy(V)
            V_[c] = V[c+1]
            V_[c+1] = V[c]
            if solver == "ASOBS"
                s_ = ASOBS(W_list, V_)
            else
                s_ = OBS(W_list, V_)
            end
            sec = (now() - time0).value / 1000
            if sec > running_time
                break
            end
            if s > s_
                V__ = copy(V_)
                s = s_
            end
        end
        if V__ == V
            V = shuffle(Vector{Int64}([j for j in 1:ncol(W_list)-2]))
        else
            V = copy(V__)
        end
        sec = (now() - time0).value / 1000
    end
    return - s
end