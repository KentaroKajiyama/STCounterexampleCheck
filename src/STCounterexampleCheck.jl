module STCounterexampleCheck

# エントリーポイント関数をエクスポート
export run_job, run_batch_job

# ==============================================================================
# Include Submodules
# ==============================================================================
include("Types.jl")
include("GraphUtils.jl")
include("Algebra.jl")
include("Matroid.jl")
include("ClassCheck.jl")
include("Output.jl")
include("Main.jl")

using .Types
using .GraphUtils
using .Algebra
using .Matroid
using .ClassCheck
using .Output
using .Main 

# ==============================================================================
# Single Job Entry Point
# ==============================================================================

"""
    run_job(; kwargs...)
    (既存の関数、内容はそのまま維持)
"""
function run_job(;
    input_file::String,
    output_dir::String = "results",
    output_path_name::String = "output",
    workflow_type::String = "standard",
    min_deg::Int = 0,
    max_deg::Int = 1000,
    target_edges::String = "all",
    part_id::String = "00"
)
    # 1. 環境変数の設定
    ENV["OUTPUT_DIR"]   = output_dir
    ENV["MIN_DEG"]      = string(min_deg)
    ENV["MAX_DEG"]      = string(max_deg)
    ENV["TARGET_EDGES"] = target_edges
    ENV["PART_ID"]      = part_id
    ENV["OUTPUT_PATH_NAME"]  = output_path_name

    # 2. バリデーション
    if !isfile(input_file)
        error("Input file not found: $input_file")
    end

    println(">> Processing: $input_file (Part ID: $part_id)")

    graphs = GraphUtils.read_graphs_from_file(input_file)
    if isempty(graphs)
        println("   Warning: Skipped (No graphs found)")
        return
    end
    println("   Loaded $(length(graphs)) graphs.")

    # 3. ワークフロー実行
    if workflow_type == "standard"
        Main.workflow(graphs)
    elseif workflow_type == "double_circuit"
        Main.workflow_double_circuit(graphs)
    else
        error("Unknown workflow type: '$workflow_type'")
    end
end

# ==============================================================================
# Batch Job Entry Point (NEW)
# ==============================================================================

"""
    run_batch_job(; input_dir, output_dir, ...)

指定されたディレクトリ内の `.g6` ファイルを全て検出し、順次 `run_job` を実行します。
各ファイルのファイル名（拡張子除く）が自動的に `part_id` として使用されます。
"""
function run_batch_job(;
    input_dir::String,
    output_dir::String = "results",
    workflow_type::String = "standard",
    min_deg::Int = 0,
    max_deg::Int = 1000,
    target_edges::String = "all"
)
    # 1. ディレクトリチェック
    if !isdir(input_dir)
        error("Input directory not found: $input_dir")
    end

    # 2. ファイルリスト取得 (.g6 のみ)
    files = filter(f -> endswith(f, ".g6"), readdir(input_dir))
    sort!(files) # 実行順序を固定するためにソート

    println("==========================================")
    println("   STCounterexampleCheck: Batch Started")
    println("==========================================")
    println(" Directory:       $input_dir")
    println(" Files found:     $(length(files))")
    println(" Workflow:        $workflow_type")
    println("------------------------------------------")

    if isempty(files)
        println("No .g6 files found. Exiting.")
        return
    end

    # 3. 順次実行
    for (i, filename) in enumerate(files)
        file_path = joinpath(input_dir, filename)
        
        # ファイル名から拡張子を除いたものを ID とする
        # 例: "chunk_01.g6" -> "chunk_01"
        current_part_id = splitext(filename)[1]

        println("\n[Batch Progress: $i / $(length(files))]")
        
        try
            run_job(
                input_file = file_path,
                output_dir = output_dir,
                output_path_name = current_part_id,
                workflow_type = workflow_type,
                min_deg = min_deg,
                max_deg = max_deg,
                target_edges = target_edges,
                part_id = current_part_id # 自動設定
            )
            
            # メモリ解放のためにGCを促す（大量ファイル処理時の安全策）
            GC.gc()
            
        catch e
            println("!!! Error processing file $filename: $e")
            # 1つのファイルで失敗しても次へ進む
            println("!!! Skipping to next file...")
        end
    end

    println("\n==========================================")
    println("   Batch Job Finished")
    println("==========================================")
end

end # module