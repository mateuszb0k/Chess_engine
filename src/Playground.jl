using Pkg
Pkg.activate(".")
using Chess

include("Zobrist.jl")
include("TranspositionTable.jl")
include("Material.jl")
include("MoveOrdering.jl")
include("OpeningBook.jl")
include("Search.jl")

using .Material
using .Search
using .OpeningBook

println("=== Test Opening Book ===")
b = startboard()
println(b)

book_move = OpeningBook.get_book_move(b)
println("Ruch z książki:  $book_move")

println("\n=== Test Search z Iterative Deepening ===")
b = startboard()
@time score, best_move = Search.search(b, 6,false,true)
println("\nNajlepszy ruch: $best_move, ocena: $score")

println("\n=== Test z Opening Book ===")
b = startboard()
@time score, best_move = Search.search(b, 6,true,true)
println("Wybrany ruch: $best_move")

println("\n=== Symulacja partii (5 ruchów) ===")
b = startboard()
for i in 1:10
    println("\nRuch $i:")
    println(b)
    
    if isempty(Chess.moves(b))
        if Chess.ischeckmate(b)
            println("SZACH MAT!")
        else
            println("PAT!")
        end
        break
    end
    
    @time score, move = Search.search(b, 5, true,false)
    println("Wybrany ruch: $move (ocena: $score)")
    Chess.domove!(b, move)
end
println("\nKońcowa pozycja:")
println(b)