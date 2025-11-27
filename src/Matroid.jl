module Matroid

export find_circuit, find_closure

using ..Types
using ..Algebra
using Graphs

"""
    find_circuit(g::AbstractGraph, M::STM, phi::Vector{Edge})

Finds a circuit in the matroid defined by M.
Returns the list of edges forming the circuit.
"""
function find_circuit(g::AbstractGraph, M::STM, phi::Vector{Edge})
  # M has columns corresponding to phi
  # We iterate through edges and build B

  B_indices = Int[] # Indices of columns in M

  for (k, e) in enumerate(phi)
    push!(B_indices, k)

    # Check independence
    subM = M[:, B_indices]
    r = compute_rank(subM)

    if r < length(B_indices)
      # Found dependency
      # B_indices contains a circuit
      # Find the minimal dependent set C within B_indices
      C_indices = Int[]

      # A subset is a circuit if it is dependent and every proper subset is independent.
      # We know B_indices is dependent.
      # We can identify C by checking each element f in B_indices.
      # If B_indices \ {f} is independent, then f MUST be in the circuit.
      # If B_indices \ {f} is dependent, then f is NOT needed for the dependency (redundant for this specific circuit, or there's another circuit).
      # Wait, if B_indices \ {f} is dependent, it means there is a circuit inside B_indices \ {f}.
      # But we stopped at the FIRST dependency.
      # So B_indices has exactly one dependency relation (rank = size - 1).
      # In this case, B_indices IS the circuit?
      # Not necessarily. We might have added an edge that completed a circuit, but there were other independent edges added before that are not part of the circuit.
      # Example: {e1, e2} independent. Add e3. {e2, e3} is circuit. {e1, e2, e3} dependent.
      # Removing e1 -> {e2, e3} dependent. So e1 is not in circuit.
      # Removing e2 -> {e1, e3} independent. So e2 is in circuit.
      # Removing e3 -> {e1, e2} independent. So e3 is in circuit.

      # So the logic is: f is in C iff rank(B \ {f}) == rank(B).
      # Wait.
      # If B is dependent with corank 1 (which it is, because we stopped immediately),
      # then rank(B) = |B| - 1.
      # If we remove f:
      # Case 1: f in C. Then B \ {f} breaks the unique circuit. So B \ {f} is independent.
      #         rank(B \ {f}) = |B| - 1 = rank(B).
      # Case 2: f not in C. Then B \ {f} still contains C. So B \ {f} is dependent.
      #         rank(B \ {f}) = |B| - 2 (if f was independent of the rest? No)
      #         Actually, if f is not in C, and B has only one circuit C,
      #         then f is effectively "independent" relative to C?
      #         rank(B \ {f}) = rank(B) - 1? No.
      #         Let's trace: B = {e1, e2, e3}, C={e2, e3}. e1 independent of C.
      #         rank(B) = 2. |B|=3.
      #         Remove e1: {e2, e3}. rank=1. |B|-1 = 2. rank < size. Dependent.
      #         rank(B \ {e1}) = 1. rank(B) = 2. So rank decreases.
      #         Remove e2: {e1, e3}. Independent. rank=2.
      #         rank(B \ {e2}) = 2. rank(B) = 2. Rank stays same.

      # So: f in C iff rank(B \ {f}) == rank(B).
      # Wait, in the example:
      # e2 in C. rank(B \ {e2}) = 2. rank(B) = 2. Match.
      # e1 not in C. rank(B \ {e1}) = 1. rank(B) = 2. Mismatch.

      # Correct logic:
      # C = { f in B | rank(B \ {f}) == rank(B) }
      # Wait, is this universally true for matroids?
      # For a set B with a unique circuit C:
      # cl(B \ {f}) = cl(B) iff f in cl(B \ {f}).
      # If f in C, then f is spanned by C \ {f}. So f in cl(B \ {f}).
      # So rank(B \ {f}) = rank(B).
      # If f not in C, then f is NOT spanned by B \ {f} (since C is the ONLY dependency).
      # So rank(B \ {f}) = rank(B) - 1.

      # Yes, this holds.

      current_rank = r
      for f_idx in B_indices
        # Construct B \ {f}
        subset_indices = filter(x -> x != f_idx, B_indices)
        subM_f = M[:, subset_indices]
        r_f = compute_rank(subM_f)

        if r_f == current_rank
          push!(C_indices, f_idx)
        end
      end

      return phi[C_indices], C_indices
    end
  end

  return Edge[], Int[]
end

"""
    find_closure(g::AbstractGraph, M::STM, C_indices::Vector{Int}, phi::Vector{Edge})

Finds the closure of the circuit C.
Returns the list of edges in the closure.
"""
function find_closure(g::AbstractGraph, M::STM, C_indices::Vector{Int}, phi::Vector{Edge})
  # F starts as C
  F_indices = copy(C_indices)

  # Calculate rank of C (should be |C| - 1)
  subM_C = M[:, C_indices]
  rank_C = compute_rank(subM_C)

  # Iterate over all edges in G (or just G \ C, but checking C again is harmless/fast enough or we can skip)
  # The prompt says G <- G - C initially.

  # We check every edge e. If rank(C + e) == rank(C), then e is in closure.
  # Note: We should check against the CURRENT F or just C?
  # Closure of C, cl(C), is the set of all x such that rank(C + x) = rank(C).
  # This is the definition.
  # So we just compare against C.

  all_indices = 1:length(phi)
  remaining_indices = setdiff(all_indices, C_indices)

  for idx in remaining_indices
    # Check rank(C U {e})
    # We can optimize by just appending the column to the matrix of C
    # But compute_rank takes a matrix.

    # Construct matrix for C + e
    test_indices = [C_indices; idx]
    subM_test = M[:, test_indices]
    r_test = compute_rank(subM_test)

    if r_test == rank_C
      push!(F_indices, idx)
    end
  end

  return phi[F_indices], F_indices
end

end
