# --- AST utils ---

const IGNORE_FUNCS = Set(Symbol[
    :+, :-, :*, :/, :÷, :^,
    :!=, :>, :<, :>=, :<=, :(==),
    :!, :&, :|,
    :get, :setindex!, :getindex,
    :length, :size,
    :isa, :typeof,
    :println, :print, :string, :push!, :pop!
])

"""
    collect_definitions!(ex, filepath, def_map)
ファイル内の関数定義をスキャンし、{関数名 => ファイル名} のマップを作成する
"""
function collect_definitions!(ex, filepath, def_map)
    if ex isa Expr
        # function f() ... end
        if ex.head == :function
            sig = ex.args[1]
            if sig isa Expr && sig.head == :call
                fname = sig.args[1]
                if fname isa Symbol
                    # すでに定義がある場合はセットに追加（複数ファイルにまたがるメソッド定義考慮）
                    push!(get!(def_map, fname, Set{String}()), filepath)
                end
            end
        # short-form f() = ...
        elseif ex.head == :(=) && ex.args[1] isa Expr && ex.args[1].head == :call
            fname = ex.args[1].args[1]
            if fname isa Symbol
                push!(get!(def_map, fname, Set{String}()), filepath)
            end
        end

        for arg in ex.args
            collect_definitions!(arg, filepath, def_map)
        end
    end
end

"""
    collect_calls(ex)
ファイル内で呼び出されている関数名を収集する
"""
function collect_calls(ex, calls=Set{Symbol}())
    if ex isa Expr
        if ex.head == :call
            f = ex.args[1]
            if f isa Symbol && !(f in IGNORE_FUNCS) && !isdefined(Base, f)
                push!(calls, f)
            end
        end
        for arg in ex.args
            collect_calls(arg, calls)
        end
    end
    return calls
end

# 既存の include/using 収集はそのまま活用
function collect_includes(ex, includes=Set{String}())
    if ex isa Expr
        if ex.head == :call && ex.args[1] == :include
            file = ex.args[2]
            file isa String && push!(includes, file)
        end
        for arg in ex.args; collect_includes(arg, includes); end
    end
    return includes
end

function collect_usings(ex, mods=Set{Symbol}())
    if ex isa Expr
        if ex.head == :using || ex.head == :import
            for arg in ex.args
                if arg isa Symbol
                    push!(mods, arg)
                elseif arg isa Expr && arg.head == :.
                    push!(mods, arg.args[end])
                end
            end
        end
        for arg in ex.args; collect_usings(arg, mods); end
    end
    return mods
end

"""
    analyze_repo_bi(entry)
リポジトリ全体をスキャンし、定義と呼び出しを照合してファイル間の依存を解決する
"""
function analyze_repo_bi(entry::String)
    visited = Set{String}()
    # 1. 構造の把握 (ファイルリストと定義マップの作成)
    def_map = Dict{Symbol, Set{String}}()
    file_ast_cache = Dict{String, Any}()
    
    function scan_structure(file)
        file in visited && return
        push!(visited, file)
        !isfile(file) && (println("Warning: $file not found"); return)
        
        code = read(file, String)
        ex = Meta.parse("begin $code end") # 全体をブロックとしてパース
        file_ast_cache[file] = ex
        
        # 定義を記録
        collect_definitions!(ex, file, def_map)
        
        # includeを辿る
        for inc in collect_includes(ex)
            scan_structure(inc)
        end

        for mod in collect_usings(ex)
            scan_structure(mod)
        end
    end

    scan_structure(entry)

    # 2. 依存関係の解決
    edges_file_call = Set{Tuple{String,String}}() # File A -> File B (AがBの関数を呼ぶ)
    edges_func_call = Set{Tuple{Symbol,Symbol}}()

    for (file, ex) in file_ast_cache
        calls = collect_calls(ex)
        for f_name in calls
            if haskey(def_map, f_name)
                for provider_file in def_map[f_name]
                    if file != provider_file
                        push!(edges_file_call, (file, provider_file))
                    end
                end
            end
        end
    end

    return visited, edges_file_call, def_map
end

"""
    write_dot_bi(edges, filename)
双方向の依存（相互参照）を色を変えて出力する
"""
function write_dot_bi(edges, filename)
    open(filename, "w") do io
        println(io, "digraph G {")
        println(io, "  node [shape=box, style=filled, color=lightblue];")
        
        processed = Set{Tuple{String, String}}()
        
        for (a, b) in edges
            (a, b) in processed && continue
            
            if (b, a) in edges
                # 相互参照（双方向）
                println(io, "  \"$a\" -> \"$b\" [dir=both, color=red, penwidth=2.0, label=\"bi\"];")
                push!(processed, (a, b), (b, a))
            else
                # 単方向
                println(io, "  \"$a\" -> \"$b\";")
                push!(processed, (a, b))
            end
        end
        println(io, "}")
    end
end

# --- メイン処理 ---
if abspath(PROGRAM_FILE) == @__FILE__
    # 解析開始
    target_entry = "STCounterexampleCheck.jl" 
    files, file_edges, def_map = analyze_repo_bi(target_entry)

    # 可視化
    write_dot_bi(file_edges, "file_dependencies_bi.dot")

    println("Analysis complete.")
    println("Found $(length(files)) files.")
    println("Defined functions: ", length(keys(def_map)))
end