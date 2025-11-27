using Pkg
Pkg.activate(".")
try
  Pkg.add("Nemo")
  println("Nemo added successfully.")
catch e
  println("Error adding Nemo: ", e)
  exit(1)
end
