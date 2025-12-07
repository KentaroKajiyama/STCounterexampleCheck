module Main

export core_main, workflow

using Graphs
using Base.Threads
using JSON
using MsgPack
using ..Types
using ..GraphUtils
using ..Algebra
using ..Matroid
using ..ClassCheck
using ..Output
using DotEnv

# Constants/Configuration
const T_DIM = 6
const P_PRIME = 2147483647
const MAX_EDGES = (T_DIM * (T_DIM + 1)) ÷ 2

function __init__()
  # Load environment variables from .env file at runtime
  cfg = DotEnv.config()
  for (k, v) in cfg
    ENV[k] = v
  end
end

get_min_deg() = parse(Int, get(ENV, "MIN_DEG", "0"))
get_max_deg() = parse(Int, get(ENV, "MAX_DEG", "1000"))
# 並列数を制御するための設定 (デフォルトはCPUスレッド数の半分、またはメモリに合わせて調整)
# メモリ不足の場合は .env で MAX_WORKERS=1 や 2 に設定してください。
get_max_workers() = parse(Int, get(ENV, "MAX_WORKERS", string(max(1, Threads.nthreads() ÷ 2))))

"""
    core_main(g::AbstractGraph, channel::Channel)

Main logic for a single graph. Pushes results to channel.
"""
function core_main(g::AbstractGraph, channel::Channel)
  valid, reason = check_graph_constraints(g, MAX_EDGES, get_min_deg(), get_max_deg())
  if !valid
    output_forbidden_graph(channel, g)
    return
  end

  n = nv(g)
  p_embed, seed = generate_embedding(n, T_DIM)
  # 1. K_n 全体の行列と、Gに対応するインデックスを取得
  M_all, phi_all, indices_g = generate_matrix(g, p_embed)
  
  # 2. G に対応する部分行列だけを切り出す
  M_g = M_all[:, indices_g]
  phi_g = phi_all[indices_g] # G の辺リスト (lex順)

  # 3. G のランクを計算
  r = compute_rank(M_g)

  if r == size(M_g, 2)
    output_independent(channel, g, phi_g, p_embed, seed)
  else
    C_indices = find_circuit(M_all, indices_g)
    C_edges = phi_all[C_indices]

    if isempty(C_edges)
      output_exception(channel, g, "Rank < cols but no circuit found (numerical error?)")
      return
    end

    F_indices = find_closure(g, M_all, C_indices)

    F_edges = phi_all[F_indices]

    F_graph = SimpleGraph(n)
    for e in F_edges
      add_edge!(F_graph, src(e), dst(e))
    end

    idx = identify_C_n6_index(F_graph, n)

    if idx > 0
      output_dependent(channel, g, phi_all, p_embed, seed, C_edges, F_edges, idx, C_indices, F_indices)
    else
      output_counterexample(channel, g, phi_all, p_embed, seed, C_edges, F_edges, C_indices, F_indices)
    end
  end
end

