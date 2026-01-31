#!/usr/bin/env julia

# ディレクトリ単位でのバッチ実行スクリプト
# 実行方法:
# julia --project=. scripts/run_job.jl <input_file> <output_dir> <output_path_name> <workflow>

using STCounterexampleCheck

if length(ARGS) < 4
    println("Usage: julia scripts/run_job.jl <input_file> <output_dir> <output_path_name> <workflow>")
    println("  <input_file>:  Path to .g6 file")
    println("  <output_dir>: Path to output directory")
    println("  <output_path_name>: Path to output file")
    println("  <workflow>:   'standard' or 'double_circuit'")
    println("Example: julia scripts/run_job.jl data/split_graphs results/batch1 standard")
    exit(1)
end

input_file  = ARGS[1]
output_dir = ARGS[2]
output_path_name = ARGS[3]
workflow   = ARGS[4]
apply_specific_edge_rule = ARGS[5]

run_job(
    input_file = input_file,
    output_dir = output_dir,
    output_path_name = output_path_name,
    workflow_type =workflow,
    apply_specific_edge_rule = parse(Bool, apply_specific_edge_rule),
    
    # 必要に応じてフィルタ設定を変更
    target_edges = "unknown",
    min_deg = 1,
    max_deg = 5
)