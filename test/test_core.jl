using STCounterexampleCheck
using STCounterexampleCheck.GraphUtils
using STCounterexampleCheck.Algebra
using STCounterexampleCheck.Types
using Graphs

println("Testing Core Logic...")

g = SimpleGraph(10)

println("1. Constraints")
valid, reason = STCounterexampleCheck.GraphUtils.check_graph_constraints(g, 21, 0, 1000)
println("Valid: $valid, Reason: $reason")

println("2. Embedding")
p = STCounterexampleCheck.Algebra.generate_embedding(10, 6)
println("Embedding size: $(size(p))")

println("3. Matrix")
M, phi = STCounterexampleCheck.Algebra.generate_matrix(g, p)
println("Matrix size: $(size(M))")
println("Phi length: $(length(phi))")

println("4. Rank")
r = STCounterexampleCheck.Algebra.compute_rank(M)
println("Rank: $r")

println("5. Core Main")
STCounterexampleCheck.core_main(g)
println("Core Main success")
