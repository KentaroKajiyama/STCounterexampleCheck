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

"""
    core_main(g::AbstractGraph, channel::Channel)

Main logic for a single graph. Pushes results to channel.
"""
function core_main(g::AbstractGraph, channel::Channel)
  valid, reason = check_graph_constraints(g, MAX_EDGES, get_min_deg(), get_max_deg())
  if !valid
    output_exception(channel, g, reason)
    return
  end

  n = nv(g)
  p_embed, seed = generate_embedding(n, T_DIM)
  M, phi = generate_matrix(g, p_embed)
  r = compute_rank(M)

  if r == size(M, 2)
    output_independent(channel, g, phi, p_embed, seed)
  else
    C_edges, C_indices = find_circuit(g, M, phi)

    if isempty(C_edges)
      output_exception(channel, g, "Rank < cols but no circuit found (numerical error?)")
      return
    end

    F_edges, F_indices = find_closure(g, M, C_indices, phi)

    F_graph = SimpleGraph(n)
    for e in F_edges
      add_edge!(F_graph, src(e), dst(e))
    end

    idx = identify_C_n6_index(F_graph, n)

    if idx > 0
      output_dependent(channel, g, phi, p_embed, seed, C_edges, F_edges, idx, C_indices, F_indices)
    else
      output_counterexample(channel, g, phi, p_embed, seed, C_edges, F_edges, C_indices, F_indices)
    end
  end
end

"""
    writer_task(channel::Channel, output_dir::String)

Consumer task that writes results to files.
"""
function writer_task(channel::Channel, output_dir::String)
  bin_path = joinpath(output_dir, "output.bin")
  counter_path = joinpath(output_dir, "counterexample.jsonl")
  exception_path = joinpath(output_dir, "exception.jsonl")

  open(bin_path, "w") do bin_io
    open(counter_path, "a") do counter_io
      open(exception_path, "a") do exception_io
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
    workflow(graphs::Vector)

Process a list of graphs in parallel using Producer-Consumer pattern.
"""
function workflow(graphs::Vector)
  output_dir = get(ENV, "OUTPUT_DIR", ".")
  if !isdir(output_dir)
    mkdir(output_dir)
  end

  channel = Channel{Any}(1000) # Buffer size 1000

  # Spawn consumer
  consumer = @async writer_task(channel, output_dir)

  # Spawn producers
  @threads for g in graphs
    try
      core_main(g, channel)
    catch e
      output_exception(channel, g, "Runtime error: $e")
    end
  end

  # Close channel when done
  close(channel)

  # Wait for consumer to finish
  wait(consumer)
end

end
