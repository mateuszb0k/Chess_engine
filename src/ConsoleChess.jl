using Pkg
Pkg.activate(".")
using Chess
using Serialization

include("Search.jl")
include("EvaluationFunction.jl")
include("OpeningBook.jl")
using .Search
using .EvaluationFunction

function play_simple()
    #weights
    txt_dir = "best_weights_t2.txt"
    if isfile(txt_dir)
        println("Loading weights from best_weights.txt")
        new_weights = EvaluationFunction.load_weights_from_txt(txt_dir)
        println("Weights Loaded")
    else
        println("No file found, using default")
    end

    board = Chess.startboard()
    
    while true
        println("\n" * "-"^20)
        println(board) 
        println("-"^20 * "\n")
        moves = Chess.moves(board)
        if isempty(moves)
            if Chess.ischeckmate(
               println("CHECKMATE") 
            )
            end
            println("DRAW")
            break
        end

        if Chess.sidetomove(board) == Chess.WHITE
            print("Your move (eg. e2e4): ")
            user_input = readline()
            
            if user_input == "quit" break end

            found = false
            for m in moves
                if Chess.tostring(m) == user_input
                    Chess.domove!(board, m)
                    found = true
                    break
                end
            end
            if !found println("!!! This move does not exist.") end

        else
            println("Engine is thinking...")
            score, best_move = Search.search_parallel(board, 5, use_book=true, verbose=true, num_threads=Base.Threads.nthreads())
            
            if best_move !== nothing
                println("Engine move: $(Chess.tostring(best_move))")
                Chess.domove!(board, best_move)
            else
                println("Engine surrenders.")
                break
            end
        end
    end
end
play_simple()