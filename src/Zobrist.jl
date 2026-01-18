module Zobrist
using Chess
using Random
const PIECE_KEYS = rand(UInt64,12,64)
const SIDE_KEY = rand(UInt64)
const CASTLE_KEYS = rand(UInt64,4)
const ENPASANT_RIGHTS = rand(UInt64,8)
const FILE_TO_INDEX = Dict(
    FILE_A => 1,
    FILE_B => 2,
    FILE_C => 3,
    FILE_D => 4,
    FILE_E => 5,
    FILE_F => 6,
    FILE_G => 7,
    FILE_H => 8
)
function piece_index(piece::Chess.Piece)
    ptype = Chess.ptype(piece)
    color = Chess.pcolor(piece)
    base = 0
    if ptype == PAWN
        base = 1
    elseif ptype == KNIGHT
        base =2
    elseif ptype == BISHOP
        base =3
    elseif ptype == ROOK
        base = 4
    elseif ptype == QUEEN
        base =5
    elseif ptype ==KING
        base =6
    else 
        return 0
    end
    if color==BLACK
        base+=6
    end
    return base
end
function compute_hash(board::Chess.Board)
    h = UInt64(0)
    for i in 1:64
        piece = Chess.pieceon(board,Chess.Square(i))
        if piece != EMPTY
            idx = piece_index(piece)
            if idx>0
                h = xor(h,PIECE_KEYS[idx,i])
            end
        end
    end
    if Chess.sidetomove(board) == BLACK
        h=xor(h,SIDE_KEY)
    end
    if Chess.cancastlekingside(board,WHITE)
        h=xor(h,CASTLE_KEYS[1])
    end
    if Chess.cancastlequeenside(board,WHITE)
        h=xor(h,CASTLE_KEYS[2])
    end
    if Chess.cancastlekingside(board,BLACK)
        h = xor(h,CASTLE_KEYS[3])
    end
    if Chess.cancastlequeenside(board,BLACK)
        h = xor(h,CASTLE_KEYS[4])
    end
    ep_square=Chess.epsquare(board)
    if ep_square !=SQ_NONE
        file = Chess.file(ep_square)
        file_idx = FILE_TO_INDEX[file]
        h=xor(h,ENPASANT_RIGHTS[file_idx])
    end
    return h
end
end