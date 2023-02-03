using DataFrames, Combinatorics, SpecialFunctions

function score(parents::Set{Int64}, i::Int64, D::DataFrame, ESS::Float64)
    num_i_states = length(Set(D[:,i]))
    state_counts = combine(DataFrames.groupby(D, names(D)[[j for j in parents]]), names(D)[i] => x -> [sum(x.==s) for s in Set(D[:,i])])
    state_counts = convert(Vector{Int64}, state_counts[:,ncol(state_counts)])
    num_parents_states = Int64(length(state_counts) / num_i_states)
    state_counts = reshape(state_counts, (num_i_states, num_parents_states))
    alpha = ESS / Float64(num_parents_states)
    beta = ESS / (Float64(num_parents_states) * Float64(num_i_states))
    score_ = 0.0
    score_ = score_ + sum([loggamma(state_counts[k,j] + beta) for j in 1:num_parents_states for k in 1:num_i_states])
    score_ = score_ - sum([loggamma(sum(state_counts[:,j]) + alpha) for j in 1:num_parents_states])
    score_ = score_ + Float64(num_parents_states) * loggamma(alpha) 
    score_ = score_ - Float64(num_parents_states) * Float64(num_i_states) * loggamma(beta) 
    return score_
end

function worker(i::Int64, W_list::DataFrame)
    n = ncol(W_list) - 2
    Wset = Set{Set{Int64}}([Set{Int64}([k for k in 1:n if W_list[j, 1 + k] == 1]) for j in 1:nrow(W_list)])
    Uset = Set{Set{Int64}}([W for W in Wset if length(W) <= 1])
    Wset = setdiff(Wset, Set{Set{Int64}}([union(U, U_) for U in Uset for U_ in Uset]))
    Vset = Set{Set{Int64}}([V for W in Wset for V in Set{Set{Int64}}([Set{Int64}(V_) for k in 0:length(W) for V_ in collect(combinations(Vector{Int64}([j for j in W]), k))]) if !(V in Uset)])
    Wset_ = copy(Wset)
    kapa = length(Wset)
    while Wset != Set{Set{Int64}}([])
        Vset = setdiff(Vset, Set{Set{Int64}}([V for W in Wset_ for V in Set{Set{Int64}}([Set{Int64}(V_) for k in 0:length(W) for V_ in collect(combinations(Vector{Int64}([j for j in W]), k))]) if (V in Vset) & (length(Set{Set{Int64}}([W_ for W_ in Wset if issubset(V, W_) == true])) == 1)]))
        Wset_ = Set{Set{Int64}}([])
        V_ = Set{Int64}([])
        kapa_ = 0
        for V in Vset
            Wset__ = intersect(Wset, Set{Set{Int64}}([union(U, V) for U in Uset]))
            if length(Wset__) > length(Wset_)
                Wset_ = copy(Wset__)
                V_ = copy(V)
                kapa_ = length(Wset__)
            end
            if kapa_ >= kapa
                break
            end
        end
        if Wset_ != Set{Set{Int64}}([])
            Uset = union(Uset, Set{Set{Int64}}([V_]))
            Vset = setdiff(Vset, Set{Set{Int64}}([V_]))
            Wset = setdiff(Wset, Wset_)
            if V_ in Set{Set{Int64}}([V for W in Wset for V in Set{Set{Int64}}([Set{Int64}(V_) for k in 0:length(W) for V_ in collect(combinations(Vector{Int64}([j for j in W]), k))])])
                kapa = length(Wset_) + 1
            else
                kapa = length(Wset_)
            end
        else
            Uset = union(Uset, Wset)
            Wset = Set{Set{Int64}}([])
        end
    end
    println("i=", i, " completed (lambda=", nrow(W_list) - 1, " mu=", length(Uset) - 1, ")")
    return Uset
end

function fit(D::DataFrame, W_list::DataFrame, ESS::Float64=1.0)
    n = ncol(W_list) - 2    
    U_list = DataFrame([(if (i == (2 + n)) Float64[] else Int64[] end) for i in 1:(2 + n)], names(W_list))
    for i in 1:n
        result = worker(i, W_list[W_list.i.== i, :])
        score0 = score(Set{Int64}([]), i, D, ESS)
        W_list_ = W_list[W_list.i.== i, :]
        W_list__ = Vector{Set{Int64}}([Set{Int64}([k for k in 1:n if W_list_[j, 1 + k] == 1]) for j in 1:nrow(W_list_)])
        for U in result
            if U != Set{Int64}([])
                if U in W_list__
                    push!(U_list, vcat(vcat([i], [(if j in U 1 else 0 end) for j in 1:n]), [score(U, i, D, ESS) - score0]))
                else
                    push!(U_list, vcat(vcat([i], [(if j in U 1 else 0 end) for j in 1:n]), [0.0]))
                end
            end
        end
    end
    return U_list
end