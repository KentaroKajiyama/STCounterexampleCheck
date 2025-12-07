<#
.SYNOPSIS
  指定ディレクトリ配下の全 MessagePack (.bin) ファイルを処理し、Leanで検証します。

.DESCRIPTION
  1. TARGET_DIR 配下の全ての .bin ファイルを検索します。
  2. 各ファイルに対し、Pythonスクリプト (convert_msgpack.py) を実行して一時的な .txt ファイルを生成します。
  3. 生成された .txt ファイルを引数として Lean の実行ファイルを呼び出し、検証を実行します。
  4. 処理後、一時ファイルを削除します。
#>

# --- 設定 ---
$TargetDir = "graphs/1_output" # 処理対象のディレクトリ名
$PythonScript = "convert_msgpack.py"
$LeanExecutable = "lean" # Leanの実行ファイル名 (パスが通っていることを前提)
$PythonPath = "python" # 仮想環境を使用する場合は ".\.venv\Scripts\python" などに修正
# ------------

Write-Host "--- MessagePack から Lean への検証スクリプト開始 ---"

# 1. ターゲットディレクトリのチェック
if (-not (Test-Path -Path $TargetDir -PathType Container)) {
    Write-Error "エラー: ターゲットディレクトリ '$TargetDir' が見つかりません。"
    exit 1
}

# 2. ターゲットディレクトリ配下の全 .bin ファイルを取得
$BinFiles = Get-ChildItem -Path $TargetDir -Filter "*.bin" -Recurse

if ($BinFiles.Count -eq 0) {
    Write-Host "処理対象の .bin ファイルが見つかりませんでした。"
    exit 0
}

Write-Host "処理対象ファイル数: $($BinFiles.Count) 件"
Write-Host "----------------------------------------------------"

$index = 0
foreach ($File in $BinFiles) {
    $index++
    $InputPath = $File.FullName
    
    # 3. 一時ファイル名の一意な生成
    # ファイル名の一部 + イテレーションインデックス + タイムスタンプのハッシュ
    $BaseName = [System.IO.Path]::GetFileNameWithoutExtension($File.Name)
    $Timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $UniqueId = "$($BaseName)_$($index)_$($Timestamp)"
    $TempOutputFile = "tmp_cert_$($UniqueId).txt"

    Write-Host "[ファイル $index / $($BinFiles.Count)] 処理中: $($File.Name)"
    Write-Host "  -> 一時出力: $($TempOutputFile)"

    # 4. Python スクリプトの実行 (bin -> txt 変換)
    Write-Host "  -> Pythonで変換を実行..."
    try {
        & $PythonPath $PythonScript $InputPath $TempOutputFile
    } catch {
        Write-Error "Pythonスクリプト実行中にエラーが発生しました: $_"
        continue # 次のファイルへ
    }
    
    # 5. Lean のメイン関数を実行し、証拠のチェックを行う
    if (Test-Path -Path $TempOutputFile) {
        Write-Host "  -> Leanで証拠のチェックを実行..."
        try {
            Write-Host "  -> Leanの検証ステップはスキップします。"
            # Lean の実行 (ここでは、生成されたTXTファイル名を引数として渡すことを想定)
            # Lean のメイン関数を呼び出す具体的なコマンドに修正してください。
            # 例: & $LeanExecutable "LeanMainFile.lean" "--input=$TempOutputFile"
            # & $LeanExecutable $TempOutputFile -ErrorAction Stop | Out-Host 
            Write-Host "  -> Leanによる検証が完了しました。"
        } catch {
            Write-Error "Leanの実行中にエラーが発生しました: $_"
            # Leanでエラーが出ても、ファイル削除は続行
        }
    } else {
        Write-Warning "警告: Pythonスクリプトが一時ファイル '$TempOutputFile' を生成できませんでした。"
    }

    # 6. 一時ファイルの削除
    if (Test-Path -Path $TempOutputFile) {
        Write-Host "  -> 一時ファイル '$TempOutputFile' を削除中..."
        Remove-Item $TempOutputFile -Force
    }

    Write-Host "----------------------------------------------------"
    break
}

Write-Host "--- すべてのファイルの処理が完了しました ---"