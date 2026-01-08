module TranspositionTable
struct TTEntry
    hash::UInt64
    depth::Int
    score::Float64
    best_move::Any
end
const TABLE = Dict{UInt64,TTEntry}()
function clear()
    empty!(TABLE)
end
function store(hash::UInt64,depth::Int,score::Float64,best_move::Any)
    existing = get(TABLE,hash,nothing)
    if isnothing(existing) || existing.depth<=depth
        TABLE[hash] = TTEntry(hash,depth,score,best_move)
    end
end
function lookup(hash::UInt64)
    return get(TABLE,hash,nothing)
end
end