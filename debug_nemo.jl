using Nemo

P_VAL = 2147483647
Fp = GF(P_VAL)
M = zero_matrix(Fp, 2, 2)
println("Type of M: ", typeof(M))
println("gfp_mat defined? ", isdefined(Nemo, :gfp_mat))
if isdefined(Nemo, :gfp_mat)
  println("gfp_mat: ", Nemo.gfp_mat)
end
