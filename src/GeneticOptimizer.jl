module GeneticOptimizer
using Random
using Statistics
using Base.Threads
using Chess
include("EvaluationFunction.jl")
include("Search.jl")
using .EvaluationFunction
using .Search
@kwdef mutable struct GAConfig
    population_size::Int=50
    generations::Int = 100
    tournament_size::Int = 5
    crossover_rate::Float64 = 0.8
    mutation_rate::Float64 = 0.15
    mutation_strength::Float64 = 0.2
    elitism_count::Int =2
    games_per_fitness::Int = 10
    search_depth::Int =3
    max_moves_per_game::Int =100
    num_threads::Int =Threads.nthreads()
    min_weights::Float64 =0.0
    max_weights::Float64 =200.0
end
mutable struct Individual
    genes::Vector{Float64}
    fitness::Float64
    games_played::Int
    wins::Int
    draws::Int
    losses::Int
end
function Individual(genes::Vector{Float64})
    return Individual(genes,0.0,0,0,0,0)
end
function random_individual(config::GAConfig)
    default = EvaluationFunction.weights_to_vector(EvaluationFunction.default_weights())
    genes = copy(default)
    for i in eachindex(genes)
        #random perturbation
        perturbation  = 1.0 + (rand() - 0.5)
        genes[i] = clamp(genes[i]*perturbation,config.min_weights,config.max_weights)
    end
    return Individual(genes)
end
function default_individual()
    genes = EvaluationFunction.weights_to_vector(EvaluationFunction.default_weights())
    return Individual(genes)
end
const GAME_POSITIONS = [
    # openings
    "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",  # Start
    "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1", # e4
    "rnbqkbnr/pppppppp/8/8/3P4/8/PPP1PPPP/RNBQKBNR b KQkq - 0 1", # d4
    "r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 0 1", # italian
    "rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 0 1", # sycylian
    
    #middlegame
    "r1bq1rk1/ppp2ppp/2np1n2/2b1p3/2B1P3/2NP1N2/PPP2PPP/R1BQ1RK1 w - - 0 1", 
    "r2q1rk1/ppp2ppp/2n1bn2/3pp3/2B1P3/2NP1N2/PPP2PPP/R1BQR1K1 b - - 0 1",
    
    #endgame
    # pawn
    "8/5pk1/5p1p/5P1P/8/6K1/8/8 w - - 0 1",
    "8/8/8/pPk5/P7/2K5/8/8 w - - 0 1",
    "4k3/5p2/6p1/7P/6P1/8/8/2K5 w - - 0 1",
    "8/2kP4/2P5/6K1/8/7p/8/8 w - - 0 1",
    "4b3/p1k5/6p1/3B4/7p/1P1K2nP/4N1P1/8 b - - 0 1",
    "8/8/4k3/p3P1p1/4K1P1/7P/8/8 b - - 0 1",
    
    # rook
    "8/5pk1/r5pp/P7/3R3P/6P1/5PK1/8 w - - 0 1",
    "r5k1/5p1p/8/4P1p1/1pp3P1/5P1P/1P6/3R2K1 b - - 0 31",
    "8/R5pp/2p1k3/2p2p2/2P5/1P2P1P1/P3r2P/6K1 b - - 0 29",
    
    "8/8/8/4K3/7P/8/1k6/n7 b - - 0 1",#knight vs pawn
    "5n2/8/7P/5K2/8/8/1k6/8 w - - 0 1",
    "8/8/8/3K4/7P/8/2k5/n7 b - - 0 1",
    #bishop vs pawn
    "2b5/4k3/8/3BP3/5K2/8/8/8 w - - 0 2",
    "8/8/b7/3BP3/8/6k1/8/1K6 b - - 0 1",
    "8/4K3/2BP4/8/6b1/6k1/8/8 w - - 0 1",
    
    # queen
    "8/8/8/8/5K2/8/5pk1/3Q4 w - - 0 1",
    "6KQ/8/8/8/8/2p5/3k4/8 b - - 0 1",
    #blocked pawns
    "8/5pk1/4p1p1/3pP1P1/3P4/8/6K1/8 w - - 0 1",

    "8/8/8/8/2R1k3/2K5/1P6/3r4 b - - 0 1", #rooks
]
function tournament_selection(population::Vector{Individual},config::GAConfig)
    best = nothing
    for _ in 1:config.tournament_size
        candidate = rand(population)
        if best === nothing || candidate.fitness > best.fitness
            best = candidate
        end
    end
    return best
