using Pkg
Pkg.activate(".")
using Chess

include("Zobrist.jl")
include("TranspositionTable.jl")
include("Material.jl")
include("MoveOrdering.jl")
include("OpeningBook.jl")
include("Search.jl")

using .Material
using .Search
using .OpeningBook
function file_to_int(f)
        files = [FILE_A, FILE_B, FILE_C, FILE_D, FILE_E, FILE_F, FILE_G, FILE_H]
        for (i,file) in enumerate(files)
            if f==file
                return i
            end
        end
    return 0
end
function rank_to_int(r)
    ranks = [RANK_1, RANK_2, RANK_3, RANK_4, RANK_5, RANK_6, RANK_7, RANK_8]
    for (i,rank) in enumerate(ranks)
        if r ==rank
            return i
        end
    end
    return 0
end
function get_pawn_info(board::Chess.Board)
    white_pawn_squares = squares(Chess.pawns(board,WHITE))
    black_pawn_squares = squares(Chess.pawns(board,BLACK))
    white_pawn_files=Set{Int}()
    black_pawn_files=Set{Int}()
    for sq in white_pawn_squares
        push!(white_pawn_files,file_to_int(Chess.file(sq)))
    end
    for sq in black_pawn_squares
        push!(black_pawn_files,file_to_int(Chess.file(sq)))
    end
    return white_pawn_files,black_pawn_files,white_pawn_squares,black_pawn_squares
end
# b = startboard()
# println(b)
# println(Chess.pawns(b))
# Chess.domove!(b,"e2e4")
# println(Chess.pawns(b))
# println(b)
# println(b)
board = Chess.fromfen("8/2p5/3p4/3P4/8/8/8/8 w - - 0 1")

white_pawn_files,black_pawn_files,white_pawn_squares,black_pawn_squares=get_pawn_info(board)
white_pawn_ranks = Dict{Int, Vector{Int}}()
black_pawn_ranks = Dict{Int, Vector{Int}}()
for sq in white_pawn_squares
        f = file_to_int(Chess.file(sq))
        r = rank_to_int(Chess.rank(sq))
        if !haskey(white_pawn_ranks,f)
            white_pawn_ranks[f] = Int[]
            push!(white_pawn_ranks[f],r)
        end
    end
for sq in black_pawn_squares
        f = file_to_int(Chess.file(sq))
        r = rank_to_int(Chess.rank(sq))
        if !haskey(black_pawn_ranks,f)
            black_pawn_ranks[f] = Int[]
            push!(black_pawn_ranks[f],r)
        end
    end
for (file,ranks) in black_pawn_ranks
    for rank in ranks
        has_left = haskey(black_pawn_ranks,file-1)
        has_right = haskey(black_pawn_ranks,file+1)
        if !has_left && !has_right
            continue
        end
        left_is_ahead = !has_left || all(r->r<rank,black_pawn_ranks[file-1])
        right_is_ahead = !has_right || all(r->r<rank,black_pawn_ranks[file+1])
        if left_is_ahead && right_is_ahead
            println("huj")
        end
    end
end
# global is_passed = true
# for (file,ranks) in white_pawn_ranks
#     for rank in ranks
#         is_passed = true
#         for r in rank+1:8
#             for f in file-1:file+1
#                 if !(Square((f - 1) * 8 + (8 - r-1) + 1) in black_pawn_squares)
#                     #passed 
#                     global is_passed = false
                
#                 end
#             end
#         end
#     end
# end
# if is_passed
#     print("PASSSED")
# end
# board = startboard()
# rooks = Chess.rooks(board,WHITE)
# if squares(rooks)[2] in rookattacks(board,squares(rooks)[1])
#     println("cipeczka")
# end
# println(rookattacks(board,squares(rooks)[1]))
# println(rooks)
# pawns = Chess.pawns(board,BLACK)
# knights = Chess.knights(board,WHITE)
# file = [file_to_int(Chess.file(pawn)) for pawn in pawns]
# for pawn in pawns
#     global file = file_to_int(Chess.file(pawn))
#     global rank =rank_to_int(Chess.rank(pawn))
#     print(rank,file)
#     print(8*(file)+rank-1)
#     print(Square((file - 1) * 8 + (8 - rank+1) + 1))
#     black_potential = pawnattacks(BLACK,Square((file - 1) * 8 + (8 - rank+1) + 1))
#     println(squares(black_potential))
#     println(squares(knights))
#     print(pawn)
# end
# white_attacks = [Chess.pawnattacks(WHITE,pawn) for pawn in squares(pawns)]
# println(white_attacks)
# p_prot=Chess.pawnattacks(WHITE,SQ_D3)
# for sq in p_prot
#     if Chess.pieceon(board,sq) == PIECE_WN
#         print("cipka")
#     end
# end
# book_move = OpeningBook.get_book_move(b)
# println("Ruch z książki:  $book_move")

# println("\n=== Test Search z Iterative Deepening ===")
# b = startboard()
# @time score, best_move = Search.search(b, 7,false,true)
# println("\nNajlepszy ruch: $best_move, ocena: $score")

# println("\n=== Test z Opening Book ===")
# b = startboard()
# @time score, best_move = Search.search(b, 7,true,true)
# println("Wybrany ruch: $best_move")