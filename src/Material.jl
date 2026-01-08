module Material
using Chess
const CENTER_SQUARES =["d4","d5","e4","e5"]
const EXTENDED_CENTER_SQUARES =["c3","c4","c5","c6","d3","d6","e3","e6","f3","f4","f5","f6"]
const ALL_FILES = [FILE_A, FILE_B, FILE_C, FILE_D, FILE_E, FILE_F, FILE_G, FILE_H]

function value(piece::Chess.Piece)
    piece_type = Chess.ptype(piece)
    if piece_type == PAWN
        return 1.0
    elseif piece_type == KNIGHT
        return 3.0
    elseif piece_type == BISHOP
        return 3.25
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
    moves = length(Chess.moves(board))
    if Chess.sidetomove(board) == WHITE
        return moves
    else
        return moves
    end
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
function development_score(board::Chess.Board)
    score =0.0
    #knights
    if Chess.pieceon(board,SQ_B1) == PIECE_WN
        score-=0.5
    end
    if Chess.pieceon(board,SQ_G1) == PIECE_WN
        score-=0.5
    end
    if Chess.pieceon(board,SQ_B8) == PIECE_BN
        score+=0.5
    end
    if Chess.pieceon(board,SQ_G8) == PIECE_BN
        score+=0.5
    end

    #bishops
    if Chess.pieceon(board,SQ_C1) == PIECE_WB
        score-=0.7
    end
    if Chess.pieceon(board,SQ_F1) == PIECE_WB
        score-=0.7
    end
    if Chess.pieceon(board,SQ_C8) == PIECE_BB
        score+=0.7
    end
    if Chess.pieceon(board,SQ_F8) == PIECE_BB
        score+=0.7
    end
    return score
end
function pawn_structure(board::Chess.Board)
    score =0.0
    for file in ALL_FILES
        white_pawns=0
        black_pawns =0
        for sq in Chess.filesquares(file)
            piece = Chess.pieceon(board,sq)
            if piece == PIECE_WP
                white_pawns+=1
            end
            if piece == PIECE_BP
                black_pawns+=1
            end

        end
        if white_pawns > 1
            score -= 0.5 * (white_pawns - 1)
        end
        if black_pawns > 1
            score += 0.5 * (black_pawns - 1)
        end
    end
    return score

end
function evaluate(board::Chess.Board)
    # material_adv,_,_ = material_score(board)
    # mobility_adv,_,_ = mobility_score(board)
    # center_advantage = center_control(board)
    mat_score,_,_ = material_score(board)
    center_score =center_control(board)
    mob_score= mobility_score(board)
    dev_score = development_score(board)
    pawn_score = pawn_structure(board)
    mat_weight=10.0
    mob_weight = 0.1
    center_weight = 0.8
    dev_weight = 1.0
    pawn_weight = 1.0
    eval = mat_score*mat_weight+center_score*center_weight+mob_score*mob_weight+dev_score*dev_weight+pawn_score*pawn_weight
    return eval
end

end