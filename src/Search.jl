module Search
using Chess
using Base.Threads
include("EvaluationFunction.jl")
include("Zobrist.jl")
include("TranspositionTable.jl")
include("MoveOrdering.jl")
include("OpeningBook.jl")
using .EvaluationFunction
using .Zobrist
using .TranspositionTable
using .MoveOrdering
using .OpeningBook
const MATE_SCORE = 100000.0
const MAX_DEPTH = 32
const INFINITY = 1_000_000.0
mutable struct SearchStats
    nodes::Atomic{Int64}
    tt_hits::Atomic{Int64}
    tt_cutoffs::Atomic{Int64}
end
function SearchStats()
    return SearchStats(Atomic{Int64}(0),Atomic{Int64}(0),Atomic{Int64}(0))
end
STATS = SearchStats()
function reset_stats!()
    global STATS = SearchStats()
end
function add_nodes!(n::Int=1)
    atomic_add!(STATS.nodes,n)
end
function add_tt_hits!(n::Int=1)
    atomic_add!(STATS.tt_hits,n)
end
function add_tt_cutoffs!(n::Int=1)
    atomic_add!(STATS.tt_cutoffs,n)
end
###quiescence
function quiescence(board::Chess.Board,alpha::Float64,beta::Float64,depth::Int=0)
    add_nodes!()
    if Chess.isdraw(board)
        return 0.0
    end
    moves = Chess.moves(board)
    if isempty(moves)
        if Chess.ischeckmate(board)
            return -MATE_SCORE  
        else
            return 0.0  
        end
    end
    stand_pat = EvaluationFunction.evaluate(board)
    if stand_pat >= beta
        return beta
    end
    if alpha<stand_pat
        alpha = stand_pat
    end
    if depth>10
        return alpha
    end
    for move in moves
        #only captures
        captured = Chess.pieceon(board,Chess.to(move))
        if captured==EMPTY && !Chess.ispromotion(move)
            continue
        end
        #delta pruning
        if captured !=EMPTY
            captured_value = get(EvaluationFunction.PIECE_VALUES,Chess.ptype(captured),0)
            #200 centipawns for margin
            if stand_pat+captured_value+200<alpha
                continue
            end
        end

        undo=Chess.domove!(board,move)
        score = -quiescence(board,-beta,-alpha,depth+1)
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

function negamax(board::Chess.Board,depth::Int,alpha::Float64,beta::Float64,ply::Int=0)
    add_nodes!()
    if Chess.isdraw(board)
        return 0.0,nothing
    end
    ##tt lookup
    hash = Zobrist.compute_hash(board)
    tt_entry = TranspositionTable.lookup(hash)
    tt_move = nothing
    # if (!isnothing(tt_entry)) && tt_entry.depth>=depth
    #     return tt_entry.score,tt_entry.best_move
    # end
    if tt_entry !==nothing
        add_tt_hits!()
        tt_move = tt_entry.best_move
        if tt_entry.depth>=depth
            if tt_entry.flag == TranspositionTable.EXACT
                add_tt_cutoffs!()
                return tt_entry.score,tt_entry.best_move
            elseif tt_entry.flag ==TranspositionTable.LOWER_BOUND
                alpha = max(alpha,tt_entry.score)
            elseif tt_entry.flag == TranspositionTable.UPPER_BOUND
                beta = min(beta,tt_entry.score)
            end
            if alpha>=beta
                add_tt_cutoffs!()
                return tt_entry.score,tt_entry.best_move
            end
        end
    end
    #terminal node check
    moves = Chess.moves(board)
    if isempty(moves)
        if Chess.ischeckmate(board)
            return -MATE_SCORE + ply, nothing
        else
            return 0.0,nothing
        end
    end
    
    #quiescence
    if depth<=0
        score=quiescence(board,alpha,beta)
        return score,nothing
    end
    
    #null move pruning

    if depth>=3 && !Chess.ischeck(board)&&ply>0
        if squarecount(Chess.occupiedsquares(board))>6
            undo = Chess.donullmove!(board)
            null_score,_ = negamax(board,depth-3,-beta,-beta+1,ply+1)
            null_score= - null_score
            Chess.undomove!(board,undo)
            if null_score>=beta
                return beta,nothing
            end
        end
    end
    
    #move ordering 
    
    moves = MoveOrdering.order_moves(board,moves,tt_move)

    #search moves

    best_move =moves[1]
    best_score= -INFINITY
    flag = TranspositionTable.UPPER_BOUND
    for (i,move) in enumerate(moves)
        captured = Chess.pieceon(board,Chess.to(move))
        is_capture = (captured!=EMPTY)
        undo = Chess.domove!(board,move)
        is_check_after = Chess.ischeck(board)
        #late move reduction
        reduction = 0
        if i>4 && depth>=3 && !is_check_after && !is_capture
            reduction = 1
            if i>10
                reduction =2
            end
        end
        if reduction > 0
            score,_ = negamax(board,depth-1-reduction,-alpha-1,-alpha,ply+1)
            score = -score
            
            if score>alpha
                score,_ = negamax(board,depth-1,-beta,-alpha,ply+1)
                score = -score
            end
        else
            score,_ =negamax(board,depth-1,-beta,-alpha,ply+1)
            score = -score
        end
        Chess.undomove!(board,undo)
        if score>best_score
            best_score = score
            best_move = move
        end
        if score>alpha
            alpha = score
            flag = TranspositionTable.EXACT
        end
        if alpha>=beta
            flag = TranspositionTable.LOWER_BOUND
            break
        end
        
        
    end
    TranspositionTable.store(hash,depth,best_score,best_move,flag)
    return best_score,best_move
