module GraphUtils

export read_graphs_from_file, check_graph_constraints, to_graph6

using Graphs
using GraphIO
using GraphIO.Graph6

# GraphUtils.jl への追加

"""
    from_graph6(s::String)
    
文字列からグラフをデコードします。
"""
function from_graph6(s::AbstractString)
    # strip(s) で得られた SubString を String() で包んで
    # 標準的な文字列型に変換してから IOBuffer に渡します
    s_clean = String(strip(s)) 
    return GraphIO.Graph6._g6StringToGraph(s_clean)
end

function enumerate_adjacent_list(g::AbstractGraph)
    for v in vertices(g)
        println("Node $v is connected to: ", neighbors(g, v))
    end
end

function test_change!(graph)
    add_edge!(graph, 1, 2)
end

"""
特定のルールに基づいてグラフを変形する関数。
ルール:
1. ノード 1, 2, 3, 4 が互いに隣接していない。
2. 次数が Node 1:3, Node 2:3, Node 3:4, Node 4:4 である。
上記を満たす場合のみ、Node 1-2 間に辺を追加する。
"""
function apply_specific_edge_rule!(g::AbstractGraph)
    # 1. パラメータ設定
    targets = [1, 2, 3, 4]
    required_degrees = [3, 3, 4, 4] # ノード 1, 2, 3, 4 に対応
    
    # 2. 条件チェック: 相互に接続していないか (Independent Set check)
    for i in targets, j in targets
        if i < j && has_edge(g, i, j)
            return false, "ルール拒否: ノード $i と $j の間に既に辺が存在します。"
        end
    end
    
    # 3. 条件チェック: 次数が一致するか
    for (i, v) in enumerate(targets)
        if degree(g, v) != required_degrees[i]
            return false, "ルール拒否: ノード $v の次数が $(degree(g, v)) です（期待値: $(required_degrees[i])）。"
        end
    end
    
    # 4. すべての条件を満たした場合の処理
    add_edge!(g, 1, 2)
    return true, ""
end

"""
    read_graphs_from_file(path::String)

Reads graphs from a file in graph6 format.
Returns a list of graphs.
"""
function read_graphs_from_file(path::String)
  try
    gs = loadgraphs(path, Graph6Format())
    if isa(gs, Dict)
      return collect(values(gs))
    else
      return gs
    end
  catch e
    println("Error reading graphs: ", e)
    return []
  end
end

"""
    check_graph_constraints(g::AbstractGraph, max_edges::Int, min_deg::Int, max_deg::Int)

Checks if the graph satisfies the constraints.
Returns (valid::Bool, reason::String)
"""
function check_graph_constraints(g::AbstractGraph, max_edges::Int, min_deg::Int, max_deg::Int)
  if ne(g) > max_edges
    return false, "Too many edges: $(ne(g)) > $max_edges"
  end

  if is_directed(g)
    return false, "Graph is directed"
  end

  if has_self_loops(g)
    return false, "Graph has self-loops"
  end

  degs = degree(g)
  if !isempty(degs)
    mn = minimum(degs)
    mx = maximum(degs)

    if mn < min_deg
      return false, "Min degree too small: $mn < $min_deg"
    end

    if mx > max_deg
      return false, "Max degree too large: $mx > $max_deg"
    end
  end

  return true, ""
end

"""
    to_graph6(g::AbstractGraph)

Converts a graph to a graph6 string.
"""
function to_graph6(g::AbstractGraph)
  n = nv(g)

  # 1. Encode N
  res = IOBuffer()
  if n <= 62
    write(res, UInt8(n + 63))
  elseif n <= 258047
    write(res, UInt8(126))
    write(res, UInt8((n >> 12) & 63 + 63))
    write(res, UInt8((n >> 6) & 63 + 63))
    write(res, UInt8(n & 63 + 63))
  else
    # Not supported for very large graphs in this simple impl
    error("Graph too large for simple graph6 encoder")
  end

  # 2. Encode Adjacency Matrix (Upper triangle)
  # x_ij for 0 <= i < j < n
  # We iterate i from 0 to n-2, j from i+1 to n-1 (0-indexed)
  # Julia is 1-indexed: i from 1 to n-1, j from i+1 to n

  bit_buffer = 0
  bit_count = 0

  for j in 2:n
    for i in 1:j-1
      bit = has_edge(g, i, j) ? 1 : 0
      bit_buffer = (bit_buffer << 1) | bit
      bit_count += 1

      if bit_count == 6
        write(res, UInt8(bit_buffer + 63))
        bit_buffer = 0
        bit_count = 0
      end
    end
  end

  if bit_count > 0
    # Pad with zeros
    bit_buffer = bit_buffer << (6 - bit_count)
    write(res, UInt8(bit_buffer + 63))
  end

  return String(take!(res))
end

end
