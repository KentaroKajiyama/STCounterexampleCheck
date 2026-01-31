#!/bin/bash

echo "--- 主張 5 の反例判定を開始します ---"

START_PART=0
MAX_PART=199
EDGE_NUM=18
IS_44331=true

mkdir -p outputs/claim5/certification/44331
mkdir -p outputs/claim5/certification/44331/independent
mkdir -p outputs/claim5/certification/44331/dependent
mkdir -p outputs/claim5/certification/44331/forbidden
mkdir -p outputs/claim5/certification/44331/counterexample
mkdir -p outputs/claim5/certification/44331/exception

for ((j=START_PART; j<=MAX_PART; j++)); do
    part_name="${EDGE_NUM}_part_${j}"
    part_name_2="${EDGE_NUM+1}_part_${j}"
    julia -t auto --project=. scripts/run_job.jl outputs/claim5/anchored/44330/${part_name}.g6 outputs/claim5/certification/44331 ${part_name} standard_stream $IS_44331
done

# 検索対象のディレクトリ
targetDirectory="./outputs/claim5/certification/44331/counterexample"

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