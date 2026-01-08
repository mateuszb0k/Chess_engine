module Search
using Chess
include("Material.jl")
include("Zobrist.jl")
include("TranspositionTable.jl")
using .Material
using .Zobrist
using .TranspositionTable
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
function search(board::Chess.Board,depth::Int)
    TranspositionTable.clear()
    score,best_move = negamax(board,depth,-Inf,Inf)
    if Chess.sidetomove(board) == BLACK
        score = -score
    end
    return score,best_move
end
end