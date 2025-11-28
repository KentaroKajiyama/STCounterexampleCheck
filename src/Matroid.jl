module Matroid

export find_circuit, find_closure

using ..Types
using ..Algebra
using Graphs
using Nemo

"""
    find_circuit(g::AbstractGraph, M::STM, phi::Vector{Edge})

行列 M (列が phi に対応) で定義されるマトロイド上のサーキットを検出します。
アルゴリズム:
1. 辺を1つずつ追加し、独立集合 B を構築する。
2. ランクが増加しなくなった瞬間(従属)、B は「ただ1つのサーキット」を含む。
3. B の各要素 f について、B \\ {f} のランクを計算する。
   - rank(B \\ {f}) == rank(B) ならば、f はサーキットの一部である (除去してもランクが下がらない = 他の要素で張れる)。
   - rank(B \\ {f}) < rank(B) ならば、f はサーキット外の要素である。

Returns:
    (circuit_edges::Vector{Edge}, circuit_indices::Vector{Int})
"""
function find_circuit(g::AbstractGraph, M::STM, phi::Vector{Edge})
    # M の列は phi の辺に対応しています
    
    B_indices = Int[] # 現在の基底候補 (列インデックス)
    
    # ランク計算用のキャッシュとして、現在までのランクを保持しても良いが
    # Nemoのrankは高速なので、都度サブセットで計算する
    
    for (k, e) in enumerate(phi)
        push!(B_indices, k)
        
        # 部分行列の作成: M[:, B_indices]
        # Nemo/AbstractAlgebra ではベクトルによるインデックス指定で新しい行列が生成される
        subM = M[:, B_indices]
        r = compute_rank(subM)
        
        # 従属判定: ランク < 列数
        if r < length(B_indices)
            # 従属集合を発見した (この時点で B_indices は唯一のサーキットを含む集合)
            # この B_indices の中から、極小従属集合 (サーキット) C を特定する
            
            C_indices = Int[]
            current_rank = r
            
            for f_idx in B_indices
                # f を除いた集合 B \ {f} を作成
                subset_indices = filter(x -> x != f_idx, B_indices)
                
                # サブセットのランク計算
                # 行列生成コストを抑えるため、本来はランクの更新式などが使えるが、
                # サイズが小さい(最大22程度)ため都度生成で十分高速
                subM_f = M[:, subset_indices]
                r_f = compute_rank(subM_f)
                
                # 判定ロジック:
                # f がサーキットに含まれる <=> B \ {f} のランクが B のランクと同じ
                # (f が他の要素の線形結合で表せるため、除いても張る空間が変わらない)
                if r_f == current_rank
                    push!(C_indices, f_idx)
                end
            end
            
            # 辞書順ルールに基づき、インデックスは昇順になっているはずだが、
            # 念のためソートしておく (filter順なので通常は昇順)
            sort!(C_indices)
            
            return phi[C_indices], C_indices
        end
    end

    # 独立 (最後までサーキットが見つからなかった場合)
    return Edge[], Int[]
end

"""
    find_closure(g::AbstractGraph, M::STM, C_indices::Vector{Int}, phi::Vector{Edge})

サーキット C の閉包 (Closure) を生成します。
定義: cl(C) = { e in E | rank(C U {e}) == rank(C) }
つまり、C の要素によって張られる空間に含まれるすべての辺を列挙します。

Returns:
    (closure_edges::Vector{Edge}, closure_indices::Vector{Int})
"""
function find_closure(g::AbstractGraph, M::STM, C_indices::Vector{Int}, phi::Vector{Edge})
    # F (閉包) の初期値は C
    F_indices = copy(C_indices)
    
    # C のランクを計算
    subM_C = M[:, C_indices]
    rank_C = compute_rank(subM_C)
    
    # G の全エッジに対して判定 (定義上、G \ C だけでなく C 内もチェックしてよいが、
    # 効率のため C に含まれないものだけをチェックする)
    
    all_indices = 1:length(phi)
    remaining_indices = setdiff(all_indices, C_indices)
    
    for idx in remaining_indices
        # テスト用部分行列: C の列 + 新しい辺 e の列
        # これにより rank(C U {e}) を計算
        
        test_indices = [C_indices; idx]
        subM_test = M[:, test_indices]
        r_test = compute_rank(subM_test)
        
        # ランクが変わらなければ、idx は閉包に含まれる
        if r_test == rank_C
            push!(F_indices, idx)
        end
    end
    
    sort!(F_indices)
    
    return phi[F_indices], F_indices
end

end