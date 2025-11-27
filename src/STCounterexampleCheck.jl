module STCounterexampleCheck

# Include submodules
include("Types.jl")
include("GraphUtils.jl")
include("Algebra.jl")
include("Matroid.jl")
include("ClassCheck.jl")
include("Output.jl")
include("Main.jl")

# Export public API
using .Types
using .GraphUtils
using .Main

export workflow, read_graphs_from_file, core_main
export Types, GraphUtils, Algebra, Matroid, ClassCheck, Output

end # module STCounterexampleCheck
