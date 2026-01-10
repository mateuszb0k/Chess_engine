module TranspositionTable
using Chess
using Base.Threads
const EXACT =0
const LOWER_BOUND = 1
const UPPER_BOUND = 2
struct TTEntry
    hash::UInt64
    depth::Int
    score::Float64
    best_move::Union{Chess.Move,Nothing}
    flag::Int
end
const TABLE_SIZE = 2^20
const TABLE = Vector{Union{TTEntry,Nothing}}(nothing, TABLE_SIZE)
const LOCKS = [ReentrantLock() for _ in 1:256] #256 locks for sharding
function get_lock_index(hash::UInt64)
    return(hash%256)+1
end
function index(hash::UInt64)
    return (hash%TABLE_SIZE) +1
end

function store(hash::UInt64,depth::Int,score::Float64,best_move::Union{Chess.Move,Nothing},flag::Int=EXACT)
    idx = index(hash)
    lock_idx = get_lock_index(hash)
    @lock LOCKS[lock_idx] begin
        existing = TABLE[idx]
        if existing === nothing || existing.hash==hash || depth>=existing.depth
            TABLE[idx] = TTEntry(hash,depth,score,best_move,flag)
        end
    end
end
function lookup(hash::UInt64)
    idx = index(hash)
    entry = TABLE[idx]
    if entry !==nothing && entry.hash == hash
        return entry
    end
    return nothing
end
function clear()
    fill!(TABLE,nothing)
end
export TTEntry,store,lookup,clear,EXACT,LOWER_BOUND,UPPER_BOUND
end