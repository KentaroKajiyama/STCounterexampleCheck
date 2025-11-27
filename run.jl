using STCounterexampleCheck
using ArgParse

function parse_commandline()
  s = ArgParseSettings()

  @add_arg_table s begin
    "input_file"
    help = "Path to the input file containing graphs (graph6 format)"
    required = true
  end

  return parse_args(s)
end

function main()
  args = parse_commandline()
  path = args["input_file"]

  println("Reading graphs from $path...")
  graphs = read_graphs_from_file(path)
  println("Read $(length(graphs)) graphs.")

  println("Starting workflow...")
  workflow(graphs)
  println("Done.")
end

main()
