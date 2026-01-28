#!/bin/bash

echo "--- 主張 5 の反例判定を開始します ---"

START_PART=0
MAX_PART=199
EDGE_NUM=19

mkdir -p outputs/claim5/certification/44440
mkdir -p outputs/claim5/certification/44440/independent
mkdir -p outputs/claim5/certification/44440/dependent
mkdir -p outputs/claim5/certification/44440/forbidden
mkdir -p outputs/claim5/certification/44440/counterexample
mkdir -p outputs/claim5/certification/44440/exception

for ((j=START_PART; j<=MAX_PART; j++)); do
    part_name="${EDGE_NUM}_part_${j}"
    julia --project=. scripts/run_job.jl outputs/claim5/anchored/44440/${part_name}.g6 outputs/claim5/certification/44440 ${part_name} standard
done
