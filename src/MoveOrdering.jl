module MoveOrdering
using Chess
const PIECE_VALUES = Dict(
    PAWN => 1,
    KNIGHT => 3,
    BISHOP => 3,
    ROOK => 5,
    QUEEN => 9,
    KING => 100
)
function piece_value(piece::Chess.Piece)
    if piece == EMPTY
        return 0
    end
    ptype = Chess.ptype(piece)
    return get(PIECE_VALUES,ptype,0)
end
function score_move(board::Chess.Board,move::Chess.Move)
    score = 0
    captured = Chess.pieceon(board, Chess.to(move))
    if captured!=EMPTY
        victim_value = piece_value(captured)
        attacker = Chess.pieceon(board,Chess.from(move))
        attacker_value = piece_value(attacker)
        score += 10*victim_value -attacker_value +100
    end
    if Chess.ispromotion(move)
        score+=90
    end
    to_sq = Chess.to(move)
    if to_sq in [SQ_D4, SQ_D5, SQ_E4, SQ_E5]
        score+=5
    elseif to_sq in [SQ_C3, SQ_C4, SQ_C5, SQ_C6, SQ_D3, SQ_D6, SQ_E3, SQ_E6, SQ_F3, SQ_F4, SQ_F5, SQ_F6]
        score+=2
    end
    return score
end
function order_moves(board::Chess.Board,moves)
    scored_moves = [(score_move(board, m), m) for m in moves]
    sort!(scored_moves, by = x -> -x[1])
    return [m for (_, m) in scored_moves]
end
end