end
function crossover(parent1::Individual,parent2::Individual,current_rate::Float64,config::GAConfig)
    if rand() > current_rate
        return Individual(copy(parent1.genes)),Individual(copy(parent2.genes))
    end
    alpha = rand()
    #tutorials point whole arithmetic recombination
    genes1 = parent1.genes .* alpha + parent2.genes .* (1-alpha)
    genes2 = parent2.genes .*alpha + parent1.genes .* (1-alpha)
    return Individual(genes1),Individual(genes2)
end
function mutate!(ind::Individual,config::GAConfig)
    for i in eachindex(ind.genes)
        if rand()<config.mutation_rate
            change = 1.0 + (randn()*config.mutation_strength)
            ind.genes[i] = clamp(ind.genes[i]*change,config.min_weights,config.max_weights)
        end
    end
    
end
#fitness
function check_game_result(board::Chess.Board,color_perspective,moves_count::Int,max_moves::Int)
    if isempty(Chess.moves(board))
        if Chess.ischeckmate(board)
            return Chess.sidetomove(board) != color_perspective ? 1.0 : 0.0
        else
            return 0.5 #stalemate
        end
    end
    if Chess.isstalemate(board) || Chess.ismaterialdraw(board) || Chess.isdraw(board)
        return 0.5
    end
    if moves_count>=max_moves
        score = EvaluationFunction.evaluate(board)
        threshold = 100.0
        if color_perspective == WHITE
            return score>threshold ? 1.0 : (score< -threshold ? 0.0 : 0.5)
        else
            return score<-threshold ? 1.0 : (score>threshold ? 0.0 : 0.5)
        end
    end
    return -1.0 #game in progress
end
function play_game(white_genes::Vector{Float64},black_genes::Vector{Float64},fen::String,config::GAConfig)
    board = Chess.fromfen(fen)
    moves_count = 0
    w_weights = EvaluationFunction.vector_to_weights(white_genes)
    b_weights = EvaluationFunction.vector_to_weights(black_genes)
    black_pawn_files = EvaluationFunction.vector_to_weights(black_genes)
    while moves_count<config.max_moves_per_game
        turn = Chess.sidetomove(board)
        if turn == WHITE
            EvaluationFunction.set_weights!(w_weights)
        else
            EvaluationFunction.set_weights!(b_weights)
        end
        score,move = Search.search_parallel(board, config.search_depth, use_book=false, verbose=false)
        if move===nothing
            break
        end
        Chess.domove!(board,move)
        moves_count+=1
        result = check_game_result(board,turn,moves_count,config.max_moves_per_game)
        if result != -1.0
            return result
        end
    end
    return 0.5
end
function play_demo_game(genes::Vector{Float64}, config::GAConfig)
    println("\n>>> PLAYING DEMO GAME (Best vs Best) <<<")
    board = Chess.startboard()
    moves_count = 0
    weights = EvaluationFunction.vector_to_weights(genes)
    EvaluationFunction.set_weights!(weights) 
    
    pgn_string = ""
    
    while moves_count < 150 
        moves_count += 1
        turn_num = ceil(Int, moves_count / 2)
        
        if moves_count % 2 != 0
            pgn_string *= "$turn_num. "
        end

        score, move = Search.search_parallel(board, config.search_depth, use_book=true, verbose=false)
        
        if move === nothing
            println("No move found.")
            break
        end
        
        try
            move_san = Chess.san(board, move)
            pgn_string *= "$move_san "
            print("$move_san ") 
        catch e
            move_str = Chess.tostring(move)
            pgn_string *= "$move_str "
            print("$move_str ")
        end
        # --------------------------------------------------
        
        Chess.domove!(board, move)
        
        if Chess.ischeckmate(board)
            println("\nCheckmate!")
            result = (moves_count % 2 != 0) ? "1-0" : "0-1"
            break
        elseif Chess.isdraw(board)
            println("\nDraw!")
            pgn_string *= "1/2-1/2"
            break
        end
    end
    println("\nGame Over.")
    
    open("last_game.pgn", "w") do io
        println(io, "[Event \"Training Demo Game\"]")
        println(io, "[Site \"Localhost\"]")
        println(io, "[White \"BestBot\"]")
        println(io, "[Black \"BestBot\"]")
        println(io, "[Result \"*\"]") 
        println(io, "")
        println(io, pgn_string)
    end
    println(">>> Demo game saved to 'last_game.pgn' (SAN format) <<<")
