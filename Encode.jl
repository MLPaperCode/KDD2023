using DataFrames

function worker(i::Int64, W_list::DataFrame, U_list::DataFrame, penalty_ratio::Float64)
    n = ncol(W_list) - 2    
    H_list_ = DataFrame([Int64[], Int64[], Float64[]], ["num1", "num2", "coefficient"])
    A_list_ = DataFrame([Int64[], Int64[], Float64[]], ["num1", "num2", "coefficient"])
    W_list_ = W_list[W_list.i.== i, :]  
    U_list_ = U_list[U_list.i.== i, :]
    count1 = nrow(U_list[U_list.i.< i, :])
    count2 = nrow(U_list) + binomial(n, 2) + sum(Vector{Int64}([1 for j in 1:i if nrow(U_list[U_list.i.== j, :]) > 2]))
    if nrow(U_list_) > 1
        xi = 0
        W_list__ = Vector{Set{Int64}}([Set{Int64}([k for k in 1:n if W_list_[j, 1 + k] == 1]) for j in 1:nrow(W_list_)])
        if nrow(U_list_) > 2
            xi = 3.0 * maximum(U_list_[:, ncol(U_list_)]) * penalty_ratio
            push!(H_list_, vcat([count2, count2], [xi]))
            for h in 1:nrow(U_list_)
                push!(H_list_, vcat([count2, count1 + h], [- xi]))
            end
        end
        for h in 1:(nrow(U_list_))
            for h_ in (h + 1):nrow(U_list_)
                U = Set{Int64}([k for k in 1:n if (U_list_[h, 1 + k] + U_list_[h_, 1 + k]) > 0])
                A = U_list_[h, ncol(U_list_)] + U_list_[h_, ncol(U_list_)]
                if U in W_list__
                    for j in 1:nrow(W_list_)
                        if issetequal(U, W_list__[j]) == true
                            A = - W_list_[j, ncol(W_list_)] + U_list_[h, ncol(U_list_)] + U_list_[h_, ncol(U_list_)]
                            break
                        end
                    end
                end
                push!(H_list_, vcat([count1 + h_, count1 + h], [A + xi]))
                push!(A_list_, vcat([count1 + h_, count1 + h], [A]))
            end
        end
    end
    return H_list_, A_list_
end

function fit(W_list::DataFrame, U_list::DataFrame, penalty_ratio::Float64=1.1)
    n = ncol(W_list) - 2
    H_list = DataFrame([Int64[], Int64[], Float64[]], ["num1", "num2", "coefficient"])
    A_list = DataFrame([Int64[], Int64[], Float64[]], ["num1", "num2", "coefficient"])
    C_list = DataFrame([Int64[], Int64[], Float64[]], ["num1", "num2", "coefficient"])
    for i in 1:n
        result = worker(i, W_list, U_list, penalty_ratio)
        H_list = vcat(H_list, result[1])
        A_list = vcat(A_list, result[2])
    end
    size1 = nrow(U_list)
    size2 = binomial(n, 2)
    delta1 = ceil(maximum(W_list[:, ncol(W_list)]) * penalty_ratio)
    delta2 = ceil((n - 2) * delta1 * penalty_ratio)
    for h in 1:nrow(U_list)
        push!(A_list, vcat([h, h], [- U_list[h, ncol(U_list)]]))
        if U_list[h, 1] > 1
            push!(H_list, vcat([h, h], [- U_list[h, ncol(U_list)] + sum([1 for i in 1:(U_list[h, 1] - 1) if U_list[h, i + 1] == 1]) * delta2]))
            push!(C_list, vcat([h, h], [sum([1 for i in 1:(U_list[h, 1] - 1) if U_list[h, i + 1] == 1]) * delta2]))
        else
            push!(H_list, vcat([h, h], [- U_list[h, ncol(U_list)]]))
        end
    end
    for i in 1:(n - 2)
        for j in (i + 1):(n - 1)
            for k in (j + 1):n
                push!(H_list, vcat([size1 + binomial(j - 1, 2) + i, size1 + binomial(k - 1, 2) + j], [delta1]))
                push!(H_list, vcat([size1 + binomial(j - 1, 2) + i, size1 + binomial(k - 1, 2) + i], [- delta1]))
                push!(H_list, vcat([size1 + binomial(k - 1, 2) + j, size1 + binomial(k - 1, 2) + i], [- delta1]))
                push!(C_list, vcat([size1 + binomial(j - 1, 2) + i, size1 + binomial(k - 1, 2) + j], [delta1]))
                push!(C_list, vcat([size1 + binomial(j - 1, 2) + i, size1 + binomial(k - 1, 2) + i], [- delta1]))
                push!(C_list, vcat([size1 + binomial(k - 1, 2) + j, size1 + binomial(k - 1, 2) + i], [- delta1]))
            end
        end
    end
    for i in 1:(n - 2)
        for k in (i + 2):n
            push!(H_list, vcat([size1 + binomial(k - 1, 2) + i, size1 + binomial(k - 1, 2) + i], [(k - i - 1) * delta1]))
            push!(C_list, vcat([size1 + binomial(k - 1, 2) + i, size1 + binomial(k - 1, 2) + i], [(k - i - 1) * delta1]))
        end
    end
    for i in 1:(n - 1)
        for j in (i + 1):n
            count1 = nrow(U_list[U_list.i.< i, :])
            count2 = nrow(U_list[U_list.i.< j, :])
            U_list1 = U_list[U_list.i.== i, :]
            U_list2 = U_list[U_list.i.== j, :]
            if nrow(U_list1) > 0               
                for h in 1:nrow(U_list1)
                    if U_list1[h, 1 + j] == 1
                        push!(H_list, vcat([size1 + binomial(j - 1, 2) + i, count1 + h], [delta2]))
                        push!(C_list, vcat([size1 + binomial(j - 1, 2) + i, count1 + h], [delta2]))
                    end
                end
            end
            if nrow(U_list2) > 0                
                for h in 1:nrow(U_list2)
                    if U_list2[h, 1 + i] == 1
                        push!(H_list, vcat([size1 + binomial(j - 1, 2) + i, count2 + h], [- delta2]))
                        push!(C_list, vcat([size1 + binomial(j - 1, 2) + i, count2 + h], [- delta2]))
                    end
                end
            end
        end
    end
    H_list.num1 = convert.(Int64, H_list.num1)
    H_list.num2 = convert.(Int64, H_list.num2)
    A_list.num1 = convert.(Int64, A_list.num1)
    A_list.num2 = convert.(Int64, A_list.num2)
    C_list.num1 = convert.(Int64, C_list.num1)
    C_list.num2 = convert.(Int64, C_list.num2)
    return H_list, A_list, C_list
end