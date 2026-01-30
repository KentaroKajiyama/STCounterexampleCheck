#!/bin/bash

echo "--- 主張 5 の反例判定を開始します ---"

START_PART=107
MAX_PART=199
EDGE_NUM=20

mkdir -p outputs/claim5/certification/44430
mkdir -p outputs/claim5/certification/44430/independent
mkdir -p outputs/claim5/certification/44430/dependent
mkdir -p outputs/claim5/certification/44430/forbidden
mkdir -p outputs/claim5/certification/44430/counterexample
mkdir -p outputs/claim5/certification/44430/exception

for ((j=START_PART; j<=MAX_PART; j++)); do
    part_name="${EDGE_NUM}_part_${j}"
    julia -t auto --project=. scripts/run_job.jl ../SymmetricTensorProof/anchored_4443_20_${j}.g6 outputs/claim5/certification/44430 ${part_name} standard_stream
done

# 検索対象のディレクトリ
targetDirectory="./outputs/claim5/certification/44430/counterexample"

# ディレクトリが存在しない場合の処理
if [ ! -d "$targetDirectory" ]; then
    echo "ディレクトリ $targetDirectory が見つかりません。"
    exit 1
fi

echo "--- 検索開始 ---"

# 1. 空ではないファイルを抽出して表示
# -size +0c : 0バイトより大きい
nonEmptyFiles=$(find "$targetDirectory" -type f -name "*counterexample.jsonl" -size +0c)

if [ -n "$nonEmptyFiles" ]; then
    echo -e "\e[32m以下のファイルは空ではありません:\e[0m"
    echo "$nonEmptyFiles"
else
    echo -e "\e[33m空ではないファイルは見つかりませんでした。\e[0m"
fi

# 2. 空のファイルを抽出して削除
# -size 0c : 0バイト
emptyFiles=$(find "$targetDirectory" -type f -name "*counterexample.jsonl" -size 0c)

if [ -n "$emptyFiles" ]; then
    echo -e "\n\e[31m--- 以下の空ファイルを削除します ---\e[0m"
    while IFS= read -r file; do
        echo "Deleting: $file"
        rm -f "$file"
    done <<< "$emptyFiles"
    echo -e "\e[36m削除が完了しました。\e[0m"
else
    echo -e "\n\e[37m削除対象の空ファイルはありませんでした。\e[0m"
fi