using Pkg
Pkg.activate(".")
using Chess
include("Search.jl")
include("Material.jl")
include("Zobrist.jl")
using .Material
using .Search
using .Zobrist
b = startboard()
hash1 =Zobrist.compute_hash(b)
println(hash1)
Chess.domove!(b,"e2e4")
hash2=Zobrist.compute_hash(b)
println(hash2)
# println(pieceon(b,"a1"))
# pawn = Chess.Piece(Chess.WHITE, Chess.PAWN)
# rook = Chess.Piece(Chess.BLACK, Chess.ROOK)
# queen = Chess.Piece(Chess.WHITE, Chess.QUEEN)

# mat_adv,_,_ = Material.material_score(b)
# mob_adv,_,_ = Material.mobility_score(b)
# print(Material.evaluate(b))
println(b)
depth = 6
@time score,best_move = Search.search(b,depth)
println(best_move)
println(score)