for ($i = 17; $i -le 20; $i++) {
    $fileName = "graphs\1_input\disconnected_18_node_${i}.g6"   # ★ファイル名
    $splitNum = if ($i -in 12, 13, 18, 19, 20) { 10 } else { 30 }

    # 全行数を高速にカウント（ReadCountを使用）
    Write-Host "行数をカウント中..."
    $totalLines = 0
    Get-Content $fileName -ReadCount 1000 | ForEach-Object { $totalLines += $_.Count }
    $chunkSize = [Math]::Ceiling($totalLines / $splitNum)

    Write-Host "合計: $totalLines 行 / 分割単位: $chunkSize 行"

    # ストリームリーダーで少しずつ読み書き
    $reader = [System.IO.StreamReader]::new($fileName)
    $currentPart = 1
    $lineCount = 0

    # 最初の出力ファイルを作成
    $writer = [System.IO.StreamWriter]::new("${fileName}_part${currentPart}.g6")

    while ($line = $reader.ReadLine()) {
        $lineCount++
        $writer.WriteLine($line)

        # 分割点に達したら次のファイルへ
        if ($lineCount -ge $chunkSize -and $currentPart -lt $splitNum) {
            $writer.Close()
            Write-Host "part${currentPart} 作成完了"
            
            $currentPart++
            $lineCount = 0
            $writer = [System.IO.StreamWriter]::new("${fileName}_part${currentPart}.g6")
        }
    }

    $writer.Close()
    $reader.Close()
    Write-Host "part${currentPart} 作成完了。すべて完了しました。"
}