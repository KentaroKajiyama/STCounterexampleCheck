module GraphUtils

export read_graphs_from_file, check_graph_constraints, to_graph6

using Graphs
using GraphIO

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
