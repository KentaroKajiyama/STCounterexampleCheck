using LinearAlgebra
using Graphs
using Random
# 既存のモジュールを読み込む (パスは環境に合わせて調整してください)
using STCounterexampleCheck
# ...





# --- 実行例 ---

# 1. ランダムに数回試して、従属が「たまたま」か確認する
# debug_check_rank("check_counterexample.g6")

# 2. 特定のシード (JSONにあったものなど) で再現確認する
debug_check_rank("check_counterexample.g6", target_seed=4733247997928746481)