"""
    double_circuit_main(g::AbstractGraph, channel::Channel)
    S_5 Double Circuit Check (t=5)
    
    Definition of Double Circuit D:
    rank(D) = |D| - 2
    for all e in D, rank(D - e) = rank(D)
"""
function double_circuit_main(g::AbstractGraph, channel::Channel)
    # (i) Constraints check
    # Edge count <= 16, Max degree <= 5
    if ne(g) > 16
        output_forbidden_graph(channel, g)
        return
    end
    
    # We check max degree manually here as it's a strict filter for this task
    if maximum(degree(g)) > 5
        output_forbidden_graph(channel, g)
        return
    end
    
    n = nv(g)
    t = 5 # Fixed for this task

    p_embed, seed = generate_embedding(n, t)
    M_all, phi_all, indices_g = generate_matrix(g, p_embed) # phi matches column indices
    
    m = ne(g)
    # 2. G に対応する部分行列だけを切り出す
    M_g = M_all[:, indices_g]
    phi_g = phi_all[indices_g] # G の辺リスト (lex順)
    
    # (ii) Rank Check: rank(G) must be |G| - 2
    r_G = compute_rank(M_g)
    if r_G != m - 2
        output_not_double_circuit(channel, g, phi_g, p_embed, seed)
        return
    end
    
    # (iii) Minimality Check: for all e, rank(G - e) == rank(G)
    # This means removing any edge does not decrease the rank.
    # Note: rank(G) = m-2. rank(G-e) <= m-1.
    # If G-e is a circuit (rank = (m-1)-1 = m-2), then rank matches.
    
    is_double_circuit = true
    
    # Check all edges
    for k in 1:m
        # Remove k-th column
        # Using Nemo's matrix subset logic
        # Indices excluding k
        subset_indices = [i for i in 1:m if i != k]
        subM = M_g[:, subset_indices]
        
        r_sub = compute_rank(subM)
        
        if r_sub != r_G
            # If rank drops, it implies e was independent/necessary for the rank.
            # Double circuit requires redundancy everywhere.
            is_double_circuit = false
            break
        end
    end
    
    if is_double_circuit
        F_indices = find_closure(g, M_all, indices_g)

        F_edges = phi_all[F_indices]
        F_graph = SimpleGraph(n)
        for e in F_edges
          add_edge!(F_graph, src(e), dst(e))
        end
        # (iv) Isomorphism Check with C_{n,5}
        idx = identify_C_n5_index(F_graph, n)
        
        if idx > 0
            output_double_circuit(channel, g, phi_g, p_embed, seed, idx)
        else
            output_double_circuit_counterexample(channel, g, phi_g, p_embed, seed)
        end
    else
        output_not_double_circuit(channel, g, phi_g, p_embed, seed)
    end
end

"""
    writer_task(channel::Channel, output_dir::String)

Consumer task that writes results to files.
"""
function writer_task_standard(channel::Channel, output_dir::String, output_path_name::String)
  bin_path = joinpath(output_dir, string(output_path_name, "_output.bin"))
  counter_path = joinpath(output_dir, string(output_path_name, "_counterexample.jsonl"))
  exception_path = joinpath(output_dir, string(output_path_name, "_exception.jsonl"))

  open(bin_path, "w") do bin_io
    open(counter_path, "w") do counter_io
      open(exception_path, "w") do exception_io
        for result in channel
          if result isa IndependentResult
            # [0, g6, seed]
            g6 = to_graph6(result.g)
            data = [0, g6, result.seed]
            write(bin_io, MsgPack.pack(data))

          elseif result isa DependentResult
            # [1, g6, seed, circuit_idx, closure_idx, family_idx]
            g6 = to_graph6(result.g)
            data = [1, g6, result.seed, result.C_indices, result.F_indices, result.class_index]
            write(bin_io, MsgPack.pack(data))

          elseif result isa ForbiddenGraphResult
            # [2, g6, seed]
            g6 = to_graph6(result.g)
            data = [2, g6, 1]
            write(bin_io, MsgPack.pack(data))

          elseif result isa CounterexampleResult
            # JSONL
            g6 = to_graph6(result.g)
            data = Dict(
              "type" => "counterexample",
              "g6" => g6,
              "seed" => result.seed,
              "G" => Dict("vertices" => nv(result.g), "edges" => [[src(e), dst(e)] for e in edges(result.g)]),
              "circuit_indices" => result.C_indices,
              "closure_indices" => result.F_indices
            )
            println(counter_io, JSON.json(data))

          elseif result isa ExceptionResult
            # JSONL
            g6 = to_graph6(result.g)
            data = Dict(
              "type" => "exception",
              "g6" => g6,
              "G" => Dict("vertices" => nv(result.g), "edges" => [[src(e), dst(e)] for e in edges(result.g)]),
              "message" => result.message
            )
            println(exception_io, JSON.json(data))
          end
        end
      end
    end
  end
end

