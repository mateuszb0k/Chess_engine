module Search
using Chess
include("Material.jl")
include("Zobrist.jl")
include("TranspositionTable.jl")
include("MoveOrdering.jl")
include("OpeningBook.jl")
using .Material
using .Zobrist
using .TranspositionTable
using .MoveOrdering
using .OpeningBook
const MATE_SCORE = 100000.0
# function minimax_ab(board::Chess.Board,depth::Int,alpha::Float64,beta::Float64, is_maximizing::Bool)
#     if depth ==0
#         return Material.evaluate(board),nothing
#     end
#     moves = Chess.moves(board)
#     if isempty(moves)
#         return Material.evaluate(board),nothing
#     end
#     best_move = nothing
#     if is_maximizing
#         best_score = -Inf
#         for move in moves
#             new_board = deepcopy(board)
#             Chess.domove!(new_board,move)
#             score,_ =minimax_ab(new_board,depth-1,alpha,beta,false)
#             if score>best_score
#                 best_score = score
#                 best_move = move
#             end
#             alpha = max(alpha,best_score)
#             if beta<=alpha
#                 break
#             end
#         end
#         return best_score,best_move
#     else
#         best_score = Inf
#         for move in moves
#             new_board = deepcopy(board)
#             Chess.domove!(new_board,move)
#             score,_ =minimax_ab(new_board,depth-1,alpha,beta,true)
#             if score<best_score
#                 best_score = score
#                 best_move = move
#             end
#             beta=min(beta,best_score)
#             if alpha>= beta
#                 break
#             end
#         end
#         return best_score,best_move
#     end
# end
function quiescence(board::Chess.Board,alpha::Float64,beta::Float64)
    stand_pat = Material.evaluate(board)
    if Chess.sidetomove(board) == BLACK
        stand_pat = -stand_pat
    end
    if stand_pat >= beta
        return beta
    end
    if alpha<stand_pat
        alpha = stand_pat
    end
    moves = Chess.moves(board)
    moves = MoveOrdering.order_moves(board,moves)
    for move in moves
        #only captures
        if Chess.pieceon(board,Chess.to(move))==EMPTY
            continue
        end
        undo=Chess.domove!(board,move)
        score = -quiescence(board,-beta,-alpha)
        Chess.undomove!(board,undo)
        if score>=beta
            return beta
        end
        if score>alpha
            alpha=score
        end
    end
    return alpha
end
function negamax(board::Chess.Board,depth::Int,alpha::Float64,beta::Float64)
    hash = Zobrist.compute_hash(board)
    tt_entry = TranspositionTable.lookup(hash)
    if (!isnothing(tt_entry)) && tt_entry.depth>=depth
        return tt_entry.score,tt_entry.best_move
    end

    moves = Chess.moves(board)
    if isempty(moves)
        if Chess.ischeckmate(board)
            return -MATE_SCORE,nothing
        elseif Chess.isstalemate(board)
            return 0.0,nothing
        end
    end
    if depth == 0
        score = quiescence(board,alpha,beta)
        return score, nothing
    end
    moves = MoveOrdering.order_moves(board,moves)
    best_move = nothing
    best_score = -Inf
    for move in moves
        undo = Chess.domove!(board,move)
        score,_ = negamax(board,depth-1,-beta,-alpha)
        score =-score
        Chess.undomove!(board,undo)
        if score>best_score
            best_score = score
            best_move = move
        end
        alpha = max(alpha,best_score)
        if alpha>=beta
            break
        end
    end
    TranspositionTable.store(hash,depth,best_score,best_move)
    return best_score,best_move
end
function search(board::Chess.Board,max_depth::Int,use_book::Bool=true,verbose::Bool=false)
    if use_book
        book_move = OpeningBook.get_book_move(board)
        if book_move !==nothing
            if verbose
                println("Book move: $book_move" )
            end
            return 0.0,book_move
        end
    end
    TranspositionTable.clear()
    best_move =nothing
    best_score =0.0
    for depth in 1:max_depth
        score,move = negamax(board,depth,-Inf,Inf)
        if move!==nothing
            best_move = move
            best_score = score
        end
        if verbose
            println("Depth $depth, Best_move $best_move, Best_score $best_score,")
        end
        if abs(best_score)>MATE_SCORE-1000
            break
        end
    end
    return best_score,best_move
end
end