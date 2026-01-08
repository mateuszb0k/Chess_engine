using Pkg
Pkg.activate(".")
using Chess
include("Search.jl")
include("Material.jl")
using .Material
using .Search
b = startboard()
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