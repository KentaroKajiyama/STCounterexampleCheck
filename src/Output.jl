module Output

export output_independent, output_dependent, output_counterexample, output_exception
export IndependentResult, DependentResult, CounterexampleResult, ExceptionResult

export ForbiddenGraphResult, output_forbidden_graph
export NotDoubleCircuitResult, DoubleCircuitResult, DoubleCircuitCounterexampleResult
export output_not_double_circuit, output_double_circuit, output_double_circuit_counterexample

using Graphs
using ..Types
using ..GraphUtils

# Data Structures for Results
struct IndependentResult
  g::AbstractGraph
  phi::Vector{Edge}
  p_embed::Embedding
  seed::Int
end

struct DependentResult
  g::AbstractGraph
  phi::Vector{Edge}
  p_embed::Embedding
  seed::Int
  C_edges::Vector{Edge}
  F_edges::Vector{Edge}
  class_index::Int
  C_indices::Vector{Int}
  F_indices::Vector{Int}
end

struct CounterexampleResult
  g::AbstractGraph
  phi::Vector{Edge}
  p_embed::Embedding
  seed::Int
  C_edges::Vector{Edge}
  F_edges::Vector{Edge}
  C_indices::Vector{Int}
  F_indices::Vector{Int}
end

struct ForbiddenGraphResult
  g::AbstractGraph
end

struct ExceptionResult
  g::AbstractGraph
  message::String
end

# === New Structs for Double Circuit ===

"""
    DoubleCircuitResult

Data structure for double circuit results.
"""
NotDoubleCircuitResult = IndependentResult

struct DoubleCircuitResult
  g::AbstractGraph
  phi::Vector{Edge}
  p_embed::Embedding
  seed::Int
  class_index::Int
end

struct DoubleCircuitCounterexampleResult
  g::AbstractGraph
  phi::Vector{Edge}
  p_embed::Embedding
  seed::Int
end

# Output functions now push to a channel
function output_independent(channel::Channel, g::AbstractGraph, phi::Vector{Edge}, p_embed::Embedding, seed::Int)
  put!(channel, IndependentResult(g, phi, p_embed, seed))
end

function output_dependent(channel::Channel, g::AbstractGraph, phi::Vector{Edge}, p_embed::Embedding, seed::Int, C_edges::Vector{Edge}, F_edges::Vector{Edge}, class_index::Int, C_indices::Vector{Int}, F_indices::Vector{Int})
  put!(channel, DependentResult(g, phi, p_embed, seed, C_edges, F_edges, class_index, C_indices, F_indices))
end

function output_counterexample(channel::Channel, g::AbstractGraph, phi::Vector{Edge}, p_embed::Embedding, seed::Int, C_edges::Vector{Edge}, F_edges::Vector{Edge}, C_indices::Vector{Int}, F_indices::Vector{Int})
  put!(channel, CounterexampleResult(g, phi, p_embed, seed, C_edges, F_edges, C_indices, F_indices))
end

function output_forbidden_graph(channel::Channel, g::AbstractGraph)
  put!(channel, ForbiddenGraphResult(g))
end

function output_exception(channel::Channel, g::AbstractGraph, message::String)
  put!(channel, ExceptionResult(g, message))
end

# New Functions
function output_not_double_circuit(channel::Channel, g::AbstractGraph, phi::Vector{Edge}, p_embed::Embedding, seed::Int)
  put!(channel, NotDoubleCircuitResult(g, phi, p_embed, seed))
end

function output_double_circuit(channel::Channel, g::AbstractGraph, phi::Vector{Edge}, p_embed::Embedding, seed::Int, class_index::Int)
  put!(channel, DoubleCircuitResult(g, phi, p_embed, seed, class_index))
end

function output_double_circuit_counterexample(channel::Channel, g::AbstractGraph, phi::Vector{Edge}, p_embed::Embedding, seed::Int)
  put!(channel, DoubleCircuitCounterexampleResult(g, phi, p_embed, seed))
end

end
