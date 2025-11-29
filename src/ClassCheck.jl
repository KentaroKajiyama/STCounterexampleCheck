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

  # Check for Complete Graph explicitly
  if ne(g) == n * (n - 1) ÷ 2
      return true
  end

  return false
end

"""
    identify_C_n6_index(g::AbstractGraph, n::Int)

Identifies the index of g in the specific C_{n,6} list.
Returns index (1-14) or 0 if not found.

Indices:
1: K_n (Complete Graph)
2: K_n_bar
3: K1 + K_{n-1}_bar
4: K2 + K_{n-2}_bar
5: K3 + K_{n-3}_bar
6: K4 + K_{n-4}_bar
7: K5 + K_{n-5}_bar
8: K3,5 U K_{n-8}_bar
9: K4,4 U K_{n-8}_bar
10: K4,5 U K_{n-9}_bar
11: K5,5 U K_{n-10}_bar
12: K1 + (K3,4 U K_{n-8}_bar)
13: K1 + (K4,4 U K_{n-9}_bar)
14: K2 + (K3,3 U K_{n-8}_bar)
"""
function identify_C_n6_index(g::AbstractGraph, n::Int)
  # 1. Complete Graph (K_n)
  if ne(g) == n * (n - 1) ÷ 2
    return 1
  end

  # 2. Empty Graph (K_n_bar)
  if ne(g) == 0
    return 2
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

  # 3-7: K_k + K_bar (shifted from 2-6)
  if check_join(g, 1, h -> ne(h) == 0)
    return 3
  end
  if check_join(g, 2, h -> ne(h) == 0)
    return 4
  end
  if check_join(g, 3, h -> ne(h) == 0)
    return 5
  end
  if check_join(g, 4, h -> ne(h) == 0)
    return 6
  end
  if check_join(g, 5, h -> ne(h) == 0)
    return 7
  end

  # 8-11: Bipartite Union (shifted from 7-10)
  if check_Kab_union_Kbar(g, n, 3, 5)
    return 8
  end
  if check_Kab_union_Kbar(g, n, 4, 4)
    return 9
  end
  if check_Kab_union_Kbar(g, n, 4, 5)
    return 10
  end
  if check_Kab_union_Kbar(g, n, 5, 5)
    return 11
  end

  # 12-14: Recursive Join (shifted from 11-13)
  if check_join(g, 1, h -> check_Kab_union_Kbar(h, n - 1, 3, 4))
    return 12
  end
  if check_join(g, 1, h -> check_Kab_union_Kbar(h, n - 1, 4, 4))
    return 13
  end
  if check_join(g, 2, h -> check_Kab_union_Kbar(h, n - 2, 3, 3))
    return 14
  end

  return 0
end

"""
    identify_C_n5_index(g::AbstractGraph, n::Int)

Identifies the index of g in the C_{n,5} list.
Returns index (1-9) or 0 if not found.

List for C_{n,5}:
1. K_n
2. K_n_bar
3. K1 + K_{n-1}_bar
4. K2 + K_{n-2}_bar
5. K3 + K_{n-3}_bar
6. K4 + K_{n-4}_bar
7. K3,4 U K_{n-7}_bar
8. K4,4 U K_{n-8}_bar
9. K1 + (K3,3 U K_{n-7}_bar)
"""
function identify_C_n5_index(g::AbstractGraph, n::Int)
    # 1. K_n
    if ne(g) == n * (n - 1) ÷ 2
        return 1
    end
    # 2. K_n_bar
    if ne(g) == 0
        return 2
    end

    # Reuse helpers (local copies or define globally if preferred)
    function check_Kab_union_Kbar(graph, total_n, a, b)
        if ne(graph) != a * b; return false; end
        if !is_bipartite(graph); return false; end
        comps = connected_components(graph)
        nontrivial = filter(c -> length(c) > 1, comps)
        if length(nontrivial) != 1; return false; end
        comp = nontrivial[1]
        if length(comp) != a + b; return false; end
        subg, _ = induced_subgraph(graph, comp)
        color_map = bipartite_map(subg)
        part1 = count(x -> x == 1, color_map)
        part2 = count(x -> x == 2, color_map)
        return Set([part1, part2]) == Set([a, b])
    end

    function check_join(graph, k, check_H_func)
        universals = [v for v in vertices(graph) if degree(graph, v) == nv(graph) - 1]
        if length(universals) < k; return false; end
        to_remove = universals[1:k]
        subset = filter(v -> !(v in to_remove), vertices(graph))
        subg, _ = induced_subgraph(graph, subset)
        return check_H_func(subg)
    end

    # 3-6: Join types (K1..K4)
    if check_join(g, 1, h -> ne(h) == 0); return 3; end
    if check_join(g, 2, h -> ne(h) == 0); return 4; end
    if check_join(g, 3, h -> ne(h) == 0); return 5; end
    if check_join(g, 4, h -> ne(h) == 0); return 6; end

    # 7-8: Bipartite Union
    if check_Kab_union_Kbar(g, n, 3, 4); return 7; end
    if check_Kab_union_Kbar(g, n, 4, 4); return 8; end

    # 9: Recursive Join K1 + (K3,3 U ...)
    if check_join(g, 1, h -> check_Kab_union_Kbar(h, n - 1, 3, 3)); return 9; end

    return 0
end

end