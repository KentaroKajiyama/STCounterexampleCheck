using Pkg
Pkg.activate(".")
try
  println("Adding MsgPack...")
  Pkg.add("MsgPack")
  println("MsgPack added successfully.")
catch e
  println("Error adding MsgPack: ", e)
  exit(1)
end
