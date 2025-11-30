# 検索対象のディレクトリ（現在はカレントディレクトリ "." を指定しています）
$targetDirectory = ".\graphs\1_output"

# ファイルの検索（再帰的に検索する場合は -Recurse をつけます）
$files = Get-ChildItem -Path $targetDirectory -Filter "*counterexample.jsonl" -Recurse -ErrorAction SilentlyContinue

# 空ではない（サイズが0より大きい）ファイルを抽出
$nonEmptyFiles = $files | Where-Object { $_.Length -gt 0 }

# 結果の判定と出力
if ($nonEmptyFiles) {
    Write-Host "以下のファイルは空ではありません:" -ForegroundColor Green
    # ファイルのフルパスを出力（ファイル名だけでよければ .Name に変更してください）
    $nonEmptyFiles | ForEach-Object { Write-Host $_.FullName }
}
else {
    Write-Host "全て空（もしくは対象ファイルが存在しません）。" -ForegroundColor Yellow
}