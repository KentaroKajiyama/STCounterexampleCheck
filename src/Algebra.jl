module Algebra

export generate_embedding, generate_matrix, compute_rank

using LinearAlgebra
using Random
using Graphs
using ..Types

# Mersenne prime p = 2^31 - 1
const P = 2147483647

"""
    generate_embedding(n::Int, t::Int, seed::Union{Int, Nothing}=nothing)

Generates a random embedding of n vertices into Z_p^t.
Returns a tuple (embedding, seed).
The embedding is an n x t matrix where row i corresponds to vertex i.
"""
function generate_embedding(n::Int, t::Int, seed::Union{Int,Nothing}=nothing)
    # Generate a seed if not provided
    if seed === nothing
        seed = abs(rand(Int))
    end
    
    # Initialize RNG with the seed for reproducibility
    rng = MersenneTwister(seed)
    
    # Generate random values in [0, P-1]
    # Result is an n x t matrix (rows are vertices, cols are dimensions)
    return rand(rng, 0:P-1, n, t), seed
end

"""
    generate_matrix(g::AbstractGraph, embedding::Embedding)

Generates the symmetric tensor matrix M and the column mapping phi.
M has size (t(t+1)/2) x |E(G)|.
phi is a list of edges corresponding to columns, sorted lexicographically to ensure consistency.
"""
function generate_matrix(g::AbstractGraph, embedding::Embedding)
    n, t = size(embedding)
    
    # Enforce the universal rule:
    # Edges must be sorted lexicographically by (src, dst) with src < dst.
    # Graphs.jl's SimpleGraph stores edges such that src <= dst.
    # We explicitly sort them here to ensure deterministic column ordering.
    edges_list = collect(edges(g))
    sort!(edges_list, by = e -> (src(e), dst(e)))
    
    m = length(edges_list)
    row_dim = (t * (t + 1)) ÷ 2
    
    M = zeros(Int, row_dim, m)
    phi = Vector{Edge}(undef, m)

    # Precompute indices for symmetric tensor elements (upper triangular)
    # Order: (1,1), (1,2), ..., (1,t), (2,2), ..., (t,t)
    idx_map = Tuple{Int,Int}[]
    for r in 1:t
        for c in r:t
            push!(idx_map, (r, c))
        end
    end

    for (k, e) in enumerate(edges_list)
        u, v = src(e), dst(e)
        phi[k] = e # Store the edge in the mapping for verification if needed

        pu = embedding[u, :]
        pv = embedding[v, :]

        # Calculate Symmetric Tensor Vector (STV)
        # The STV component for (i, j) is defined as: p_u[i]*p_v[j] + p_v[i]*p_u[j]
        # We perform calculations modulo P.
        
        for (row_idx, (i, j)) in enumerate(idx_map)
            # Use widemul to prevent overflow before modulo operation.
            # Int is 64-bit, P is 2^31-1, so product fits in Int64, 
            # but sum of products might exceed slightly, so we use logic carefully or widemul.
            # (P-1)^2 approx 4.6e18, Int64 max approx 9e18. Safe, but widemul is robust.
            val = (widemul(pu[i], pv[j]) + widemul(pv[i], pu[j])) % P
            M[row_idx, k] = Int(val)
        end
    end

    return M, phi
end

"""
    compute_rank(M::STM)

Computes the rank of matrix M over Z_p using Gaussian elimination.
"""
function compute_rank(M::STM)
    # Perform Gaussian elimination over Z_p (Field)
    # We work on a copy to avoid modifying the original matrix
    A = copy(M)
    rows, cols = size(A)
    pivot_row = 1

    for col in 1:cols
        if pivot_row > rows
            break
        end

        # Find pivot in the current column
        pivot = pivot_row
        while pivot <= rows && A[pivot, col] == 0
            pivot += 1
        end

        if pivot > rows
            continue
        end

        # Swap rows to bring pivot to the current row
        if pivot != pivot_row
            A[pivot_row, :], A[pivot, :] = A[pivot, :], A[pivot_row, :]
        end

        # Normalize pivot row (multiply by modular inverse)
        inv_val = invmod(A[pivot_row, col], P)
        # Vectorized update for the pivot row
        A[pivot_row, :] = (A[pivot_row, :] .* inv_val) .% P

        # Eliminate other rows
        for r in 1:rows
            if r != pivot_row && A[r, col] != 0
                factor = A[r, col]
                # Row operation: Row_r = Row_r - factor * Row_pivot
                # Optimize by iterating only from current column onwards
                for c in col:cols 
                    val = A[r, c] - widemul(factor, A[pivot_row, c])
                    A[r, c] = mod(val, P)
                end
            end
        end

        pivot_row += 1
    end

    return pivot_row - 1
end

"""
    invmod(a::Int, p::Int)

Computes the modular multiplicative inverse of `a` modulo `p` using Fermat's Little Theorem.
Assumes `p` is prime.
"""
function invmod(a::Int, p::Int)
    return powermod(a, p - 2, p)
end

end