module Material

using Chess

# Funkcja przypisująca wartość punktową dla figury
function value(piece::Chess.Piece)
    piece_type = Chess.ptype(piece)
    if piece_type == PAWN
        return 1.0
    elseif piece_type == KNIGHT || piece_type == BISHOP
        return 3.0
    elseif piece_type == ROOK
        return 5.0
    elseif piece_type == QUEEN
        return 9.0
    else
        return 0.0  # Król (KING) i inne przypadki zwracają 0
    end
end
function material_score(board::Chess.Board)
    scorew=0.0
    scoreb=0.0
    for i in 1:64
        piece =(pieceon(board,Square(i)))
        if pcolor(piece) == WHITE
            val = Material.value(piece)
            scorew+=val
        elseif pcolor(piece)==BLACK
            val = Material.value(piece)
            scoreb+=val
        end
    end
    adv = scorew-scoreb
    return adv,scorew,scoreb
end

end # module