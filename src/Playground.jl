using Pkg
Pkg.activate(".")
using Chess
include("Zobrist.jl")
include("Search.jl")
include("Material.jl")
include("TranspositionTable.jl")
using .Material
using .Search
using .Zobrist
using .TranspositionTable
println("\n=== Test search ===")
b = startboard()
for depth in 4:6
    @time score, best_move = Search.search(b, depth)
    println("Głębokość $depth: $best_move, ocena: $score")
end
