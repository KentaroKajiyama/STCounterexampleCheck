module ClassCheck

export is_in_C, identify_C_n6_index

using Graphs
using ..Types

"""
    is_in_C(g::AbstractGraph, n::Int, t::Int)

Checks if graph g (with n vertices) is in C_{n,t}.
"""
function is_in_C(g::AbstractGraph, n::Int, t::Int)
  if nv(g) != n
    return false
  end

  if t >= 1 && n <= t + 1
    return ne(g) == 0
  end

  if t == 1
    if ne(g) == 0
      return true
    end
    if ne(g) == n * (n - 1) ÷ 2
      return true
    end
    return false
  end

  if ne(g) == 0
    return true
  end

  if is_bipartite(g)
    components = connected_components(g)
    nontrivial_comps = filter(c -> length(c) > 1, components)

    if length(nontrivial_comps) == 1
      comp_nodes = nontrivial_comps[1]
      subg, _ = induced_subgraph(g, comp_nodes)

      color_map = bipartite_map(subg)
      if !isempty(color_map)
        part1 = count(x -> x == 1, color_map)
        part2 = count(x -> x == 2, color_map)
        a, b = part1, part2

        if ne(subg) == a * b
          if (3 <= a <= t - 1 && 3 <= b <= t - 1 && t + 2 <= a + b <= n)
            return true
          end
        end
      end
    end
  end

  for v in vertices(g)
    if degree(g, v) == n - 1
      subset = filter(u -> u != v, vertices(g))
      subg, _ = induced_subgraph(g, subset)
      if is_in_C(subg, n - 1, t - 1)
        return true
      end
    end
  end

  return false
end

"""
    identify_C_n6_index(g::AbstractGraph, n::Int)

Identifies the index of g in the specific C_{n,6} list.
Returns index (1-13) or 0 if not found.
"""
function identify_C_n6_index(g::AbstractGraph, n::Int)
  if ne(g) == 0
    return 1
  end

  function check_Kab_union_Kbar(graph, total_n, a, b)
    if ne(graph) != a * b
      return false
    end
    if !is_bipartite(graph)
      return false
    end
    comps = connected_components(graph)
    nontrivial = filter(c -> length(c) > 1, comps)
    if length(nontrivial) != 1
      return false
    end
    comp = nontrivial[1]
    if length(comp) != a + b
      return false
    end
    subg, _ = induced_subgraph(graph, comp)
    color_map = bipartite_map(subg)
    part1 = count(x -> x == 1, color_map)
    part2 = count(x -> x == 2, color_map)
    return Set([part1, part2]) == Set([a, b])
  end

  function check_join(graph, k, check_H_func)
    universals = [v for v in vertices(graph) if degree(graph, v) == nv(graph) - 1]
    if length(universals) < k
      return false
    end
    to_remove = universals[1:k]
    subset = filter(v -> !(v in to_remove), vertices(graph))
    subg, _ = induced_subgraph(graph, subset)
    return check_H_func(subg)
  end

  if check_join(g, 1, h -> ne(h) == 0)
    return 2
  end
  if check_join(g, 2, h -> ne(h) == 0)
    return 3
  end
  if check_join(g, 3, h -> ne(h) == 0)
    return 4
  end
  if check_join(g, 4, h -> ne(h) == 0)
    return 5
  end
  if check_join(g, 5, h -> ne(h) == 0)
    return 6
  end

  if check_Kab_union_Kbar(g, n, 3, 5)
    return 7
  end
  if check_Kab_union_Kbar(g, n, 4, 4)
    return 8
  end
  if check_Kab_union_Kbar(g, n, 4, 5)
    return 9
  end
  if check_Kab_union_Kbar(g, n, 5, 5)
    return 10
  end

  if check_join(g, 1, h -> check_Kab_union_Kbar(h, n - 1, 3, 4))
    return 11
  end
  if check_join(g, 1, h -> check_Kab_union_Kbar(h, n - 1, 4, 4))
    return 12
  end
  if check_join(g, 2, h -> check_Kab_union_Kbar(h, n - 2, 3, 3))
    return 13
  end

  return 0
end

end
