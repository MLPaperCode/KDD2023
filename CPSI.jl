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

function worker(i::Int64, D::DataFrame, m::Int64, ESS::Float64, ipshi::Float64=1e-10)
    W_list = Vector{Set{Int64}}([Set{Int64}(W) for k in 0:m for W in collect(combinations(Vector{Int64}([j for j in 1:ncol(D) if j != i]), k))])
    W_list_ = copy(W_list)
    Score_list = Vector{Float64}([score(W, i, D, ESS) for W in W_list_])
    Score_list_ = copy(Score_list)
    for (h_, W_) in enumerate(W_list_)
        for (h, W) in Iterators.reverse(enumerate(W_list))
            if (issubset(W_, W) == true) & (issetequal(W_, W) == false) & (Score_list_[h_] >= (Score_list[h] - ipshi))
                deleteat!(W_list, h)
                deleteat!(Score_list, h)
            end
        end
    end
    W_list = Set{Set{Int64}}(W_list)
    println("i=", i, " completed (lambda=", length(W_list) - 1, ")")
    return W_list
end

function fit(D::DataFrame, m::Int64=ncol(D)-1, ESS::Float64=1.0)
    sort!(D)
    n = ncol(D)
    W_list = DataFrame([(if (i == (2 + n)) Float64[] else Int64[] end) for i in 1:(2 + n)], vcat(vcat(["i"], [D_ for D_ in names(D)]), ["score"]))
    for i in 1:n
        result = worker(i, D, m, ESS)
        score0 = score(Set{Int64}([]), i, D, ESS)
        for W in result
            push!(W_list, vcat(vcat([i], [(if j in W 1 else 0 end) for j in 1:n]), [score(W, i, D, ESS) - score0]))
        end
    end
    return W_list
end