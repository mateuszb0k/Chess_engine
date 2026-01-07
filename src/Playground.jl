using Pkg
Pkg.activate(".")
using Chess
include("Material.jl")
using .Material
b = startboard()
println(pieceon(b,"a1"))
# Tworzymy figury i testujemy funkcję value
pawn = Chess.Piece(Chess.WHITE, Chess.PAWN)
rook = Chess.Piece(Chess.BLACK, Chess.ROOK)
queen = Chess.Piece(Chess.WHITE, Chess.QUEEN)

println("Wartość pionka: ", Material.value(pawn))     # Powinno być 1.0
println("Wartość wieży: ", Material.value(rook))     # Powinno być 5.0
println("Wartość hetmana: ", Material.value(queen))  # Powinno być 9.0
print(Material.material_score(b))
