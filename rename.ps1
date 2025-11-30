# 対象ディレクトリを指定
$dir = "graphs\1_input"

# # disconnected_18_node_[1-2][0-9].g6_partXXX.g6 → disconnected_18_node_[1-2][0-9]_partXXX.g6
# Get-ChildItem -Path $dir -File -Recurse |
#     Where-Object { $_.Name -match '^disconnected_18_node_(\d{2})\.g6_part(\d{1,3})\.g6$' } |
#     ForEach-Object {
#         $newName = "disconnected_18_node_$($matches[1])_part$($matches[2]).g6"
#         Rename-Item -Path $_.FullName -NewName $newName
#     }

# connected_1[6-8].g6_partXXX.g6 → connected_1[6-8]_partXXX.g6
# Get-ChildItem -Path $dir -File -Recurse |
#     Where-Object { $_.Name -match '^disconnected_(1[5-6])\.g6_part(\d{1,3})\.g6$' } |
#     ForEach-Object {
#         $newName = "disconnected_$($matches[1])_part$($matches[2]).g6"
#         Rename-Item -Path $_.FullName -NewName $newName
#     }

# $dir = "C:\path\to\your\directory"

Get-ChildItem -Path $dir -File -Filter "connected_15_part*.g6" |
    Where-Object {
        # part番号が 11～100 の範囲にあるものだけ対象
        $_.Name -match '^connected_15_part(\d+)\.g6$' -and
        [int]$matches[1] -ge 1 -and [int]$matches[1] -le 10
    } |
    ForEach-Object {
        $part = $matches[1]
        $newName = "disconnected_15_part$part.g6"
        Rename-Item -Path $_.FullName -NewName $newName
    }