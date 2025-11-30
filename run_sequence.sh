#!/bin/bash

# ==============================================================================
# Graph Job Runner (Bash Script for macOS/Linux)
# This script executes Julia jobs based on the logic of the original PowerShell script.
#
# Usage:
# 1. Make the script executable: chmod +x run_graph_jobs.sh
# 2. Run the script: ./run_graph_jobs.sh
# ==============================================================================

# Connected graphs の処理
echo "--- Connected Graphs (連結グラフ) の処理を開始します ---"

for i in {1..18}; do
    name="connected_${i}"
    echo "Processing ${name}..."

    if [[ "$i" -ge 16 && "$i" -le 18 ]]; then
        # i が 16, 17, 18 の場合
        max_part=0
        if [[ "$i" -eq 16 ]]; then
            max_part=10
        elif [[ "$i" -eq 17 ]]; then
            max_part=50
        else # i == 18
            max_part=300
        fi

        # $j のループ (1 から $max_part まで)
        for ((j=1; j<=max_part; j++)); do
            part_name="connected_${i}_part${j}"
            
            # Standard job
            julia --project=. scripts/run_job.jl graphs/1_input/${part_name}.g6 graphs/1_output ${part_name} standard
            
            # Double circuit job (i=16 のみ)
            if [[ "$i" -eq 16 ]]; then
                julia --project=. scripts/run_job.jl graphs/1_input/${part_name}.g6 graphs/2_output ${part_name} double_circuit
            fi
        done
    else
        # i が 1-15 の場合
        julia --project=. scripts/run_job.jl graphs/1_input/${name}.g6 graphs/1_output ${name} standard
        julia --project=. scripts/run_job.jl graphs/1_input/${name}.g6 graphs/2_output ${name} double_circuit
    fi
done

echo ""
echo "--- Disconnected Graphs (非連結グラフ) の処理を開始します ---"

# Disconnected graphs の処理
for i in {1..18}; do
    name="disconnected_${i}"
    echo "Processing ${name}..."

    if [[ "$i" -eq 15 || "$i" -eq 16 ]]; then
        # i が 15, 16 の場合
        max_part=0
        if [[ "$i" -eq 15 ]]; then
            max_part=10
        else # i == 16
            max_part=100
        fi

        # $j のループ (1 から $max_part まで)
        for ((j=1; j<=max_part; j++)); do
            part_name="disconnected_${i}_part${j}"
            julia --project=. scripts/run_job.jl graphs/1_input/${part_name}.g6 graphs/1_output ${part_name} standard
            julia --project=. scripts/run_job.jl graphs/1_input/${part_name}.g6 graphs/2_output ${part_name} double_circuit
        done

    elif [[ "$i" -eq 17 ]]; then
        # i が 17 の場合 (j は 7 から 32)
        for j in {7..32}; do
            node_name="disconnected_17_node_${j}"
            julia --project=. scripts/run_job.jl graphs/1_input/${node_name}.g6 graphs/1_output ${node_name} standard
        done

    elif [[ "$i" -eq 18 ]]; then
        # i が 18 の場合 (k は 7 から 32)
        for k in {7..32}; do
            if [[ "$k" -ge 12 && "$k" -le 20 ]]; then
                # k が 12 から 20 の間
                # 特定の値 (12, 13, 18, 19, 20) は max_part=10
                if [[ "$k" -eq 12 || "$k" -eq 13 || "$k" -eq 18 || "$k" -eq 19 || "$k" -eq 20 ]]; then
                    max_part=10
                else
                    max_part=30
                fi
                
                # $j のループ (1 から $max_part まで)
                for ((j=1; j<=max_part; j++)); do
                    part_name="disconnected_18_node_${k}_part${j}"
                    julia --project=. scripts/run_job.jl graphs/1_input/${part_name}.g6 graphs/1_output ${part_name} standard
                done
            else
                # k が 7-11 または 21-32 の場合
                node_name="disconnected_18_node_${k}"
                julia --project=. scripts/run_job.jl graphs/1_input/${node_name}.g6 graphs/1_output ${node_name} standard
            fi
        done
        
    else
        # i が 1-14, 18 以外の場合
        # Note: 17, 18 の複雑な処理は elif ブロックで処理済み
        julia --project=. scripts/run_job.jl graphs/1_input/${name}.g6 graphs/1_output ${name} standard
    fi
done

echo "--- 全てのグラフ処理を完了しました ---"