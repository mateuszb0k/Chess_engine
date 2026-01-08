module Material

using Chess
const CENTER_SQUARES =["d4","d5","e4","e5"]
const EXTENDED_CENTER_SQUARES =["c3","c4","c5","c6","d3","d6","e3","e6","f3","f4","f5","f6"]
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
        return 0.0
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
function mobility_score(board::Chess.Board)
    score_w=0.0
    score_b=0.0
    if Chess.sidetomove(board) == WHITE
        moves_w = Chess.moves(board)
        moves_b = Chess.moves(Chess.flip(board))
    elseif Chess.sidetomove(board) == BLACK
        moves_w = Chess.moves(Chess.flip(board))
        moves_b = Chess.moves(board)
    end
    score_w = length(moves_w)
    score_b = length(moves_b)
    adv = score_w-score_b
    return adv,score_w,score_b
end
function center_control(board::Chess.Board)
    score_w = 0.0
    score_b = 0.0
    for sq in CENTER_SQUARES 
        piece = Chess.pieceon(board,sq)
        if piece != EMPTY
            if Chess.pcolor(piece)==WHITE
                score_w+=3
            else
                score_b+=3
            end
        end
    end
    for sq in EXTENDED_CENTER_SQUARES
        piece = Chess.pieceon(board,sq)
        if piece != EMPTY
            if Chess.pcolor(piece)==WHITE
                score_w+=1
            else
                score_b+=1
            end
        end
    end
    return score_w - score_b
end
function evaluate(board::Chess.Board)
    material_adv,_,_ = material_score(board)
    mobility_adv,_,_ = mobility_score(board)
    center_advantage = center_control(board)
    mat_weight=10.0
    mob_weight = 0.1
    center_weight = 0.5
    eval = material_adv*mat_weight + mobility_adv*mob_weight + center_advantage*center_weight
    return eval
end

end