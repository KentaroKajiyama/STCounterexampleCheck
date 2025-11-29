#!/usr/bin/env julia

# ディレクトリ単位でのバッチ実行スクリプト
# 実行方法:
# julia --project=. scripts/run_batch_analysis.jl <input_dir> <output_dir> <workflow>

using STCounterexampleCheck

if length(ARGS) < 3
    println("Usage: julia scripts/run_batch_analysis.jl <input_dir> <output_dir> <workflow>")
    println("  <input_dir>:  Path to directory containing .g6 files")
    println("  <output_dir>: Path to output directory")
    println("  <workflow>:   'standard' or 'double_circuit'")
    println("Example: julia scripts/run_batch_analysis.jl data/split_graphs results/batch1 standard")
    exit(1)
end

input_dir  = ARGS[1]
output_dir = ARGS[2]
workflow   = ARGS[3]

run_batch_job(
    input_dir = input_dir,
    output_dir = output_dir,
    workflow_type = workflow,
    
    # 必要に応じてフィルタ設定を変更
    target_edges = "unknown",
    min_deg = 0,
    max_deg = 1000
)