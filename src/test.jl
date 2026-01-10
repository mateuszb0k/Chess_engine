# test_engine.jl
using Chess

println("="^70)
println("CHESS ENGINE TEST SUITE")
println("="^70)
println("Julia threads: $(Threads.nthreads())")
println()

# Include modules
include("EvaluationFunction.jl")
include("Zobrist.jl")
include("TranspositionTable.jl")
include("MoveOrdering.jl")
include("OpeningBook.jl")
include("Search.jl")

using .EvaluationFunction
using .Search


println("\n" * "="^70)
println("TEST 1: EVALUATION FUNCTION")
println("="^70)

test_positions = [
    ("Starting position", "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", 0),
    ("White up a pawn", "rnbqkbnr/ppp1pppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", 100),
    ("White up a knight", "rnbqkb1r/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", 320),
    ("White up a queen", "rnb1kbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", 900),
]

println("\nBasic material evaluation:")
for (name, fen, expected_approx) in test_positions
    board = fromfen(fen)
    score = EvaluationFunction.evaluate(board)
    status = abs(score - expected_approx) < 200 ? "✓" : "?"
    println("  $status $name: $(round(score, digits=1)) (expected ~$expected_approx)")
end


# println("\n" * "="^70)
# println("TEST 2: SEARCH (Single-threaded)")
# println("="^70)

# println("\nStarting position (depth 4):")
# board = startboard()
# start = time()
# score, move = Search.search(board, 4, use_book=false, verbose=true)
# elapsed = time() - start
# println("Result: $move, Score: $(round(score, digits=2)), Time: $(round(elapsed, digits=2))s")



println("\n" * "="^70)
println("TEST 3: TACTICAL POSITIONS")
println("="^70)

tactical_tests = [
    ("Mate in 1", "6k1/5ppp/8/8/8/8/8/4R2K w - - 0 1", "e1e8"),
    ("Win Queen", "r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 0 1", "h5f7"),
    ("Fork", "r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 0 1", "f3e5"),
]

for (name, fen, expected_move) in tactical_tests
    println("\n$name:")
    board = fromfen(fen)
    println(board)
    score, move = Search.search_parallel(board, 5, use_book=false, verbose=false)
    move_str = lowercase(string(move))
    status = move_str == expected_move ? "✓" : "✗"
    println("$status Found: $move (expected:  $expected_move), Score: $(round(score, digits=1))")
end



println("\n" * "="^70)
println("TEST 4: PARALLEL SEARCH")
println("="^70)

if Threads.nthreads() > 1
    println("\nParallel search (depth 5) with $(Threads.nthreads()) threads:")
    board = startboard()
    Search.reset_stats!()
    start = time()
    score, move = Search.search_parallel(board, 5, use_book=false, verbose=true)
    elapsed = time() - start
    nodes = Search.STATS.nodes[]
    println("Result: $move, NPS: $(round(Int, nodes/elapsed))")
else
    println("\n⚠ Only 1 thread available. Run with:  julia -t 4 test_engine.jl")
end



println("\n" * "="^70)
println("TEST 5: OPENING BOOK")
println("="^70)

println("\nStarting position with book:")
board = startboard()
score, move = Search.search_parallel(board, 1, use_book=true, verbose=true)
println("Book move: $move")


println("\n" * "="^70)
println("TEST 6: PERFORMANCE BENCHMARK")
println("="^70)

positions = [
    ("Opening", "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1"),
    ("Middlegame", "r1bq1rk1/ppp2ppp/2np1n2/2b1p3/2B1P3/2NP1N2/PPP2PPP/R1BQ1RK1 w - - 0 1"),
    ("Endgame", "8/5pk1/5p1p/8/8/5P1P/5PK1/8 w - - 0 1"),
]

println("\nBenchmark (depth 5):")
global total_nodes = 0
global total_time = 0.0

for (name, fen) in positions
    board = fromfen(fen)
    Search.reset_stats!()
    start = time()
    score, move = Search.search_parallel(board, 5, use_book=false, verbose=false)
    elapsed = time() - start
    nodes = Search.STATS.nodes[]
    nps = round(Int, nodes / elapsed)
    global total_nodes += nodes
    global total_time += elapsed
    println("  $name: $move | $(round(elapsed, digits=2))s | $nodes nodes | $nps NPS")
end

println("\nTotal:  $(round(total_time, digits=2))s, $total_nodes nodes, $(round(Int, total_nodes/total_time)) NPS")


println("\n" * "="^70)
println("ALL TESTS COMPLETED!")
println("="^70)