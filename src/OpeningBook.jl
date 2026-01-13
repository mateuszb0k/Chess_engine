module OpeningBook
using Chess
const BOOK = Dict(
    # start
    "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -" => ["e2e4", "d2d4", "c2c4", "g1f3"],
    # e4
    "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq -" => ["e7e5", "c7c5"],
    # d4
    "rnbqkbnr/pppppppp/8/8/3P4/8/PPP1PPPP/RNBQKBNR b KQkq -" => ["d7d5", "g8f6", "e7e6"], 
    # e4,e5
    "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq -" => ["g1f3", "f1c4", "b1c3"],
    # e4,e5,Nf3
    "rnbqkbnr/pppp1ppp/8/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq -" => ["b8c6", "g8f6"],
    # e4 c5
    "rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq -" => ["g1f3", "b1c3", "c2c3"],
    # d4 d5
    "rnbqkbnr/ppp1pppp/8/3p4/3P4/8/PPP1PPPP/RNBQKBNR w KQkq -" => ["c2c4", "g1f3", "b1c3"],
    # d4 nf6
    "rnbqkb1r/pppppppp/5n2/8/3P4/8/PPP1PPPP/RNBQKBNR w KQkq -" => ["c2c4", "g1f3", "b1c3"],
    # e4 e5 Nf3 Nc6
    "r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq -" => ["f1b5", "f1c4", "d2d4"],
    
    # after bc4 italian
    "r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R b KQkq -" => ["f8c5", "g8f6"],
    
    # after Bb5 spanish/ruylopez
    "r1bqkbnr/pppp1ppp/2n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R b KQkq -" => ["a7a6", "g8f6", "f8c5"],
)
function get_book_move(board::Chess.Board)
    fen_full = Chess.fen(board)
    if haskey(BOOK,fen_full)
        println("found the position in the book")
        moves_str = BOOK[fen_full]
        move_str = rand(moves_str)
        legal_moves = Chess.moves(board)
        for m in legal_moves
            if lowercase(Chess.tostring(m))==lowercase(move_str)
                return m
            end
        end
    else
        println("position not found")
    end
    return nothing
end
end