end
function evaluate_population!(population::Vector{Individual},config::GAConfig)
    baseline = default_individual()
    println("Starting evaluation of $(length(population)) individuals")
    for (i,ind) in enumerate(population)
        points = 0.0
        ind.games_played = 0
        ind.wins = 0
        ind.draws = 0
        ind.losses = 0
        for j in 1:config.games_per_fitness
            fen = rand(GAME_POSITIONS)
            is_white = j%2 !=0
            if is_white
                result = play_game(ind.genes,baseline.genes,fen,config)
            else
                white_score = play_game(baseline.genes,ind.genes,fen,config)
                result =1.0-white_score
            end
            points+=result
            ind.games_played +=1
            if result == 1.0 ind.wins+=1
            elseif result==0.5 ind.draws+=1
            elseif result ==0.0 ind.losses+=1
            end
        end
        ind.fitness=points
    end
    println("Evaluation Complete")
end
function optimize(config::GAConfig;start_genes::Vector{Float64}=Float64[])
    # population = [random_individual(config) for _ in 1:config.population_size]
    # population[1] = default_individual()
    # best_ever = population[1]
    population = Vector{Individual}()
    println("DEBUG: Received start_genes length: $(length(start_genes))")
    if !isempty(start_genes)
        println("Loaded previous weights")
        push!(population,Individual(copy(start_genes)))
        for _ in 2:config.population_size
            ind = Individual(copy(start_genes))
            mutate!(ind, config)
            push!(population, ind)
        end
        best_ever = population[1]
    else
        println("Default weights")
        population = [random_individual(config) for _ in 1:config.population_size]
        population[1] = default_individual()
        best_ever = population[1]
    end
    for gen in 1:config.generations
        println("------------ Gen $gen -------")
        evaluate_population!(population,config)
        sort!(population, by= x->x.fitness,rev = true)
        if population[1].fitness>=best_ever.fitness
            current_gen_crossover_rate = min(1.0, config.crossover_rate + 0.2)
        else
            current_gen_crossover_rate = config.crossover_rate
        end
        if population[1].fitness>best_ever.fitness
            best_ever = deepcopy(population[1])
            println("New best found: fitness = $(best_ever.fitness)")
            println("Stats wins: $(best_ever.wins), draws: $(best_ever.draws), losses: $(best_ever.losses)")
        end
        println("Best in gen $gen: $(population[1].fitness) pts")
        if gen%2==0
            println("Checkpoint: Saving best wweights to best_weights$gen.txt")
            open("best_weights$gen.txt","w") do io
                for w in (best_ever.genes)
                    println(io,w)
                end
            end
        end
        #elitism 
        new_population = Vector{Individual}()
        for i in 1:config.elitism_count
            push!(new_population,deepcopy(population[i]))
        end
        #new population
        while length(new_population) < config.population_size
            parent1 = tournament_selection(population,config)
            parent2= tournament_selection(population,config)
            child1,child2 = crossover(parent1,parent2,current_gen_crossover_rate,config)
            mutate!(child1,config)
            mutate!(child2,config)
            push!(new_population,child1)
            if length(new_population)<config.population_size
                push!(new_population,child2)
            end
        end
        population  = new_population
    end
    play_demo_game(best_ever.genes, config)
    return best_ever
end
export optimize,GAConfig
end#module