module Types

export STV, STM, Embedding

using LinearAlgebra

# Symmetric Tensor Vector (represented as a vector of length t(t+1)/2)
const STV = Vector{Int}

# Symmetric Tensor Matrix
const STM = Matrix{Int}

# Embedding of graph vertices into Z_p^t
# n x t matrix where n is number of vertices
const Embedding = Matrix{Int}

end