end
    struct SearchResult
        score::Float64
        move::Union{Chess.Move,Nothing}
        depth::Int
        thread_id::Int
    end
    function search_thread(fen::String,depth::Int,thread_id::Int,results::Channel{SearchResult})
        board = fromfen(fen)
        adjusted_depth = depth
        if thread_id >1
            adjusted_depth=depth + (thread_id%3)-1
            adjusted_depth=max(1,adjusted_depth)
        end
        score,move=negamax(board,adjusted_depth,-INFINITY,INFINITY,0)
        put!(results,SearchResult(score,move,adjusted_depth,thread_id))
    end
    function search_parallel(board::Chess.Board,max_depth::Int;
        use_book::Bool=true,verbose::Bool=false,time_limit::Float64=INFINITY,num_threads::Int=Threads.nthreads())
        if use_book
            book_move=OpeningBook.get_book_move(board)
            if book_move !==nothing
                verbose && println("Book move $book_move")
                return 0.0,book_move
            end
        end
        reset_stats!()
        TranspositionTable.clear()
        fen = Chess.fen(board)
        best_move = nothing
        best_score = 0.0
        start_time = time()
        if verbose
            println("Parallel search with $num_threads threads")
        end
        
        for depth in 1:max_depth
            elapsed = time() - start_time
            if elapsed>time_limit
                break
            end
            results = Channel{SearchResult}(num_threads)
            @sync begin
                for t in 1:num_threads
                    Threads.@spawn search_thread(fen,depth,t,results)
                end
            end
            close(results)
            for result in results
                if result.move !== nothing
                    if best_move === nothing || (result.depth == depth && result.score > best_score) || (result.depth > depth)
                        best_score = result.score
                        best_move = result.move
                    end
                end
            end
            elapsed = time() - start_time
            if verbose
                nodes=STATS.nodes[]
                nps = nodes/max(elapsed,0.001)
                println("Depth $depth | Score:  $(round(best_score, digits=2)) | Move: $best_move | Nodes: $nodes | NPS:  $(round(Int, nps)) | Time: $(round(elapsed, digits=2))s")
            end
            if abs(best_score) > MATE_SCORE-1000
                break
            end
        end
        return best_score,best_move
    end
    # moves = Chess.moves(board)
    # if isempty(moves)
    #     if Chess.ischeckmate(board)
    #         return -MATE_SCORE,nothing
    #     elseif Chess.isstalemate(board)
    #         return 0.0,nothing
    #     end
    # end
    # if depth == 0
    #     score = quiescence(board,alpha,beta)
    #     return score, nothing
    # end
    # moves = MoveOrdering.order_moves(board,moves)
    # best_move = nothing
    # best_score = -Inf
    # for move in moves
    #     undo = Chess.domove!(board,move)
    #     score,_ = negamax(board,depth-1,-beta,-alpha)
    #     score =-score
    #     Chess.undomove!(board,undo)
    #     if score>best_score
    #         best_score = score
    #         best_move = move
    #     end
    #     alpha = max(alpha,best_score)
    #     if alpha>=beta
    #         break
    #     end
    # end
    # TranspositionTable.store(hash,depth,best_score,best_move)
    # return best_score,best_move
    # function search(board::Chess.Board,max_depth::Int,use_book::Bool=true,verbose::Bool=false)
    #     if use_book
    #         book_move = OpeningBook.get_book_move(board)
    #         if book_move !==nothing
    #             if verbose
    #                 println("Book move: $book_move" )
    #             end
    #             return 0.0,book_move
    #         end
    #     end
    #     TranspositionTable.clear()
    #     best_move =nothing
    #     best_score =0.0
    #     for depth in 1:max_depth
    #         score,move = negamax(board,depth,-Inf,Inf)
    #         if move!==nothing
    #             best_move = move
    #             best_score = score
    #         end
    #         if verbose
    #             println("Depth $depth, Best_move $best_move, Best_score $best_score,")
    #         end
    #         if abs(best_score)>MATE_SCORE-1000
    #             break
    #         end
    #     end
    #     return best_score,best_move
    # end
end