"""
    writer_task_double_circuit(channel::Channel, output_dir::String, output_path_name::String)

Consumer task that writes results to files.
"""
function writer_task_double_circuit(channel::Channel, output_dir::String, output_path_name::String)
  bin_path = joinpath(output_dir, string(output_path_name, "_output.bin"))
  counter_path = joinpath(output_dir, string(output_path_name, "_counterexample.jsonl"))
  exception_path = joinpath(output_dir, string(output_path_name, "_exception.jsonl"))

  open(bin_path, "w") do bin_io
    open(counter_path, "w") do counter_io
      open(exception_path, "w") do exception_io
        for result in channel
          if result isa NotDoubleCircuitResult
            # [0, g6, seed]
            g6 = to_graph6(result.g)
            data = [0, g6, result.seed]
            write(bin_io, MsgPack.pack(data))

          elseif result isa DoubleCircuitResult
            # [1, g6, seed, class_index]
            g6 = to_graph6(result.g)
            data = [1, g6, result.seed, result.class_index]
            write(bin_io, MsgPack.pack(data))

          elseif result isa ForbiddenGraphResult
            # [2, g6, seed]
            g6 = to_graph6(result.g)
            data = [2, g6, 1]
            write(bin_io, MsgPack.pack(data))

          elseif result isa DoubleCircuitCounterexampleResult
            # JSONL
            g6 = to_graph6(result.g)
            data = Dict(
              "type" => "counterexample",
              "g6" => g6,
              "seed" => result.seed,
              "G" => Dict("vertices" => nv(result.g), "edges" => [[src(e), dst(e)] for e in edges(result.g)]),
            )
            println(counter_io, JSON.json(data))

          elseif result isa ExceptionResult
            # JSONL
            g6 = to_graph6(result.g)
            data = Dict(
              "type" => "exception",
              "g6" => g6,
              "G" => Dict("vertices" => nv(result.g), "edges" => [[src(e), dst(e)] for e in edges(result.g)]),
              "message" => result.message
            )
            println(exception_io, JSON.json(data))
          end
        end
      end
    end
  end
end

"""
    workflow(graphs::Vector)

Process a list of graphs in parallel using Producer-Consumer pattern.
"""
function workflow(graphs::Vector)
  output_dir = get(ENV, "OUTPUT_DIR", ".")
  output_path_name = get(ENV, "OUTPUT_PATH_NAME", "output")
  n_workers = get_max_workers() # 並列数を取得
  if !isdir(output_dir)
    mkdir(output_dir)
  end

  result_channel = Channel{Any}(1000) # Buffer size 1000

  # Input Channel (Job Queue)
  input_channel = Channel{Any}(length(graphs))
  for g in graphs
      put!(input_channel, g)
  end
  close(input_channel) # 入力受付終了
  # Spawn consumer
  consumer = @async writer_task_standard(result_channel, output_dir, output_path_name)

  # Start Workers (Worker Pool Pattern)
  # n_workers の数だけタスクを起動し、それらが input_channel を取り合います。
  # これにより、同時に走る core_main の数を厳密に n_workers に制限します。
  @sync begin
      for w in 1:n_workers
          Threads.@spawn begin
              for g in input_channel
                  try
                      core_main(g, result_channel)
                  catch e
                      # bt = catch_backtrace()
                      output_exception(result_channel, g, "Runtime error: $e")
                  end
              end
          end
      end
  end

  # Close channel when done
  close(result_channel)

  # Wait for consumer to finish
  wait(consumer)
end

"""
    workflow_double_circuit(graphs::Vector)
    Workflow for S_5 Double Circuit Check
"""
function workflow_double_circuit(graphs::Vector)
    output_dir = get(ENV, "OUTPUT_DIR", ".")
    output_path_name = get(ENV, "OUTPUT_PATH_NAME", "output")
    n_workers = get_max_workers() # 並列数を取得
    if !isdir(output_dir); mkpath(output_dir); end
    println("Starting Double Circuit Workflow (t=5). Output: $output_dir")

    result_channel = Channel{Any}(2000)
    # Input Channel (Job Queue)
    input_channel = Channel{Any}(length(graphs))
    for g in graphs
        put!(input_channel, g)
    end
    close(input_channel) # 入力受付終了
    consumer = @async writer_task_double_circuit(result_channel, output_dir, output_path_name)

    @sync begin
      for w in 1:n_workers
          Threads.@spawn begin
              for g in input_channel
                  try
                      double_circuit_main(g, result_channel)
                  catch e
                      # bt = catch_backtrace()
                      output_exception(result_channel, g, "Runtime error: $e")
                  end
              end
          end
      end
  end
    close(result_channel)
    wait(consumer)
    println("Double Circuit Workflow completed.")
end

end
