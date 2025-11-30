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

Generates the symmetric tensor matrix M for the COMPLETE GRAPH K_n.
Also identifies which columns correspond to the edges of the input graph g.

Returns:
    M: Nemo matrix over GF(P) for K_n (size: row_dim x n*(n-1)/2)
    phi: Vector{Edge} mapping column indices to edges of K_n
    indices_g: Vector{Int} indices of columns corresponding to edges in g
"""
function generate_matrix(g::AbstractGraph, embedding::Embedding)
    n, t = size(embedding)

    # Prepare lookup set for g's edges (normalized u < v)
    g_edges_set = Set{Edge}()
    for e in edges(g)
        u, v = src(e), dst(e)
        push!(g_edges_set, Edge(min(u, v), max(u, v)))
    end

    # Number of edges in K_n
    m_Kn = (n * (n - 1)) ÷ 2
    row_dim = (t * (t + 1)) ÷ 2

    # Initialize Nemo Matrix over Finite Field Fp
    Fp = get_Fp()
    M = zero_matrix(Fp, row_dim, m_Kn)
    phi = Vector{Edge}(undef, m_Kn)
    indices_g = Int[] # Indices corresponding to g

    # Precompute indices for symmetric tensor elements
    idx_map = Tuple{Int,Int}[]
    for r in 1:t
        for c in r:t
            push!(idx_map, (r, c))
        end
    end

    # Iterate over ALL pairs (u, v) in lexicographical order (edges of K_n)
    col_idx = 0
    for u in 1:(n-1)
        for v in (u+1):n
            col_idx += 1
            e_Kn = Edge(u, v)
            phi[col_idx] = e_Kn

            # If this edge is in g, store the index
            if e_Kn in g_edges_set
                push!(indices_g, col_idx)
            end

            # --- Calculate STV column for edge (u, v) ---
            pu_row = embedding[u, :]
            pv_row = embedding[v, :]

            for (row_idx, (i, j)) in enumerate(idx_map)
                # val = p_u[i]*p_v[j] + p_v[i]*p_u[j]
                val_int = (widemul(pu_row[i], pv_row[j]) + widemul(pv_row[i], pu_row[j])) % P_VAL
                M[row_idx, col_idx] = Fp(Int(val_int))
            end
        end
    end

    return M, phi, indices_g
end

"""
    compute_rank(M::STM)

Computes the rank of matrix M over Z_p using Nemo's optimized C library (Flint).
"""
function compute_rank(M::STM)
    return rank(M)
end

end