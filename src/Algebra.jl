module Algebra

export generate_embedding, generate_matrix, compute_rank

using Nemo
using Graphs
using ..Types

# ==============================================================================
# Lean 検証用 カスタム乱数生成器 (Linear Congruential Generator)
# ==============================================================================
# アルゴリズム: Knuth's MMIX LCG
# X_{n+1} = (a * X_n + c) mod 2^64
# a = 6364136223846793005
# c = 1442695040888963407
# ==============================================================================

mutable struct LcRNG
    state::UInt64
end

"""
    lcg_next!(rng::LcRNG)

Advances the RNG state and returns the next UInt64 value.
Implemented to be bit-exact compatible with Lean verification code.
"""
function lcg_next!(rng::LcRNG)
    # Constants for MMIX LCG
    a = 0x5851f42d4c957f2d # 6364136223846793005
    c = 0x14057b7ef767814f # 1442695040888963407

    # Update state: wrapping multiplication/addition is automatic for UInt64
    rng.state = rng.state * a + c
    return rng.state
end

"""
    get_random_Zp(rng::LcRNG)

Returns a random integer in [0, P_VAL-1] using the custom LCG.
"""
function get_random_Zp(rng::LcRNG)
    val = lcg_next!(rng)
    # P_VAL is defined in Types.jl
    return Int(val % UInt64(P_VAL))
end

# ==============================================================================
# Core Functions
# ==============================================================================

"""
    generate_embedding(n::Int, t::Int, seed::Union{Int, Nothing}=nothing)

Generates a random embedding of n vertices into Z_p^t using the custom LCG.
Returns a tuple (embedding, seed).
Note: Returns Matrix{Int} for easier serialization. Conversion to Fp happens in generate_matrix.
"""
function generate_embedding(n::Int, t::Int, seed::Union{Int,Nothing}=nothing)
    if seed === nothing
        seed = abs(rand(Int))
    end

    rng = LcRNG(UInt64(seed))

    embedding = Matrix{Int}(undef, n, t)

    for i in 1:n
        for j in 1:t
            embedding[i, j] = get_random_Zp(rng)
        end
    end

    return embedding, seed
end

"""
    generate_matrix(g::AbstractGraph, embedding::Embedding)

Generates the symmetric tensor matrix M and the column mapping phi using Nemo.
M is a Nemo matrix over GF(P).
phi is a list of edges corresponding to columns, sorted lexicographically.
"""
function generate_matrix(g::AbstractGraph, embedding::Embedding)
    n, t = size(embedding)

    # Enforce the universal rule:
    # Edges must be sorted lexicographically by (src, dst) with src < dst.
    edges_list = collect(edges(g))
    sort!(edges_list, by=e -> (src(e), dst(e)))

    m = length(edges_list)
    row_dim = (t * (t + 1)) ÷ 2

    # Initialize Nemo Matrix over Finite Field Fp (defined in Types.jl)
    Fp = get_Fp()
    M = zero_matrix(Fp, row_dim, m)
    phi = Vector{Edge}(undef, m)

    # Precompute indices for symmetric tensor elements
    # Order: (1,1), (1,2), ..., (1,t), (2,2), ..., (t,t)
    idx_map = Tuple{Int,Int}[]
    for r in 1:t
        for c in r:t
            push!(idx_map, (r, c))
        end
    end

    for (k, e) in enumerate(edges_list)
        u, v = src(e), dst(e)
        phi[k] = e

        # embedding is Matrix{Int}
        pu_row = embedding[u, :]
        pv_row = embedding[v, :]

        # Calculate Symmetric Tensor Vector (STV) elements
        for (row_idx, (i, j)) in enumerate(idx_map)
            # Calculate in Int first (using widemul for safety before modulo)
            val_int = (widemul(pu_row[i], pv_row[j]) + widemul(pv_row[i], pu_row[j])) % P_VAL

            # Assign to Nemo matrix (automatically converts Int to Fp element)
            M[row_idx, k] = Fp(Int(val_int))
        end
    end

    return M, phi
end

"""
    compute_rank(M::STM)

Computes the rank of matrix M over Z_p using Nemo's optimized C library (Flint).
"""
function compute_rank(M::STM)
    return rank(M)
end

end