using STCounterexampleCheck
using Graphs

println("Testing K_{3,5} U K_bar (n=10)")
g3 = SimpleGraph(10)
# K_{3,5} between 1..3 and 4..8
for i in 1:3
  for j in 4:8
    add_edge!(g3, i, j)
  end
end

println("Edges: $(ne(g3))")
println("Vertices: $(nv(g3))")

try
  core_main(g3)
  println("core_main finished")
catch e
  showerror(stdout, e, catch_backtrace())
  println()
end
