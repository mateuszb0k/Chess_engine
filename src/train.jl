using Pkg
Pkg.activate(".")
include("GeneticOptimizer.jl")
include("EvaluationFunction.jl")
using .GeneticOptimizer
using .EvaluationFunction
config = GeneticOptimizer.GAConfig(
    population_size=20,
    generations = 30,
    games_per_fitness = 8,
    search_depth = 3,
    max_moves_per_game=50,
    mutation_rate=0.2
)
println("Starting evolution")
@time best_ind = GeneticOptimizer.optimize(config)
println("Optimization finished")
println("Best fitness: $(best_ind.fitness)")
best_weights = EvaluationFunction.vector_to_weights(best_ind.genes)
println(best_weights)