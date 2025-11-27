module Output

export output_independent, output_dependent, output_counterexample, output_exception
export IndependentResult, DependentResult, CounterexampleResult, ExceptionResult

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

struct ExceptionResult
  g::AbstractGraph
  message::String
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

function output_exception(channel::Channel, g::AbstractGraph, message::String)
  put!(channel, ExceptionResult(g, message))
end

end
