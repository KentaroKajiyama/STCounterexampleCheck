using STCounterexampleCheck
println("Names in STCounterexampleCheck:")
println(names(STCounterexampleCheck, all=true))

println("Checking GraphUtils:")
try
  println(STCounterexampleCheck.GraphUtils)
  println(names(STCounterexampleCheck.GraphUtils, all=true))
catch e
  println("GraphUtils not found: $e")
end
