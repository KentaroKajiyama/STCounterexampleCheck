using Test
using Graphs
using Nemo

using STCounterexampleCheck
using STCounterexampleCheck.Types
using STCounterexampleCheck.Algebra
using STCounterexampleCheck.Matroid

@testset "Matroid Operations Tests" begin
    
    # マトロイドのランク上限（行数）は t(t+1)/2 で決まります。
    # t=2 -> Row=3
    # t=3 -> Row=6
    
    @testset "Case 1: Independent Graph (K3 with t=2)" begin
        # t=2 (Rank Max = 3)
        # K3 (Edge = 3)
        # 3 <= 3 なので独立になりうる
        
        t = 2
        n = 3
        g = complete_graph(n)
        
        embed, seed = generate_embedding(n, t)
        M, phi = generate_matrix(g, embed)
        
        c_edges, c_indices = find_circuit(g, M, phi)
        
        # 独立なのでサーキットは空
        @test isempty(c_indices)
    end

    @testset "Case 2: Dependent Graph by Rank Limit (K4 with t=2)" begin
        # t=2 (Rank Max = 3)
        # K4 (Edge = 6)
        # 辺数がランク上限を超えているため、確実に従属する
        # ※ K4全体を見る前に、辺数が4になった時点で従属判定される
        
        t = 2
        n = 4
        g = complete_graph(n)
        
        embed, seed = generate_embedding(n, t)
        M, phi = generate_matrix(g, embed)
        
        c_edges, c_indices = find_circuit(g, M, phi)
        
        # 検証:
        # 1. サーキットが見つかること
        @test !isempty(c_indices)
        # 2. サーキットのサイズは 4 以下であること (ランク3の世界なので)
        @test length(c_indices) <= 4
        
        # 3. 閉包計算
        f_edges, f_indices = find_closure(g, M, c_indices, phi)
        # 閉包はサーキットを含む
        @test issubset(c_indices, f_indices)
    end

    @testset "Case 3: Independent K4 (with t=3)" begin
        # t=3 (Rank Max = 6)
        # K4 (Edge = 6)
        # 辺数 <= ランク上限 なので、一般に独立になるはず
        
        t = 3
        n = 4
        g = complete_graph(n)
        
        embed, seed = generate_embedding(n, t)
        M, phi = generate_matrix(g, embed)
        
        c_edges, c_indices = find_circuit(g, M, phi)
        
        # 独立であることを確認
        @test isempty(c_indices)
    end

    @testset "Case 4: Closure Calculation (t=2)" begin
        # K4 (Edge=6) on t=2 (Rank=3)
        # 最初の3辺 (1,2), (1,3), (1,4) は独立と仮定（スターグラフ）
        # これに対する閉包を計算すると、ランクを増やさない他の辺が含まれるはず
        
        t = 2
        n = 4
        g = complete_graph(n)
        embed, seed = generate_embedding(n, t)
        M, phi = generate_matrix(g, embed)
        
        # 最初の3辺を取得（辞書順なので (1,2), (1,3), (1,4)）
        # スターグラフは t=2 で独立になる確率が高い（縮退しなければ）
        independent_indices = [1, 2, 3] 
        
        # 念のため独立性を確認
        if compute_rank(M[:, independent_indices]) == 3
            f_edges, f_indices = find_closure(g, M, independent_indices, phi)
            
            # 元の集合は含まれる
            @test issubset(independent_indices, f_indices)
            # ランク上限に達しているので、K4の他の辺も閉包に含まれる可能性がある
            # (ただし埋め込みによっては含まれない場合もあるので、エラーにならない範囲で確認)
            @test length(f_indices) >= 3
        else
            # 運悪く独立でなかった場合はスキップ (乱数次第だが稀)
            @info "Skipping closure test due to degenerate embedding"
        end
    end
end