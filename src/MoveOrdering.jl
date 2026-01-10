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
#most valuable victim least valuable attacker
const MVV_LVA = [
    # P    N    B    R    Q    K
    [105, 205, 305, 405, 505, 605],  # P captures
    [104, 204, 304, 404, 504, 604],  # N captures
    [103, 203, 303, 403, 503, 603],  # B captures
    [102, 202, 302, 402, 502, 602],  # R captures
    [101, 201, 301, 401, 501, 601],  # Q captures
    [100, 200, 300, 400, 500, 600],  # K captures
]

function piece_index(ptype)
    ptype == PAWN && return 1
    ptype == KNIGHT && return 2
    ptype == BISHOP && return 3
    ptype == ROOK && return 4
    ptype == QUEEN && return 5
    ptype == KING && return 6
    return 1
end
function score_move(board::Chess.Board,move::Chess.Move,tt_move::Union{Chess.Move,Nothing}=nothing)
    score = 0
    if tt_move !== nothing && move == tt_move
        return 10000
    end
    from_sq = Chess.from(move)
    to_sq = Chess.to(move)
    attacker = Chess.pieceon(board,from_sq)
    captured = Chess.pieceon(board,to_sq)
    #captures mvv_lva
    if captured != EMPTY
        attacker_idx = piece_index(Chess.ptype(attacker))
        victim_idx = piece_index(Chess.ptype(captured))
        score+=MVV_LVA[attacker_idx][victim_idx] + 1000
    end
    #promotion bonus
    if Chess.ispromotion(move)
        score+=900
    end
    #center control bonus
    if to_sq in [SQ_D4,SQ_D5,SQ_E4,SQ_E5]
        score+=10
    elseif to_sq in [SQ_C3, SQ_C4, SQ_C5, SQ_C6, SQ_D3, SQ_D6, SQ_E3, SQ_E6, SQ_F3, SQ_F4, SQ_F5, SQ_F6]
        score+=5
    end
    #penalty for moving to attacked suqre
    if Chess.isattacked(board,to_sq,Chess.sidetomove(board)== WHITE ? BLACK : WHITE )
        score-=50
    end
    return score
end
# function score_move(board::Chess.Board,move::Chess.Move)
#     score = 0
#     captured = Chess.pieceon(board, Chess.to(move))
#     if captured!=EMPTY
#         victim_value = piece_value(captured)
#         attacker = Chess.pieceon(board,Chess.from(move))
#         attacker_value = piece_value(attacker)
#         score += 10*victim_value -attacker_value +100
#     end
#     if Chess.ispromotion(move)
#         score+=90
#     end
#     to_sq = Chess.to(move)
#     if to_sq in [SQ_D4, SQ_D5, SQ_E4, SQ_E5]
#         score+=5
#     elseif to_sq in [SQ_C3, SQ_C4, SQ_C5, SQ_C6, SQ_D3, SQ_D6, SQ_E3, SQ_E6, SQ_F3, SQ_F4, SQ_F5, SQ_F6]
#         score+=2
#     end
#     return score
# end
function order_moves(board::Chess.Board,moves,tt_move::Union{Chess.Move,Nothing}=nothing)
    scored_moves = [(score_move(board, m,tt_move), m) for m in moves]
    sort!(scored_moves, by = x -> -x[1])
    return [m for (_, m) in scored_moves]
end
export score_move,order_moves
end