# STCounterexampleCheck

This project implements a search for counterexamples to the Symmetric Tensor conjecture using Julia.
本プロジェクトは、Juliaを用いて対称テンソルマトロイドの反例を探索するプログラムを実装したものです。

## Directory Structure / ディレクトリ構成

### `src/` Directory / `src/` ディレクトリ

This directory contains the core source code of the package.
このディレクトリには、パッケージのコアソースコードが含まれています。

- **`STCounterexampleCheck.jl`**
    - **English**: The main module file. It exports the public API and includes all other submodules.
    - **日本語**: メインモジュールファイルです。公開APIをエクスポートし、他のすべてのサブモジュールをインクルードします。

- **`Types.jl`**
    - **English**: Defines custom data types used throughout the project.
        - `STV`: Symmetric Tensor Vector (Vector{Int})
        - `STM`: Symmetric Tensor Matrix (Matrix{Int})
        - `Embedding`: Vertex embedding matrix (Matrix{Int})
    - **日本語**: プロジェクト全体で使用されるカスタムデータ型を定義します。
        - `STV`: 対称テンソルベクトル (Vector{Int})
        - `STM`: 対称テンソル行列 (Matrix{Int})
        - `Embedding`: 頂点埋め込み行列 (Matrix{Int})

- **`GraphUtils.jl`**
    - **English**: Provides utilities for graph manipulation and validation.
        - `read_graphs_from_file`: Reads graphs from a file in graph6 format.
        - `check_graph_constraints`: Checks constraints like edge count, direction, and degree.
        - `to_graph6`: Converts a graph object to a graph6 string (manual implementation).
    - **日本語**: グラフの操作と検証のためのユーティリティを提供します。
        - `read_graphs_from_file`: graph6形式のファイルからグラフを読み込みます。
        - `check_graph_constraints`: 辺の数、有向性、次数などの制約をチェックします。
        - `to_graph6`: グラフオブジェクトをgraph6文字列に変換します（独自実装）。

- **`Algebra.jl`**
    - **English**: Implements algebraic computations over the finite field $\mathbb{Z}_p$ ($p=2^{31}-1$).
        - `generate_embedding`: Generates a random embedding matrix.
        - `generate_matrix`: Constructs the Symmetric Tensor Matrix (STM) from a graph and embedding.
        - `compute_rank`: Computes the rank of a matrix using Gaussian elimination.
    - **日本語**: 有限体 $\mathbb{Z}_p$ ($p=2^{31}-1$) 上の代数計算を実装します。
        - `generate_embedding`: ランダムな埋め込み行列を生成します。
        - `generate_matrix`: グラフと埋め込みから対称テンソル行列 (STM) を構築します。
        - `compute_rank`: ガウスの消去法を用いて行列のランクを計算します。

- **`Matroid.jl`**
    - **English**: Handles matroid-theoretic operations.
        - `find_circuit`: Identifies a circuit (minimal dependent set) in the matroid.
        - `find_closure`: Computes the closure of a given set of edges.
    - **日本語**: マトロイド理論に基づく操作を扱います。
        - `find_circuit`: マトロイド内のサーキット（極小従属集合）を特定します。
        - `find_closure`: 与えられた辺集合の閉包を計算します。

- **`ClassCheck.jl`**
    - **English**: Verifies graph membership in the family $\mathcal{C}_{n,t}$.
        - `is_in_C`: General recursive check for $\mathcal{C}_{n,t}$.
        - `identify_C_n6_index`: Checks if a graph matches one of the specific types in $\mathcal{C}_{n,6}$ and returns its index.
    - **日本語**: グラフが族 $\mathcal{C}_{n,t}$ に属するかどうかを検証します。
        - `is_in_C`: $\mathcal{C}_{n,t}$ に対する一般的な再帰的チェック。
        - `identify_C_n6_index`: グラフが $\mathcal{C}_{n,6}$ の特定の型に一致するか確認し、そのインデックスを返します。

- **`Output.jl`**
    - **English**: Defines result data structures and output logic.
        - Structs: `IndependentResult`, `DependentResult`, `CounterexampleResult`, `ExceptionResult`.
        - Functions: `output_*` functions that push results to a `Channel`.
    - **日本語**: 結果のデータ構造と出力ロジックを定義します。
        - 構造体: `IndependentResult`, `DependentResult`, `CounterexampleResult`, `ExceptionResult`。
        - 関数: 結果を `Channel` にプッシュする `output_*` 関数群。

- **`Main.jl`**
    - **English**: Orchestrates the workflow using a Producer-Consumer pattern.
        - `core_main`: Processes a single graph and sends the result to a channel.
        - `writer_task`: Consumer task that writes results from the channel to `.bin` (MsgPack) and `.jsonl` files.
        - `workflow`: Manages parallel execution of `core_main` (Producers) and the `writer_task` (Consumer).
    - **日本語**: プロデューサー・コンシューマーパターンを用いてワークフローを統括します。
        - `core_main`: 単一のグラフを処理し、結果をチャンネルに送信します。
        - `writer_task`: チャンネルから結果を受け取り、`.bin` (MsgPack) および `.jsonl` ファイルに書き込むコンシューマータスク。
        - `workflow`: `core_main`（プロデューサー）と `writer_task`（コンシューマー）の並列実行を管理します。

### `test/` Directory / `test/` ディレクトリ

This directory contains verification scripts and unit tests.
このディレクトリには、検証用スクリプトと単体テストが含まれています。

- **`verify.jl`**
    - **English**: The primary verification script. It runs the full `workflow` on a set of sample graphs (Independent, Dependent, Exception) and verifies that the output files are correctly created and contain the expected data.
    - **日本語**: 主要な検証スクリプトです。サンプルグラフ（独立、従属、例外）のセットに対して完全な `workflow` を実行し、出力ファイルが正しく作成され、期待されるデータが含まれていることを検証します。

- **`test_core.jl`**
    - **English**: Unit tests for individual core components (constraints, matrix generation, rank, etc.).
    - **日本語**: 個々のコアコンポーネント（制約、行列生成、ランクなど）の単体テストです。

- **`test_k35.jl`**
    - **English**: A focused test script for the $K_{3,5}$ graph. This graph is a known dependent graph in $\mathcal{C}_{n,6}$, and this script ensures it is correctly classified and output.
    - **日本語**: $K_{3,5}$ グラフに焦点を当てたテストスクリプトです。このグラフは $\mathcal{C}_{n,6}$ における既知の従属グラフであり、このスクリプトはそれが正しく分類・出力されることを確認します。

- **`test_output.jl`**
    - **English**: Tests for the output functions (older unit tests).
    - **日本語**: 出力関数のためのテスト（古い単体テスト）。
