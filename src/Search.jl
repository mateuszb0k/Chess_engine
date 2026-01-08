module Search
using Chess
include("Material.jl")
using .Material
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
        
    end
end
function negamax(board::Chess.Board,depth::Int,alpha::Float64,beta::Float64)
    moves = Chess.moves(board)
    if isempty(moves)
        if Chess.ischeckmate(board)
            return -MATE_SCORE + depth,nothing
        elseif Chess.isstalemate(board)
            return 0.0,nothing
        end
    end
    if depth == 0
        eval_score = Material.evaluate(board)
        # Pamiętaj o negacji dla czarnych, jeśli evaluate zwraca z perspektywy białych
        if Chess.sidetomove(board) == BLACK
             eval_score = -eval_score
        end
        return eval_score, nothing
    end
    best_move = nothing
    best_score = -Inf
    for move in moves
        new_board = deepcopy(board)
        Chess.domove!(new_board,move)
        score,_ = negamax(new_board,depth-1,-beta,-alpha)
        score =-score
        if score>best_score
            best_score = score
            best_move = move
        end
        alpha = max(alpha,best_score)
        if alpha>=beta
            break
        end
    end
    return best_score,best_move
end
function search(board::Chess.Board,depth::Int)
    return negamax(board,depth,-Inf,Inf)
end
end