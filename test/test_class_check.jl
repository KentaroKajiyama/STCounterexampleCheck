using Test
using Graphs
using STCounterexampleCheck
using STCounterexampleCheck.ClassCheck

# ==============================================================================
# Helper Functions for Graph Construction
# ==============================================================================

"""
    disjoint_union(g1, g2)
Returns the disjoint union of two graphs.
"""
function disjoint_union(g1::AbstractGraph, g2::AbstractGraph)
    return blockdiag(g1, g2)
end

"""
    graph_join(g1, g2)
Returns the join of two graphs G1 + G2.
"""
function graph_join(g1::AbstractGraph, g2::AbstractGraph)
    nv1 = nv(g1)
    nv2 = nv(g2)
    g = blockdiag(g1, g2)
    for i in 1:nv1
        for j in 1:nv2
            add_edge!(g, i, nv1 + j)
        end
    end
    return g
end

# ==============================================================================
# Test Set
# ==============================================================================

@testset "ClassCheck Coverage Tests (n=10, t=6)" begin
    n = 10
    t = 6

    # ----------------------------------------------------------------------
    # 1. Index 1: Complete Graph (K_n) [NEW]
    # ----------------------------------------------------------------------
    @testset "Index 1: K_n (Complete Graph)" begin
        g = complete_graph(n)
        @test is_in_C(g, n, t)
        @test identify_C_n6_index(g, n) == 1
    end

    # ----------------------------------------------------------------------
    # 2. Index 2: Empty Graph (K_n_bar) [Shifted from 1]
    # ----------------------------------------------------------------------
    @testset "Index 2: K_n_bar" begin
        g = SimpleGraph(n) # 孤立点のみ
        @test is_in_C(g, n, t)
        @test identify_C_n6_index(g, n) == 2
    end

    # ----------------------------------------------------------------------
    # 3-7. Join Types: K_k + K_{n-k}_bar [Shifted from 2-6]
    # ----------------------------------------------------------------------
    @testset "Indices 3-7: K_k + K_bar" begin
        # Index 3: K1 + K9_bar
        g3 = graph_join(complete_graph(1), SimpleGraph(9))
        @test is_in_C(g3, n, t)
        @test identify_C_n6_index(g3, n) == 3

        # Index 4: K2 + K8_bar
        g4 = graph_join(complete_graph(2), SimpleGraph(8))
        @test is_in_C(g4, n, t)
        @test identify_C_n6_index(g4, n) == 4

        # Index 5: K3 + K7_bar
        g5 = graph_join(complete_graph(3), SimpleGraph(7))
        @test is_in_C(g5, n, t)
        @test identify_C_n6_index(g5, n) == 5

        # Index 6: K4 + K6_bar
        g6 = graph_join(complete_graph(4), SimpleGraph(6))
        @test is_in_C(g6, n, t)
        @test identify_C_n6_index(g6, n) == 6

        # Index 7: K5 + K5_bar
        g7 = graph_join(complete_graph(5), SimpleGraph(5))
        @test is_in_C(g7, n, t)
        @test identify_C_n6_index(g7, n) == 7
    end

    # ----------------------------------------------------------------------
    # 8-11. Bipartite Union Types [Shifted from 7-10]
    # ----------------------------------------------------------------------
    @testset "Indices 8-11: K_{a,b} U K_bar" begin
        # Index 8: K3,5 U K2_bar
        k35 = complete_bipartite_graph(3, 5)
        g8 = disjoint_union(k35, SimpleGraph(2))
        @test is_in_C(g8, n, t)
        @test identify_C_n6_index(g8, n) == 8

        # Index 9: K4,4 U K2_bar
        k44 = complete_bipartite_graph(4, 4)
        g9 = disjoint_union(k44, SimpleGraph(2))
        @test is_in_C(g9, n, t)
        @test identify_C_n6_index(g9, n) == 9

        # Index 10: K4,5 U K1_bar
        k45 = complete_bipartite_graph(4, 5)
        g10 = disjoint_union(k45, SimpleGraph(1))
        @test is_in_C(g10, n, t)
        @test identify_C_n6_index(g10, n) == 10

        # Index 11: K5,5 U K0_bar
        g11 = complete_bipartite_graph(5, 5)
        @test is_in_C(g11, n, t)
        @test identify_C_n6_index(g11, n) == 11
    end

    # ----------------------------------------------------------------------
    # 12-14. Recursive Join Types [Shifted from 11-13]
    # ----------------------------------------------------------------------
    @testset "Indices 12-14: Recursive Structures" begin
        # Index 12: K1 + (K3,4 U K_{n-8}_bar)
        inner12 = disjoint_union(complete_bipartite_graph(3, 4), SimpleGraph(2))
        g12 = graph_join(complete_graph(1), inner12)
        @test is_in_C(g12, n, t)
        @test identify_C_n6_index(g12, n) == 12

        # Index 13: K1 + (K4,4 U K_{n-9}_bar)
        inner13 = disjoint_union(complete_bipartite_graph(4, 4), SimpleGraph(1))
        g13 = graph_join(complete_graph(1), inner13)
        @test is_in_C(g13, n, t)
        @test identify_C_n6_index(g13, n) == 13

        # Index 14: K2 + (K3,3 U K_{n-8}_bar)
        inner14 = disjoint_union(complete_bipartite_graph(3, 3), SimpleGraph(2))
        g14 = graph_join(complete_graph(2), inner14)
        @test is_in_C(g14, n, t)
        @test identify_C_n6_index(g14, n) == 14
    end

    # ----------------------------------------------------------------------
    # Negative Cases
    # ----------------------------------------------------------------------
    @testset "Negative Cases" begin
        # Case: Cycle Graph C10
        # 2部グラフだが完全2部ではない
        g_cycle = cycle_graph(n)
        @test !is_in_C(g_cycle, n, t)
        @test identify_C_n6_index(g_cycle, n) == 0

        # Case: K2,8 (Partition size violation: a=2)
        k28 = complete_bipartite_graph(2, 8)
        @test !is_in_C(k28, n, t)
        @test identify_C_n6_index(k28, n) == 0

        # Case: K2,6 U K2_bar (Partition size violation)
        g_k26 = disjoint_union(complete_bipartite_graph(2, 6), SimpleGraph(2))
        @test !is_in_C(g_k26, n, t)
        @test identify_C_n6_index(g_k26, n) == 0

        # Case: K3,5 missing one edge
        k35_missing = complete_bipartite_graph(3, 5)
        rem_edge!(k35_missing, 1, 3 + 1)
        g_missing = disjoint_union(k35_missing, SimpleGraph(2))
        @test !is_in_C(g_missing, n, t)
        @test identify_C_n6_index(g_missing, n) == 0

        # Case: Multiple non-trivial components (K3,3 U K2,2)
        k33 = complete_bipartite_graph(3, 3)
        k22 = complete_bipartite_graph(2, 2)
        g_multi = disjoint_union(k33, k22)
        @test !is_in_C(g_multi, n, t)
        @test identify_C_n6_index(g_multi, n) == 0
    end
end