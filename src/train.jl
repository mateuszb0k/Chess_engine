using Pkg
Pkg.activate(".")
include("GeneticOptimizer.jl")
include("EvaluationFunction.jl")
using .GeneticOptimizer
using .EvaluationFunction
using Serialization
config = GeneticOptimizer.GAConfig(
    population_size=20, 
    generations = 20,
    games_per_fitness = 25,
    search_depth = 5,
    max_moves_per_game=50,
    mutation_rate=0.2
)
start_genes = Float64[]
weights_file = "best_weights2.txt"
if isfile(weights_file)
    println("Weights found $weights_file ")
    try
        lines = readlines(weights_file)
        global start_genes = [parse(Float64, strip(l)) for l in lines if !isempty(strip(l))]
        print(start_genes)
    catch e
        println("Error reading the file $e")
        println("default genes")
        start_genes = Float64[]
    end
else
    println("No file found")
end
println("Starting evolution...")
@time best_ind = GeneticOptimizer.optimize(config, start_genes=start_genes)
println("Optimization finished")
println("Best fitness: $(best_ind.fitness)")
println("Wins: $(best_ind.wins), Draws: $(best_ind.draws), Losses:$(best_ind.losses)") 
println("Saving final best weights to 'best_weights.txt'...")
open("best_weights_t2.txt", "w") do io
    for w in best_ind.genes
        println(io, w)
    end
end
println("Saved!")