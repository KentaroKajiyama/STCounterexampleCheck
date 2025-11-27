using STCounterexampleCheck
using STCounterexampleCheck.Output
using Graphs
using STCounterexampleCheck.Types

# Ensure output dir exists
if !isdir("output_verify")
  mkdir("output_verify")
end
ENV["OUTPUT_DIR"] = "output_verify"

println("Testing Output...")

g = SimpleGraph(10)
phi = STCounterexampleCheck.Types.STV[] # Empty vector of edges? No, phi is Vector{Edge}
phi = Edge[]
p = zeros(Int, 10, 6)

try
  output_independent(g, phi, p)
  println("output_independent success")
catch e
  showerror(stdout, e, catch_backtrace())
  println()
end
