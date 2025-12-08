import msgpack
import networkx as nx
import sys
import argparse
import os

# ==========================================
# 1. フォーマット定義
# ==========================================
def format_list(lst):
    """リスト [1, 2] を文字列 "1,2" に変換"""
    return ",".join(map(str, lst))

def format_edges(edges):
    """辺のリスト [(0,1), (2,3)] を文字列 "0:1,2:3" に変換"""
    return ",".join([f"{u}:{v}" for u, v in edges])

# ==========================================
# 2. 変換ロジック (メイン処理)
# ==========================================
def convert_msgpack_to_txt(input_path, output_path):
    print(f"Loading {input_path}...")
    
    try:
        # MessagePackストリームを扱うため Unpacker を使用
        unpacker = msgpack.Unpacker(open(input_path, "rb"), raw=False)
        
    except FileNotFoundError:
        print(f"Error: Input file '{input_path}' not found.")
        sys.exit(1)
    except Exception as e:
        print(f"Error reading messagepack: {e}")
        sys.exit(1)

    print(f"Reading records. Converting...")

    try:
        # 出力ファイルヘッダーを定義 (全てのデータ構造に対応できる列名)
        # Type, Seed, C_indices, F_indices, Class_index, Edges
        with open(output_path, "w") as f:
            count = 0
            
            for record in unpacker:
                try:
                    version = record[0]
                    
                    # 共通要素
                    g6_str = record[1]
                    seed = record[2]
                    
                    # Graph6 のパース (全タイプ共通)
                    try:
                        g6_bytes = g6_str.encode('utf-8')
                        G = nx.from_graph6_bytes(g6_bytes)
                        n = G.number_of_nodes()
                        edges = format_edges(list(G.edges()))
                    except Exception as e:
                        print(f"Warning: Failed to parse graph6 string '{g6_str}' (Type {version}). Skipping. Error: {e}")
                        continue
                    
                    # タイプごとのデータ展開とフォーマット
                    if version == 0:  # IndependentResult: [0, g6, seed]
                        # C_indices, F_indices, Class_index は空欄/デフォルト値
                        c_indices = "0"
                        f_indices = "0"
                        class_index = "0"
                        
                        # データ要素数が3であることを確認
                        if len(record) != 3:
                            raise IndexError("IndependentResult has unexpected number of elements.")

                    elif version == 1:  # DependentResult: [1, g6, seed, C_indices, F_indices, Class_index]
                        # 特定の要素を取り出し、フォーマット
                        c_indices = format_list(record[3])
                        f_indices = format_list(record[4])
                        class_index = str(record[5])
                        
                        # データ要素数が6であることを確認
                        if len(record) != 6:
                            raise IndexError("DependentResult has unexpected number of elements.")

                    elif version == 2:  # ForbiddenGraphResult: [2, g6, seed]
                        # C_indices, F_indices, Class_index は空欄/デフォルト値
                        # seedは通常1だが、元のデータ構造を尊重
                        c_indices = "0"
                        f_indices = "0"
                        class_index = "0"
                        
                        # データ要素数が3であることを確認
                        if len(record) != 3:
                            raise IndexError("ForbiddenGraphResult has unexpected number of elements.")
                    
                    else:
                        print(f"Warning: Unknown version type {version}. Skipping.")
                        continue

                    # 文字列へのフォーマット (共通)
                    # 出力形式: Version Seed C_indices F_indices Class_index Edges
                    line_parts = [
                        str(version),
                        str(seed),
                        str(n),
                        c_indices,
                        f_indices,
                        class_index,
                        edges
                    ]
                    
                    line = " ".join(line_parts) + "\n"
                    f.write(line)
                    count += 1

                except IndexError as ie:
                    print(f"Warning: Skipping a malformed record (IndexError: {ie}). Record: {record}")
                    continue
                except Exception as ex:
                    print(f"Warning: Skipping record due to unexpected error. Error: {ex}. Record: {record}")
                    continue
            
            print(f"Successfully converted {count} records.")
            print(f"Output saved to: {output_path}")

    except Exception as e:
        print(f"Error writing to output file or during conversion: {e}")
        sys.exit(1)

# ==========================================
# 3. テストデータの生成 (オプション)
# ==========================================
def generate_dummy_data(filename):
    print(f"Generating dummy data to {filename}...")
    
    # DependentResult (Type 1)
    G_dep = nx.path_graph(3) 
    g6_dep_bytes = nx.to_graph6_bytes(G_dep, header=False).rstrip(b'\n')
    g6_dep = g6_dep_bytes.decode('utf-8')
    data_dep = [1, g6_dep, 42, [0, 2], [1], 5] # 6要素

    # IndependentResult (Type 0)
    G_ind = nx.cycle_graph(4)
    g6_ind_bytes = nx.to_graph6_bytes(G_ind, header=False).rstrip(b'\n')
    g6_ind = g6_ind_bytes.decode('utf-8')
    data_ind = [0, g6_ind, 99] # 3要素

    # ForbiddenGraphResult (Type 2)
    G_forb = nx.complete_graph(2)
    g6_forb_bytes = nx.to_graph6_bytes(G_forb, header=False).rstrip(b'\n')
    g6_forb = g6_forb_bytes.decode('utf-8')
    data_forb = [2, g6_forb, 1] # 3要素
    
    with open(filename, "wb") as f:
        # MessagePackストリームとして独立して書き込む
        f.write(msgpack.pack(data_dep))
        f.write(msgpack.pack(data_ind))
        f.write(msgpack.pack(data_forb))

# ==========================================
# メイン実行ブロック
# ==========================================
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert MessagePack (Graph6) to Text for Lean 4. Handles different result types.")
    
    # 引数の定義
    parser.add_argument("input", help="Path to input MessagePack file")
    parser.add_argument("output", help="Path to output Text file")
    parser.add_argument("--gen-dummy", action="store_true", help="Generate dummy data to the input path before converting")

    args = parser.parse_args()

    # ダミーデータ生成フラグがある場合
    if args.gen_dummy:
        generate_dummy_data(args.input)

    # 変換実行
    convert_msgpack_to_txt(args.input, args.output)