using STCounterexampleCheck
using Graphs
using MsgPack
using JSON

println("Testing Workflow with Producer-Consumer...")

# Create test graphs
g1 = SimpleGraph(10) # Independent
g2 = SimpleGraph(10) # Exception (Too many edges)
count = 0
for i in 1:10
  for j in i+1:10
    add_edge!(g2, i, j)
    global count += 1
    if count >= 22
      break
    end
  end
  if count >= 22
    break
  end
end

g3 = SimpleGraph(10) # Dependent (K3,5)
for i in 1:3
  for j in 4:8
    add_edge!(g3, i, j)
  end
end

graphs = [g1, g2, g3]

# Run workflow
ENV["OUTPUT_DIR"] = "output_verify_new"
if isdir("output_verify_new")
  rm("output_verify_new", recursive=true)
end

try
  workflow(graphs)
  println("Workflow finished.")
catch e
  showerror(stdout, e, catch_backtrace())
  println()
end

# Verify outputs
println("Verifying outputs...")
bin_path = joinpath("output_verify_new", "output.bin")
counter_path = joinpath("output_verify_new", "counterexample.jsonl")
exception_path = joinpath("output_verify_new", "exception.jsonl")

if isfile(bin_path)
  println("output.bin exists.")
  # Read MessagePack
  # We need to read sequentially.
  open(bin_path) do io
    while !eof(io)
      try
        obj = MsgPack.unpack(io)
        println("Bin Object: ", obj)
      catch e
        println("Error unpacking: ", e)
        break
      end
    end
  end
else
  println("output.bin MISSING")
end

if isfile(counter_path)
  println("counterexample.jsonl exists.")
  for line in eachline(counter_path)
    println("Counterexample: ", line)
  end
else
  println("counterexample.jsonl MISSING (Expected if no counterexamples)")
end

if isfile(exception_path)
  println("exception.jsonl exists.")
  for line in eachline(exception_path)
    println("Exception: ", line)
  end
else
  println("exception.jsonl MISSING")
end
