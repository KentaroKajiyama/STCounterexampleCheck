using Test
using Graphs
using Nemo

# パッケージとして読み込めない場合のパス設定（必要に応じて）
# push!(LOAD_PATH, "../src") 

using STCounterexampleCheck
using STCounterexampleCheck.Types
using STCounterexampleCheck.Algebra

@testset "Algebra Tests" begin

  @testset "Embedding Generation" begin
    n = 10
    t = 6

    # Test 1: Dimensions
    embed, seed = generate_embedding(n, t)
    @test size(embed) == (n, t)
    @test embed isa Matrix{Int}
    @test seed isa Int

    # Test 2: Reproducibility
    embed1, seed1 = generate_embedding(n, t, 12345)
    embed2, seed2 = generate_embedding(n, t, 12345)
    @test embed1 == embed2
    @test seed1 == 12345

    # Test 3: Different seeds
    embed3, seed3 = generate_embedding(n, t, 67890)
    @test embed1 != embed3

    # Test 4: Values in range
    @test all(0 .<= embed .< P_VAL)
  end

  @testset "Matrix Generation & Edge Sorting" begin
    # ---------------------------------------------------
    # Case 1: Manual Calculation Check (Triangle K3)
    # ---------------------------------------------------
    g = SimpleGraph(3)
    add_edge!(g, 1, 2)
    add_edge!(g, 2, 3)
    add_edge!(g, 1, 3)

    n = 3
    t = 2 
    embed = [1 0; 0 1; 1 1] # Fixed embedding

    M, phi = generate_matrix(g, embed)

    # Basic Dimensions
    @test size(M) == (3, 3)
    @test length(phi) == 3

    # Check logic values (Nemo Fp elements)
    Fp = get_Fp()
    # Col 1: Edge (1,2) -> [0, 1, 0]^T
    @test M[1, 1] == Fp(0); @test M[2, 1] == Fp(1); @test M[3, 1] == Fp(0)
    # Col 2: Edge (1,3) -> [2, 1, 0]^T
    @test M[1, 2] == Fp(2); @test M[2, 2] == Fp(1); @test M[3, 2] == Fp(0)
    # Col 3: Edge (2,3) -> [0, 1, 2]^T
    @test M[1, 3] == Fp(0); @test M[2, 3] == Fp(1); @test M[3, 3] == Fp(2)

    # ---------------------------------------------------
    # Case 2: Edge Sorting Verification (Critical!)
    # ---------------------------------------------------
    # あえて辞書順と逆に辺を追加してみる
    g_unsorted = SimpleGraph(4)
    add_edge!(g_unsorted, 3, 4) # Last
    add_edge!(g_unsorted, 1, 2) # First
    add_edge!(g_unsorted, 2, 3) # Middle
    
    # 期待される順序: (1,2), (2,3), (3,4)
    _, phi_sorted = generate_matrix(g_unsorted, generate_embedding(4, 2)[1])
    
    @test src(phi_sorted[1]) == 1 && dst(phi_sorted[1]) == 2
    @test src(phi_sorted[2]) == 2 && dst(phi_sorted[2]) == 3
    @test src(phi_sorted[3]) == 3 && dst(phi_sorted[3]) == 4
    
    println("Edge sorting test passed: Input order was mixed, output is sorted.")
    
    # ---------------------------------------------------
    # Case 3: Disconnected Graph / Isolated Vertex
    # ---------------------------------------------------
    g_iso = SimpleGraph(3)
    add_edge!(g_iso, 1, 2)
    # Vertex 3 is isolated
    
    M_iso, phi_iso = generate_matrix(g_iso, generate_embedding(3, 2)[1])
    @test size(M_iso, 2) == 1 # Only 1 edge
    @test length(phi_iso) == 1
  end

  @testset "Rank Computation" begin
    Fp = get_Fp()
    
    # 1. Square Identity (Full Rank)
    M1 = zero_matrix(Fp, 3, 3)
    M1[1, 1] = Fp(1); M1[2, 2] = Fp(1); M1[3, 3] = Fp(1)
    @test compute_rank(M1) == 3

    # 2. Deficient Rank
    M2 = zero_matrix(Fp, 3, 3)
    M2[1, 1] = Fp(1); M2[1, 2] = Fp(1)
    M2[2, 1] = Fp(1); M2[2, 2] = Fp(1) # Linear dependent
    M2[3, 3] = Fp(1)
    @test compute_rank(M2) == 2

    # 3. Rectangular Matrix (Tall: Rows > Cols)
    # [1 0]
    # [0 1]
    # [0 0] -> Rank 2
    M4 = zero_matrix(Fp, 3, 2)
    M4[1, 1] = Fp(1); M4[2, 2] = Fp(1)
    @test compute_rank(M4) == 2

    # 4. Rectangular Matrix (Wide: Cols > Rows)
    # [1 0 0]
    # [0 1 0] -> Rank 2
    M5 = zero_matrix(Fp, 2, 3)
    M5[1, 1] = Fp(1); M5[2, 2] = Fp(1)
    @test compute_rank(M5) == 2
    
    # 5. Zero Matrix
    M3 = zero_matrix(Fp, 3, 3)
    @test compute_rank(M3) == 0
    
    # 6. Empty Matrix (0 columns) - Edge case for empty graph
    M_empty = zero_matrix(Fp, 3, 0)
    @test compute_rank(M_empty) == 0
  end
end