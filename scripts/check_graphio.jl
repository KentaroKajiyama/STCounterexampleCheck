using GraphIO
println("--- GraphIO Names ---")
for n in names(GraphIO; all=true)
  println(n)
end

println("\n--- Submodules ---")
try
  import GraphIO.Graph6
  println("GraphIO.Graph6 imported successfully.")
  println("Names in GraphIO.Graph6: ", names(GraphIO.Graph6))
catch e
  println("Failed to import GraphIO.Graph6: ", e)
end

println("\n--- Graph6Format Check ---")
try
  println("Graph6Format: ", Graph6Format)
catch
  println("Graph6Format not defined.")
end
