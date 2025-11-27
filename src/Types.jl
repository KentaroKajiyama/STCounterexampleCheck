module Types

export STV, STM, Embedding, get_Fp, P_VAL

using Nemo

# 定数定義
const P_VAL = 2147483647

# Nemo の GF(p) オブジェクトを取得する関数
# グローバル定数にするとプレコンパイル時にポインタが無効になる可能性があるため関数化
get_Fp() = GF(P_VAL)

# 型定義
# STM (Symmetric Tensor Matrix)
const STM = Union{FpMatrix, FqMatrix}

# Embedding
const Embedding = Matrix{Int}

# STV
const STV = Vector{Int}

end