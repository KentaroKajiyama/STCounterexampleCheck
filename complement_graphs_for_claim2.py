import networkx as nx

def get_graph6_string(G):
    """グラフGをGraph6形式の文字列（ヘッダーなし）に変換する"""
    # header=Falseにすることで、ファイル内で1行1グラフとして扱いやすくします
    # 必要であれば header=True に変更してください
    return nx.to_graph6_bytes(G, header=False).decode('ascii').strip()

def save_graphs_to_file(filename, graphs):
    """グラフのリストを指定されたファイル名で保存する"""
    print(f"Saving {len(graphs)} graph(s) to {filename}...")
    with open(filename, 'w', encoding='ascii') as f:
        for G in graphs:
            # 次数条件と孤立点なしのチェック
            degrees = [d for n, d in G.degree()]
            assert max(degrees) <= 5, f"Max degree check failed for {filename}"
            assert min(degrees) >= 1, f"Isolation check failed for {filename}"
            
            g6_str = get_graph6_string(G)
            f.write(g6_str + '\n')

# ---------------------------------------------------------
# 1. 辺数 17, 頂点数 33 (構成: P3 + 15*K2) -> 1通り
# ---------------------------------------------------------
graphs_17_33 = []
G = nx.Graph()
G.add_edges_from([(0, 1), (1, 2)]) # P3
start_node = 3
for _ in range(15): # + 15 K2
    G.add_edge(start_node, start_node + 1)
    start_node += 2
graphs_17_33.append(G)

save_graphs_to_file("disconnected_17_node_33.g6", graphs_17_33)


# ---------------------------------------------------------
# 2. 辺数 18, 頂点数 35 (構成: P3 + 16*K2) -> 1通り
# ---------------------------------------------------------
# 辺数18で頂点数35の場合、成分数は 35-18=17個。
# 17個の成分で18辺を持つため、P3(2辺)が1つ、K2(1辺)が16個の構成のみ。
graphs_18_35 = []
G = nx.Graph()
G.add_edges_from([(0, 1), (1, 2)]) # P3
start_node = 3
for _ in range(16): # + 16 K2
    G.add_edge(start_node, start_node + 1)
    start_node += 2
graphs_18_35.append(G)

save_graphs_to_file("disconnected_18_node_35.g6", graphs_18_35)


# ---------------------------------------------------------
# 3. 辺数 18, 頂点数 34 (構成: 成分数16, 余剰辺2) -> 3通り
# ---------------------------------------------------------
# ベースは16個の成分。基本すべてK2(1辺)とすると16辺。残り2辺をどう配分するか。
# パターンA: 1つの成分に+2辺 (合計3辺の木 -> P4 or Star) + 15 K2
# パターンB: 2つの成分に+1辺ずつ (合計2辺の木 -> P3, P3) + 14 K2
graphs_18_34 = []

# A-1: P4 (0-1-2-3)
G = nx.path_graph(4) # P4
G = nx.disjoint_union(G, nx.create_empty_copy(nx.Graph(), with_data=False)) # index reset ensure
start_node = 4
for _ in range(15): G.add_edge(start_node, start_node+1); start_node+=2
graphs_18_34.append(G)

# A-2: K1,3 (Star)
G = nx.star_graph(3) # Center 0, leaves 1,2,3
start_node = 4
for _ in range(15): G.add_edge(start_node, start_node+1); start_node+=2
graphs_18_34.append(G)

# B: 2 * P3
G = nx.path_graph(3)
G = nx.disjoint_union(G, nx.path_graph(3)) # P3 + P3
start_node = 6
for _ in range(14): G.add_edge(start_node, start_node+1); start_node+=2
graphs_18_34.append(G)

save_graphs_to_file("disconnected_18_node_34.g6", graphs_18_34)


# ---------------------------------------------------------
# 4. 辺数 18, 頂点数 33 (構成: 成分数15, 余剰辺3) -> 6通り
# ---------------------------------------------------------
# ベース15個。残り3辺の配分 (Partition of 3: 3, 2+1, 1+1+1)
# 孤立点なし、次数5以下。
graphs_18_33 = []

# --- Partition [1, 1, 1] ---
# 3つの成分が+1辺される -> 3 * P3 + 12 * K2
G = nx.path_graph(3)
G = nx.disjoint_union(G, nx.path_graph(3))
G = nx.disjoint_union(G, nx.path_graph(3))
start_node = 9
for _ in range(12): G.add_edge(start_node, start_node+1); start_node+=2
graphs_18_33.append(G)

# --- Partition [2, 1] ---
# 1つが+2辺(P4 or Star), 1つが+1辺(P3)
# Case: P4 + P3 + 13*K2
G = nx.disjoint_union(nx.path_graph(4), nx.path_graph(3))
start_node = 7
for _ in range(13): G.add_edge(start_node, start_node+1); start_node+=2
graphs_18_33.append(G)

# Case: Star(K1,3) + P3 + 13*K2
G = nx.disjoint_union(nx.star_graph(3), nx.path_graph(3))
start_node = 7
for _ in range(13): G.add_edge(start_node, start_node+1); start_node+=2
graphs_18_33.append(G)

# --- Partition [3] ---
# 1つの成分が+3辺される (合計4辺、頂点数5の木) + 14 * K2
# 5頂点の木の種類: Path(P5), Star(K1,4), T-shape(Branch)

# Case: P5
G = nx.path_graph(5)
start_node = 5
for _ in range(14): G.add_edge(start_node, start_node+1); start_node+=2
graphs_18_33.append(G)

# Case: Star(K1,4) (次数4なので条件OK)
G = nx.star_graph(4)
start_node = 5
for _ in range(14): G.add_edge(start_node, start_node+1); start_node+=2
graphs_18_33.append(G)

# Case: T-shape (0-1-2-3, and 2-4)
T = nx.Graph()
T.add_edges_from([(0,1), (1,2), (2,3), (2,4)]) # 頂点2が次数3
start_node = 5
for _ in range(14): T.add_edge(start_node, start_node+1); start_node+=2
graphs_18_33.append(T)

save_graphs_to_file("disconnected_18_node_33.g6", graphs_18_33)

print("All files generated successfully.")