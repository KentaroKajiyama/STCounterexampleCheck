module STCounterexampleCheck

# エントリーポイント関数をエクスポート
export run_job, run_batch_job, debug_check_rank

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
using Graphs

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
    apply_specific_edge_rule::Bool = false,
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
    println("Workflow type: $workflow_type")

    # 3. ワークフロー実行（ストリーム）
    if workflow_type == "standard_stream"
        Main.workflow_stream(input_file, output_dir, output_path_name, apply_specific_edge_rule)
        return
    end

    # 4. ワークフロー実行（事前読み込み）
    graphs = GraphUtils.read_graphs_from_file(input_file)
    if isempty(graphs)
        println("   Warning: Skipped (No graphs found)")
        return
    end
    println("   Loaded $(length(graphs)) graphs.")

    
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


"""
指定されたファイルのグラフに対してランク計算を行い、詳細を標準出力する関数
args:
    input_file: グラフファイルのパス
    target_seed: 特定のシードで試したい場合は数値を指定。Nothingならランダムに試行。
"""

# 定数設定 (探索プログラムと同じ値にしてください)
const T_DIM = 6  # 例
const MAX_EDGES = 100 # 例

function debug_check_rank(input_file::String; target_seed::Union{Int, UInt64, Nothing}=nothing)
    # 1. グラフの読み込み
    graphs = read_graphs_from_file(input_file)
    println("Loaded $(length(graphs)) graphs from $input_file")

    for (i, g) in enumerate(graphs)
        println("\n" * "="^60)
        println("Checking Graph #$i")
        println("Vertices (n): $(nv(g))")
        println("Edges (m):    $(ne(g))")
        println("Edge List:    $(edges(g))")

        # 制約チェック
        valid, reason = check_graph_constraints(g, MAX_EDGES, 0, 5)
        if !valid
            println("Skipping: Constraints check failed ($reason)")
            continue
        end

        n = nv(g)
        
        # 試行するシードを決める
        # target_seed があればそれ1回、なければランダムに5回試す
        seeds_to_try = isnothing(target_seed) ? [rand(Int64) for _ in 1:5] : [target_seed]

        for seed in seeds_to_try
            println("\n" * "-"^40)
            println("Trial with Seed: $seed")

            # 2. 埋め込み生成
            # generate_embedding が内部で rand() を呼んでいれば、上の seed! が効きます
            p_embed, used_seed = generate_embedding(n, T_DIM, seed)
            
            # 念のため、返ってきたシードも確認（generate_embeddingの実装依存）
            # println("Debug: seed returned from function: $used_seed")

            # 1. K_n 全体の行列と、Gに対応するインデックスを取得
            M_all, phi_all, indices_g = generate_matrix(g, p_embed)
            
            # 2. G に対応する部分行列だけを切り出す
            M_g = M_all[:, indices_g]
            phi_g = phi_all[indices_g] # G の辺リスト (lex順)

            println("\n[generate_matrix]")
            println("  phi_all: $phi_all")
            println("  indices_g: $indices_g")
            println("  phi_g: $phi_g")

            # 4. ランク計算
            r = compute_rank(M_g)

            # 5. 結果出力
            println("Matrix Size:   $(size(M_g))")
            println("Computed Rank: $r")
            
            # 期待値との比較（サーキットなら |E|-1, 独立なら |E|）
            if r == ne(g)
                println("Status: Independent (Full Rank)")
            elseif r == ne(g) - 1
                println("Status: Circuit candidate (|E|-1)")
            else
                println("Status: Dependent (Deficiency: $(ne(g) - r))")
            end

            C_indices = find_circuit(M_all, indices_g)
            C_edges = phi_all[C_indices]

            println("\n[Circuit Analysis]")
            println("  Circuit Size (Edges): $(length(C_edges))")
            println("  Circuit Indices:      $C_indices")
            println("  phi length:           $(length(phi_g))")
            if length(C_edges) > 0
                # エッジリストを整形して表示
                edge_strs = ["($(src(e)), $(dst(e)))" for e in C_edges]
                println("  Circuit Edges:        $(join(edge_strs, ", "))")
            else
                println("  (No circuit found or graph is independent)")
            end

            # --- 閉包探索結果の出力 ---
            F_indices = find_closure(g, M_all, C_indices)

            F_edges = phi_all[F_indices]
            
            println("\n[Closure Analysis]")
            println("  Closure Size (Edges): $(length(F_edges))")
            println("  Closure Indices:      $F_indices")
            
            # 閉包内の辺リスト
            if length(F_edges) > 0
                edge_strs_F = ["($(src(e)), $(dst(e)))" for e in F_edges]
                # 長すぎる場合は省略表示
                if length(edge_strs_F) > 20
                    println("  Closure Edges:        $(join(edge_strs_F[1:20], ", "))... (total $(length(F_edges)))")
                else
                    println("  Closure Edges:        $(join(edge_strs_F, ", "))")
                end
            end

            # 閉包グラフの作成 (可視化や分析用)
            F_graph = SimpleGraph(n)
            for e in F_edges
                add_edge!(F_graph, src(e), dst(e))
            end
            println("  Closure Graph (Vertices): $(nv(F_graph)), Edges: $(ne(F_graph))")

            # ★ 行列 M の中身を表示 (サイズが大きい場合は一部のみ)
            println("\nMatrix M content:")
            if size(M_g, 1) <= 20 && size(M_g, 2) <= 20
                display(M_g) # Julia の標準的な行列表示
            else
                println("(Matrix is too large to display fully. Showing top-left 5x5)")
                display(M_g[1:min(5, end), 1:min(5, end)])
            end
        end
    end
end

end # module