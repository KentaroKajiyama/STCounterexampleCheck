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
        with open(input_path, "rb") as f:
            # ファイル全体を一括で読み込む
            dataset = msgpack.unpack(f, raw=False)
            
    except FileNotFoundError:
        print(f"Error: Input file '{input_path}' not found.")
        sys.exit(1)
    except Exception as e:
        print(f"Error reading messagepack: {e}")
        sys.exit(1)

    print(f"Found {len(dataset)} records. Converting...")

    try:
        with open(output_path, "w") as f:
            count = 0
            for record in dataset:
                try:
                    # データの解凍: [ver, g6, seed, c_inds, f_inds, cls_ind]
                    version = record[0]
                    g6_str = record[1]
                    seed = record[2]
                    c_indices = record[3]
                    f_indices = record[4]
                    class_index = record[5]

                    # Graph6 のパース
                    try:
                        G = nx.from_graph6_string(g6_str)
                        edges = list(G.edges())
                    except Exception as e:
                        print(f"Warning: Failed to parse graph6 string '{g6_str}'. Skipping.")
                        continue

                    # 文字列へのフォーマット
                    line_parts = [
                        str(version),
                        str(seed),
                        format_list(c_indices),
                        format_list(f_indices),
                        str(class_index),
                        format_edges(edges)
                    ]
                    
                    line = " ".join(line_parts) + "\n"
                    f.write(line)
                    count += 1

                except IndexError:
                    print("Warning: Skipping a malformed record.")
                    continue
        
        print(f"Successfully converted {count} records.")
        print(f"Output saved to: {output_path}")

    except Exception as e:
        print(f"Error writing to output file: {e}")
        sys.exit(1)

# ==========================================
# 3. テストデータの生成 (オプション)
# ==========================================
def generate_dummy_data(filename):
    print(f"Generating dummy data to {filename}...")
    G1 = nx.path_graph(3) 
    g6_1 = nx.to_graph6_string(G1, header=False)
    G2 = nx.complete_graph(4)
    g6_2 = nx.to_graph6_string(G2, header=False)

    data = [
        [1, g6_1, 42, [0, 2], [1], 5],
        [1, g6_2, 99, [0, 1], [2, 3], 1]
    ]
    
    with open(filename, "wb") as f:
        msgpack.pack(data, f)

# ==========================================
# メイン実行ブロック
# ==========================================
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert MessagePack (Graph6) to Text for Lean 4.")
    
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

# python convert_msgpack.py my_data.msgpack graph_output.txt
# python convert_msgpack.py test_data.msgpack result.txt --gen-dummy
# python convert_msgpack.py -h