# # Connected graphs
# for ($i = 15; $i -le 18; $i++) {
    
#     $name = "connected_$i"
#     Write-Host "Processing $name..."
#     if ($i -in 16, 17, 18) {
#         $max_part = if ($i -eq 16) {10} elseif ($i -eq 17) {50} else {300}
#         for ($j = 1; $j -le $max_part; $j++) {
#             if ($i -in 2,3,4) {
#                 continue
#             }
#             $name = "connected_${i}_part$j"
#             julia --project=. scripts/run_job.jl graphs/1_input/$name.g6 graphs/1_output $name standard
#             if ($i -eq 16) {
#                 julia --project=. scripts/run_job.jl graphs/1_input/$name.g6 graphs/2_output $name double_circuit
#             }
#         }
#     } else {
#         julia --project=. scripts/run_job.jl graphs/1_input/$name.g6 graphs/1_output $name standard
#         julia --project=. scripts/run_job.jl graphs/1_input/$name.g6 graphs/2_output $name double_circuit
#     }
# }

# Disconnected graphs
for ($i = 18; $i -le 18; $i++) {
    $name = "disconnected_$i"
    Write-Host "Processing $name..."
    if ($i -in 15, 16) {
        $max_part = if ($i -eq 15) {10} elseif ($i -eq 16) {100}
        for ($j = 1; $j -le $max_part; $j++) {
            $name = "disconnected_${i}_part$j"
            julia --project=. scripts/run_job.jl graphs/1_input/$name.g6 graphs/1_output $name standard
            julia --project=. scripts/run_job.jl graphs/1_input/$name.g6 graphs/2_output $name double_circuit
        }
    } elseif ($i -eq 17) {
        for ($j = 7; $j -le 32; $j++) {
            $name = "disconnected_17_node_$j"
            julia --project=. scripts/run_job.jl graphs/1_input/$name.g6 graphs/1_output $name standard
        }
    } elseif ($i -eq 18) {
        for ($k = 18; $k -le 32; $k++) {
            if ($k -ge 12 -and $k -le 20) {
                $max_part = if ($k -in 12,13,18,19,20) {10} else {30}
                for ($j = 1; $j -le $max_part; $j++) {
                    $name = "disconnected_18_node_${k}_part$j"
                    julia --project=. scripts/run_job.jl graphs/1_input/$name.g6 graphs/1_output $name standard
                }
            } else {
                $name = "disconnected_18_node_$k"
                julia --project=. scripts/run_job.jl graphs/1_input/$name.g6 graphs/1_output $name standard
            }
        }
    } else {
        julia --project=. scripts/run_job.jl graphs/1_input/$name.g6 graphs/1_output $name standard
    }
}
